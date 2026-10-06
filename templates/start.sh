# Source this file at the start of every new terminal window:
#
#     source ~/ccw5g/templates/start.sh
#
# It sets KIT (this repository), puts run-case.sh on your PATH, sets PYTHON to a suitable Python, stops git
# from opening a pager (so pasted blocks of commands cannot lose keystrokes to it), and switches on the practice
# virtual environment once you have made it. It works in bash and zsh, and changes
# nothing outside the current terminal window. (Open a new window and the changes are gone: run it again.)
# The zsh branch uses zsh-only syntax, which shellcheck cannot parse.
# shellcheck disable=SC2296
if [ -n "${BASH_SOURCE[0]:-}" ]; then _ccw5g_here="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then _ccw5g_here="${(%):-%x}"
else _ccw5g_here="$0"; fi
_ccw5g_dir="$(cd "$(dirname "$_ccw5g_here")" && pwd)"
KIT="$(dirname "$_ccw5g_dir")"
export KIT
export GIT_PAGER=cat
case ":$PATH:" in *":$_ccw5g_dir:"*) ;; *) export PATH="$_ccw5g_dir:$PATH" ;; esac
if _ccw5g_py="$("$_ccw5g_dir/check-setup.sh" --print-python 2>/dev/null)" && [ -n "$_ccw5g_py" ]; then
  export PYTHON="$_ccw5g_py"
else
  unset PYTHON
fi
if [ -f "$HOME/nw-foundation/.venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  . "$HOME/nw-foundation/.venv/bin/activate"
fi
echo "KIT=$KIT"
echo "PYTHON=${PYTHON:-not found: run check-setup.sh}"
if [ -n "${VIRTUAL_ENV:-}" ]; then echo "Practice virtual environment: on ($VIRTUAL_ENV)"; else echo "Practice virtual environment: off (you make it in step 1.13 of WALKTHROUGH.md)"; fi
unset _ccw5g_here _ccw5g_dir _ccw5g_py
