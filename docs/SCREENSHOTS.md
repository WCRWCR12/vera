# Screenshot shot list (to capture before publishing)

README.md has a `[screenshot slot: name.png]` marker at every step that could be unclear. Capture each one
from a real phone or computer, put it in `docs/img/` under that name, and replace the marker with
`![what it shows](docs/img/name.png)`. Circle or arrow the thing to tap. Blur the token, usernames, emails
and phone numbers.

| File | Device | What to capture |
|---|---|---|
| claude-authorize.png | computer | the browser page where Claude asks you to Authorize the command-line tool |
| claude-email-link.png | phone or computer | the Anthropic sign-in email, with the link circled |
| tg-01-search-botfather.png | phone | Telegram search bar with `@BotFather` typed, blue-tick result circled |
| tg-02-newbot-name-username.png | phone | the BotFather chat after `/newbot`, name and username replies |
| tg-03-token-highlighted.png | phone | the "Done! Congratulations" message, token line highlighted (token blurred) |
| token-box-before.png | computer | the Telegram token box, empty |
| token-box-saved.png | computer | the same box after Save (token hidden) |
| mac-unidentified-developer.png | Mac | the "unidentified developer" warning, and the right-click > Open menu |
| win-smartscreen.png | Windows | "Windows protected your PC" with More info / Run anyway circled |
| start-vera-running.png | both | the start-vera window showing "Signed in to Claude: yes" and "Starting Vera" |
| tg-04-find-your-bot.png | phone | Telegram home with the new bot in the chat list |
| tg-05-pairing-code.png | phone | the bot's "Pairing required" reply, code circled (blurred) |

Also, before publishing: one supervised run by someone who has never installed it (README T1 to T7) on a
clean Mac and a clean Windows login. Note every place they hesitate, and fix the guide there.
