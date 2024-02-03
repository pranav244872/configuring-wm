#
# ~/.bashrc
#
source ~/.cache/wal/colors.sh
source ~/.cache/wal/colors-tty.sh
(cat ~/.cache/wal/sequences &)
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export EDITOR=nvim
export VISUAL=nvim

#Making Screenshot directory
export HYPRSHOT_DIR=/home/pranav/Pictures/Screenshots
export XDG_PICTURES_DIR=~/Pictures
