if status is-interactive
# Commands to run in interactive sessions can go here
    set fish_greeting
end

starship init fish | source
zoxide init fish --cmd cd | source
mise activate fish | source

# eza aliases (showing hidden files)
alias ls="eza -la --group-directories-first --icons=auto"
alias lt="eza --tree --level=2 -la --icons --git"

# fzf with bat preview
alias ff="fzf --preview 'bat --color=always {}'"
alias eff='nvim (fzf --preview "bat --color=always {}")'

# Replace cat with bat
alias cat="bat"
