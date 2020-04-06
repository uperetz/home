[[ "$-" != *i* ]] && return

# Setup screen
if [ -n "$SSH_CLIENT" ] && [[ "$TERM" != "screen"* ]]; then
    export PROMPT_COMMAND='/bin/echo -ne "\033k\033\0134"'
    screen -r > /dev/null 
    [ $? -eq 0 ] && exit
    screen -x -p 0 > /dev/null
    [ $? -eq 0 ] && exit
    exec screen
else
    export PROMPT_COMMAND=''
    if [[ "$TERM" == "screen"* ]]; then
        screen_title_slicer() { echo "${1:0:20}"; }
        screen_title_format='\ek%s\e\\'
        screen_group() { screen -t "$1" //group; }
        screen_mv() { screen -X group "$1"; }
    else
        screen_title_slicer() { echo "${1//[^[:print:]]/}"; } # Fix highlight on CentOS"
        screen_title_format="\033]0;%s\007"
    fi
fi

set_screen_window() {
    title_string=$1
    [ -z "$title_string" ] && title_string=$(screen_title_slicer "$BASH_COMMAND")
    [ "$title_string" == "fg" ] && job=($(jobs %% 2> /dev/null))
    [ "$title_string" == "fg " ] && job=($(jobs "${title_string:3} 2> /dev/null"))
    if [ -n "$job" ]; then
        job=${job[@]:2}
        title_string=$(screen_title_slicer "$job")
    fi
    printf "$screen_title_format" "$title_string"
}
# Fix highlight on CentOS"

#Setup terminal
stty -ixon
export MYPS='$(echo -n "${PWD/#$HOME/~}" | awk -F "/" '"'"'{
if (length($0) > 14) { if (NF>4) print $1 "/" $2 "/.../" $(NF-1) "/" $NF;
else if (NF>3) print $1 "/" $2 "/.../" $NF;
else print $1 "/.../" $NF; }
else print $0;}'"'"')'
PS1='$(eval "echo ${MYPS}")>'

#general dirs
export PYTHONPATH=~/sources

#Useful variables
export EDITOR=vim
[ -f ~/.setup.py ] && export PYTHONSTARTUP=~/.setup.py

#Useful aliases
linediff() { 
    if [ -z "$1" ] || [ -z "$2" ]; then return; fi
    f1=$(basename "$1")
    f2=$(basename "$2")
    cat -n "$1" > "/tmp/$f1"
    cat -n "$2" > "/tmp/$f2"
    vimdiff "/tmp/$f1" "/tmp/$f2"
    rm "/tmp/$f1" "/tmp/$f2"
}
alias gitroot='git rev-parse --show-toplevel'
alias cdgit='cd $(gitroot)'
alias ps2pdf="ps2pdf -dEPSFitPage"
alias ps2pdfall='for x in *.ps; do ps2pdf $x; rm $x; done'
alias pdflatex="pdflatex -synctex=1 -interaction=nonstopmode"
alias ps2pdfall='for x in *.ps; do ps2pdf $x; done'

# Application aliases
alias py="python3"
alias rp="realpath"
alias vi="vim"
alias imagej="setsid imagej &> /dev/null"
alias gk="gitk --all &"
alias glog="git log --all --graph --pretty=format:'%C(auto) %h %d  %s %C(auto,yellow)(%cr) <%an>' --branches"
alias ctags="ctags -R --c-kinds=+p --c++-kinds=+pf --python-kinds=-i --fields=+iaS --extras=+q"

# Shell aliases
alias cp="cp -i"
alias rm="rm -I"
alias mv="mv -i"
alias grep='grep --color --exclude-dir=__pycache__ --exclude=*.pyc --exclude=*.o --exclude=*.so --exclude=tags --exclude=*.swp --exclude-dir=CMakeFiles --exclude-dir=.git'
alias wget='wget --content-disposition'
alias ls='ls -h --color=tty --group-directories-first'
alias la='ls -A'
alias ll='ls -ltr'
set match-hidden-files off

#Shell history and matching
bind '"\e[5~": history-search-backward'
bind '"\e[6~": history-search-forward'
bind 'set match-hidden-files off'
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

#Merge user Xresources
function pdfopt {
    pdf=$1
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=opt_$1 $1
}

function append_path {
    PATH="$1:$PATH"
    for f in $(ls $1/); do
        dir=$1
        if [[ -d $dir/$f/ ]]; then
            append_path $dir/$f
        fi
    done 2> /dev/null
}
append_path ~/bin

#Git completion
if [ -f /etc/bash_completion.d/git ]; then
    . /etc/bash_completion.d/git
elif [ -f ~/.git_completion.bash ]; then
    . ~/.git_completion.bash
fi

SHELL=$(which $SHELL)
if [ -f "${HOME}/.bashrc.private" ]; then
    . "${HOME}/.bashrc.private"
fi
export https_proxy="$http_proxy"
if [ -z "$DISPLAY" ]; then
    export DISPLAY="localhost:0"
fi
userresources=.Xresources
if [ -f $userresources ]; then
    /usr/bin/xrdb -merge $userresources
fi
xset b off
set_screen_window "Ready!"
trap 'set_screen_window "Ready!"' ERR
trap set_screen_window DEBUG
