#    _               _              
#   | |__   __ _ ___| |__  _ __ ___ 
#   | '_ \ / _` / __| '_ \| '__/ __|
#  _| |_) | (_| \__ \ | | | | | (__ 
# (_)_.__/ \__,_|___/_| |_|_|  \___|
# 

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
#PS1='[\u@\h \W]\$ '
#PS1='\[\e[38;5;44m\]\u\[\e[0m\] \[\e[38;5;75m\]\W\[\e[0m\] '
PS1='\u \w '
# -----------------------------------------------------
# LOAD CUSTOM .bashrc_custom if exists
# -----------------------------------------------------
if [ -f ~/.bashrc_custom ] ;then
    source ~/.bashrc_custom
fi

# -----------------------------------------------------
# Fastfetch if in Hyprland
# -----------------------------------------------------
if [[ $(tty) == *"pts"* ]]; then
    fastfetch
else
    echo
    echo "Start Hyprland with command Hyprland"
fi

alias ml4w-hyprland='~/.config/ml4w/apps/ML4W_Hyprland_Settings-x86_64.AppImage'

#rndm
alias l="ls"


#git
alias gs="git status"
alias ga.="git add ."
alias gcm="git commit -m"
alias gc="git commit"
alias gp="git push"
