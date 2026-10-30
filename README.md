# Vera | The ultimate life and business agent set-up

**Free.** A chief of staff, PA and accountability partner that lives in the Claude app on your computer, runs a
whole office of AI agents, and takes orders from your phone by voice note.

Made by **Will** · Instagram [@will.ai.m_system](https://www.instagram.com/will.ai.m_system/) (new agents and free
updates every week) · Built by [System GC](https://systemgc.com.au), who also set this up for businesses.

---


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

> **Using Vera from your phone (Telegram)? Read this first.**
> Your Telegram bot can only reply while **Vera's phone window is open on your computer AND that window is
> signed in to your Claude account.** Until both are true, anything you send the bot (`/start`, "hey")
> gets no reply, and nothing tells you why. So the order is always: sign in, start the window, *then*
> message the bot. The [Telegram walkthrough](#telegram-walkthrough-about-10-minutes) checks this for you.

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

## Telegram walkthrough (about 10 minutes)

Do these in order. Each step ends with a **Yes / No** check: only move on when the answer is Yes. Claude
guides you through the same steps when you say "set up Telegram"; this page is so you can see where you
are. Have your phone and your computer side by side, and **plug the computer into the charger** (a
sleeping laptop means a silent bot).

**Two rules before you start**
- The bot's **token** (a long code BotFather gives you) only ever goes into a small box Claude opens on
  your computer. **Never paste it into a chat, an email or a screenshot.** If you do by accident, send
  `/revoke` to @BotFather and make a new one.
- **Only pair yourself.** Right now anyone paired to the bot can answer Vera's "allow this?" questions, so
  don't add family or colleagues yet. (Details: [SECURITY.md](SECURITY.md).)

### T1. Let Claude install the Telegram tools
In the Code tab (your setup folder), say **set up Telegram**. Claude installs two free tools (Bun, and
the Claude command-line tool that Telegram needs) and the Telegram plugin, asking before each one. Click
**Allow** when asked.
- **Yes:** Claude says the tools and the plugin are installed. → T2
- **No / it stopped:** say "carry on setting up Telegram". Claude checks what's missing and tells you in
  plain words; if a download failed it retries it. Never move on with a step marked missing.

### T2. Sign in: link Vera to your Claude account (the step everyone misses)
Claude now signs Vera's phone window in to your Claude account. Your **browser opens** on a Claude page:
check it's the same account you use in the app and click **Authorize**. Then come back to the Code tab.
`[screenshot slot: claude-authorize.png, the Authorize page]`
- **Yes:** Claude says "Signed in as ..." with your email. → T3
- **No, the browser didn't open:** say "the sign-in didn't open". Claude gives you the link to click.
- **No, Claude asks you to check your email:** open the email from Anthropic, click the sign-in link
  in it, then come back. `[screenshot slot: claude-email-link.png]`

### T3. Make your bot (on your phone)
1. In Telegram, tap the **search bar** at the top, type `@BotFather`, and tap the result with the **blue
   tick**. `[screenshot slot: tg-01-search-botfather.png]`
2. Tap **Start**, then send `/newbot`.
3. It asks for a **name**: send `Vera` (or anything). It asks for a **username**: send one ending in
   `bot`, e.g. `sams_vera_bot`. `[screenshot slot: tg-02-newbot-name-username.png]`
4. BotFather replies "Done! Congratulations on your new bot" with a long code under **"Use this token"**.
   That code is the token. Tap it once to copy it. `[screenshot slot: tg-03-token-highlighted.png]`
- **Yes:** you see that message and the token is copied. Tell Claude "done". → T4
- **No, "username is already taken":** send another username ending in `bot`.

### T4. Save the token in the box (on your computer)
A small box pops up titled **Telegram token**. Paste the token in and click **Save**. Claude never sees it.
`[screenshot slot: token-box-before.png and token-box-saved.png]`
(Can't paste from your phone? Open Telegram on this computer, desktop app or web.telegram.org: the same
BotFather chat is there.)
- **Yes:** Claude says "token: present". → T5
- **No, "token: missing":** the box wasn't saved. Claude opens it again.

### T5. Start the bot (its own window)
This is what makes the bot answer. It runs in **one extra window** that you leave open.
1. Claude opens it for you the first time. Later, you open it yourself: in your **Vera** folder,
   double-click **start-vera**.
   - **Mac, first time only:** macOS says it "can't be opened because it is from an unidentified
     developer". Right-click (or Control-click) **start-vera**, choose **Open**, then **Open** again.
     `[screenshot slot: mac-unidentified-developer.png]`
   - **Windows, first time only:** if a blue "Windows protected your PC" box appears, click **More info**,
     then **Run anyway**. `[screenshot slot: win-smartscreen.png]`
2. The window checks itself and shows one of two banners:
   - **"Signed in to Claude: yes"** then **"Starting Vera"**. Good.
   - **"NOT SIGNED IN TO CLAUDE YET"**: the window asks you to sign in. Press **Enter** at each question
     (colour theme, trust this folder) and click **Authorize** in the browser.
3. Leave the window open. Closing it stops the bot. `[screenshot slot: start-vera-running.png]`
- **Yes:** the window says "Starting Vera" and stays open with no red error. → the gate below
- **No, it says "isn't connected to Telegram yet":** the token wasn't saved; go back to T4.
- **No, it says "command-line tool is not installed":** go back to T1.
- **No, the window closes straight away:** say "start-vera closes" to Claude in the Code tab.

> **Gate: before you message the bot.** Did T2 say "Signed in as ...", AND is the start-vera window open
> right now saying "Starting Vera"? **Yes** → T6. **No** → go back to T2 (sign in) or T5 (start the
> window). Messages sent before both are true get no reply.

### T6. Pair your phone
1. On your phone, go back to the Telegram home screen. Your new bot is in your chat list under the name
   you gave it (or search its username). `[screenshot slot: tg-04-find-your-bot.png]`
2. Open it and send `hi`. Within a few seconds it replies **"Pairing required"** with a **6-character
   code**. `[screenshot slot: tg-05-pairing-code.png]`
3. Tell Claude those 6 characters **in the Code tab chat on your computer** (not in Telegram). Claude
   pairs you and locks the bot to you.
- **Yes:** the bot says **"Paired!"**. → T7
- **No reply at all:** see "My bot isn't replying" below.
- **Claude says the code expired:** send the bot another message for a fresh code.

### T7. Test it
Send your bot `hello`. Vera should answer within a minute.
- **Yes:** done. From now on, double-click **start-vera** whenever you want her on your phone.
- **No:** see the fix card below.

### My bot isn't replying (fix card)
Check these in order, and stop at the first one that's wrong:
1. **Is the start-vera window open on your computer right now?** Closed, or the laptop is asleep or out of
   battery, means no replies. Plug in, wake it up, double-click **start-vera**.
2. **Does that window say "NOT SIGNED IN TO CLAUDE YET", or is it waiting on a question?** Press Enter
   and finish the sign-in in the browser (T2). Messages sent before that were never seen: send a new one.
3. **Did you get a "Pairing required" code but never gave it to Claude?** Give it to Claude in the Code
   tab (T6). The bot stays quiet with you until you're paired.
4. **Is it the right bot?** Check the username in the chat matches the one you made in T3.
5. **Still nothing:** in the Code tab (setup folder) say "my Telegram bot isn't replying". Claude checks
   the token, the sign-in, the plugin and the pairing for you, and tells you which one failed.

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
- **The bot doesn't answer:** follow [My bot isn't replying](#my-bot-isnt-replying-fix-card).
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

---

## Terms, disclaimer and limitation of liability

By downloading, installing or using Vera you agree to the [Terms](legal/TERMS.md) and [Privacy policy](legal/PRIVACY.md).
In short:

- **Free, as is.** Vera is provided free of charge, "as is" and "as available", without warranties of any kind,
  express or implied, including fitness for a particular purpose, accuracy, availability or freedom from errors.
- **You are in control and responsible.** Vera runs on your computer, under your own Claude account and the
  services you connect. You are responsible for what you ask her to do, what you approve, and for checking
  anything she drafts, books, sends, spends or deletes before you say yes.
- **Not professional advice.** Nothing Vera says is legal, financial, tax, medical or other professional advice.
- **No liability.** To the maximum extent permitted by law, Will, System GC and contributors are not liable for any
  loss or damage of any kind (direct, indirect, consequential, lost data, lost profit or otherwise) arising from
  downloading, installing or using Vera, or from any third-party service it connects to (Anthropic/Claude,
  Telegram, Google and others, each under their own terms).
- **Your consumer rights.** Nothing here excludes rights you have under the Australian Consumer Law or other laws
  that cannot be excluded; where liability can be limited, it is limited to resupplying the software (free).
- Licensed under the [MIT License](LICENSE). Not affiliated with or endorsed by Anthropic, Meta or Telegram.
