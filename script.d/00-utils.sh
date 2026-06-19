log()  { printf "\033[1;34m[%s]\033[0m %s\n" "$(date +%H:%M:%S)" "$*"; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
fail() { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; }

section() {
  printf "\n\033[1;36m━━━ %s ━━━\033[0m\n" "$1"
}
