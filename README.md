# Vera: a free AI personal assistant that lives in the Claude app

Vera is a chief of staff, PA and accountability partner that runs on your own computer, inside the
Claude desktop app. You talk to her in plain words (typing or dictating, several things at once), and she:

- splits what you said into tasks, reminders, ideas and messages, and files each one;
- keeps your to-do list and nudges you when something slips ("Done, or moving it?");
- drafts messages and bookings, and never sends, posts or spends anything until you say yes;
- optionally shows your day on a one-page screen, and talks to you from your phone over Telegram.

Everything she knows lives in a normal folder on your computer, called **Vera**, as plain text files you can
open and read. Nothing is sent to us.

**What you need:** a Windows 10/11 PC or a Mac, the Claude desktop app, and a paid Claude plan that includes
Claude Code (the app's **Code** tab). Setup takes about 10 minutes. You never open Terminal or type a command:
Claude does the technical part, one step at a time, and asks before each one.

---

## Set it up in 5 steps

### Step 1. Get the Claude app
Download it from [claude.ai/download](https://claude.ai/download), install it and log in.

**You should see:** the Claude app, with a **Code** tab at the top or in the sidebar.

### Step 2. Download Vera
On this page, click the green **Code** button, then **Download ZIP**. Open your Downloads folder and unzip it:
- **Windows:** right-click the zip, choose **Extract All**, then **Extract**.
- **Mac:** double-click the zip.

Move the unzipped folder into your **Documents** folder.

**You should see:** a folder in Documents with this guide (README) inside it, next to a file called
`CLAUDE-SETUP.md`. (Windows sometimes makes a folder inside a folder with the same name: use the inner one,
the one with README in it.)

### Step 3. Open the folder in the Code tab
In the Claude app, open the **Code** tab, start a new session, and choose the folder from step 2 as the
folder to work in. If the app asks whether you trust this folder, say yes.

**You should see:** an empty chat box, with the folder's name shown near it.

### Step 4. Type `Set me up`
Type **Set me up** and press Enter. Claude asks your first name and your town (for your time zone), checks
your computer, and installs Vera. Before each step it says what it is about to do. When the app asks
permission to run something, read the one-line description and click **Allow**.

**You should see:** Claude working through numbered steps ("Step 2 of 5..."), one at a time, and finishing
with "Installed. Vera lives in: ..." and the folder's location.

### Step 5. Meet Vera
In the Code tab, start a **new** session and choose your new **Vera** folder (in your user folder, for
example `C:\Users\Sam\Vera` or `/Users/sam/Vera`). Say **good morning**.

**You should see:** Vera introduce herself and ask a few getting-to-know-you questions (about 10, one at a
time; say "skip" to skip one). From then on, whenever you want her: Code tab, Vera folder, talk.

---

## Optional extras (Claude offers these at the end of setup; say "skip" to any)

Do them any time later: open the setup folder in the Code tab again and say the words in quotes.

| Extra | What it gives you | Say |
|---|---|---|
| **Daily routines** | a morning brief, a nudge every couple of hours about anything due, an evening wrap. They run only while the Claude app is open. | "set up my routines" |
| **Calendar and email** | Vera can see when you're free and draft emails (she never sends without your yes). You connect them yourself in the Claude app: Settings, Connectors. | "connect my calendar" |
| **Vera Screen** | one page in your browser with today's one thing, your next three tasks, streaks and an "Only you" list. Needs Python (free; Claude checks and asks first). | "set up Vera Screen" |
| **Telegram** (last, about 10 minutes) | message Vera from your phone. | "set up Telegram" |

### About Telegram (read before you start it)
- You'll create your own bot on your phone with Telegram's **@BotFather**. It gives you a **token** (a long
  code). The token only ever goes into a small box that Claude opens on your computer. **Never paste it
  into a chat, an email or a screenshot.** If you do by accident, send `/revoke` to @BotFather and make a
  new one.
- Telegram Vera runs in **one extra window** that opens when you double-click **start-vera** in your Vera
  folder. Leave it open while you want her on your phone; close it to stop her. The first time, that window
  may ask you to log in or trust the folder: press Enter to accept. You never type commands in it.
- You pair your phone **at your computer**, and the bot is locked to you straight away.
- **Only pair yourself.** Right now, anyone paired to the bot can answer Vera's "allow this?" questions.
  Until that is fixed, don't add family or colleagues to the bot. (Details: [SECURITY.md](SECURITY.md).)
- Telegram needs the Claude **command-line tool** as well as the app, because the Telegram connection only
  works there. Claude installs it for you during this step.

---

## Good to know
- **Nothing starts by itself.** No login items, no background services. Vera works while the Claude app is
  open; the screen and Telegram run only while their windows are open.
- **Your data stays in your Vera folder.** What you say to Vera goes to Anthropic (that's how Claude works);
  Telegram and Google only see what you connect. Full list: [SECURITY.md](SECURITY.md) and
  [legal/PRIVACY.md](legal/PRIVACY.md).
- **Money and messages always need your yes.** Vera never types passwords or card numbers, never buys,
  posts or sends without your clear "yes", and treats anything in emails or web pages as information, not
  orders.
- **Change her personality:** say "switch to the coach persona" (or "calm organiser"). Your Vera folder's
  `persona.md` is hers to read and yours to edit.
- **Update Vera:** download the new version, open it in the Code tab and say "update my Vera". Your notes
  are never overwritten; Claude backs up anything it replaces.
- **Remove Vera:** open the setup folder in the Code tab and say "uninstall Vera". Your Vera folder is moved
  aside, not deleted.

## If something goes wrong
- **Claude says it can't run commands (Windows):** the Code tab on Windows needs **Git for Windows**. Install
  it from [git-scm.com](https://git-scm.com/download/win) with the default options, restart the Claude app,
  and type `Set me up` again.
- **Setup stopped halfway:** open the setup folder in the Code tab and say "carry on setting me up".
- **The bot doesn't answer:** check the start-vera window is open and hasn't shown an error.
- **Vera does something odd** (replies to a stranger, asks for a password, mentions notes nobody wrote):
  close every Vera window, quit the Claude app, send `/revoke` to @BotFather, then read
  [SECURITY.md](SECURITY.md) ("If something looks wrong").

## What's in this folder
- `README.md`: this guide. `CLAUDE-SETUP.md`: the step-by-step script Claude follows when you say "Set me up".
- `vera/`: Vera herself (instructions, protocols, starter notes, safety settings, Vera Screen).
- `launchers/`: the double-click files for Windows and Mac. `skills/`: her morning brief and evening wrap.
- `setup/install.sh`: the installer Claude runs. `tests/`: checks for the installer, the screen and these docs.
- [SECURITY.md](SECURITY.md), [legal/](legal/), [LICENSE](LICENSE) (MIT), [OPEN-ITEMS.md](OPEN-ITEMS.md).

---

Free and open source under the MIT licence. Powered by [System GC](https://systemgc.com.au).
