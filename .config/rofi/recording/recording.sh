#!/usr/bin/env bash

dir="$HOME/.config/rofi/recording"
theme='style'
RECORDING_FILE="/tmp/screenrecord-filename"
LAST_RECORDING_FILE="$HOME/.cache/screenrecord-last"

get_elapsed() {
  local pid
  pid=$(pgrep -f "^gpu-screen-recorder" | head -1)
  if [[ -n $pid ]]; then
    local elapsed
    elapsed=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
    if [[ -n $elapsed ]]; then
      local m=$((elapsed / 60))
      local s=$((elapsed % 60))
      printf "%02d:%02d" "$m" "$s"
      return
    fi
  fi
}

get_filename() {
  if [[ -f $RECORDING_FILE ]]; then
    basename "$(cat "$RECORDING_FILE")" 2>/dev/null || echo "unknown"
  elif [[ -f $LAST_RECORDING_FILE ]]; then
    basename "$(cat "$LAST_RECORDING_FILE")" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  elapsed=$(get_elapsed)
  filename=$(get_filename)
  prompt="󰻂  Recording"
  mesg="$(printf "%s %s" "$elapsed" "$filename")"
  chosen=$(echo -e "⏹  Stop Recording" | rofi -dmenu -p "$prompt" -mesg "$mesg" -theme "${dir}/${theme}.rasi")

  case "$chosen" in
    "⏹  Stop Recording") ~/.config/hypr/scripts/screenrecord stop ;;
  esac
else
  last_file=$(get_filename)
  if [[ -z $last_file ]]; then
    mesg="No recordings yet"
  else
    mesg="Last: $last_file"
  fi
  prompt="󰻂  Recording"
  chosen=$(echo -e "▶ Start\n🎤  Start (with audio)" | rofi -dmenu -p "$prompt" -mesg "$mesg" -theme "${dir}/${theme}.rasi")

  case "$chosen" in
    "▶  Start") ~/.config/hypr/scripts/screenrecord ;;
    "🎤  Start (with audio)") ~/.config/hypr/scripts/screenrecord --with-audio ;;
  esac
fi
