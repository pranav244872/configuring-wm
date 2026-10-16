if status is-interactive
    # No greeting on startup
    set fish_greeting
end

# zoxide: smarter cd. --cmd cd replaces `cd` entirely:
#   cd <name>  -> fuzzy jump to the best match (falls back to a real path cd)
#   cdi <name> -> interactive picker (needs fzf, not installed yet)
zoxide init fish --cmd cd | source

# Not ported from the old config yet (tools not installed):
#   starship init fish | source      -> starship (rice step)
#   mise activate fish | source      -> mise (not installed)
#   eza/bat/fzf aliases              -> eza, bat, fzf (rice step)
#   vssh/vpush/vpull functions       -> need cloudflared setup
