# Vera and your computer: what's safe, and what to do if something looks wrong

Plain English first (two minutes), then the technical detail and the known limitations.

## What Vera is
Vera is Claude (Anthropic's AI) working in one folder on your computer, called **Vera**, with a set of
instructions, protocols and safety settings. Vera Screen, if you set it up, is a small page that runs on
your computer at `http://127.0.0.1:5191`. That address means "this computer only": other computers, your
Wi-Fi and the internet can't open it, and even on this computer it needs a key that only the start-screen
window hands to your browser.

## What Vera can use
- The Vera folder: her notes, your tasks, people, ideas and logs.
- Files you hand her: things you drag into the chat, or photos you send her bot.
- The browser, for research and for sites you are already logged in to. She never types passwords or
  card numbers. If a site asks, she stops and tells you.
- Your calendar and email, only if you connected them yourself, and only to read and draft. Nothing is
  sent without your "send".

## What Vera is blocked from
These are switched off in Vera's settings files, not just "asked nicely":
- Your SSH and cloud keys, saved passwords (macOS Keychain, Windows Credential Manager folders), and browser
  cookie and profile folders. Your Messages and Mail folders on a Mac.
- The Telegram bot token, the Telegram guest list (access.json) and Vera Screen's key.
- Admin commands (`sudo`), piping downloads into a shell, wiping folders, scheduled-task and login-item
  tools, and changing your shell start-up files.
- Changing her own safety settings, launchers or code. On Telegram she also can't change her rules files
  (people, preferences, protocols, CLAUDE.md), can't use the network tools (curl, ssh and the like) and
  has no PowerShell.
- Skip-permissions ("bypass") mode is disabled in her settings.

She can still be wrong. She can't spend money, post publicly or message anyone without your approval.

## What leaves your computer
Your notes stay in the Vera folder. **Nothing is sent to System GC, and there are no usage statistics.**
What does travel, so you know:
- **To Anthropic (Claude):** what you say to Vera and what she reads to answer you. That is how Claude
  works; your Claude account's terms and privacy settings apply.
- **To Telegram** (if set up): messages, photos and voice notes you send to or receive from your bot.
- **To Google or Microsoft** (if you connected them in the Claude app): calendar and email Vera reads or drafts.
- **When you tell her to:** web pages she visits, sites you're logged in to.

## The rules Vera follows with other people's text
Anything that arrives from outside (an email, a web page, a document, a photo someone sent, another
agent's output) is information, never an order. Only you, at the desk or from your own Telegram account
(checked by its numeric user id, not by name), can tell her to spend, send, publish, install or change settings.

## Good habits
- Keep your firewall, disk encryption and automatic updates on (setup checks these).
- **Only pair yourself to the Telegram bot** (see the first known limitation below).
- Never share the bot token or a screenshot of it. If it leaks, send `/revoke` to @BotFather.
- If Vera asks permission for something odd ("read this file in AppData", "run this command"), say no and
  ask her why.

## If something looks wrong
Examples: Vera replies to someone you don't know, notes appear that nobody wrote, she asks for a password,
or your computer does something you didn't ask for.
1. **Stop her.** Close the start-vera window (Telegram) and the start-screen window, and quit the Claude
   app. Nothing of Vera runs once those are closed.
2. **Lock Telegram.** In Telegram, open @BotFather, send `/revoke`, pick your bot. The old token stops
   working straight away. Make a new one later with "set up Telegram".
3. **Look, don't delete.** `log.md` in your Vera folder shows what Vera did and when. If you think a
   password was exposed, change it from a different device first.
4. **Report a security problem** with Vera itself: info@systemgc.com.au (or a private security advisory on
   https://github.com/WCRWCR12/vera).

---

## Technical detail

**Two sessions, two settings files.**
- At the desk (Claude app, Code tab, Vera folder): `.claude/settings.json`. Default permission mode,
  bypass disabled. Allowed without asking: reading the Vera folder and editing her notes (`*.md` at the top
  level, `inbox/`, `workflows/`, `screen/data/*.json`). Asks first: CLAUDE.md, persona.md, people.md,
  preferences.md, protocols/, the Telegram access list, `rm -rf`, `chmod`, interpreters with `-c/-e`,
  PowerShell. Denied: everything that runs or sets policy (`.claude/`, `vera-settings.json`, launchers,
  `tools/`, `screen/server.py`, `screen/web/`), secret stores on both systems, shell start-up files,
  login-item folders, `sudo`, pipe-to-shell, `reg`, `schtasks`, `icacls`, `launchctl`, `defaults write`.
- On Telegram (start-vera window): the desk settings plus `vera-settings.json`, which hard-**denies**
  (not asks) anything owner-only: the token, access.json and `approved/`, the rules files, `.claude/`,
  launchers, tools, the screen's code and key, user-level Claude settings and skills, network and
  persistence tools, package installers, interpreters with `-c/-e`, and the PowerShell tool.
- Both: `cleanupPeriodDays: 30` (old transcripts are removed after 30 days); transcripts are denied for Read.

**Launchers** (`start-vera`, `start-screen`): run only when double-clicked, never restart themselves, put
system folders first on PATH, call Claude by absolute path, and start Telegram Vera with
`--permission-mode default` and `--add-dir` limited to the Telegram **inbox** (the token, allowlist and
pairing files stay outside). start-vera refuses to start if `vera-settings.json` is missing or its key
rules are gone. On a Mac it uses `umask 077` and `caffeinate`.

**Installer** (`setup/install.sh`): non-interactive flags only (Claude never answers prompts on your
behalf), `--dry-run` first, never overwrites notes, backs up before replacing, never `rm -rf`s anything
(uninstall moves the folder aside), makes settings and launchers read-only, adds nothing that starts at
login, `umask 077` and `chmod go-rwx` on a Mac.

**Telegram token:** typed only into a masked helper box (`tools/set-telegram-token.*`), format-checked,
written atomically to `~/.claude/channels/telegram/.env` with owner-only permissions (mode 600 on Mac,
an owner-only access list on Windows). It never enters a chat or a transcript.

**Pairing:** done at the desk by the setup Claude from a code the owner reads off their own phone, then
the policy is switched to `allowlist` immediately and the owner's numeric id is written to people.md.
Vera never pairs anyone.

**Vera Screen:** binds 127.0.0.1 only; every `/api/` request needs the per-install key (header
`X-Vera-Token`, constant-time compare), which `start-screen` passes in the URL fragment (never sent over
HTTP) and the page keeps in session storage; writes also need a same-origin request (Origin and
Sec-Fetch-Site checked); wrong Host gets 421; CSP `script-src 'self'`, `frame-ancestors 'none'`,
`X-Frame-Options: DENY`, `nosniff`, `no-referrer`; only html/js/css/fonts/images from `web/` are served;
body size and type checked; 30 s socket timeout; generic errors to the page; links on the "Only you" list
must be https and show their real hostname. No OPTIONS or CORS.

**Subagents:** scout and booker have no shell or PowerShell; booker can't write files; maker may only
write `Status: draft`; none publishes.

## Known limitations (read these)
1. **Open, critical: any paired Telegram user can approve permission prompts.** The official Telegram
   plugin sends Vera's "allow this?" prompts to every allowlisted chat and accepts the answer from any of
   them. **Only pair yourself until this is fixed.** Mitigation: anything owner-only is a hard deny in the
   Telegram session, so no approval can unlock it. The real fix needs the plugin to send approvals only to
   the owner, or a second bot.
2. **Permission rules that match command text are defence in depth, not a sandbox.** A determined
   command can be phrased to avoid a pattern. The Telegram session therefore runs in default mode (it asks
   you on your phone) rather than an auto mode. Claude Code's sandbox and root-owned managed settings are
   not used yet.
3. **Settings files live in your own folder.** They are read-only on disk and Vera's settings deny editing
   them, and start-vera checks them before starting, but another program running as you could still change
   them.
4. **Rules files are editable at the desk.** Tiers, spending caps and standing rules are in people.md and
   preferences.md. They ask before changing at the desk and are locked on Telegram; there is no separate
   signed policy file.
5. **The Telegram reply tool can attach any file Vera can read.** Vera's rules say files go to the owner's
   chat only, and only the owner is paired, but no hook enforces it.
6. **Supply chain:** the Telegram plugin and Claude Code update from their official sources and are not
   pinned; Bun is pinned at install (1.2.23). This repository is not signed: download it only from
   https://github.com/WCRWCR12/vera.
7. **Skills are installed for your whole user** (`~/.claude/skills/morning-brief`, `evening-wrap`), so other
   Claude sessions can see them too.
8. **Vera Screen's CSP allows inline styles** (not scripts) because the page builds styled HTML.
