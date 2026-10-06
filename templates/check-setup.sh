#!/usr/bin/env bash
# Checks that this computer is ready for the workshop, and says how to fix anything that is not.
# It changes nothing on your computer. Run it as often as you like.
#
#   ./check-setup.sh            check the tools (free)
#   ./check-setup.sh --live     also make one tiny real call to Claude Code, to prove you are signed in
#                               (costs a few cents on your plan or API account)
#   ./check-setup.sh --print-python   print the name of a suitable Python (used by start.sh), and nothing else
#
# Needs Python 3.11, 3.12, or 3.13 (the Northwind service's tests are known to work on these), git 2.28 or later,
# and Claude Code 2.1.257 or later, signed in. Works on macOS, Linux, and Windows through WSL.
LIVE=0 PRINT_PY=0
for a in "$@"; do
  case "$a" in
    --live) LIVE=1 ;;
    --print-python) PRINT_PY=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $a (try --help)" >&2; exit 2 ;;
  esac
done

MIN_GIT=2.28 MIN_CLAUDE=2.1.257

# dotted-number compare: vge A B succeeds when A >= B
vge() {
  local IFS=. i x y
  local -a a b
  read -r -a a <<<"$1"
  read -r -a b <<<"$2"
  for i in 0 1 2; do
    x=${a[$i]:-0} y=${b[$i]:-0}
    [ "$x" -gt "$y" ] && return 0
    [ "$x" -lt "$y" ] && return 1
  done
  return 0
}
vnum() { sed -n 's/[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\(\.[0-9][0-9]*\)\{0,1\}\).*/\1/p' | head -1; }

# A Python in the supported range: prefer an exact 3.13/3.12/3.11, then plain python3.
find_python() {
  local c v
  for c in python3.13 python3.12 python3.11 python3; do
    command -v "$c" >/dev/null 2>&1 || continue
    v="$("$c" --version 2>&1 | vnum)"
    case "$v" in 3.11.*|3.12.*|3.13.*|3.11|3.12|3.13) echo "$c"; return 0 ;; esac
  done
  return 1
}
if [ "$PRINT_PY" = 1 ]; then find_python; exit $?; fi

FIXES=0 WARNS=0
ok()   { printf '  [ ok ]  %s\n' "$*"; }
warn() { WARNS=$((WARNS + 1)); printf '  [warn]  %s\n' "$*"; }
fix()  { FIXES=$((FIXES + 1)); printf '  [FIX ]  %s\n' "$1"; shift; for l in "$@"; do printf '            %s\n' "$l"; done; }

OS=other
case "$(uname -s)" in
  Darwin) OS=mac ;;
  Linux) OS=linux ;;
  MINGW*|MSYS*|CYGWIN*) OS=gitbash ;;
esac
WSL=0
if [ "$OS" = linux ] && grep -qi microsoft /proc/version 2>/dev/null; then WSL=1; fi
APT=0
if command -v apt-get >/dev/null 2>&1; then APT=1; fi

echo "Checking this computer for the Claude Lab: Evaluate Claude Code on Your Own Work"
echo

echo "Your system"
case "$OS" in
  mac)
    mv_="$(sw_vers -productVersion 2>/dev/null)"
    if [ -n "$mv_" ] && vge "$mv_" 13.0; then ok "macOS $mv_"
    else fix "macOS ${mv_:-unknown}: Claude Code needs macOS 13 or later" "Update macOS in System Settings > General > Software Update." ; fi ;;
  linux)
    if [ "$WSL" = 1 ]; then ok "Linux inside Windows (WSL)"; else ok "Linux"; fi ;;
  gitbash)
    fix "You are in Git Bash, which this workshop does not support" \
        "On Windows, use WSL (Windows Subsystem for Linux). Open PowerShell as Administrator and run:  wsl --install" \
        "Restart when asked, open 'Ubuntu' from the Start menu, and run this script again there." ;;
  *) warn "Unrecognized system ($(uname -s)). The workshop is tested on macOS, Linux, and WSL." ;;
esac
if [ "$OS" != gitbash ]; then
  if [ -w "$HOME" ]; then ok "Your home folder ($HOME) is writable"; else fix "Cannot write to $HOME"; fi
  kb="$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')"
  if [ -n "$kb" ] && [ "$kb" -ge 1048576 ] 2>/dev/null; then ok "At least 1 GB of free disk space"
  elif [ -n "$kb" ]; then warn "Less than 1 GB of free disk space. The workshop needs a few hundred MB."; fi
  if command -v curl >/dev/null 2>&1; then
    if curl -fsS -o /dev/null --max-time 8 https://code.claude.com 2>/dev/null; then ok "Internet access to code.claude.com"
    else warn "Could not reach https://code.claude.com. If you are behind a company proxy or VPN, ask your IT team how to allow it."; fi
  fi
fi
echo

[ "$OS" = gitbash ] && { echo "Fix the item above first, then run this check again."; exit 1; }

echo "Git"
if command -v git >/dev/null 2>&1; then
  gv="$(git --version | vnum)"
  if vge "$gv" "$MIN_GIT"; then ok "git $gv"
  else
    fix "git $gv is too old (need $MIN_GIT or later)" \
        "$( [ "$OS" = mac ] && echo 'Run:  xcode-select --install   (or: brew install git)' || echo 'Run:  sudo apt update && sudo apt install -y git' )"
  fi
  if [ -n "$(git config --global user.name 2>/dev/null)" ]; then ok "git knows your name (user.name)"
  else warn "git does not know your name yet. Not needed for the workshop, but you will see a hint if you commit. Set it with:  git config --global user.name \"Your Name\""; fi
else
  if [ "$OS" = mac ]; then
    fix "git is not installed" "Run:  xcode-select --install     then click Install, wait, and run this check again." "(If you use Homebrew, you can run:  brew install git)"
  else
    fix "git is not installed" "Run:  sudo apt update && sudo apt install -y git" "(Other Linux: use your package manager, for example  sudo dnf install git)"
  fi
fi
echo

echo "Python (3.11, 3.12, or 3.13)"
PY="$(find_python)"
if [ -n "$PY" ]; then
  pv="$("$PY" --version 2>&1 | vnum)"
  ok "$PY is Python $pv"
  tmp="$(mktemp -d 2>/dev/null)"
  if [ -n "$tmp" ] && "$PY" -m venv "$tmp/v" >/dev/null 2>&1 && "$tmp/v/bin/python" -m pip --version >/dev/null 2>&1; then
    ok "$PY can create a virtual environment and has pip"
  else
    if [ "$APT" = 1 ]; then
      pm="$("$PY" --version 2>&1 | vnum | cut -d. -f1,2)"
      fix "$PY cannot create a virtual environment (the 'venv' part is not installed)" \
          "Run:  sudo apt update && sudo apt install -y python3-venv python3-pip" "If that is not enough, run:  sudo apt install -y python${pm}-venv"
    else
      fix "$PY cannot create a virtual environment with pip" "Reinstall Python from https://www.python.org/downloads/ (macOS and Windows) or add your system's python3-venv package (Linux)."
    fi
  fi
  [ -n "$tmp" ] && rm -rf "$tmp"
else
  found="$(command -v python3 >/dev/null 2>&1 && python3 --version 2>&1 | vnum)"
  if [ -n "$found" ]; then
    msg="python3 is version $found, outside the supported 3.11 to 3.13 range"
  else
    msg="Python is not installed"
  fi
  if [ "$OS" = mac ]; then
    fix "$msg" "Easiest: download the macOS installer for Python 3.12 from https://www.python.org/downloads/ and run it." \
        "Or, if you use Homebrew (https://brew.sh):  brew install python@3.12" "Then open a NEW terminal window and run this check again."
  elif [ "$APT" = 1 ] && [ -n "$found" ]; then
    fix "$msg" "Your Ubuntu is too old to have a suitable Python. Add a newer one (this does not replace your system Python):" \
        "  sudo apt update && sudo apt install -y software-properties-common" \
        "  sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt update && sudo apt install -y python3.12 python3.12-venv" \
        "Or install a current Ubuntu (24.04 includes Python 3.12). In WSL:  wsl --install -d Ubuntu-24.04"
  elif [ "$APT" = 1 ]; then
    fix "$msg" "Run:  sudo apt update && sudo apt install -y python3 python3-venv python3-pip" \
        "If that installs a version older than 3.11, see the note above for adding Python 3.12 from the deadsnakes PPA."
  else
    fix "$msg" "Install Python 3.12 with your package manager, or from https://www.python.org/downloads/"
  fi
fi
echo

echo "Claude Code (version $MIN_CLAUDE or later)"
if command -v claude >/dev/null 2>&1; then
  cv="$(claude --version 2>/dev/null | vnum)"
  if [ -z "$cv" ]; then
    fix "claude is installed but did not report a version" "Run:  claude doctor     and follow what it says."
  elif vge "$cv" "$MIN_CLAUDE"; then
    ok "Claude Code $cv"
  else
    fix "Claude Code $cv is too old (need $MIN_CLAUDE or later)" "Run:  claude update" "(Installed with Homebrew? Run:  brew upgrade claude-code)"
  fi
elif [ -x "$HOME/.local/bin/claude" ]; then
  fix "Claude Code is installed, but this terminal cannot find it" \
      "Add its folder to your PATH. For zsh (macOS):  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc" \
      "For bash (Linux, WSL):  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc" \
      "Then open a NEW terminal window and run this check again."
else
  if ! command -v curl >/dev/null 2>&1; then
    fix "Claude Code is not installed, and curl is missing" "Run:  sudo apt update && sudo apt install -y curl     then install Claude Code:  curl -fsSL https://claude.ai/install.sh | bash"
  else
    fix "Claude Code is not installed" "Run:  curl -fsSL https://claude.ai/install.sh | bash" \
        "Then open a NEW terminal window, run  claude  once to sign in (a browser opens), type  /exit  to leave, and run this check again."
    [ "$OS" = mac ] && echo "            (If you use Homebrew you can instead run:  brew install --cask claude-code)"
  fi
fi

if [ "$LIVE" = 1 ]; then
  if command -v claude >/dev/null 2>&1; then
    echo
    echo "Signing in (one tiny real call, a few cents)"
    out="$(claude -p "Reply with the single word ok" --output-format json </dev/null 2>&1)"
    if printf '%s' "$out" | grep -q '"is_error":false' 2>/dev/null || printf '%s' "$out" | grep -qi '"result":"ok'; then
      ok "claude -p works, so you are signed in on a plan or account that can run it"
    else
      fix "claude -p did not work" "Start Claude Code with:  claude   and sign in when the browser opens (or type /login)." \
          "You need a Claude Pro, Max, Team, or Enterprise plan, a Console account, or your organization's cloud provider setup." \
          "What it printed: $(printf '%s' "$out" | head -c 200)"
    fi
  fi
else
  echo
  echo "  (Not checked: that you are signed in. Run  ./check-setup.sh --live  to check, at a cost of a few cents.)"
fi

echo
echo "Your workshop folders"
if [ -e "$HOME/nw-foundation/northwind-shipments-api" ] || [ -e "$HOME/nw-foundation/eval-set" ]; then
  # The tilde below is text for the reader, not a path.
  # shellcheck disable=SC2088
  warn "~/nw-foundation already has practice files. The build script will not overwrite them. To start fresh, see 'Clean up' in WALKTHROUGH.md."
else
  ok "No leftover practice folders from an earlier try"
fi
echo

if [ "$FIXES" -eq 0 ]; then
  echo "All set. ($WARNS note$( [ "$WARNS" = 1 ] || echo s ) above.)"
  [ -n "$PY" ] && echo "Your Python is called:  $PY     (start.sh sets this for you as \$PYTHON)"
  echo "Next: continue with the walkthrough."
  exit 0
else
  echo "$FIXES item$( [ "$FIXES" = 1 ] || echo s ) to fix. Do them in order, open a NEW terminal window, and run this check again."
  exit 1
fi
