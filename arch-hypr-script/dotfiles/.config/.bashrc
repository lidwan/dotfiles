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

#pacman
alias ro='sudo pacman -Rns $(pacman -Qtdq)'

#grup
alias grubupdate='sudo grub-mkconfig -o /boot/grub/grub.cfg'

#shutdown
alias sdn="shutdown now"
alias sd30="shutdown +30"
alias sd60="shutdown +60"
alias sdc="shutdown -c"
alias sds="shutdown --show"

#ls
alias l="ls --color=auto -h --group-directories-first"
alias ls="ls --color=auto -h --group-directories-first"
alias la="ls --color=auto -ha --group-directories-first"
alias ll="ls --color=auto -hal --group-directories-first"

#other
alias mkfile='touch'
alias ff="fastfetch"
