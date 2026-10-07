# Walkthrough: Evaluate Claude Code on Your Own Work

A step-by-step guide to **Claude Lab: Evaluate Claude Code on Your Own Work**, in the order of the workshop agenda. Use it to follow along in a live session, to rehearse beforehand, or to work through the whole workshop on your own.

- **Track A, practice on Northwind:** every step below. You work on a fictional service with six ready-made practice cases, and check your work against [demo/python-fastapi/ANSWERS.md](demo/python-fastapi/ANSWERS.md).
- **Track B, your own repositories:** do [Setup](#1-setup) and the pre-work ([markdown](ccw5g-pre-work.md) · [Word](ccw5g-pre-work.docx)) first, then follow each exercise. Where you see the 🅱 note, use your own pull requests instead of Northwind's. [Section 10](#10-track-b-doing-it-on-your-own-repositories) collects the differences.

**Who it's for:** anyone. **No experience with terminals, git, or Python is needed**: [Section 1](#1-setup) takes you from a bare computer to a working setup, and every later step says what to type and what you should see.

> **A .NET and Angular team that already uses Claude Code?** [WALKTHROUGH-dotnet.md](WALKTHROUGH-dotnet.md) runs the same workshop on an ASP.NET Core and Angular practice kit, on Windows, WSL, macOS, or Linux.

**Time:** about 3 hours, the length of the workshop. Setup takes about 20 minutes if you already have the tools, and up to an hour from scratch.
**Cost:** Exercise 4 makes real `claude -p` calls, billed to your plan or API account. In testing, a Northwind practice run cost about $0.40. Six runs (two cases, three runs each) is the workshop's standard load. Each run's JSON output reports its exact cost.

## Contents

0. [How the walkthrough maps to the workshop](#0-how-the-walkthrough-maps-to-the-workshop)
1. [Setup](#1-setup)
2. [Welcome and room check](#2-welcome-and-room-check)
3. [What the foundation has to prove](#3-what-the-foundation-has-to-prove)
4. [Exercise 1: Choose target tasks and success criteria](#4-exercise-1-choose-target-tasks-and-success-criteria)
5. [Exercise 2: Write cases from real work](#5-exercise-2-write-cases-from-real-work)
6. [Exercise 3: Calibrate](#6-exercise-3-calibrate)
7. [Exercise 4: Run the baseline](#7-exercise-4-run-the-baseline)
8. [Reading the result](#8-reading-the-result)
9. [Exercise 5: Decide and hand off](#9-exercise-5-decide-and-hand-off)
10. [Track B: doing it on your own repositories](#10-track-b-doing-it-on-your-own-repositories)
11. [Clean up](#11-clean-up)
12. [Troubleshooting](#12-troubleshooting)

---

## 0. How the walkthrough maps to the workshop

| Workshop time | Segment | Slides | Workbook | Here |
|---|---|---|---|---|
| 0:00–0:10 | Welcome and room check | 1–3 | — | [§2](#2-welcome-and-room-check) |
| 0:10–0:25 | What the foundation has to prove | 4–8 | Reference: What the foundation has to prove | [§3](#3-what-the-foundation-has-to-prove) |
| 0:25–0:45 | Exercise 1 | 9–11 | Exercise 1 | [§4](#4-exercise-1-choose-target-tasks-and-success-criteria) |
| 0:45–1:15 | Exercise 2 | 12–15 | Exercise 2 | [§5](#5-exercise-2-write-cases-from-real-work) |
| 1:15–1:25 | Break | | | |
| 1:25–1:40 | Exercise 3 | 16–17 | Exercise 3 | [§6](#6-exercise-3-calibrate) |
| 1:40–2:15 | Exercise 4 | 18–21 | Exercise 4 | [§7](#7-exercise-4-run-the-baseline) |
| 2:15–2:25 | Break | | | |
| 2:25–2:40 | Reading the result | 22–23 | Reference: From failure to fix | [§8](#8-reading-the-result) |
| 2:40–2:55 | Exercise 5 | 24 | Exercise 5 | [§9](#9-exercise-5-decide-and-hand-off) |
| 2:55–3:00 | Readout and close | 25–26 | Reference: After the workshop | [§9](#9-exercise-5-decide-and-hand-off) |

Each exercise below gives the time for its hands-on part; the rest of its slot in the table is slides and discussion.

Keep the deck ([ccw5g-slides.pptx](ccw5g-slides.pptx)) and the workbook ([markdown](ccw5g-participant-workbook.md) · [Word](ccw5g-participant-workbook.docx)) open alongside this page. The workbook's [Reference](ccw5g-participant-workbook.md#reference) section, which ends with a glossary, defines every term used here. Use the Word version to type into it or print it; the markdown version reads best on GitHub.

---

## 1. Setup

You do this once. In a live session, do it before the session starts.

**You don't need any experience with terminals, git, or Python.** Every step says what to type and what you should see. If you already have the tools, step 1.6 checks them all for you in a few seconds. Setup takes about 20 minutes if you have the tools, and up to an hour starting from scratch.

| Step | What you do |
|---|---|
| [1.1](#11-what-you-need) | See what you need |
| [1.2](#12-open-a-terminal) | Open a terminal (on Windows, set up WSL first) |
| [1.3](#13-how-to-read-this-guide-and-six-terminal-commands) | Learn how to read the commands in this guide |
| [1.4](#14-install-git) | Install git |
| [1.5](#15-get-this-repository) | Get this repository |
| [1.6](#16-check-what-you-have) | **Check what you have.** It tells you which of 1.7 to 1.10 you need |
| [1.7](#17-install-python) · [1.8](#18-install-claude-code) · [1.9](#19-sign-in-to-claude-code) · [1.10](#110-a-spreadsheet-and-opening-files) | Install Python, install Claude Code, sign in, get a spreadsheet |
| [1.11](#111-start-every-terminal-session-with-startsh) | Start every terminal window with `start.sh` |
| [1.12](#112-know-where-things-live) · [1.13](#113-build-the-practice-repository) · [1.14](#114-copy-the-tracker) | Where things live, build the practice repository, copy the tracker |

### 1.1 What you need

| You need | Why | If you don't have it |
|---|---|---|
| A computer running **macOS 13 or later**, **Linux** (Ubuntu 20.04 or later, Debian 10 or later), or **Windows 10 (version 2004 or later) or 11, with WSL** | Claude Code runs on these. The workshop's scripts need a bash-style terminal, and on Windows that means WSL | Windows: set up WSL in [1.2](#12-open-a-terminal) |
| 4 GB of memory, about 1 GB of free disk space, and an internet connection | To download the tools and run Claude Code | |
| A **terminal** | The window where you type commands | [1.2](#12-open-a-terminal) |
| **git** 2.28 or later | Downloads this repository, and replays the practice history | [1.4](#14-install-git) |
| **Python** 3.11, 3.12, or 3.13 | Runs the practice service's tests | [1.7](#17-install-python) |
| **Claude Code** 2.1.257 or later | The tool the workshop measures | [1.8](#18-install-claude-code) |
| A **Claude account** that can use Claude Code: a Pro, Max, Team, or Enterprise plan; a Console account with credits; or your organization's Amazon Bedrock, Google Cloud, or Microsoft Foundry setup | Every run is billed to it | Ask your Claude administrator, or see [claude.com/pricing](https://claude.com/pricing) |
| A **spreadsheet** that opens `.xlsx` files and calculates formulas. Excel is recommended | The evaluation tracker | [1.10](#110-a-spreadsheet-and-opening-files) |
| A budget for model calls: about **$7** if you run all 18 practice runs, about $2.50 for the workshop's standard six | Each `claude -p` run is billed to your account | |
| *Track B only:* merged pull requests for each target task, the repositories they were merged into, and a senior engineer or reviewer who can judge the work | They are the cases you measure | The [pre-work](ccw5g-pre-work.md) |

### 1.2 Open a terminal

A **terminal** is a window where you type commands instead of clicking. Everything in this guide that looks like a command goes there.

- **macOS:** press `Cmd + Space`, type `Terminal`, and press `Enter`.
- **Linux:** press `Ctrl + Alt + T`, or open "Terminal" from your applications menu.
- **Windows:** use **WSL**, which runs real Linux inside Windows. Set it up once:
  1. Press the Windows key, type `PowerShell`, right-click **Windows PowerShell**, choose **Run as administrator**, and click **Yes**.
  2. Type this and press `Enter`. It downloads Ubuntu, so give it a few minutes:
     ```powershell
     wsl --install -d Ubuntu-24.04
     ```
  3. Restart the computer if it asks. Afterwards an **Ubuntu** window opens (or open **Ubuntu 24.04 LTS** from the Start menu). It asks you to create a username and a password. Choose anything you'll remember. When you type the password **no characters appear**: that is normal.
  4. **That Ubuntu window is your terminal for the whole workshop.** Wherever this guide says "terminal", use it, not PowerShell or Command Prompt.
  - If `wsl` isn't recognized, or your company blocks it, ask your IT team to enable WSL, or use another computer.
  - If the install stops with a message about **virtualization** (or an error code such as `0x80370102`), virtualization is turned off in the computer's firmware. Your IT team can turn it on; on a company laptop, don't change firmware settings yourself.

What you should see is a window with a blinking cursor and a line of text ending in `$` or `%`, such as `alex@laptop:~$`. That line is the **prompt**: it means the terminal is waiting for you.

### 1.3 How to read this guide, and six terminal commands

**Commands** are in grey boxes. Type or paste each one into the terminal and press `Enter`. To paste: `Cmd + V` on macOS, `Ctrl + Shift + V` in a Linux or WSL terminal (or right-click). On GitHub, a copy button appears when you point at a box.

- **Don't type the prompt** (the `$` or `%`).
- **There are no `#` comments inside the command boxes**, on purpose. Some terminals, including the default one on macOS, don't understand comments and would treat them as part of the command. What each command does is explained in the text around the box.
- A `\` at the end of a line means the command **continues on the next line**. Paste the whole box at once.
- `~` means **your home folder**, such as `/Users/alex` or `/home/alex`.
- Text in `<angle brackets>` is a **placeholder**: replace it, brackets and all, with your own value.
- Wait for the prompt to **come back** before you type the next command. Some commands take minutes and print nothing meanwhile.
- If a command is still running and you need to stop it, press `Ctrl + C`.
- **`less` opens a pager.** When a command shows a file one screen at a time and the last line shows `:` or `(END)`, press **`q`** to get back to the prompt. Press `Space` to scroll down first if you like. Run commands that open a pager **one at a time**, and wait for the prompt before you paste the next one. Git's own output just prints (once you've run `start.sh`): scroll up with your trackpad or mouse wheel to read the top.

Six commands you'll meet:

| Command | What it does |
|---|---|
| `pwd` | Prints **where you are** (the folder you're in) |
| `ls` | **Lists** the files in the current folder |
| `cd <folder>` | **Moves** into a folder. `cd ..` goes up one level. `cd ~` goes home |
| `cat <file>` | Prints a file's contents |
| `less <file>` | Shows a file one screen at a time. `Space` scrolls, `q` quits |
| `clear` | Tidies the screen |

On Windows, pasting a box of several lines into the Ubuntu window may show a warning that you're pasting multiple lines: choose **Paste anyway**.

Two time-savers: press `Tab` after typing the start of a file or folder name and the terminal completes it, and press the **up arrow** to bring back the previous command.

### 1.4 Install git

**git** is the tool that tracks changes to code. You need it to download this repository and to replay Northwind's history.

```bash
git --version
```

You should see something like `git version 2.43.0`. Any version from 2.28 up is fine.

- **If you see `command not found`, or on macOS a window offers to install "command line developer tools":**
  - **macOS:** click **Install**, wait a few minutes, then run `git --version` again. Or run `xcode-select --install`.
  - **Ubuntu, Debian, or WSL:**
    ```bash
    sudo apt update && sudo apt install -y git
    ```
    `sudo` asks for your password (the one you chose in 1.2). No characters appear as you type: that is normal.

### 1.5 Get this repository

```bash
cd ~
git clone https://github.com/WWT-AINE-Workshops/workshop-evaluate-claude-code ccw5g
cd ccw5g
ls
```

This downloads the repository, `workshop-evaluate-claude-code`, from the WWT-AINE-Workshops organization on GitHub. The `ccw5g` at the end of the command is just the name of the folder it creates on your computer: keep it, because the rest of this guide uses `~/ccw5g`. The `ls` command should list these names (your terminal may lay them out in columns):

```text
AGENTS.md  CLAUDE.md  LICENSE  README.md  WALKTHROUGH-dotnet.md  WALKTHROUGH.md  demo  templates
ccw5g-participant-workbook.docx  ccw5g-participant-workbook.md
ccw5g-pre-work.docx  ccw5g-pre-work.md  ccw5g-slides.pptx
ccw5gd-participant-workbook.docx  ccw5gd-participant-workbook.md
ccw5gd-pre-work.docx  ccw5gd-pre-work.md  ccw5gd-slides.pptx
```

- **On Windows, clone inside Ubuntu (WSL), in your home folder `~`**, not under `/mnt/c`. Files on the Windows side get changed in ways that break the scripts.
- **If it says the repository isn't found, or asks for a username and password,** you need access to the WWT-AINE-Workshops organization first: ask your presenter. GitHub doesn't accept account passwords at that prompt, so use your GitHub username and a [personal access token](https://github.com/settings/tokens) as the password, or run `gh auth login` if you have GitHub's command-line tool.
- **No git access at all?** On GitHub, choose **Code > Download ZIP**, unzip it into your home folder, and rename the folder to `ccw5g`. ZIP files can lose the "runnable" flag on scripts, so put the word `bash` in front of every script you run, for example `bash ~/ccw5g/templates/check-setup.sh`.
  - **On Windows,** the ZIP lands in your Windows Downloads folder. Move it into Ubuntu's home folder from the Ubuntu window, replacing `<you>` with your Windows user name (look in `C:\Users` if unsure):
    ```bash
    sudo apt update && sudo apt install -y unzip
    cd ~ && cp /mnt/c/Users/<you>/Downloads/workshop-evaluate-claude-code-main.zip ~/ && unzip -q workshop-evaluate-claude-code-main.zip && mv workshop-evaluate-claude-code-main ccw5g
    ```

### 1.6 Check what you have

This script looks at your computer and tells you what's missing and **exactly how to fix it**. It changes nothing.

```bash
bash ~/ccw5g/templates/check-setup.sh
```

Each line starts with `[ ok ]`, `[warn]`, or `[FIX ]`. When everything is fine you'll see something like this (shortened here):

```text
Git
  [ ok ]  git 2.43.0
Python (3.11, 3.12, or 3.13)
  [ ok ]  python3.12 is Python 3.12.3
  [ ok ]  python3.12 can create a virtual environment and has pip
Claude Code (version 2.1.257 or later)
  [ ok ]  Claude Code 2.1.285

All set. (0 notes above.)
```

For every `[FIX ]`, follow its instructions (or the matching step below: [1.4](#14-install-git) git, [1.7](#17-install-python) Python, [1.8](#18-install-claude-code) Claude Code, [1.9](#19-sign-in-to-claude-code) signing in). Then **open a new terminal window** and run the check again. Repeat until it says `All set`.

If you already have everything, skip the rest of 1.7 to 1.10 except the sign-in check in 1.9.

### 1.7 Install Python

**Python** is the programming language the practice service is written in. You don't write any Python: you only need it installed. Versions **3.11, 3.12, or 3.13** work. Newer versions work but print many warnings. Your computer may have several Pythons: `start.sh` ([1.11](#111-start-every-terminal-session-with-startsh)) picks a suitable one for you.

- **macOS:** the easiest way is the installer. Go to [python.org/downloads](https://www.python.org/downloads/), download **Python 3.12** for macOS, open the file, and click **Continue** through the screens. (If you use Homebrew, `brew install python@3.12` does the same.)
- **Ubuntu or Debian, or WSL:**
  ```bash
  sudo apt update && sudo apt install -y python3 python3-venv python3-pip
  ```
  `python3-venv` matters: without it, the workshop's next step fails with a message about `ensurepip`. Ubuntu 24.04 (the WSL default we installed) includes Python 3.12. On Ubuntu 22.04 or older the version is too old, so add a newer one instead:
  ```bash
  sudo apt install -y software-properties-common
  sudo add-apt-repository ppa:deadsnakes/ppa
  sudo apt update && sudo apt install -y python3.12 python3.12-venv
  ```

Then **open a new terminal window** and run the check from 1.6 again.

### 1.8 Install Claude Code

**macOS, Linux, or WSL**, one command:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

You'll see text scroll by, ending with `Claude Code successfully installed!`. Then **open a new terminal window** and check:

```bash
claude --version
```

You should see a number such as `2.1.285 (Claude Code)`. The workshop needs **2.1.257 or later**.

- **`claude: command not found`:** the installer put Claude Code in `~/.local/bin`, which your terminal doesn't search yet. Run the line for your terminal, then open a new window.
  - On **macOS** (zsh):
    ```bash
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    ```
  - On **Linux or WSL** (bash):
    ```bash
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    ```
- **Version too old:** run `claude update`. If you installed with Homebrew, run `brew upgrade claude-code`.
- **On Windows, install inside Ubuntu (WSL)**, not in PowerShell: Claude Code's Windows version isn't what this guide's scripts expect.
- **Prefer Homebrew on a Mac?** `brew install --cask claude-code`.
- Still stuck? Run `claude doctor`: it checks your installation and says what's wrong.

### 1.9 Sign in to Claude Code

Claude Code needs an account the first time you run it. In the terminal:

```bash
cd ~
claude
```

1. The first time, Claude Code asks you to pick a colour theme (any is fine) and how to sign in: choose your **Claude account** (subscription) unless your organization told you to use the Console or a cloud provider. Then, if it asks whether you trust the folder, choose **Yes**.
2. A browser window opens. Sign in to your Claude account and approve. (**No browser, such as in WSL?** Copy the web address it prints into any browser on your computer and follow the steps there.)
3. Back in the terminal you'll see the Claude Code welcome screen. Type `/exit` and press `Enter` to leave.

You only do this once. If you use your organization's Amazon Bedrock, Google Cloud, or Microsoft Foundry setup instead, your administrator gives you the settings to use first.

Now prove it works. This makes one tiny real call to Claude Code and costs a few cents:

```bash
bash ~/ccw5g/templates/check-setup.sh --live
```

You want to see `[ ok ]  claude -p works, so you are signed in`. If it says `claude -p did not work`, read the message under it: it's almost always that you aren't signed in yet, or your plan doesn't include Claude Code.

> **Why `claude -p`?** The `-p` stands for "print". It makes Claude Code answer one request and exit, with no back-and-forth. The workshop's runs all work this way, so everything repeats the same way each time.

### 1.10 A spreadsheet, and opening files

The evaluation tracker is an Excel workbook (`.xlsx`) with formulas. It was built for **Microsoft Excel**, on the desktop or on the web. **LibreOffice** (free from [libreoffice.org](https://www.libreoffice.org/)) and Google Sheets usually work. If the numbers look wrong or blank, switch to Excel.

Opening a file or folder from the terminal:

| Where you are | Open a file | Open a folder |
|---|---|---|
| macOS | `open <file>` | `open <folder>` |
| Linux | `xdg-open <file>` | `xdg-open <folder>` |
| WSL (Windows) | `explorer.exe "$(wslpath -w <file>)"` | `explorer.exe .` (opens the current folder) |

On WSL you can also open **File Explorer** and type `\\wsl$\Ubuntu-24.04\home\<your-username>` in the address bar.

### 1.11 Start every terminal session with `start.sh`

Type `source`, not `bash`, for this one script: `bash` would run it and forget everything it set at once.

Each new terminal window starts with a clean slate: it forgets where this repository is, and which Python tools are switched on. So **at the start of every new terminal window** run:

```bash
source ~/ccw5g/templates/start.sh
```

It prints three lines and changes nothing outside this window:

```text
KIT=/home/alex/ccw5g
PYTHON=python3.12
Practice virtual environment: off (you make it in step 1.13 of WALKTHROUGH.md)
```

- **`KIT`** is where this repository lives. Later commands use it, so you don't type the long path.
- **`PYTHON`** is the name of a suitable Python on your computer. If it says `not found`, go back to 1.6.
- **The virtual environment** (explained in 1.13) says `off` until you build the practice repository, then `on` every time.

It also puts `run-case.sh` on your path, so you can run it by name, and stops git from opening a pager (see 1.3), so git's output simply prints.

### 1.12 Know where things live

Isolation is the heart of this workshop. Three places, kept apart:

| Folder | What's in it | Who reads it |
|---|---|---|
| `~/ccw5g` | This repository: slides, workbook, templates, the demo kit | You |
| `~/nw-foundation` | The practice repository **with its full history**, and `eval-set/`: case files, reference answers, outputs, your tracker | You and the graders. **Never Claude.** |
| `~/nw-runs` | Clones that stop at the commit before each fix, and one worktree per run | Claude, and nothing else |

Keep these folders in your home folder, not in `/tmp`. Never put one inside another.

### 1.13 Build the practice repository

> 🅱 **Track B:** you only need this step to rehearse on Northwind first. Skip it if you're going straight to your own repositories.

First, a **virtual environment**: a private folder of Python tools just for this workshop, so nothing is installed system-wide and nothing can clash. You make it once, and **switch it on in each terminal window** (`start.sh` does that for you once it exists). When it's on, the prompt starts with `(.venv)`.

```bash
source ~/ccw5g/templates/start.sh
mkdir -p ~/nw-foundation
"$PYTHON" -m venv ~/nw-foundation/.venv
source ~/nw-foundation/.venv/bin/activate
pip install -r "$KIT/demo/python-fastapi/northwind-shipments-api/requirements.txt" \
            -r "$KIT/demo/python-fastapi/northwind-shipments-api/requirements-dev.txt"
```

The install takes under a minute. It ends with a long `Successfully installed …` line. A `[notice] A new release of pip is available` message is harmless: ignore it.

- **`"$PYTHON"` is empty or `command not found`:** you skipped 1.6 or `start.sh`. Go back and run them.
- **A message about `ensurepip` or `python3-venv`:** on Ubuntu or WSL, run `sudo apt install -y python3-venv`, then try again.

Now build the practice repository. Still in the same window:

```bash
"$KIT/demo/python-fastapi/make-foundation-history.sh" --verify ~/nw-foundation
```

The script copies the fictional `northwind-shipments-api` service into `~/nw-foundation`, gives it a history of merged, closed, and open pull requests, and writes `~/nw-foundation/eval-set/` with six practice cases. `--verify` then checks every step as it goes. It takes about 15 seconds and prints about 50 lines, each starting `PASS`. It never signs commits or runs your git hooks.

You should end with:

```text
Verify: all checks PASSED
Created /home/alex/nw-foundation/northwind-shipments-api
Created /home/alex/nw-foundation/eval-set (eval set for cases P-01 to P-06)
dbb6768 (pr-171) docs: add carriers examples to docs/api.md (#171)
71f20dc (pr-170, case/P-05) feat: export shipments as CSV (#170)
2e681b9 (HEAD -> main, tag: pr-163-merged, case/P-06) fix: admin delete requires an admin (#163)
d7c826e (tag: pr-161-weak) test: admin delete endpoint (#161)
88974b5 (tag: pr-158-merged, case/P-04) fix: search with an apostrophe returns a 500 (#156)
e19343f (tag: pr-153-merged, case/P-02) test: cover the carriers sort parameter (#153)
6a6a74d (tag: pr-151-merged, case/P-03) fix: shipment lookup when no carrier is assigned yet (#151)
fd648d1 Revert "fix: hide carrier lookup errors on shipment lookup (#149)"
57cf5f2 (tag: pr-149-weak) fix: hide carrier lookup errors on shipment lookup (#149)
569ea91 (tag: issue-142-base, case/P-01) feat: show the carrier name on shipment lookup (#147)
13136eb (tag: v1.4.0) chore: release 1.4.0
```

Your eleven commit codes (the first column) match these exactly. That tells you the history is the one the workshop expects.

- **Done when** the script ends with `Verify: all checks PASSED`.
- **If you get stuck:**
  - **`already exists`:** you've run it before. Remove the old copies, then run it again (leave `.venv` in place):
    ```bash
    rm -rf ~/nw-foundation/northwind-shipments-api ~/nw-foundation/eval-set
    ```
  - **`--verify needs pytest, ruff…`:** the virtual environment isn't switched on. Run `source ~/nw-foundation/.venv/bin/activate` and try again.
  - **`FAIL` lines:** copy the first one into a message to your presenter. Don't carry on: later steps depend on this.

### 1.14 Copy the tracker

```bash
cp "$KIT/templates/foundation-evaluation-tracker.xlsx" ~/nw-foundation/eval-set/
```

Now open it (see the table in [1.10](#110-a-spreadsheet-and-opening-files)). On macOS: `open ~/nw-foundation/eval-set/foundation-evaluation-tracker.xlsx`. On WSL: `explorer.exe "$(wslpath -w ~/nw-foundation/eval-set/foundation-evaluation-tracker.xlsx)"`.

The tracker is where every exercise's results go. Its **Read Me** tab explains each tab. Row 4 of every tab is a grey example that the calculations skip: start your entries on row 5. If Excel opens the file in **Protected View**, choose **Enable Editing** so the formulas calculate. **Save** (`Cmd/Ctrl + S`) as you go.

Spreadsheet basics, if you need them: click a cell and type; `Tab` moves right and `Enter` moves down. A cell with a small arrow is a **dropdown**: pick from the list, so the Summary can count it. Grey cells calculate themselves: don't type in them.

> 🅱 **Track B:** your coordinator has already made an `eval-set` folder for your team, as [pre-work](ccw5g-pre-work.md) Step 1 describes. Use that tracker instead.

---

## 2. Welcome and room check

*Slides 1–3. In a live session this is the opening; on your own, read the slides and do the check.*

1. Read slide 2 (what you will leave with) and slide 3 (the agenda).
2. Run `claude --version` and write the version down. It goes on every row of the Runs tab later.
3. **Working agreements:** every run happens in its own fresh worktree, never in a working tree you're using; nobody pushes to a shared branch; secrets and confidential data stay out of anything you share. In a live session, post `stuck` in chat at any point and the presenter comes to you.

---

## 3. What the foundation has to prove

*Slides 4–8, 15 minutes. Workbook: [Reference](ccw5g-participant-workbook.md#reference), "What the foundation has to prove".*

Read slides 4–8, then take these five ideas with you:

1. **Decide the evidence before you see it.** Name the decision the foundation supports and who makes it. Criteria written after the results tend to fit the results.
2. **Adoption is not quality.** The analytics dashboard shows whether Claude Code was used, not whether the change was right. Today is about quality: is the change good enough to merge, every time?
3. **Benchmarks are for comparison, not targets.** Anthropic publishes about $13 per developer per active day on average. Set your own targets from your foundation's week-1 figures.
4. **Start evaluating now.** Twenty to fifty cases drawn from real work is a strong start. Today each group builds six to ten; the Northwind practice track uses six.
5. **Most foundation cases are capability cases** (can Claude Code do this yet?). The ones that pass every run become the regression set.

**Try it:** write one sentence naming the decision your foundation supports and who makes it. For Northwind, it's: *"Whether to offer Claude Code to every backend team, made by the head of engineering."*

---

## 4. Exercise 1: Choose target tasks and success criteria

*Slides 9–11. About 15 minutes. Workbook Exercise 1 ([markdown](ccw5g-participant-workbook.md#exercise-1-choose-target-tasks-and-success-criteria) · [Word](ccw5g-participant-workbook.docx)). Tracker: **Target Tasks** and **Exit Criteria** tabs.*

A good target task is work engineers do often, where a test or a reviewer can judge the output, and where merged pull requests show what good looks like.

**Northwind's foundation targets three tasks.** Enter them on the **Target Tasks** tab, rows 5–7, with names spelled *exactly* like this (the Summary matches cases to tasks by name):

| Target task | Owner (role) | What good output looks like (you write this) |
|---|---|---|
| Bug fix from a closed issue | Backend lead | ? |
| Unit tests for changed code | QA lead | ? |
| Pull request review against the checklist | Staff engineer | ? |

Then:

1. For each task, fill in **What good output looks like** in one or two lines a reviewer would agree with. Fill in how often it happens and the inputs it needs; leave **Decision** as *Not decided yet*. The service's `docs/review-checklist.md` and `tests/conftest.py` are worth a look first: `less ~/nw-foundation/northwind-shipments-api/docs/review-checklist.md`, then `less ~/nw-foundation/northwind-shipments-api/tests/conftest.py` (press `q` to leave each).
2. On the **Exit Criteria** tab, set a target for each criterion **before any result exists**:
   - **Target-task pass rate, per task** (row 5): the percentage each target task must reach. The tracker judges every task against it separately, on the Summary tab.
   - **Share of cases passing every run** (row 6), the consistency bar, as a percentage.
   - **Adoption** (rows 7–8), from Northwind's fictional week-1 analytics: 20 seats, 7 daily active users in week 1 (35%), and 9% of pull requests with Claude Code.
   - **Target tasks ready to expand** (row 9).
   - **Cost per developer per active day** (row 10). Northwind's week-1 cost was about $11; Anthropic's benchmark of about $13 sits in the Source column for comparison.
3. Use the workbook page to draft, if that's easier.

- **Done when** three target tasks have a row each and every exit criterion has a target, written before you have run anything.
- **Compare:** [ANSWERS.md §1](demo/python-fastapi/ANSWERS.md#1-exercise-1-target-tasks-and-exit-criteria). Your targets can differ. What matters is that each one could be measured.

> 🅱 **Track B:** confirm the three to five target tasks from your pre-work, and set targets from your own week-1 figures.

---

## 5. Exercise 2: Write cases from real work

*Slides 12–15. About 24 minutes. Workbook Exercise 2 ([markdown](ccw5g-participant-workbook.md#exercise-2-write-cases-from-real-work) · [Word](ccw5g-participant-workbook.docx)). Tracker: **Eval Cases** tab.*

> **Don't open `~/nw-foundation/eval-set/` yet.** It holds the finished cases, so it's the answer key for this exercise. Write your own first.

A case is a request, phrased as an engineer would ask, plus the code as it was before the pull request, what a good result must include, what it must not do, and its target task. The merged pull request is the reference output.

### 5.1 Explore Northwind's work

> **New terminal window?** Run `source ~/ccw5g/templates/start.sh` first ([1.11](#111-start-every-terminal-session-with-startsh)).

The practice repository is a record of the team's work. These commands read it. They change nothing:

```bash
cd ~/nw-foundation/northwind-shipments-api
git log --oneline --graph --decorate --all
```

You should see this picture, newest work at the top. Each line is one change (a **commit**). The code in the first column identifies it, and the brackets show its labels.

```text
* dbb6768 (pr-171) docs: add carriers examples to docs/api.md (#171)
| * 71f20dc (pr-170, case/P-05) feat: export shipments as CSV (#170)
|/
* 2e681b9 (HEAD -> main, tag: pr-163-merged, case/P-06) fix: admin delete requires an admin (#163)
| * d7c826e (tag: pr-161-weak) test: admin delete endpoint (#161)
|/
* 88974b5 (tag: pr-158-merged, case/P-04) fix: search with an apostrophe returns a 500 (#156)
* e19343f (tag: pr-153-merged, case/P-02) test: cover the carriers sort parameter (#153)
* 6a6a74d (tag: pr-151-merged, case/P-03) fix: shipment lookup when no carrier is assigned yet (#151)
* fd648d1 Revert "fix: hide carrier lookup errors on shipment lookup (#149)"
* 57cf5f2 (tag: pr-149-weak) fix: hide carrier lookup errors on shipment lookup (#149)
* 569ea91 (tag: issue-142-base, case/P-01) feat: show the carrier name on shipment lookup (#147)
* 13136eb (tag: v1.4.0) chore: release 1.4.0
```

Now look at one merged fix, first as a summary:

```bash
git show --stat pr-151-merged
```

That prints which files the fix changed. Then see the full change, including its regression test (it is longer than one screen, so scroll up to read the top):

```bash
git show pr-151-merged
```

The summary lists three files: `CHANGELOG.md`, `app/routes/shipments.py` (one line), and `tests/test_shipments.py` (8 new lines, the regression test). In the full view, lines starting with `+` were added and lines starting with `-` were removed.

What the graph shows:

- **Tags** (`pr-151-merged`, …) mark merged pull requests.
- **`pr-149-weak`** is an early fix that was merged and then reverted.
- **`pr-161-weak`** is a pull request that was closed without merging.
- **`pr-170` and `pr-171`** are branches with open pull requests.
- **`case/P-0N` branches** sit at the commit before each pull request. That's where each case's run starts. The two review cases are the exception: `case/P-05` sits on pull request 170 itself, and `case/P-06` on `main`.

Northwind's issue tracker, as the team would see it on its Git host:

| Pull request | Case | Status | Issue or description | Approved or reviewed by |
|---|---|---|---|---|
| #151 (`pr-151-merged`) | P-01 | Merged | Issue 142: "GET /shipments/{id} returns a 500 when the shipment has no carrier yet. A missing carrier is valid for shipments not yet dispatched." | Backend lead |
| #149 (`pr-149-weak`) | P-01 (its weak output) | Merged, then reverted (#150) | An early fix for issue 142, written with Claude Code | Reverted by the backend lead |
| #153 (`pr-153-merged`) | P-03 | Merged | "Write tests for the carriers sort parameter." | QA lead |
| #158 (`pr-158-merged`) | P-02 | Merged | Issue 156: "Searching shipments for a name with an apostrophe, such as O'Brien, returns a 500." | Backend lead |
| #161 (`pr-161-weak`) | P-04 (its weak output) | Closed, not merged | "Add tests for the admin delete endpoint", first attempt, written with Claude Code | Rejected by the QA lead |
| #163 (`pr-163-merged`) | P-04 | Merged | Admin delete requires an admin, with its tests | QA lead |
| #170 (branch `pr-170`) | P-05, and P-06 | Open | "feat: export shipments as CSV". The staff engineer's review blocked it. | Staff engineer |
| #171 (branch `pr-171`) | P-06 | Open | "docs: add carriers examples to docs/api.md" | — |

The Case column says which practice case each pull request belongs to: the case IDs follow the order the cases are written in, not the pull request numbers. Use `git show <tag-or-branch>` to read any of them, and `git diff case/P-02 pr-158-merged` (for example) to see exactly what a pull request changed.

### 5.2 Write six cases

On the **Eval Cases** tab, write one row per case, **P-01 to P-06**:

- Two cases for each target task, from the table above.
- At least one case where the right response is to **ask a question first**. Hint: a reviewer is asked to "Review this" while two pull requests are open.
- Write the **request** as the engineer would have typed it, usually the issue text.
- Write **Must include** and **Must not** in words a reviewer could apply. Ask yourself what a bad fix could get away with.
- Record any **weak output** with its case: the reverted, rejected, or wrong earlier attempt.
- Fill in the **Automatable grader** column: the pull request's tests, the tests on the fixed code, or reviewer judgment.

**Done when** six cases have a row each, naming their target task and reference.

**Compare:** now open the finished cases: `ls ~/nw-foundation/eval-set/P-0*` (or browse [demo/python-fastapi/eval-set/](demo/python-fastapi/eval-set/)), and the table in [ANSWERS.md §2](demo/python-fastapi/ANSWERS.md#2-exercise-2-the-six-cases). Stop at the table: the notes after it give away Exercise 3. Each `request.md`, `context.md`, and `note.md` is one case. Rewrite any row where yours missed something a bad fix could get away with.

> 🅱 **Track B:** write cases from the pull requests in your team's `eval-set` folder. Create the case branch for each, as [pre-work](ccw5g-pre-work.md) Step 3 describes.

---

## 6. Exercise 3: Calibrate

*Slides 16–17. About 10 minutes. Workbook Exercise 3 ([markdown](ccw5g-participant-workbook.md#exercise-3-calibrate) · [Word](ccw5g-participant-workbook.docx)). Tracker: **Calibration** tab.*

The standard: two domain experts, grading separately, reach the same verdict. If graders disagree, the case is unclear, so the fix is to rewrite the case, not to correct the grader. You don't need Claude Code for this: you grade outputs that already exist.

Three cases have both a reference output and a weak one: **P-01, P-04, and P-06**.

1. For each of the three, grade the **reference** and the **weak** output against *your* Must include and Must not, without looking at the answer key. Use Pass, Fail, or Can't tell (Can't tell means the case doesn't say enough to decide).

   ```bash
   cd ~/nw-foundation/eval-set
   ```

   Open each pair **one at a time**. Each command opens two files, one after the other: press `q` to leave the first, and `q` again to leave the second. Wait for the prompt before the next command.

   ```bash
   less P-01/reference.diff P-01/weak.diff
   ```

   ```bash
   less P-04/reference.diff P-04/weak.diff
   ```

   ```bash
   less P-06/reference.md P-06/weak.md
   ```

2. On the **Calibration** tab, add one row per output: Case ID, Output graded (Weak or Reference), Grader A = you, Grader A verdict.
3. Open [ANSWERS.md §3](demo/python-fastapi/ANSWERS.md#3-exercise-3-calibration). It plays **Grader B**. Enter its verdicts, and set "Both domain experts?" to **No**: the case is recorded as *Expert and presenter* until a second real expert confirms it.
4. Where the verdicts differ, rewrite the case on the Eval Cases tab, and grade it again on a new Calibration row.

- **Done when** every graded output has an agreed verdict or a rewritten case, and the agreement rate shows at the top right of the Calibration tab.
- **The lesson most people find here:** a case for P-04 that says only "tests for the admin delete endpoint" lets the weak tests pass, even though they assert the bug.

---

## 7. Exercise 4: Run the baseline

*Slides 18–21. About 28 minutes. Workbook Exercise 4 ([markdown](ccw5g-participant-workbook.md#exercise-4-run-the-baseline) · [Word](ccw5g-participant-workbook.docx)). Tracker: **Runs** tab.*

You now measure what Claude Code does today. No skill is needed: the baseline is Claude Code as installed, with the repository's own CLAUDE.md. Anything you've added to Claude Code for yourself is switched off for the runs: your personal add-ons (plugins, hooks, connections to other tools called MCP servers), your own instructions file, and the notes Claude Code saves between sessions (auto memory). The glossary in the workbook defines each one. Two reasons: everyone tests the same out-of-the-box Claude Code, and no run can read what an earlier run left behind.

**Why isolation matters.** Anthropic has seen Claude gain an unfair advantage in its own evaluations by reading the git history of earlier trials. Three things guard against that here:

1. Each run's clone stops at the case branch, so the fix isn't in its history.
2. `eval-run-settings.json` turns on `permissions.blockReadsOutsideWorkingDirectories`. Without it, commands like `cat` can read `~/nw-foundation` (where the answers are) from inside a run. With it, Claude's own reads outside the run folder are refused. It does not cover programs the run starts: a test that Claude writes and then runs with `pytest` could still open a file outside the folder. So when you grade, read every new or changed test in the diff.
3. Each run loads only the repository's own settings and CLAUDE.md, and saves nothing for a later run to find (the personal setup described above).

### 7.1 One run by hand (case P-01)

Do one run by hand, so you know what the script does for you later. Take it a few lines at a time and check each result.

> **New terminal window?** Run `source ~/ccw5g/templates/start.sh` first. The prompt should start with `(.venv)`.

**Step 1.** Make a clone that stops at the commit before the fix, and a fresh worktree to run in. These commands make the runs folder and move into it, clone only the `case/P-01` branch (so the fix isn't in the history), cut the clone's link to the original, list its commits, add a fresh worktree beside the clone (the `../` in the path means "one folder up from the clone"), and move into that worktree:

```bash
mkdir -p ~/nw-runs && cd ~/nw-runs
git clone --quiet --no-local --single-branch --branch case/P-01 --no-tags \
    ~/nw-foundation/northwind-shipments-api eval-P-01
git -C eval-P-01 remote remove origin
git -C eval-P-01 log --oneline
git -C eval-P-01 worktree add --detach ../P-01-run-1
cd ~/nw-runs/P-01-run-1
```

You should see exactly two commits (the fix isn't there to find), and then a line such as `HEAD is now at 569ea91 feat: show the carrier name on shipment lookup (#147)`:

```text
569ea91 feat: show the carrier name on shipment lookup (#147)
13136eb chore: release 1.4.0
```

A **worktree** is a second working folder for the same repository, so each run has a folder of its own to change. Check where you are with `pwd`: it should end in `/nw-runs/P-01-run-1`.

**Step 2.** The run itself. You're still inside `~/nw-runs/P-01-run-1` from Step 1: Claude works in whatever folder you run it from, which is why isolation matters.

```bash
claude -p "$(cat ~/nw-foundation/eval-set/P-01/request.md)" \
  --settings ~/nw-foundation/eval-set/eval-run-settings.json \
  --permission-mode acceptEdits \
  --setting-sources project,local --strict-mcp-config --no-session-persistence \
  --allowedTools "Bash(pytest *),Bash(python -m pytest *)" \
  --output-format json > ~/nw-foundation/eval-set/outputs/P-01-run-1.json
```

**This takes one to five minutes and prints nothing while it works**: the answer goes into the file after `>`. It's working, not frozen. Wait for the prompt to come back. (If it returns at once with an error, see Troubleshooting.)

What the flags do:

- `acceptEdits` lets Claude edit files without asking.
- `--setting-sources project,local`, `--strict-mcp-config`, and `--no-session-persistence` switch off your personal setup and save nothing after the run; the settings file does the rest. If your organization signs you in through Amazon Bedrock, Google Cloud, or Microsoft Foundry, see the sign-in row in [Troubleshooting](#12-troubleshooting) first.
- `--allowedTools` pre-approves the test command. Nobody answers prompts in a `-p` run, so anything else that would ask is denied.
- `--output-format json` keeps the reply together with its cost and the model used.

**Step 3.** Look at what Claude did:

```bash
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['result']); print('model:', ', '.join(d.get('modelUsage', {})), '  cost: \$%.2f' % d['total_cost_usd'])" ~/nw-foundation/eval-set/outputs/P-01-run-1.json
git diff > ~/nw-foundation/eval-set/outputs/P-01-run-1.diff
git status --short
git -C ~/nw-foundation/northwind-shipments-api show pr-151-merged:tests/test_shipments.py > tests/test_shipments.py
pytest -q
less ~/nw-foundation/eval-set/outputs/P-01-run-1.diff
```

What each line does, and what you should see:

- **The first line** prints Claude's own summary of what it did, then a line like `model: <the model name>   cost: $0.40`.
- **`git diff`** saves Claude's change to a file.
- **`git status --short`** lists the files changed, for example ` M app/routes/shipments.py` (` M` means "modified"). A line starting `??` is a **new** file that the diff leaves out: read it too.
- **The `git ... show` line** copies the merged pull request's tests into the run folder, replacing Claude's version of that file, so the team's own tests decide.
- **`pytest -q`** runs the test suite. It ends with a line such as `13 passed`. If you see `failed`, the run did not fix the problem, or changed something it should not have.
- **`less`** shows the diff: lines starting `+` are what Claude added, `-` what it removed. Press `q` to leave.

Then judge the diff against `P-01/note.md` (read it with `cat ~/nw-foundation/eval-set/P-01/note.md`):

- Does it touch only the shipment lookup?
- Is `carrier_name` still in the response, and null when there's no carrier?
- Did it leave the existing tests alone?

Record the run on the **Runs** tab, row 5, typing across the columns: Case ID (`P-01`), run number (`1`), date, your role, Claude Code version (from `claude --version`), the model (printed above), `None` for skill, `Fresh worktree`, your verdict (Pass, Fail, or Can't tell, from the dropdown), what you noticed, the output location (`~/nw-foundation/eval-set/outputs/P-01-run-1`), the cost, and the duration in minutes (a rough guess is fine for a hand run).

Clean up the worktree. Claude Code doesn't clean up worktrees you create yourself.

```bash
cd ~/nw-runs && git -C eval-P-01 worktree remove --force ../P-01-run-1
```

### 7.2 Check the isolation (optional, about $0.05)

From any run folder, compare the same read with and without the settings file:

```bash
cd ~/nw-runs && git -C eval-P-01 worktree add --detach ../iso-check && cd ~/nw-runs/iso-check
SHOW='import json,sys; d=json.load(sys.stdin); print("denied:", [x.get("tool_name") for x in d.get("permission_denials", [])]); print(d["result"][:200])'
claude -p "Print the first line of ~/nw-foundation/eval-set/P-01/reference.diff" \
  --settings ~/nw-foundation/eval-set/eval-run-settings.json --output-format json | python3 -c "$SHOW"
claude -p "Print the first line of ~/nw-foundation/eval-set/P-01/reference.diff" --output-format json | python3 -c "$SHOW"
cd ~/nw-runs && git -C eval-P-01 worktree remove --force ../iso-check
```

The first run lists a denied tool (Read or Bash) and says it couldn't read the file. The second prints the answer file's first line, `diff --git a/CHANGELOG.md b/CHANGELOG.md`. That's why every run passes `--settings`.

### 7.3 Three runs per case, with run-case.sh

Passing once is not passing every time. A case that passes three times in four passes all three of three runs only about 42% of the time, so each case gets three runs. `run-case.sh` does everything in 7.1 for N runs in parallel and prints rows to paste into the Runs tab.

Take **two cases** (the workshop's standard load): P-01, to finish the case you started, and one that contrasts with it, such as P-04. Each case's `context.md` file holds the exact command to run it. To run **any case's stored command** in one go, use the two lines below, changing `P-04` to the case you want. (The first line is only needed in a new terminal window.)

```bash
source ~/ccw5g/templates/start.sh
bash -c "$(sed '1,/^```bash/d;/^```/,$d' ~/nw-foundation/eval-set/P-04/context.md)"
```

It starts three runs at once, prints `Started 3 run(s) of P-04…waiting…`, and a few minutes later prints three rows of results. (To *see* the command first, run `cat ~/nw-foundation/eval-set/P-04/context.md`.)

| Case | Kind | What run-case.sh grades for you | What you still read |
|---|---|---|---|
| P-01, P-02 | Bug fix | Copies in the merged tests, runs the suite | The .diff: scope, schema, placeholders (P-02) |
| P-03 | Tests for working code | Runs the suite as Claude left it | The .diff: one test per sort value plus the 400, conftest fixtures |
| P-04 | Tests that must catch a bug | `--check-before`: Claude's tests on the buggy code (should fail), then on the fixed code (should pass) | The .diff: is there a 403 test for a customer? |
| P-05, P-06 | Review | Nothing (review case) | The reply (.md): did it flag the export route (P-05), and did it ask which pull request (P-06)? |

You already did P-01 run 1 by hand, so finish its three runs with runs 2 and 3:

```bash
run-case.sh --case P-01 --repo ~/nw-foundation/northwind-shipments-api --branch case/P-01 \
  --request ~/nw-foundation/eval-set/P-01/request.md \
  --test "pytest -q" --allow "Bash(pytest *),Bash(python -m pytest *)" \
  --eval-set ~/nw-foundation/eval-set --runs-dir ~/nw-runs \
  --reference-repo ~/nw-foundation/northwind-shipments-api --reference-ref pr-151-merged \
  --reference-files tests/test_shipments.py --start 2 --runs 2
```

The script reuses P-01's clone from 7.1. For any other case, use the command from its `context.md` as it is: three runs, numbered 1 to 3.

1. Paste the printed rows into the **Runs** tab. Select the copied text with your mouse in the terminal, copy it (`Cmd + C` on macOS, `Ctrl + Shift + C` in Linux or WSL), click cell **A** of the next empty row in the Runs tab (row 5 for your first), and paste (`Cmd/Ctrl + V`). Each value lands in its own column. The same rows are saved in `~/nw-foundation/eval-set/outputs/<case>-runs.tsv`, so you can open that file instead if selecting is awkward. The Verdict column is empty on purpose: you fill it in next. To open that file on WSL: `explorer.exe "$(wslpath -w ~/nw-foundation/eval-set/outputs)"` opens the folder.
2. For each run, read its `.diff`, `.status`, and `.md` in `~/nw-foundation/eval-set/outputs/` (list them with `ls ~/nw-foundation/eval-set/outputs/`, open one with `less`, and press `q` to leave). Judge them against the case's Must include, Must not, and `note.md`, then type **Pass, Fail, or Can't tell** in the Verdict column. Passing tests are necessary, not sufficient. A run that edits a test to make it pass is a Fail.
3. While one case runs, read the last one's diffs. That's where you'll notice the things a verdict misses: put them in **What we noticed**.

- **Done when** each of your cases has three graded runs on the Runs tab.
- **If time runs short,** step down: three runs of one case, then one run per case. Note it in What we noticed. Consistency isn't measured until a case has three graded runs.
- **Going further (self-paced):** run all six cases. That's 18 runs, around $7 at about $0.40 each, so check the cost of your first few before launching the rest.

> 🅱 **Track B:** run your own cases with your repository's test command in `--test` and `--allow`, your own `eval-set` folder, and a runs folder kept apart from it. For a test-writing case, use `--reference-files` with the fixed source files and `--check-before`. For a review case, leave out `--test`.

---

## 8. Reading the result

*Slides 22–23. About 15 minutes. Workbook: [Reference](ccw5g-participant-workbook.md#reference), "From failure to fix". Tracker: **Summary** tab.*

Open the **Summary** tab. It calculates everything from your Eval Cases, Runs, and Calibration rows.

1. **Read it by target task**, not overall. An overall pass rate hides different stories.
2. **Consistency:** the cases with **Passed every run = Yes** are your first regression set. A case that passes sometimes needs a closer look at what varies, run by run.
3. **Name the likely fix for every failing case**, on the **Decisions** tab:

   | What the failure shows | Likely fix |
   |---|---|
   | Context the engineer knew but didn't give | Improve the brief, or add it to CLAUDE.md |
   | A team standard Claude doesn't know | Build a skill |
   | Work Claude can't reach: the issue tracker, logs | Add a tool or MCP server |
   | Judgment Claude shouldn't exercise | Out of scope |

4. **Before you call anything a pass:** trace every file, function, and version in the output back to the repository, and remember that a changed test is the most common way a bad fix gets through.

If you ran only a few cases, read your numbers as a first look, not a result: one run shows whether Claude Code *can* do the work, not whether it does it every time.

**Compare:** [ANSWERS.md §4](demo/python-fastapi/ANSWERS.md#4-reading-the-result) walks through a full, fictional set of 18 runs on these six cases, the same one presenters show.

---

## 9. Exercise 5: Decide and hand off

*Slides 24–26. About 15 minutes, then a 5-minute readout. Workbook Exercise 5 ([markdown](ccw5g-participant-workbook.md#exercise-5-decide-and-hand-off) · [Word](ccw5g-participant-workbook.docx)). Tracker: **Decisions** and **Exit Criteria** tabs.*

1. For each target task, choose **one** decision on the **Target Tasks** tab (Decision column), and record why on the **Decisions** tab, with an owner:
   - Ready to expand · Build a skill · Improve the brief or CLAUDE.md · Add a tool or MCP server · Out of scope
2. On **Exit Criteria**, rows 5, 6, and 9 calculate themselves from your results. Fill in the measured value for the others. For Northwind's fictional analytics: daily active users 52%, pull requests with Claude Code 27%, cost $11. Where a criterion isn't met, write what would change the result in Notes.
3. **Readout:** say out loud, or write down, the target tasks measured, the pass rate by task, the share of cases passing every run, which exit criteria are met, and the decision and owner for each task.

- **Done when** every target task has one decision and an owner, and every exit criterion has a measured value or reads *Not yet measured*.
- **Compare:** [ANSWERS.md §5](demo/python-fastapi/ANSWERS.md#5-exercise-5-decisions).

**After the workshop:**

- Keep the cases that passed every run as the regression set. Re-run it before and after any change to CLAUDE.md, settings, a skill, a plugin, the Claude Code version, or the model.
- Tasks marked *Build a skill* go to **Workshop 2, Skills and Plugins for Engineering Teams**, with their cases as the baseline. Once skills ship in a plugin, **Workshop 5 · Established** moves the cases into `claude plugin eval`.

---

## 10. Track B: doing it on your own repositories

Everything above works the same on your own code. Your team prepares the inputs with the pre-work ([markdown](ccw5g-pre-work.md) · [Word](ccw5g-pre-work.docx)): the `eval-set` folder, the case branches, the analytics figures, and the named experts. These things change:

| Northwind (Track A) | Your repositories (Track B) |
|---|---|
| `make-foundation-history.sh` builds the history and case files | Your coordinator collects merged pull requests into an `eval-set` folder (pre-work Steps 1–3) |
| `case/P-0N` branches already exist | Create a case branch at each pull request's commit before, and push it (pre-work Step 3): `git branch case/P-01 <commit before> && git push origin case/P-01` |
| `~/nw-foundation/eval-set` | Your team's `eval-set` folder, outside every repository |
| `--repo ~/nw-foundation/northwind-shipments-api` | `--repo <your repository's clone URL or path>` |
| `pytest -q` and `Bash(pytest *)` | Your repository's exact test command, in both `--test` and `--allow` |
| `--reference-repo` = the practice repository | A full-history clone of your repository, kept **outside** the runs folder |
| Answer key in `demo/python-fastapi/ANSWERS.md` | Your domain experts, grading separately |
| Fictional week-1 analytics | Your analytics dashboard (pre-work Step 4) |

Things to watch on real code:

- Test suites that need a database, other services, or secrets: pick pull requests whose tests run without them, or use your CI's local setup steps. Never put live secrets in a run folder.
- Monorepos: put the command that runs only the affected package's tests in `--test` and `--allow`.
- Your code stays with your team. Nothing is sent to WWT. Groups share screens during exercises, so keep anything confidential out of the cases.

---

## 11. Clean up

Everything the workshop created is in two folders in your home folder. **Copy your tracker somewhere else first if you want to keep it**, because it lives inside the second folder. Then delete both: On WSL, `cp ~/nw-foundation/eval-set/foundation-evaluation-tracker.xlsx /mnt/c/Users/<you>/Documents/` copies it to your Windows Documents folder.

```bash
rm -rf ~/nw-runs
rm -rf ~/nw-foundation
```

`~/nw-runs` holds the clones and worktrees. `~/nw-foundation` holds the practice repository, the case files, the run outputs, and your tracker. (Deleting a folder removes the worktrees inside it.) To remove this repository too, delete `~/ccw5g` the same way.

---

## 12. Troubleshooting

| Symptom | Fix |
|---|---|
| `command not found: git`, `python3`, `claude` | The tool isn't installed, or this terminal can't find it. Run `bash ~/ccw5g/templates/check-setup.sh` and follow its `[FIX ]` lines, then open a new terminal window |
| `Permission denied` when running a script | Put `bash` in front: `bash ~/ccw5g/templates/check-setup.sh`. (Scripts from a ZIP download lose their "runnable" flag) |
| The prompt doesn't start with `(.venv)`, or `pytest: command not found` | The practice virtual environment is off in this window. Run `source ~/ccw5g/templates/start.sh` |
| `$PYTHON` is empty | No suitable Python was found. Do [1.7](#17-install-python), open a new window, and run `start.sh` again |
| The screen shows `:` or `(END)` and nothing responds | You're in a pager. Press `q` |
| A run seems stuck | `claude -p` prints nothing until it finishes, and a run can take up to five minutes. Wait. To give up, press `Ctrl + C`, then remove the worktree (see below) and start that run again |
| `claude -p` fails with a login or permission message | Run `bash ~/ccw5g/templates/check-setup.sh --live`. Usually you need to sign in (run `claude`), or your plan doesn't include Claude Code |
| A run can't sign in, although plain `claude -p` works | Your Amazon Bedrock, Google Cloud, or Microsoft Foundry settings, or an `apiKeyHelper`, are in your `~/.claude/settings.json`, which the runs skip. Set the same values as environment variables in your terminal instead (for example `export CLAUDE_CODE_USE_BEDROCK=1`), then run again |
| `make-foundation-history.sh` says the folder already exists | Remove `~/nw-foundation/northwind-shipments-api` and `~/nw-foundation/eval-set`, then run it again |
| `--verify` says it needs pytest, ruff, and the requirements | Activate the virtual environment: `source ~/nw-foundation/.venv/bin/activate` |
| Many `DeprecationWarning` lines in test output | You're on Python 3.14 or later. Use 3.11–3.13, or add `-W ignore::DeprecationWarning` to the test command |
| A run says its test command was denied | `--allow` doesn't match the exact command Claude ran. Include both `Bash(pytest *)` and `Bash(python -m pytest *)` |
| The isolation check (7.2) prints the file even with `--settings` | Check `claude --version` is 2.1.257 or later, and that `~/nw-foundation` and `~/nw-runs` are in your home folder, not a temporary folder |
| `run-case.sh: command not found` | Run `export PATH="$KIT/templates:$PATH"`, or call `"$KIT/templates/run-case.sh"` |
| `run-case.sh` says a worktree or output already exists | An earlier run of the same case is still there. To add more runs to a case, use `--start` with the next run number (for example `--start 4 --runs 3`). Remove `~/nw-runs/<case>-run-N` (`git -C ~/nw-runs/eval-<case> worktree remove --force …`) and the matching files in `outputs/`, or use a new `--case` label |
| A worktree folder appears inside `eval-P-01/` | The path in `git -C eval-P-01 worktree add` is relative to the clone. Use `../P-01-run-1` |
| Tracker formulas show 0 or nothing | Choose **Enable Editing** in Excel; in other spreadsheets, recalculate (LibreOffice: Data > Calculate > Recalculate Hard) |
| Summary doesn't count a case | The Case ID or target task on another tab doesn't match exactly. Use the dropdowns |
