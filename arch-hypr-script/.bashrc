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
#PS1='\u \w '
# PS1="\u on \h at \W "
. ~/.git-prompt.sh
PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'; PS1='\u in \W${PS1_CMD1} '

# -----------------------------------------------------

#git
alias gs="git status"
alias ga.="git add ."
alias gcm="git commit -m"
alias gc='git clone '
alias gp="git push"

#vim
alias v="nvim"

#nano
alias n="nano"

#yay
alias ys="yay -S"
alias ysy="yay -Sy"
alias ysyu="yay -Syu"

alias yr="yay -R"

alias yq="yay -Q"
alias yqu="yay -Qu"
alias yqm="yay -Qm"

#pacman
alias ro='sudo pacman -Rns $(pacman -Qtdq)' #remove orphan packages.
alias ps="sudo pacman -S"
alias psy="sudo pacman -Sy"
alias psyu="sudo pacman -Syu"
alias pr="sudo pacman -R"

#grup
alias grubupdate='sudo grub-mkconfig -o /boot/grub/grub.cfg' #updates grub

#shutdown
alias sdn="shutdown now"
alias sd30="shutdown +30"
alias sd45="shutdown +45"
alias sd60="shutdown +60"
alias sd90="shutdown +90"
alias sdc="shutdown -c"
alias sds="shutdown --show"

#suspend
alias susn="systemctl suspend"
alias sus30="sleep 1800 && systemctl suspend"
alias sus45="sleep 2700 && systemctl suspend"
alias sus60="sleep 3600 && systemctl suspend"
#ls
alias l="ls --color=auto -h --group-directories-first"
alias ls="ls --color=auto -h --group-directories-first"
alias la="ls --color=auto -ha --group-directories-first"
alias ll="ls --color=auto -hal --group-directories-first"

#other
alias mkfile='touch'
alias ff="fastfetch"
alias code="code ."
alias ref="sudo reflector --save /etc/pacman.d/mirrorlist --protocol https --country Germany --latest 5 --sort age --fastest 5"


#firefox
alias yt-music='firefox --new-window https://music.youtube.com/ & sleep 1 && hyprctl dispatch movetoworkspace 9 && hyprctl dispatch fullscreen'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
