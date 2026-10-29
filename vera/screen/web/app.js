// Vera Screen front end. Plain JS, no build step. Re-reads /api/state every 60 s and on focus.
(function () {
  'use strict';
  var S = null;
  var TABS = [['today', 'Today'], ['tasks', 'Tasks'], ['streaks', 'Streaks'], ['onlyyou', 'Only you']];
  var tab = 'today';
  try { tab = localStorage.getItem('vera.tab') || 'today'; } catch (e) { /* private window */ }
  var FLAME = '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 2c1 3.5-1.5 5-1.5 7.5 0 1.4 1 2.5 2.3 2.5 1.5 0 2.4-1.2 2.2-3 2.3 1.6 4 4.3 4 7.2C19 20 15.9 22 12 22s-7-2-7-5.8c0-3 1.6-5 3.3-6.8C10.4 7.3 11.6 5 12 2z"/></svg>';

  function $(id) { return document.getElementById(id); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function toast(t) { var el = $('toast'); el.textContent = t; el.hidden = false; clearTimeout(toast.h); toast.h = setTimeout(function () { el.hidden = true; }, 1800); }

  // Per-install key: start-screen opens the page with #vt=<key>. Keep it for this tab only, then hide it from the address bar.
  var KEY = '';
  try {
    var m = /[#&]vt=([A-Za-z0-9_-]{32,})/.exec(location.hash);
    if (m) { sessionStorage.setItem('vera.key', m[1]); history.replaceState(null, '', location.pathname); }
    KEY = sessionStorage.getItem('vera.key') || '';
  } catch (e) { KEY = ''; }
  function safeUrl(u) { return /^https:\/\/[^\s"'<>]+$/i.test(String(u || '')) ? String(u) : ''; }

  function post(url, body) {
    return fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Vera-Token': KEY }, body: JSON.stringify(body) })
      .then(function (r) { return r.json().then(function (j) { if (!r.ok) throw new Error(j.error || 'Failed'); return j; }); });
  }
  function load() {
    return fetch('/api/state', { cache: 'no-store', headers: { 'X-Vera-Token': KEY } })
      .then(function (r) { if (r.status === 403) throw new Error('key'); return r.json(); }).then(function (s) { S = s; render(); })
      .catch(function (err) {
        $('main').innerHTML = err && err.message === 'key'
          ? '<div class="card">Open Vera Screen by double-clicking <b>start-screen</b> in your Vera folder. It passes this page its key.</div>'
          : '<div class="card">The screen is not running. Double-click <b>start-screen</b> in your Vera folder.</div>';
      });
  }

  function dueText(t) {
    if (!t.due) return 'no date';
    if (t.due < S.today) return 'carried from ' + t.due;
    if (t.due === S.today) return 'today' + (t.time ? ' ' + t.time : '');
    return t.due + (t.time ? ' ' + t.time : '');
  }
  function taskRow(t, opts) {
    opts = opts || {};
    return '<div class="task"><button class="check" data-done="' + esc(t.key) + '" title="Done" aria-label="Mark done"></button>' +
      '<div class="t"><div>' + esc(t.text) + (t.due && t.due < S.today ? '<span class="tag">carried</span>' : '') + '</div>' +
      '<div class="meta">' + esc(dueText(t)) + (t.notes ? ' · ' + esc(t.notes) : '') + '</div></div>' +
      (opts.star ? '<button class="star" data-star="' + esc(t.key) + '" title="Make this today\'s one thing">&#9734;</button>' : '') + '</div>';
  }
  function list(arr, opts) { return arr.length ? arr.map(function (t) { return taskRow(t, opts); }).join('') : '<p class="empty">Nothing here.</p>'; }

  function header() {
    $('title').textContent = S.assistant + ' Screen';
    document.title = S.assistant + ' Screen';
    $('tabs').innerHTML = TABS.map(function (t) { return '<button role="tab" data-tab="' + t[0] + '" aria-selected="' + (tab === t[0]) + '">' + t[1] + '</button>'; }).join('');
    var st = $('streak');
    st.className = 'streak' + (S.streak.aliveToday ? '' : ' cold');
    st.innerHTML = FLAME + '<span>' + S.streak.current + '</span>';
    st.style.color = S.streak.aliveToday ? 'var(--flame)' : '';
    var b = S.branding, a = $('sgc'), f = $('foot');
    a.hidden = true;
    if (b && b.on) {
      f.hidden = false;
      f.innerHTML = 'Powered by <a href="' + esc(b.url) + '" target="_blank" rel="noopener noreferrer">' + esc(b.name) + '</a>';
    } else { f.hidden = true; }
  }

  function today() {
    var one = S.oneThing;
    var h = '<section class="card w8"><h1>' + esc(S.greeting) + ', ' + esc(S.owner) + '.</h1>' +
      '<p class="sub">' + (S.doneToday.length ? S.doneToday.length + ' done today. ' : '') + S.doneWeek + ' this week.</p>' +
      '<h2 style="margin-top:18px">The one thing</h2>' +
      (one ? '<div class="task" style="border:0"><button class="check" data-done="' + esc(one.key) + '"></button><div class="t"><div class="one">' + esc(one.text) + '</div><div class="meta">' + esc(dueText(one)) + '</div></div></div>' : '<p class="empty">Nothing open. Enjoy it.</p>') +
      '<h2 style="margin-top:18px">Next three</h2>' + list(S.nextThree, { star: true }) + '</section>';
    h += '<section class="card w4"><h2>Streak</h2><div class="big" style="color:' + (S.streak.aliveToday ? 'var(--flame)' : 'var(--muted)') + '">' + FLAME + S.streak.current + '</div>' +
      '<p class="sub">' + (S.streak.aliveToday ? 'Alive today. Best: ' + S.streak.best + '.' : (S.streak.current ? 'Tick one thing today to keep it alive.' : 'Tick one thing to start a streak.')) + '</p>' +
      '<h2 style="margin-top:18px">Habits</h2>' + habits() + '</section>';
    h += '<section class="card w6"><h2>Today</h2>' + sched(S.schedule.today) + '<h2 style="margin-top:14px">Tomorrow</h2>' + sched(S.schedule.tomorrow) + '</section>';
    h += '<section class="card w6"><h2>Tell ' + esc(S.assistant) + '</h2><form class="chat" id="chat"><input id="chatText" placeholder="Anything. Tasks, ideas, reminders..." autocomplete="off"><button class="btn">Send</button></form>' +
      (S.replies.length ? S.replies.slice().reverse().map(function (r) { return '<div class="reply">' + esc(S.assistant) + ': ' + esc(r.text) + '</div>'; }).join('') : '') +
      '<h2 style="margin-top:16px">Latest from ' + esc(S.assistant) + '</h2>' +
      (S.log.length ? S.log.slice(0, 5).map(function (l) { return '<div class="row"><span class="time">' + esc(l.date || '') + '</span><span>' + esc(l.what || '') + '</span></div>'; }).join('') : '<p class="empty">Nothing yet.</p>') + '</section>';
    if (S.goals.length) h += '<section class="card"><h2>Goals</h2>' + S.goals.map(function (g, i) { return '<div class="row"><span class="time">' + (i + 1) + '</span><span>' + esc(g) + '</span></div>'; }).join('') + '</section>';
    return h;
  }
  function sched(rows) { return rows.length ? rows.map(function (r) { return '<div class="row"><span class="time">' + esc(r.time) + '</span><span>' + esc(r.what) + '</span></div>'; }).join('') : '<p class="empty">Nothing booked.</p>'; }
  function habits() {
    if (!S.habits.length) return '<p class="empty">No habits yet. Add them in screen/data/habits.json (or ask your assistant).</p>';
    return S.habits.map(function (hb) {
      return '<div class="habit"><button class="check' + (hb.doneToday ? ' on' : '') + '" data-habit="' + esc(hb.id) + '" title="' + esc(hb.why || '') + '"></button><span>' + esc(hb.label) + (hb.streak ? ' <span class="meta">' + hb.streak + ' days</span>' : '') + '</span>' +
        '<span class="dots">' + hb.week.map(function (on) { return '<i class="' + (on ? 'on' : '') + '"></i>'; }).join('') + '</span></div>';
    }).join('');
  }
  function tasks() {
    var g = S.groups;
    return '<section class="card w8"><h2>Carried over (' + g.overdue.length + ')</h2>' + list(g.overdue, { star: true }) +
      '<h2 style="margin-top:16px">Today (' + g.today.length + ')</h2>' + list(g.today, { star: true }) +
      '<h2 style="margin-top:16px">This week (' + g.week.length + ')</h2>' + list(g.week, { star: true }) +
      '<details><summary>Later (' + g.later.length + ')</summary>' + list(g.later) + '</details>' +
      '<details><summary>No date (' + g.nodate.length + ')</summary>' + list(g.nodate) + '</details></section>' +
      '<section class="card w4"><h2>Waiting on others (' + S.waiting.length + ')</h2>' + list(S.waiting) +
      '<h2 style="margin-top:16px">Done today</h2>' + (S.doneToday.length ? S.doneToday.map(function (t) { return '<div class="row"><span>' + esc(t.text) + '</span></div>'; }).join('') : '<p class="empty">Not yet.</p>') + '</section>';
  }
  function streaks() {
    return '<section class="card w6"><h2>Your streak</h2><div class="big" style="color:' + (S.streak.aliveToday ? 'var(--flame)' : 'var(--muted)') + '">' + FLAME + S.streak.current + ' days</div>' +
      '<p class="sub">Any day you tick at least one task or habit counts. Best so far: ' + S.streak.best + ' days.</p></section>' +
      '<section class="card w6"><h2>Habits, last 7 days</h2>' + habits() + '</section>';
  }
  function onlyyou() {
    var open = S.onlyyou.filter(function (o) { return !o.done; });
    var mins = open.reduce(function (n, o) { return n + (Number(o.minutes) || 0); }, 0);
    return '<section class="card w8"><h2>Only you can do these (' + open.length + (mins ? ', about ' + mins + ' min' : '') + ')</h2>' +
      '<p class="sub" style="margin-bottom:10px">Sign-ins, keys and settings. Your assistant never asks for passwords or keys in chat: you enter them yourself, then tick here.</p>' +
      (S.onlyyou.length ? S.onlyyou.map(function (o) {
        return '<div class="oy' + (o.done ? ' done' : '') + '"><button class="check' + (o.done ? ' on' : '') + '" data-oy="' + esc(o.id) + '"></button><div class="t"><div><b>' + esc(o.title) + '</b>' + (o.minutes ? ' <span class="meta">' + esc(o.minutes) + ' min</span>' : '') + '</div>' +
          '<div class="meta">' + esc(o.why || '') + '</div>' + (o.how ? '<div class="meta">' + esc(o.how) + '</div>' : '') +
          (safeUrl(o.url) ? '<a href="' + esc(safeUrl(o.url)) + '" target="_blank" rel="noopener noreferrer">' + esc(o.link_label || 'Open') + '</a> <span class="meta">' + esc(new URL(safeUrl(o.url)).hostname) + '</span>' : '') + '</div></div>';
      }).join('') : '<p class="empty">Nothing waiting on you.</p>') + '</section>';
  }

  function render() {
    header();
    var views = { today: today, tasks: tasks, streaks: streaks, onlyyou: onlyyou };
    $('main').innerHTML = (views[tab] || today)();
  }

  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-tab],[data-done],[data-habit],[data-oy],[data-star]');
    if (!t) return;
    if (t.dataset.tab) { tab = t.dataset.tab; try { localStorage.setItem('vera.tab', tab); } catch (x) { /* ignore */ } $('main').innerHTML = ''; return render(); }
    var p = t.dataset.done ? post('/api/task/done', { key: t.dataset.done }).then(function () { toast('Logged.'); })
      : t.dataset.habit ? post('/api/habit', { id: t.dataset.habit })
        : t.dataset.oy ? post('/api/onlyyou', { id: t.dataset.oy })
          : post('/api/task/star', { key: t.dataset.star }).then(function () { toast('Today\'s one thing.'); });
    p.then(load).catch(function (err) { toast(err.message); load(); });
  });
  document.addEventListener('submit', function (e) {
    if (e.target.id !== 'chat') return;
    e.preventDefault();
    var v = $('chatText').value.trim();
    if (!v) return;
    post('/api/chat', { text: v }).then(function () { $('chatText').value = ''; toast('Sent to ' + S.assistant + '.'); }).catch(function (err) { toast(err.message); });
  });
  document.addEventListener('keydown', function (e) {
    if (e.target.tagName === 'INPUT') return;
    var n = Number(e.key);
    if (n >= 1 && n <= TABS.length) { tab = TABS[n - 1][0]; $('main').innerHTML = ''; render(); }
    if (e.key === 'r') load();
  });
  window.addEventListener('focus', load);
  setInterval(load, 60000);
  load();
})();
