# Brave Debloat for macOS

A small shell script that turns off the extra features in the Brave browser on macOS: Rewards, Crypto Wallet, VPN, Leo AI, News, Talk, Tor, IPFS and telemetry. It uses Brave's official policy system, so it doesn't modify the Brave app itself.

It is a macOS port of the **Brave Browser - Debloat** tweak from [WinUtil](https://github.com/ChrisTitusTech/winutil) by Chris Titus Tech, which does the same job on Windows through the registry.

> **New to Terminal?** Follow [Quick start for beginners](#quick-start-for-beginners). Every step is explained, including what you should see.

---

## Table of contents

1. [What it disables](#what-it-disables)
2. [Before you start](#before-you-start)
3. [Quick start for beginners](#quick-start-for-beginners)
4. [Commands](#commands)
5. [Options](#options)
6. [Check that it worked](#check-that-it-worked)
7. [Undo everything](#undo-everything)
8. [Alternative: configuration profile](#alternative-configuration-profile)
9. [Troubleshooting](#troubleshooting)
10. [How it works](#how-it-works)
11. [FAQ](#faq)
12. [Credits and license](#credits-and-license)

---

## What it disables

| Policy | What it turns off |
|---|---|
| `BraveRewardsDisabled` | Brave Rewards (BAT ads) |
| `BraveWalletDisabled` | Crypto Wallet (and its toolbar button) |
| `IPFSEnabled` = false | IPFS / Web3 gateway |
| `BraveVPNDisabled` | Brave VPN |
| `BraveAIChatEnabled` = false | Leo AI chat |
| `BraveNewsDisabled` | Brave News |
| `BraveTalkDisabled` | Brave Talk |
| `TorDisabled` | Private window with Tor |
| `BraveStatsPingEnabled` = false | Usage ping |
| `BraveP3AEnabled` = false | Privacy-preserving product analytics |
| `UrlKeyedAnonymizedDataCollectionEnabled` = false | URL-keyed data collection |
| `SafeBrowsingExtendedReportingEnabled` = false | Safe Browsing extended reporting |
| `MetricsReportingEnabled` = false | Usage and crash metrics |

Your bookmarks, passwords, history and extensions are **not touched**.

## Before you start

- A Mac running macOS with Brave installed (Stable, Beta, Nightly or Dev).
- An administrator account. You'll need your Mac login password for `sudo`.
- Nothing else to install. The script only uses tools that come with macOS.

## Quick start for beginners

### Step 1. Download the script

On this page, click `brave-debloat-macos.sh`, then click the **Download raw file** button (the download icon at the top right of the file view). It will normally go to your **Downloads** folder.

Or download the whole project: click the green **Code** button, then **Download ZIP**, and double-click the zip to unpack it.

### Step 2. Open Terminal

Press **Cmd + Space**, type `Terminal`, and press **Enter**. A window with a text prompt opens.

### Step 3. Go to the folder with the script

If the script is in Downloads:

```bash
cd ~/Downloads
```

If you unpacked the ZIP, the script is inside a folder, for example:

```bash
cd ~/Downloads/brave-debloat-macos-main
```

Check that the script is there:

```bash
ls | grep brave
```

You should see `brave-debloat-macos.sh`. If you see nothing, you are in the wrong folder or the file has a different name. See [Troubleshooting](#troubleshooting).

### Step 4. Make the script runnable

```bash
chmod +x brave-debloat-macos.sh
```

If macOS later complains the file is from the internet, run this once:

```bash
xattr -d com.apple.quarantine brave-debloat-macos.sh
```

### Step 5. Run it

```bash
sudo ./brave-debloat-macos.sh apply
```

- `sudo` runs it as administrator. Type your Mac password when asked. **Nothing appears while you type. That is normal.** Press Enter when done.
- You should see a list of 13 lines such as `BraveRewardsDisabled = true`.

### Step 6. Restart Brave completely

Press **Cmd + Q** in Brave. Closing the window is **not** enough. Then open Brave again.

### Step 7. Check it worked

In Brave's address bar, go to:

```
brave://policy
```

You should see the policies listed. You can also run:

```bash
./brave-debloat-macos.sh status
```

Each active policy shows `[x]`.

You're done. Brave will say **"Managed by your organization"** in its menu. That is normal. It is how Brave shows that policies are active.

## Commands

```bash
sudo ./brave-debloat-macos.sh apply     # apply the policies
sudo ./brave-debloat-macos.sh revert    # remove the policies
     ./brave-debloat-macos.sh status    # show which policies are active
     ./brave-debloat-macos.sh profile   # create a .mobileconfig file instead
     ./brave-debloat-macos.sh --help    # show help
```

`apply` and `revert` need `sudo`. `status` and `profile` don't.

## Options

| Option | Meaning |
|---|---|
| `-c stable` | Brave (default) |
| `-c beta` | Brave Beta |
| `-c nightly` | Brave Nightly |
| `-c dev` | Brave Dev |
| `-c all` | All of the above |

Example: `sudo ./brave-debloat-macos.sh apply -c all`

## Check that it worked

1. Fully quit Brave (**Cmd + Q**) and reopen it.
2. Open `brave://policy`. The policies should be listed with status **OK**.
3. The wallet, Rewards, VPN and Leo buttons should be gone from the toolbar and menus.

If a leftover button remains, right-click the toolbar or go to `brave://settings/appearance` and turn it off.

## Undo everything

```bash
sudo ./brave-debloat-macos.sh revert
```

Then quit and reopen Brave. This removes only the policies the script added.

## Alternative: configuration profile

Use this only if `apply` doesn't work on your Mac (for example, if macOS blocks writing the policy file).

1. Create the profile (no `sudo` needed):
   ```bash
   ./brave-debloat-macos.sh profile
   ```
   This creates `brave-debloat.mobileconfig` in the current folder.
2. Double-click the file. On modern macOS this does **not** install it. It only shows a notification saying "Review the profile in System Settings". **Clicking the notification often does nothing. This is normal.**
3. Open the profiles page yourself:
   ```bash
   open "x-apple.systempreferences:com.apple.preferences.configurationprofiles"
   ```
   Or go to it manually:
   - macOS 15 and later: **System Settings → General → Device Management**
   - macOS 13 and 14: **System Settings → Privacy & Security → Profiles**
4. Find **Brave Browser Debloat**, double-click it, then click **Install** and confirm with your password. A warning that the profile is **Not Signed** is expected, because it is created locally.
5. Quit and reopen Brave, then check `brave://policy`.

To remove it later, open the same page, select the profile and click the **−** (minus) button.

> Use either `apply` or the profile. You don't need both.

## Troubleshooting

**`No such file or directory` when running `chmod` or the script**
The script isn't in the folder you are in. Run `ls ~/Downloads | grep -i brave` to find it. If the name differs (for example `brave-debloat-macos (1).sh`), use that exact name in quotes. If it ends in `.txt`, rename it:
`mv ~/Downloads/brave-debloat-macos.sh.txt ~/Downloads/brave-debloat-macos.sh`
You can also search with: `mdfind -name brave-debloat`

**`Run with sudo`**
`apply` and `revert` need administrator rights. Put `sudo` in front.

**`Permission denied`**
Run `chmod +x brave-debloat-macos.sh` first.

**`cannot be opened because it is from an unidentified developer`, or the file is quarantined**
Run `xattr -d com.apple.quarantine brave-debloat-macos.sh`.

**`chown: ... No such file or directory`, or the policy file isn't created**
This happened with an older version of the script. Download the latest version. The current script writes the file directly and tells you if it can't.

**Nothing shows in `brave://policy`**
- Did you quit Brave with **Cmd + Q** and reopen it? Closing the window isn't enough.
- Run `./brave-debloat-macos.sh status`. If policies show `[ ]`, run `apply` again.
- Check the file exists: `ls "/Library/Managed Preferences/"`
- Try the [configuration profile](#alternative-configuration-profile).

**I double-clicked the `.mobileconfig` and nothing happened**
See [Alternative: configuration profile](#alternative-configuration-profile), step 2 and 3. You have to open System Settings yourself.

**A button is still visible**
Hide it manually in `brave://settings/appearance`. Also check `brave://settings/web3`.

**Policies disappeared after a macOS or Brave update**
Run `sudo ./brave-debloat-macos.sh apply` again.

**My Mac is managed by work or school (MDM)**
The organization may override or remove these settings. Ask your IT admin.

## How it works

Chromium-based browsers, including Brave, read enterprise policies from macOS **managed preferences**. Ordinary user settings (`defaults write` for your own account) are ignored for this purpose.

The script:
1. Writes the policies into `/Library/Managed Preferences/com.brave.Browser.plist` (and the matching file for Beta, Nightly or Dev).
2. Backs up an existing file once as `.bak`.
3. On `revert`, removes only the keys it added.

The policies and values are the same ones WinUtil sets on Windows under `HKLM\SOFTWARE\Policies\BraveSoftware\Brave`.

## FAQ

**Is it safe?** It only sets documented Brave policies. It doesn't download anything or modify the Brave app. You should still read any script before running it with `sudo`. It's short and readable.

**Does it delete my data?** No.

**Can I pick which features to disable?** Yes. Open the script in a text editor and delete or comment out lines in the `POLICIES=( ... )` list near the top. Then run `apply` again.

**Why does Brave say "Managed by your organization"?** Brave shows this whenever policies are set. Here, you are the "organization".

**Does it work on Windows or Linux?** No. For Windows, use the original [WinUtil](https://github.com/ChrisTitusTech/winutil).

## Credits and license

The policy list is derived from [WinUtil](https://github.com/ChrisTitusTech/winutil) (MIT License, Copyright (c) 2022 CT Tech Group LLC).

Released under the [MIT License](LICENSE). Use at your own risk.
