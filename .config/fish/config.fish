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

# vssh.toothaids.com tunnel and SSH
function vssh-tunnel
    if contains -- --help $argv; or contains -- -h $argv
        echo "Usage: vssh-tunnel"
        echo "Start cloudflared tunnel to vssh.toothaids.com (runs in foreground)."
        return 0
    end
    cloudflared access ssh --hostname vssh.toothaids.com --url localhost:2222
end

function vssh
    if contains -- --help $argv; or contains -- -h $argv
        echo "Usage: vssh"
        echo "SSH into the server through the tunnel (run vssh-tunnel first)."
        return 0
    end
    ssh -p 2222 dpsv@localhost $argv
end

function vpush
    if test (count $argv) -lt 2
        echo "Usage: vpush <local-source> <remote-dest>"
        echo "Copy file/dir FROM local TO server through tunnel."
        echo ""
        echo "Examples:"
        echo "  vpush file.txt ~/backup/"
        echo "  vpush ./project/ ~/server-backup/"
        return 1
    end
    rsync -avz -e "ssh -p 2222" $argv[1] "dpsv@localhost:$argv[2]"
end

function vpull
    if test (count $argv) -lt 2
        echo "Usage: vpull <remote-source> <local-dest>"
        echo "Copy file/dir FROM server TO local through tunnel."
        echo ""
        echo "Examples:"
        echo "  vpull ~/remote-file.txt ."
        echo "  vpull ~/server-backup/ ./local-backup/"
        return 1
    end
    rsync -avz -e "ssh -p 2222" "dpsv@localhost:$argv[1]" $argv[2]
end
