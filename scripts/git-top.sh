#!/usr/bin/env bash
# Real-time git working-tree monitor (top-like). Usage: git-top.sh [interval_seconds]
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]:-$0}")"

_bold() { printf '%b' "\033[1m$*\033[0m"; }
_dim() { printf '%b' "\033[2m$*\033[0m"; }
_red() { printf '%b' "\033[31m$*\033[0m"; }
_green() { printf '%b' "\033[32m$*\033[0m"; }
_yellow() { printf '%b' "\033[33m$*\033[0m"; }
_cyan() { printf '%b' "\033[36m$*\033[0m"; }
_magenta() { printf '%b' "\033[35m$*\033[0m"; }

_have_diffstat() { command -v diffstat >/dev/null 2>&1; }

_section() {
	_bold "$(_cyan "── $1 ──")"
	echo
}

_git_top_tick() {
	local root short upstream ab untracked n stashc ahead behind stash_w i max
	root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
		_red "Not a git repository."
		return 1
	}
	short="$(git -c color.status=always status -sb --branch 2>/dev/null | head -1)"
	upstream="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)" || upstream=""
	if [[ -n "$upstream" ]]; then
		ab="$(git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null | tr '\t' ' ')" || ab=""
	fi
	stashc="$(git stash list 2>/dev/null | wc -l | tr -d ' ')"
	stashc="${stashc:-0}"
	if [[ "$stashc" -eq 1 ]]; then
		stash_w=entry
	else
		stash_w=entries
	fi

	# Header bar (top-like)
	printf '%b' "\033[7m "
	_bold " git-top "
	printf '%b' " \033[27m "
	_dim "$(date '+%Y-%m-%d %H:%M:%S')"
	echo
	_cyan "$root"
	echo
	[[ -n "$short" ]] && echo "$short"
	if [[ -n "${ab:-}" ]]; then
		read -r ahead behind <<<"$ab" || true
		[[ "${ahead:-0}" != "0" ]] && _green "  ↑ $ahead commit(s) ahead of $upstream"
		[[ "${behind:-0}" != "0" ]] && _yellow "  ↓ $behind commit(s) behind $upstream"
	fi
	[[ "$stashc" != "0" ]] && _magenta "  stash: $stashc $stash_w"
	echo

	_section "status (short)"
	env GIT_PAGER=cat git -c color.status=always status --short
	echo

	_section "unstaged (diffstat)"
	if git diff --quiet 2>/dev/null; then
		_dim "  (no unstaged changes)"
	else
		env GIT_PAGER=cat git diff --shortstat
		echo
		if _have_diffstat; then
			git diff | diffstat -w "${COLUMNS:-100}"
		else
			env GIT_PAGER=cat git -c color.diff=always diff --stat --stat-width="${COLUMNS:-100}"
		fi
	fi
	echo

	_section "staged (diffstat)"
	if git diff --staged --quiet 2>/dev/null; then
		_dim "  (nothing staged)"
	else
		env GIT_PAGER=cat git diff --staged --shortstat
		echo
		if _have_diffstat; then
			git diff --staged | diffstat -w "${COLUMNS:-100}"
		else
			env GIT_PAGER=cat git -c color.diff=always diff --staged --stat --stat-width="${COLUMNS:-100}"
		fi
	fi
	echo

	_section "untracked"
	mapfile -t untracked < <(git ls-files --others --exclude-standard)
	n="${#untracked[@]}"
	if [[ "$n" -eq 0 ]]; then
		_dim "  (none)"
	else
		_yellow "  $n file(s) not ignored"
		echo
		max=40
		for ((i = 0; i < n && i < max; i++)); do
			echo "        ${untracked[i]}"
		done
		((n > max)) && _dim "        … and $((n - max)) more"
	fi
	echo

	_dim "  refresh: ${GIT_TOP_INTERVAL:-2}s  │  exit: Ctrl+C"
}

if [[ "${1:-}" == "--watch-tick" ]]; then
	_git_top_tick
	exit 0
fi

INTERVAL="${1:-${GIT_TOP_INTERVAL:-2}}"
case "$INTERVAL" in
'' | *[!0-9]*) _red "Interval must be a positive integer (seconds)."; exit 2 ;;
0) _red "Interval must be greater than 0."; exit 2 ;;
esac

export GIT_TOP_INTERVAL="$INTERVAL"
exec watch -t -n "$INTERVAL" -c "$(printf '%q' "$SCRIPT_PATH") --watch-tick"
