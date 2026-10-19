if status is-interactive
    # No greeting on startup
    set fish_greeting
end

# zoxide: smarter cd. --cmd cd replaces `cd` entirely:
#   cd <name>  -> fuzzy jump to the best match (falls back to a real path cd)
#   cdi <name> -> interactive picker (needs fzf, not installed yet)
zoxide init fish --cmd cd | source

# eza: ls shows hidden files too, dirs first, Nerd Font icons (kitty carries the
# font). Flags are the old setup's. EZA_COLORS / EZA_ICON_SPACING are unset on
# purpose - stock colours.
alias ls="eza -la --group-directories-first --icons=auto"

# lt: two-level tree with git status. It is a function, not an alias, because
# eza 0.23 prints *nothing* for `eza --tree` with no path (the old alias relied
# on that default), so we supply "." unless a path is given.
function lt --wraps 'eza --tree' --description 'two-level tree with git status'
    set -l target .
    if set -q argv[1]
        set target $argv
    end
    eza --tree --level=2 -la --icons=auto --git $target
end

# Starship prompt. Colours come from ~/.config/starship.toml, which matugen
# regenerates on every wallpaper change.
starship init fish | source

# Not ported from the old config yet:
#   mise activate fish | source      -> mise (not installed)
#   bat/fzf aliases                  -> bat, fzf (rice step)
#   vssh/vpush/vpull functions       -> need cloudflared setup
