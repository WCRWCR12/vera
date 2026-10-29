#!/usr/bin/env python3
"""Vera Screen: a one-page command screen for your AI assistant.

Reads the assistant's markdown files (tasks.md, schedule.md, log.md, goals.md, reminders.md) live and
shows today's one thing, the next three, habits and streaks, the schedule and the "Only you" list.
Ticking a task writes ONE status cell in tasks.md and ONE row in log.md (backup first, atomic replace).

Python 3.9+ standard library only. Binds 127.0.0.1 (this computer only).
Security: every /api/ request needs the per-install key (header X-Vera-Token). The key lives in
screen/.token (owner-only file, created on first start). The launcher hands it to the browser in the
URL fragment (#vt=...), which is never sent over HTTP. Writes also need a same-origin request.
Never add OPTIONS or CORS handling to this server.

    python server.py --open            # http://127.0.0.1:5191, opens the browser (folder = the parent folder)
    python server.py --port 5199 --dir /path/to/assistant-folder
"""
import argparse
import datetime as dt
import hashlib
import hmac
import json
import os
import re
import secrets
import shutil
import socket
import sys
import tempfile
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(HERE, "web")
DATA = os.path.join(HERE, "data")
BACKUPS = os.path.join(HERE, "backups")
TOKEN_PATH = os.path.join(HERE, ".token")
LOCK = threading.Lock()
MAX_BODY = 65536

ap = argparse.ArgumentParser()
ap.add_argument("--port", type=int, default=int(os.environ.get("VERA_SCREEN_PORT", "5191")))
ap.add_argument("--dir", default=os.environ.get("VERA_DIR", os.path.dirname(HERE)))
ap.add_argument("--open", action="store_true", help="open the screen in the browser once it is running")
ARGS = ap.parse_args()
VERA = os.path.abspath(ARGS.dir)


def load_token():
    """Per-install key. Created once with owner-only permissions, then reused."""
    try:
        with open(TOKEN_PATH, encoding="utf-8") as f:
            tok = f.read().strip()
        if len(tok) >= 32:
            return tok
    except OSError:
        pass
    tok = secrets.token_urlsafe(32)
    fd = os.open(TOKEN_PATH, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(tok)
    return tok


TOKEN = load_token()


# ---------------------------------------------------------------- helpers
def read(path, default=""):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except OSError:
        return default


def read_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def write_atomic(path, text):
    d = os.path.dirname(path)
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-")
    with os.fdopen(fd, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    os.replace(tmp, path)


def backup(path):
    if not os.path.exists(path):
        return
    os.makedirs(BACKUPS, exist_ok=True)
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    shutil.copy2(path, os.path.join(BACKUPS, f"{os.path.basename(path)}.{stamp}.bak"))
    olds = sorted(f for f in os.listdir(BACKUPS) if f.startswith(os.path.basename(path) + "."))
    for f in olds[:-60]:
        try:
            os.remove(os.path.join(BACKUPS, f))
        except OSError:
            pass


def settings():
    s = read_json(os.path.join(DATA, "screen.json"), {})
    return {"owner": s.get("owner") or "there", "assistant": s.get("assistant") or "Vera", "timezone": s.get("timezone") or ""}


def now():
    tz = settings()["timezone"]
    if tz:
        try:
            from zoneinfo import ZoneInfo
            return dt.datetime.now(ZoneInfo(tz)).replace(tzinfo=None)
        except Exception:
            pass
    return dt.datetime.now()


def branding():
    s = read_json(os.path.join(DATA, "screen.json"), {})
    return {"on": s.get("branding", True) is not False, "url": "https://systemgc.com.au", "name": "System GC"}


# ---------------------------------------------------------------- markdown tables
def split_row(line):
    s = line.strip()
    if not s.startswith("|"):
        return None
    s = s[1:-1] if s.endswith("|") else s[1:]
    return [c.strip() for c in s.split("|")]


def is_sep(cells):
    return cells and all(re.fullmatch(r":?-{2,}:?", c or "") for c in cells)


def tables(text):
    """Yield (header, [(line_no, cells)]) for every markdown table."""
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        head = split_row(lines[i])
        if head and i + 1 < len(lines) and is_sep(split_row(lines[i + 1]) or []):
            rows, j = [], i + 2
            while j < len(lines) and split_row(lines[j]) is not None:
                rows.append((j, split_row(lines[j])))
                j += 1
            yield [h.lower() for h in head], rows
            i = j
        else:
            i += 1


DONE_RE = re.compile(r"^\s*(done|completed|closed|finished|shipped|resolved|\[x\])", re.I)
DROP_RE = re.compile(r"^\s*(dropped|cancelled|canceled|abandoned|superseded)", re.I)
WAIT_RE = re.compile(r"^\s*waiting", re.I)
DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})(?:[ T](\d{1,2}:\d{2}))?")


def task_key(tid, text):
    return f"{tid}:{hashlib.sha1(text.encode('utf-8')).hexdigest()[:8]}"


def parse_tasks():
    out = []
    for head, rows in tables(read(os.path.join(VERA, "tasks.md"))):
        if "task" not in head or "id" not in head:
            continue
        col = {h: k for k, h in enumerate(head)}
        for line_no, c in rows:
            get = lambda name: c[col[name]] if name in col and col[name] < len(c) else ""
            tid, text, status, due = get("id"), get("task"), get("status"), get("due")
            if not tid or not text:
                continue
            m = DATE_RE.search(due or "")
            done_m = DATE_RE.search(status or "")
            state = "done" if DONE_RE.match(status) else "dropped" if DROP_RE.match(status) else "waiting" if WAIT_RE.match(status) else "open"
            out.append({
                "id": tid, "text": text, "due": m.group(1) if m else None, "time": m.group(2) if m and m.group(2) else None,
                "status": status, "state": state, "doneOn": done_m.group(1) if state == "done" and done_m else None,
                "nudges": get("nudges"), "notes": get("notes"), "key": task_key(tid, text), "line": line_no,
            })
    return out


def parse_schedule(today):
    text = read(os.path.join(VERA, "schedule.md"))
    days = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
    tomorrow = today + dt.timedelta(days=1)

    def on_day(spec, d):
        s = spec.lower().strip()
        if DATE_RE.search(s):
            return DATE_RE.search(s).group(1) == d.isoformat()
        wd = d.weekday()
        if s in ("daily", "every day", "everyday"):
            return True
        m = re.match(r"(mon|tue|wed|thu|fri|sat|sun)[a-z]*\s*-\s*(mon|tue|wed|thu|fri|sat|sun)", s)
        if m:
            a, b = days.index(m.group(1)), days.index(m.group(2))
            return a <= wd <= b if a <= b else wd >= a or wd <= b
        return any(s.startswith(x) and days.index(x) == wd for x in days)

    res = {"today": [], "tomorrow": []}
    for head, rows in tables(text):
        if "what" not in head:
            continue
        col = {h: k for k, h in enumerate(head)}
        key = "date" if "date" in col else "day" if "day" in col else None
        if key is None:
            continue
        for _, c in rows:
            spec = c[col[key]] if col[key] < len(c) else ""
            item = {"time": c[col["time"]] if "time" in col and col["time"] < len(c) else "", "what": c[col["what"]] if col["what"] < len(c) else ""}
            if not item["what"]:
                continue
            if on_day(spec, today):
                res["today"].append(item)
            if on_day(spec, tomorrow):
                res["tomorrow"].append(item)
    for k in res:
        res[k].sort(key=lambda x: x["time"] or "99")
    return res


def parse_log(limit=8):
    out = []
    for head, rows in tables(read(os.path.join(VERA, "log.md"))):
        if "what" not in head:
            continue
        col = {h: k for k, h in enumerate(head)}
        for _, c in rows[:limit]:
            out.append({h: (c[k] if k < len(c) else "") for h, k in col.items()})
        break
    return out


def parse_goals():
    goals = []
    for line in read(os.path.join(VERA, "goals.md")).split("\n"):
        m = re.match(r"\s*\d+\.\s+(.+)", line)
        if m and m.group(1).strip():
            goals.append(m.group(1).strip())
    return goals[:3]


# ---------------------------------------------------------------- state + streaks
def state():
    return read_json(os.path.join(DATA, "state.json"), {"habits": {}, "onlyyou": {}, "active": [], "mit": {}})


def save_state(s):
    write_atomic(os.path.join(DATA, "state.json"), json.dumps(s, indent=2) + "\n")


def run_length(days_set, today):
    """Consecutive days ending today (or yesterday, if today isn't done yet: the streak is still alive)."""
    d = today if today.isoformat() in days_set else today - dt.timedelta(days=1)
    n = 0
    while d.isoformat() in days_set:
        n += 1
        d -= dt.timedelta(days=1)
    return n


def best_run(days_set):
    best, cur, prev = 0, 0, None
    for s in sorted(days_set):
        d = dt.date.fromisoformat(s)
        cur = cur + 1 if prev and (d - prev).days == 1 else 1
        best, prev = max(best, cur), d
    return best


def build_state():
    n = now()
    today = n.date()
    t_iso = today.isoformat()
    tasks = parse_tasks()
    st = state()
    habits_cfg = read_json(os.path.join(DATA, "habits.json"), [])
    active = set(st.get("active", []))
    active |= {t["doneOn"] for t in tasks if t["doneOn"]}
    active |= {d for d, ids in st.get("habits", {}).items() if ids}

    habits = []
    for h in habits_cfg:
        days = {d for d, ids in st.get("habits", {}).items() if h.get("id") in ids}
        week = [(today - dt.timedelta(days=6 - i)).isoformat() in days for i in range(7)]
        habits.append({**h, "doneToday": t_iso in days, "streak": run_length(days, today), "week": week})

    open_ = [t for t in tasks if t["state"] == "open"]
    waiting = [t for t in tasks if t["state"] == "waiting"]

    def when(t):
        return (t["due"] or "9999-12-31", t["time"] or "99:99", t["id"])

    open_.sort(key=when)
    groups = {"overdue": [], "today": [], "week": [], "later": [], "nodate": []}
    for t in open_:
        if not t["due"]:
            groups["nodate"].append(t)
        elif t["due"] < t_iso:
            groups["overdue"].append(t)
        elif t["due"] == t_iso:
            groups["today"].append(t)
        elif t["due"] <= (today + dt.timedelta(days=7)).isoformat():
            groups["week"].append(t)
        else:
            groups["later"].append(t)

    mit = st.get("mit", {})
    one = next((t for t in open_ if mit.get("date") == t_iso and mit.get("key") == t["key"]), None)
    one = one or (groups["overdue"] + groups["today"] + groups["week"] + groups["later"] + groups["nodate"] or [None])[0]
    rest = [t for t in groups["overdue"] + groups["today"] + groups["week"] if not one or t["key"] != one["key"]]

    onlyyou = []
    for item in read_json(os.path.join(DATA, "onlyyou.json"), []):
        onlyyou.append({**item, "done": item.get("id") in st.get("onlyyou", {})})

    replies = []
    for line in read(os.path.join(VERA, "inbox", "screen-replies.jsonl")).splitlines()[-20:]:
        try:
            replies.append(json.loads(line))
        except ValueError:
            pass

    s = settings()
    hour = n.hour
    return {
        "now": n.isoformat(timespec="minutes"), "today": t_iso, "owner": s["owner"], "assistant": s["assistant"],
        "greeting": "Good morning" if hour < 12 else "Good afternoon" if hour < 17 else "Evening wrap",
        "oneThing": one, "nextThree": rest[:3], "groups": groups, "waiting": waiting,
        "doneToday": [t for t in tasks if t["doneOn"] == t_iso],
        "doneWeek": len([t for t in tasks if t["doneOn"] and t["doneOn"] >= (today - dt.timedelta(days=6)).isoformat()]),
        "streak": {"current": run_length(active, today), "best": best_run(active), "aliveToday": t_iso in active},
        "habits": habits, "schedule": parse_schedule(today), "log": parse_log(), "goals": parse_goals(),
        "onlyyou": onlyyou, "replies": replies[-5:], "branding": branding(),
    }


# ---------------------------------------------------------------- writes
def log_row(text, who="screen", status="done"):
    path = os.path.join(VERA, "log.md")
    content = read(path)
    if not content:
        return
    lines = content.split("\n")
    for i in range(len(lines) - 1):
        if split_row(lines[i]) and is_sep(split_row(lines[i + 1]) or []):
            cols = len(split_row(lines[i]))
            cells = [now().date().isoformat(), f"{now().strftime('%H:%M')} {text}", who, status][:cols]
            cells += [""] * (cols - len(cells))
            lines.insert(i + 2, "| " + " | ".join(c.replace("|", "/") for c in cells) + " |")
            backup(path)
            write_atomic(path, "\n".join(lines))
            return


def tick_task(key):
    path = os.path.join(VERA, "tasks.md")
    with LOCK:
        matches = [t for t in parse_tasks() if t["key"] == key]
        if len(matches) != 1:
            return 409, {"error": "That task changed or moved. Refresh and try again."}
        t = matches[0]
        if t["state"] in ("done", "dropped"):
            return 409, {"error": "Already closed."}
        content = read(path)
        lines = content.split("\n")
        head = None
        for h, rows in tables(content):
            if any(ln == t["line"] for ln, _ in rows):
                head = h
        cells = split_row(lines[t["line"]])
        if head is None or "status" not in head or cells is None:
            return 409, {"error": "Could not find the status column."}
        stamp = now().strftime("%Y-%m-%d %H:%M")
        cells[head.index("status")] = f"done {stamp} (screen)"
        new_line = "| " + " | ".join(cells) + " |"
        check = split_row(new_line)
        if [c for k, c in enumerate(check) if k != head.index("status")] != [c for k, c in enumerate(split_row(lines[t["line"]])) if k != head.index("status")]:
            return 500, {"error": "Safety check failed; nothing written."}
        lines[t["line"]] = new_line
        backup(path)
        write_atomic(path, "\n".join(lines))
        log_row(f"Ticked task {t['id']} done on Vera Screen: {t['text']}")
        st = state()
        st.setdefault("active", [])
        if now().date().isoformat() not in st["active"]:
            st["active"].append(now().date().isoformat())
        save_state(st)
    return 200, {"ok": True}


def toggle_habit(hid):
    with LOCK:
        st = state()
        day = now().date().isoformat()
        ids = st.setdefault("habits", {}).setdefault(day, [])
        if hid in ids:
            ids.remove(hid)
        else:
            ids.append(hid)
        save_state(st)
    return 200, {"ok": True}


def toggle_onlyyou(oid):
    with LOCK:
        st = state()
        oy = st.setdefault("onlyyou", {})
        if oid in oy:
            del oy[oid]
        else:
            oy[oid] = now().isoformat(timespec="minutes")
            log_row(f"Ticked Only-you item on Vera Screen: {oid}. Assistant: check and carry on", status="waiting on assistant")
        save_state(st)
    return 200, {"ok": True}


def set_mit(key):
    with LOCK:
        st = state()
        st["mit"] = {"date": now().date().isoformat(), "key": key}
        save_state(st)
    return 200, {"ok": True}


def chat(text):
    text = str(text or "").strip()[:2000]
    if not text:
        return 400, {"error": "Empty message."}
    path = os.path.join(VERA, "inbox", "screen-chat.jsonl")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with LOCK, open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps({"ts": now().isoformat(timespec="seconds"), "from": "screen", "text": text}) + "\n")
    return 200, {"ok": True}


# ---------------------------------------------------------------- http
TYPES = {".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8",
         ".png": "image/png", ".woff2": "font/woff2", ".ico": "image/x-icon"}
# No inline script, nothing from other sites, never framed.
CSP = ("default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; "
       "connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'")


class H(BaseHTTPRequestHandler):
    server_version = "VeraScreen"
    sys_version = ""
    timeout = 30

    def log_message(self, *a):
        pass

    def host_ok(self):
        host = (self.headers.get("Host") or "").rsplit(":", 1)[0]
        return host in ("127.0.0.1", "localhost")

    def token_ok(self):
        given = self.headers.get("X-Vera-Token") or ""
        return hmac.compare_digest(given.encode("utf-8"), TOKEN.encode("utf-8"))

    def same_origin(self):
        origin = self.headers.get("Origin")
        if origin is not None and origin not in (f"http://127.0.0.1:{ARGS.port}", f"http://localhost:{ARGS.port}"):
            return False
        site = self.headers.get("Sec-Fetch-Site")
        return site in (None, "same-origin", "none")

    def send(self, code, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else json.dumps(body).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Security-Policy", CSP)
        self.send_header("X-Frame-Options", "DENY")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def do_HEAD(self):
        return self.do_GET()

    def do_GET(self):
        if not self.host_ok():
            return self.send(421, {"error": "wrong host"})
        p = urlparse(self.path).path
        if p.startswith("/api/"):
            if not self.same_origin() or not self.token_ok():
                return self.send(403, {"error": "forbidden: open Vera Screen with start-screen"})
            if p == "/api/state":
                try:
                    return self.send(200, build_state())
                except Exception as e:  # details to the console, never to the page
                    print(f"state error: {e!r}", file=sys.stderr)
                    return self.send(500, {"error": "internal error"})
            return self.send(404, {"error": "not found"})
        name = "index.html" if p in ("/", "") else p.lstrip("/")
        full = os.path.normpath(os.path.join(WEB, name))
        if (not full.startswith(WEB + os.sep) or not os.path.isfile(full)
                or os.path.splitext(full)[1].lower() not in TYPES):
            return self.send(404, {"error": "not found"})
        with open(full, "rb") as f:
            return self.send(200, f.read(), TYPES[os.path.splitext(full)[1].lower()])

    def do_POST(self):
        if not self.host_ok():
            return self.send(421, {"error": "wrong host"})
        if not self.same_origin() or not self.token_ok():
            return self.send(403, {"error": "forbidden"})
        try:
            n = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            return self.send(400, {"error": "bad length"})
        if n < 0 or n > MAX_BODY:
            return self.send(400, {"error": "bad length"})
        try:
            body = json.loads(self.rfile.read(n) or b"{}")
        except ValueError:
            return self.send(400, {"error": "bad json"})
        if not isinstance(body, dict):
            return self.send(400, {"error": "bad json"})
        p = urlparse(self.path).path
        routes = {
            "/api/task/done": lambda: tick_task(str(body.get("key", ""))),
            "/api/task/star": lambda: set_mit(str(body.get("key", ""))),
            "/api/habit": lambda: toggle_habit(str(body.get("id", ""))),
            "/api/onlyyou": lambda: toggle_onlyyou(str(body.get("id", ""))),
            "/api/chat": lambda: chat(body.get("text")),
        }
        if p not in routes:
            return self.send(404, {"error": "not found"})
        try:
            code, res = routes[p]()
        except Exception as e:
            print(f"write error: {e!r}", file=sys.stderr)
            return self.send(500, {"error": "internal error"})
        return self.send(code, res)


def port_open(port):
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=0.3):
            return True
    except OSError:
        return False


if __name__ == "__main__":
    url = f"http://127.0.0.1:{ARGS.port}/#vt={TOKEN}"
    if not os.path.exists(os.path.join(VERA, "tasks.md")):
        print(f"Warning: no tasks.md in {VERA}. Pass --dir <your assistant folder>.")
    if port_open(ARGS.port):
        print("Vera Screen is already running. Opening it.")
        if ARGS.open:
            webbrowser.open(url)
        sys.exit(0)
    srv = ThreadingHTTPServer(("127.0.0.1", ARGS.port), H)
    print(f"Vera Screen is running at http://127.0.0.1:{ARGS.port} (this computer only).")
    print("Close this window to stop it.")
    if ARGS.open:
        threading.Timer(0.5, lambda: webbrowser.open(url)).start()
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
