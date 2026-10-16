#!/bin/sh
# Brightness control with a floor.
#
#   brightness.sh up|down [step%]   step by 5% (default), never below 1%
#   brightness.sh set <percent>     absolute value, clamped to 1..100
#
# The panel can't usefully go to 0 (it looks broken, and a few presses of the
# key used to slam it into the kernel minimum), so:
#   * down never goes below 1%
#   * up from 1% (or below) jumps straight back to 5%, so you never crawl out
#     of the floor one percent at a time
#
# The `set` mode exists for the OSD slider in quickshell (it drags to a value).
# Called from ~/.config/hypr/modules/keybinds.lua and from modules/osd - `sh
# <path>` so it doesn't depend on PATH.

set -eu

floor=1
resume=5

raw=$(brightnessctl get) || exit 1
max=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1)
[ -n "$max" ] || exit 1

# Round, don't truncate: with plain integer division a real 15% reads back as
# 14% and every step after that drifts.
pct=$(( (raw * 100 + max / 2) / max ))

case ${1:-} in
up | down)
	dir=$1
	step=${2:-5}
	case $dir in
	up)
		if [ "$pct" -le "$floor" ] && [ "$step" -eq "$resume" ]; then
			target=$resume
		else
			target=$(( pct + step ))
		fi
		;;
	down)
		target=$(( pct - step ))
		if [ "$target" -lt "$floor" ]; then
			target=$floor
		fi
		;;
	esac
	;;
set)
	target=${2:-}
	if [ -z "$target" ] || ! [ "$target" -eq "$target" ] 2>/dev/null; then
		echo "usage: $0 up|down [step%] | $0 set <percent>" >&2
		exit 2
	fi
	if [ "$target" -lt "$floor" ]; then
		target=$floor
	fi
	;;
*)
	echo "usage: $0 up|down [step%] | $0 set <percent>" >&2
	exit 2
	;;
esac

if [ "$target" -gt 100 ]; then
	target=100
fi

brightnessctl set "${target}%" >/dev/null
echo "$target"