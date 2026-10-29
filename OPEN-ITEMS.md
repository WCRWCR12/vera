# Open items (before and after publishing)

## Placeholders still to fill
Left as `{{...}}` because the facts are not in any source file. Search the repository for `{{SYSTEMGC_`,
`{{SECURITY_`, `{{GITHUB_` and `{{EFFECTIVE_` to find them. (`{{OWNER_NAME}}`, `{{ASSISTANT_NAME}}`,
`{{TIMEZONE}}`, `{{TODAY}}` and `{{TODAY+3}}` in `vera/`, `launchers/` and `skills/` are filled by the
installer and must stay.)

| Placeholder | Where | What it needs |
|---|---|---|
| `{{GITHUB_REPO_URL}}` | SECURITY.md (twice) | the public repository address, once the account and name are chosen |
| `{{SECURITY_CONTACT}}` | SECURITY.md | an address for security reports |
| `{{SYSTEMGC_CONTACT_EMAIL}}` | legal/TERMS.md, legal/PRIVACY.md (twice) | contact email |
| `{{SYSTEMGC_LEGAL_NAME}}` | legal/TERMS.md, legal/PRIVACY.md | the legal entity behind System GC |
| `{{SYSTEMGC_ABN}}` | legal/TERMS.md, legal/PRIVACY.md | ABN |
| `{{SYSTEMGC_ADDRESS}}` | legal/PRIVACY.md | postal address (Queensland) |
| `{{EFFECTIVE_DATE}}` | legal/TERMS.md, legal/PRIVACY.md | the date the terms take effect |

## Decisions for the owner of this repository
1. **GitHub account and repository name.** README step 2 says "a folder ... with this guide inside it" and
   doesn't name it, so any name works. The "comment VERA" bot needs the final link.
2. **Commit author.** The first commit was made locally with a neutral placeholder author ("System GC",
   example.com address). Amend it to your GitHub identity or noreply address before pushing if you prefer.
3. **Copyright holder in LICENSE** is "System GC". Change it to the legal entity if it should be that.
4. **Legal review.** legal/ was adapted from the client package's drafts for a free MIT release with no
   usage statistics (the licence section now points to MIT; the community-sharing and usage-stats sections
   were removed). Not lawyer-reviewed. Decide whether to keep TERMS/PRIVACY at all for a free repository.
5. **What's in, what's out.** This repository ships the personal-assistant core: Vera's brain, protocols,
   subagents, morning-brief and evening-wrap skills, Vera Screen, Telegram. Left out on purpose: the
   65 social-media skills, memory files, the content-board app, the virtual office, and the video templates and media
   (client- and brand-specific, large, and some third-party). Add any back as a separate optional pack.
6. **Telegram permission mode.** The client package started Telegram Vera with `--permission-mode auto`.
   This repository uses `default` (every unlisted action asks on the phone) because pattern denies aren't a
   sandbox. Switching to `dontAsk` plus an allow list and the sandbox is the stronger long-term option.
7. **Bun pin.** Setup pins Bun 1.2.23 (from the client package). Confirm it still works with the current
   Telegram plugin (it was 0.0.7 when this was built), or move the pin.
8. **TG-01 (critical, open).** Any paired Telegram user can approve permission prompts. The guide says
   "only pair yourself until this is fixed". The fix needs a plugin fork (approvals to the owner's id only)
   or a second bot; once fixed, the "pair someone else" refusal in CLAUDE-SETUP.md and protocols/circles.md
   can be relaxed.

## Not verified here (verify on a clean machine before launch)
- **Mac**: the installer's Mac branch was tested for file layout under Git Bash (`tests/test-install.sh --os
  mac`), not on a real Mac. Still to try on a Mac: the osascript token box, `open` on the .command files and
  Gatekeeper, `caffeinate`, `socketfilterfw` / `fdesetup` checks, and Python via the developer-tools prompt.
- **Windows token box** (`set-telegram-token.ps1`) and the Windows Telegram launcher were not executed: the
  build machine's own security policy blocks PowerShell from the build session. Run T5 to T9 of
  CLAUDE-SETUP.md once on a clean Windows PC (with a throwaway bot) before launch.
- **Desktop app behaviours** the guide relies on, from Anthropic's docs and not from a live run: the
  Code tab's "+ > Plugins" install, plugin skills (`telegram:access`) showing up in a desktop session, the
  desktop app's scheduled tasks, and whether the command-line tool shares the app's login (setup handles
  both cases). Channels (`--channels`) are documented for the command-line tool only, which is why
  Telegram runs in its own start-vera window.
- **First-run prompts in the start-vera window** (theme, login, folder trust) vary by Claude Code version;
  the guide says "press Enter to accept" rather than naming them.

## Testing (how to rerun)
```
bash tests/test-install.sh            # installer: dry run, install, idempotency, user data kept, update, uninstall
bash tests/test-install.sh --os mac   # the Mac file layout (on any machine with bash)
python tests/test-screen.py           # Vera Screen security and smoke test on port 5961
bash tests/check-docs.sh              # links, named files, no leftover guides, JSON and shell syntax
bash tests/scan.sh --terms <file>     # secrets and personal data; keep the private terms file outside the repo
```
