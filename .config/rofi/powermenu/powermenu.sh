#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu"
theme='style-4'

shutdown=''
reboot=''
lock=''
suspend=''
logout=''
rofi_cmd() {
	rofi -dmenu \
		-theme ${dir}/${theme}.rasi
}

run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

run_cmd() {
	if [[ $1 == '--shutdown' ]]; then
		systemctl poweroff
	elif [[ $1 == '--reboot' ]]; then
		systemctl reboot
	elif [[ $1 == '--suspend' ]]; then
		systemctl suspend
	elif [[ $1 == '--logout' ]]; then
		hyprctl dispatch "hl.dsp.exit()"
	fi
}

chosen="$(run_rofi)"
case ${chosen} in
    $shutdown) run_cmd --shutdown ;;
    $reboot)   run_cmd --reboot ;;
    $lock)     hyprlock ;;
    $suspend)  run_cmd --suspend ;;
    $logout)   run_cmd --logout ;;
esac
