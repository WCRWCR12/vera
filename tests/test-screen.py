#!/usr/bin/env python3
"""Vera Screen security and smoke test. Runs the server from a throwaway copy on a spare port.

    python tests/test-screen.py
"""
import datetime as dt
import http.client
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PORT = 5961
PASS = FAIL = 0


def check(name, cond):
    global PASS, FAIL
    if cond:
        PASS += 1
        print(f"  ok    {name}")
    else:
        FAIL += 1
        print(f"  FAIL  {name}")


def req(method, path, headers=None, body=None, host=None):
    c = http.client.HTTPConnection("127.0.0.1", PORT, timeout=5)
    h = {"Host": host or f"127.0.0.1:{PORT}"}
    h.update(headers or {})
    if body is not None and not isinstance(body, bytes):
        body = json.dumps(body).encode()
    c.putrequest(method, path, skip_host=True)
    for k, v in h.items():
        c.putheader(k, v)
    if body is not None and "Content-Length" not in h:
        c.putheader("Content-Length", str(len(body)))
    c.endheaders()
    if body:
        c.send(body)
    r = c.getresponse()
    data = r.read()
    c.close()
    return r.status, dict(r.getheaders()), data


def main():
    tmp = tempfile.mkdtemp(prefix="vera-screen-test.")
    vera = os.path.join(tmp, "Vera")
    shutil.copytree(os.path.join(REPO, "vera"), vera)
    today = dt.date.today().isoformat()
    for root, _, files in os.walk(vera):
        for f in files:
            if f.endswith((".md", ".json")):
                p = os.path.join(root, f)
                s = open(p, encoding="utf-8").read()
                s = (s.replace("{{OWNER_NAME}}", "Sam").replace("{{ASSISTANT_NAME}}", "Vera").replace("{{TIMEZONE}}", "")
                     .replace("{{TODAY+3}}", today).replace("{{TODAY}}", today))
                open(p, "w", encoding="utf-8", newline="\n").write(s)
    srv = subprocess.Popen([sys.executable, "-E", "-s", os.path.join(vera, "screen", "server.py"), "--port", str(PORT), "--dir", vera],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    try:
        tok_path = os.path.join(vera, "screen", ".token")
        for _ in range(50):
            if os.path.exists(tok_path):
                try:
                    req("GET", "/")
                    break
                except OSError:
                    pass
            time.sleep(0.1)
        tok = open(tok_path, encoding="utf-8").read().strip()
        T = {"X-Vera-Token": tok}
        print(f"Vera Screen test on port {PORT} ({vera})")

        check("token created, 32+ chars", len(tok) >= 32)
        if os.name != "nt":
            check("token file is owner-only", (os.stat(tok_path).st_mode & 0o077) == 0)

        st, hd, body = req("GET", "/")
        check("page loads without the key", st == 200 and b"app.js" in body)
        csp = hd.get("Content-Security-Policy", "")
        check("CSP: scripts only from the page, never framed", "script-src 'self'" in csp and "frame-ancestors 'none'" in csp)
        check("X-Frame-Options DENY", hd.get("X-Frame-Options") == "DENY")
        check("server header has no version", hd.get("Server", "").startswith("VeraScreen") and "Python" not in hd.get("Server", ""))

        st, _, _ = req("GET", "/api/state")
        check("state without key -> 403", st == 403)
        st, _, _ = req("GET", "/api/state", {"X-Vera-Token": "x" * 43})
        check("state with wrong key -> 403", st == 403)
        st, _, body = req("GET", "/api/state", T)
        state = json.loads(body) if st == 200 else {}
        check("state with key -> 200", st == 200 and state.get("owner") == "Sam")
        check("no office in state", "office" not in state)
        st, _, _ = req("GET", "/api/state", dict(T, **{"Sec-Fetch-Site": "cross-site"}))
        check("cross-site read with key -> 403", st == 403)

        st, _, _ = req("GET", "/", host="evil.example")
        check("wrong Host header -> 421", st == 421)
        st, _, _ = req("HEAD", "/", host="evil.example")
        check("HEAD with wrong Host -> 421", st == 421)
        for path in ("/../server.py", "/..%2fserver.py", "/.token", "/../.token", "/../data/screen.json"):
            st, _, _ = req("GET", path)
            check(f"no file outside web/ ({path}) -> 404", st == 404)

        key = state["nextThree"][0]["key"] if state.get("nextThree") else (state.get("oneThing") or {}).get("key", "")
        st, _, _ = req("POST", "/api/task/done", {"Content-Type": "application/json"}, {"key": key})
        check("write without key -> 403", st == 403)
        st, _, _ = req("POST", "/api/task/done", dict(T, Origin="https://evil.example"), {"key": key})
        check("write from another site -> 403", st == 403)
        st, _, _ = req("POST", "/api/task/done", dict(T, **{"Sec-Fetch-Site": "same-site"}), {"key": key})
        check("write from a same-site page -> 403", st == 403)
        st, _, _ = req("POST", "/api/task/done", dict(T, **{"Content-Length": "-1"}), b"")
        check("negative Content-Length -> 400", st == 400)
        st, _, _ = req("POST", "/api/task/done", T, [1, 2])
        check("non-object JSON -> 400", st == 400)
        st, _, _ = req("POST", "/api/task/done", T, b"{not json")
        check("bad JSON -> 400", st == 400)
        st, _, _ = req("OPTIONS", "/api/task/done", T)
        check("no OPTIONS / CORS -> 501", st == 501)

        before = open(os.path.join(vera, "tasks.md"), encoding="utf-8").read()
        st, _, _ = req("POST", "/api/task/done", dict(T, Origin=f"http://127.0.0.1:{PORT}", **{"Sec-Fetch-Site": "same-origin"}), {"key": key})
        after = open(os.path.join(vera, "tasks.md"), encoding="utf-8").read()
        changed = [ln for ln in after.splitlines() if ln not in before.splitlines()]
        check("same-origin tick with key -> 200", st == 200)
        check("tick changes exactly one line of tasks.md", len(changed) == 1 and "| done" in changed[0])
        check("tick adds a log.md row", "screen" in open(os.path.join(vera, "log.md"), encoding="utf-8").read())
        st, _, _ = req("POST", "/api/task/done", T, {"key": key})
        check("second tick refused (409)", st == 409)
        st, _, _ = req("POST", "/api/chat", T, {"text": "hello from the test"})
        check("chat lands in inbox/screen-chat.jsonl", st == 200 and "hello from the test" in
              open(os.path.join(vera, "inbox", "screen-chat.jsonl"), encoding="utf-8").read())
    finally:
        srv.terminate()
        try:
            srv.wait(5)
        except subprocess.TimeoutExpired:
            srv.kill()
        shutil.rmtree(tmp, ignore_errors=True)
    print(f"Result: {PASS} passed, {FAIL} failed")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
