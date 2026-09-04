# Conquest of Azeroth — preservation guide

> ### Check you have the real version
>
> **Official post: https://www.kookapp.cn/app/channels/8766670179908841/3538459662568933** — the only place this guide and the addon are
> published. If you got them anywhere else, verify before running anything.
>
> **Addon build tag:** `2026-09-04a`
> The addon prints this in your chat window when you log in. If what you see does not
> match, **do not use it.**
>
> **Addon file:** `CoAExport.zip`
> `SHA-256: 162760ec90dcb4cb1273a018292393e1a0d854d83f68845f75ec60081dfe100a`
> *Checking this is optional — the build tag above is the easy check.* If you want to
> verify the file itself: right-click the zip → **CRC SHA** → **SHA-256** (needs 7-Zip).
>
> The addon is **plain readable text** — open `CoAExport.lua` in Notepad and read it. It is
> about 580 lines and it only reads your character.
>
> *Translations are welcome and will not match this file's wording. The **addon** checksum
> and build tag are what matter — those stay the same in every language.*

**The servers close Friday 4 September, 19:00 PT** (Saturday 5 September, 02:00 UTC /
10:00 Beijing). After that, nothing below can ever be collected again.

Pick the level that matches you. **Level 1 is enough.** Most people should stop there.

| Level | You need | Time | What it saves |
|---|---|---|---|
| **1** | Nothing. Anyone can do this. | 10 min | Your characters |
| **2** | Able to install a program and click through a settings window | 30 min | The game's network protocol |
| **3** | You understand what a process memory dump is | 5 min | Makes Level 2 *more* complete. Genuinely optional. |

You do not have to do all three. Each is useful on its own.

---

# Read this first — 30 seconds

**If your Ascension password is used on any other website — email, bank, another game —
go change it on those other sites now.** That is the single most important line in this
document. Level 3 can expose it, and the fix costs you two minutes.

**Everything here only reads.** Nothing modifies the game, and none of it can get you
banned for cheating.

**Files are plain text or standard formats.** You can open them and see exactly what you
are sharing before you share it.

---

# Level 1 — Save your characters

**10 minutes. No technical knowledge. This is the one that matters most to you personally.**

### Safety first

- The addon records character names, gear, gold, playtime. That is the point of it.
- It automatically blanks out anything that looks like a **password, token, or email**.
  That is pattern matching — a good safety net, **not a guarantee**.
- So: change a reused password anyway, and skim the output file before sharing it.
- **Never share the `WTF` folder blindly.** It also holds *other* addons' data, which can
  include your **chat and whisper logs**. Details in "Sharing files" at the end.

### Steps

1. **Close the game.**

2. Unzip `CoAExport.zip` into your AddOns folder so you get this exactly:

   ```
   <Ascension folder>\resources\client\Interface\AddOns\CoAExport\CoAExport.toc
   <Ascension folder>\resources\client\Interface\AddOns\CoAExport\CoAExport.lua
   ```

   > **The most common mistake:** ending up with `CoAExport\CoAExport\CoAExport.toc`.
   > If you see the name twice, move the inner folder up one level.

> ![Screenshot 1](screenshots/01-addon-folder.png)
> **Screenshot 1 — `screenshots/01-addon-folder.png`**
> *Must show: File Explorer inside the CoAExport folder, showing exactly two files - CoAExport.toc and CoAExport.lua - with the full path visible in the address bar*

3. Start the game. At character select click **AddOns** (bottom-left). Tick **CoA Export**
   and tick **Load out of date AddOns**.

> ![Screenshot 2](screenshots/02-addon-list.png)
> **Screenshot 2 — `screenshots/02-addon-list.png`**
> *Must show: the AddOns window at character select, with 'CoA Export' ticked AND 'Load out of date AddOns' ticked, both clearly visible*

4. **Check the build tag.** When you log in, the addon prints in your chat window:

   ```
   CoAExport: v1.0  build 2026-09-04a
   ```

   If that tag does not match the one in the official post, **stop and do not use it** —
   you have a modified copy.

> ![Screenshot 3](screenshots/03-build-tag.png)
> **Screenshot 3 — `screenshots/03-build-tag.png`**
> *Must show: the chat window just after login, showing the green CoAExport lines including the build tag*

5. **For each character** — including alts:
   - Log in. Open a **bank** if one is nearby (bank contents can only be read while the
     bank window is open).
   - Type `/coaexport` and press Enter.
   - Type `/reload` and press Enter. **This is what saves the file.** The screen flashes —
     that is normal.

> ![Screenshot 4](screenshots/04-export-done.png)
> **Screenshot 4 — `screenshots/04-export-done.png`**
> *Must show: the chat window after typing /coaexport, showing the summary line with item, spell and quest counts*

6. When you are completely finished playing, **quit to desktop properly**. Do not kill the
   game with Task Manager.

7. Your data is now here:

   ```
   <Ascension folder>\resources\client\WTF\Account\<YOUR ACCOUNT>\SavedVariables\CoAExport.lua
   ```

   If that file exists and is bigger than a few KB, **it worked.**

*The addon also runs itself ~15 seconds after login, so you get most of your data even if
you forget the commands. But `/coaexport` then `/reload` is what makes it complete.*

---

# Level 2 — Record the network traffic

**30 minutes. If you can install a program and click through a settings window, you can
do this. There is nothing to type except one line you paste in.**

This captures how the game and server talk to each other — the part needed to rebuild a
server one day.

### Safety first

- **This is safe.** It records only traffic between your PC and the game servers. Your
  browsing, banking and everything else is excluded by the filter.
- **Your password is not in it.** WoW proves you know your password without ever sending
  it, so it cannot be recovered from this recording.
- It never touches the game program, so the anticheat cannot see it.

### Steps

No typing of commands. All of this is clicking.

**1. Install Wireshark.** Download the **Windows x64 Installer** from
<https://www.wireshark.org/download.html> and run it. Click **Next** through the installer.
When it offers to install **Npcap**, say **yes** — it will not work without it. Restart the
PC if it asks.

**2. Make a folder for the recordings.** Open File Explorer, go to your `C:` drive,
right-click in the empty space → **New** → **Folder**, and name it `coa-capture`.

**3. Open Wireshark as Administrator.** Right-click the Wireshark icon → **Run as
administrator**. Without this it cannot see your network.

**4. Menu bar: `Capture` → `Options`.** A window opens with tabs along the top.

**5. On the `Input` tab:**

- **Select every adapter in the list.** Click the first one, then hold **Shift** and click
  the last one, so they are all highlighted.

  Why all of them: if you use a game accelerator (**UU加速器 / 网易UU, 迅游, Clash**, or a
  VPN), your game traffic does **not** go through your normal Wi-Fi or Ethernet adapter —
  it goes through a hidden virtual adapter created by the accelerator. Recording only Wi-Fi
  would capture **nothing at all**, and you would not find out until afterwards.

  Selecting everything costs nothing, because the filter below throws away everything that
  is not game traffic.

- At the bottom, in the box labelled **Capture filter for selected interfaces**, paste
  exactly this:

  ```
  host 51.210.230.10 or host 51.254.7.227 or tcp port 3724
  ```

  **The box turns green** when the filter is valid. If it is red, something was mistyped.
  This filter is what keeps your normal browsing out of the recording.

> ![Screenshot 5](screenshots/05-wireshark-input.png)
> **Screenshot 5 — `screenshots/05-wireshark-input.png`**
> *Must show: the Capture Options 'Input' tab, with the active adapter highlighted and the capture filter box GREEN with the filter text in it*

**6. On the `Output` tab:**

- Click **Browse…**, go to `C:\coa-capture`, type the file name `coa`, click **Save**.
- Tick **Create a new file automatically**, and set it to **after 100 megabytes**.
- Tick **Use a ring buffer with 200 files**.

  These two together mean the recording saves itself continuously and can never fill up
  your disk.

> ![Screenshot 6](screenshots/06-wireshark-output.png)
> **Screenshot 6 — `screenshots/06-wireshark-output.png`**
> *Must show: the 'Output' tab with the file path set to C:\coa-capture\coa, and both tickboxes ticked - 100 megabytes and ring buffer 200 files*

**7. Click `Start`.** Then launch the game.

Lines will scroll in the Wireshark window once you reach the character screen.

**If nothing appears at all once you are in the game**, click `Capture` → `Stop` and check
two things: that you selected *all* the adapters in step 5, and that the filter box was
green. Those two mistakes account for almost every failed recording.

> ![Screenshot 7](screenshots/07-wireshark-running.png)
> **Screenshot 7 — `screenshots/07-wireshark-running.png`**
> *Must show: Wireshark actively recording with packet lines scrolling, proving traffic is being captured*

> ## The one rule that matters
>
> **Start the recording BEFORE you launch the game. Every time.**
>
> The login exchange happens in the first two seconds and is the most valuable part of the
> whole session. Start late and it is gone. Restart the game — restart the recording.

**8. Leave it running.** While you play, while you are AFK, overnight. It costs nothing.

**9. To stop:** `Capture` → `Stop`. Your files are already saved in `C:\coa-capture` —
there is nothing else to do.

---

# Level 3 — Memory dump

**Only do this if you read and accept the warning. It is optional. Skipping it is fine.**

### Safety first — read all of it

> **A memory dump can contain your account password in plain text.**
>
> - **Change your Ascension password anywhere else you reuse it, before you do this.**
> - **Never post a memory dump to a public share link**, on Baidu Pan, Quark or anywhere
>   else. Anyone with the link can download it. That is the same as posting your password.
> - **Never send one to someone you do not know and trust.** A stranger asking you to
>   upload one is how accounts get stolen.
> - Keeping it on your own drive is a perfectly good outcome. It can be read later.
>
> If any of that makes you uncomfortable: **stop here. Levels 1 and 2 are still valuable.**

### Why it exists

**Update, 4 September — this step matters less than I first thought.**

We have now tested this against a real recording. The game encrypts only the small
*header* on each message, not the contents. So a Level 2 recording on its own already
yields readable data — we pulled 281 server settings and a pile of world data straight out
of one, with no memory dump involved at all.

What the memory dump adds is the key to those headers, which tells us exactly where each
message begins and which type it is. That makes the recording far more complete and is
still worth having.

But it is now clearly **optional**, and the recording is valuable without it. If you are at
all unsure about the password risk below, **skip this level.** You are not losing much.

### Steps

Once per login, just after you enter the world:

1. Press `Ctrl+Shift+Esc` → **Details** tab.
2. Right-click **Ascension.exe** → **Create dump file**.

> ![Screenshot 8](screenshots/08-task-manager-dump.png)
> **Screenshot 8 — `screenshots/08-task-manager-dump.png`**
> *Must show: Task Manager on the Details tab with Ascension.exe right-clicked and 'Create dump file' highlighted in the menu*
3. It saves to `C:\Users\<you>\AppData\Local\Temp\Ascension.DMP` and is 1–3 GB.
4. **Rename and move it straight away** — the next dump overwrites it. No commands needed:
   - Open **File Explorer**. Click the address bar at the top, type `%TEMP%` and press Enter.
   - Find **Ascension.DMP**. Right-click → **Rename**.
   - Name it with today's date and the time, like `dump-0904-2130.dmp`
     (that is `dump-MMDD-HHMM`).
   - Drag it into `C:\coa-capture`.

   The timestamp is what pairs the dump with the right part of the recording, so do not
   skip it.

A dump only unlocks traffic from **its own login session**, so take a fresh one each time
you log in.

---

# What to go and do in game

Applies to every level. **Nothing is recorded for a feature you never open**, so please
spend some time deliberately opening things — even ones you do not care about.

Most valuable first:

1. **Log in and out a few times, then go and play.**

   Logging in is worth doing — the server sends its settings and world data on connect, and
   we have confirmed that comes through readable. But testing showed a login is **not** a
   copy of the whole game database, so repeated logins on their own hit diminishing returns
   fast. Two or three is plenty.

   After that, **actually playing is what fills the recording.** Every window you open and
   every system you touch makes the server describe something new.
2. **Skill cards / Hand of Fate** — open, draft, reveal boosters, turn in a quest.
3. **Class, spec and advancement** — open the panes, browse specs, spend a point, respec.
4. **Transmogrification** — open it, browse appearances, apply one, save an outfit.
   *Urgent:* this data does not exist on your disk at all. Captured now or lost forever.
5. **Mystic / random enchants, wildcard** — open, roll, apply.
6. **Bank, mail, auction house, professions** — open each, scroll the lists.
7. **Vendors, trainers, quest givers, a dungeon.**

Ordinary play helps too — just running around a zone makes the server describe the world
to you, and none of that is stored on your PC.

### Keep a short log

If you did Level 2, make `C:\coa-capture\sessions.txt` and jot lines as you go:

```
2026-09-04 21:30  recording started, adapter 2
2026-09-04 21:34  logged in, dump-0904-2134.dmp
2026-09-04 21:40  skill cards, opened 12 boosters
2026-09-04 22:05  transmog, applied 3 appearances
```

Two minutes of typing. It roughly doubles how useful the recording is later.

---

# Sharing files

Upload to a cloud drive and share the link. Do not email large files.

### Check before you upload

1. **Password changed** anywhere you reused it?
2. **Open `CoAExport.lua` in Notepad and skim it.** You should see character names, item
   names, spells, numbers. If you spot a password, your email, or a long random string the
   filter missed — delete those lines, or do not upload it and report it instead.

### What to upload

| File | Size | Share publicly? |
|---|---|---|
| `CoAExport.lua` | Small | Yes. **Upload this first.** |
| `sessions.txt` | Tiny | Yes. |
| `.pcapng` recordings | 1–10 GB | Yes. |
| `.dmp` memory dumps | 1–3 GB each | **No — see the warning below.** |

**Upload the small files first and immediately.** Small-and-certain beats large-and-maybe.

### Where to upload

Compress first — **`.pcapng` files shrink enormously in a zip**, often to a fraction of
their size.

| Drive | Notes |
|---|---|
| **夸克网盘 Quark Pan** | Recommended. Fast upload and download without paying. |
| **阿里云盘 Aliyun Drive** | Also fast and free. Good alternative. |
| **百度网盘 Baidu Pan** | Everyone has it, but free accounts are slow and cap single files at 4 GB. |

Then: create a share link (分享链接), **set an extraction code (提取码)**, and post the link
and code where your capture is being coordinated.

> **If a file is over 4 GB and you are on Baidu Pan**, split it with 7-Zip or WinRAR
> ("split to volumes", set 2000M) and upload the parts. Or just use Quark instead.

> ## Warning — memory dumps and public links
>
> **A share link is a public link.** Anyone who has the link and code can download the file.
> An extraction code slows strangers down; it does not make the file private.
>
> **So never post a public link to a `.dmp` file.** It can contain your account password.
> Posting one is the same as posting your password.
>
> Memory dumps should go **directly to a specific person you trust**, or stay on your own
> drive. Keeping it locally is a perfectly good outcome — it can still be read later.
>
> `CoAExport.lua`, `sessions.txt` and `.pcapng` recordings are fine to share openly.

### About the `WTF` folder

You may be asked for the whole `WTF` folder. Be aware it contains **other addons' saved
data, which can include chat and whisper logs**, plus your account name. If you would
rather not share that, send only these three files:

```
WTF\Account\<YOUR ACCOUNT>\SavedVariables\CoAExport.lua
WTF\Account\<YOUR ACCOUNT>\SavedVariables\Ascension_SkillCards.lua
WTF\Account\<YOUR ACCOUNT>\SavedVariables\Ascension_CoATalents.lua
```

That is the preservation-relevant part. The rest is convenience.

---

# Checklist

**Level 1 — everyone**

- [ ] Reused password changed on other sites
- [ ] Addon in `Interface\AddOns\CoAExport\`, ticked at character select
- [ ] `/coaexport` then `/reload` on every character
- [ ] Quit to desktop properly
- [ ] `CoAExport.lua` exists and is more than a few KB

**Level 2**

- [ ] Wireshark + Npcap installed as Administrator
- [ ] **All** adapters selected (accelerators route game traffic through a hidden one)
- [ ] Filter box green
- [ ] Recording started **before** launching the game, packet count rising
- [ ] `sessions.txt` kept up to date

**Level 3 — optional**

- [ ] Warning read and accepted
- [ ] Dump taken after entering the world, renamed with date and time
- [ ] Fresh dump after each login
- [ ] **Never uploaded to a public share link** — trusted person only, or kept locally
