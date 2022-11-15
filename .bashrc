#!/bin/bash

[[ "$-" != *i* ]] && return

# Setup screen
if command -v screen &> /dev/null && [ -n "$SSH_CLIENT" ] && [[ "$TERM" != "screen"* ]]; then
    export PROMPT_COMMAND='/bin/echo -ne "\033k\033\0134"'
    if screen -r > /dev/null; then exit; fi
    if screen -x -p 0 > /dev/null; then exit; fi
    exec screen
else
    export PROMPT_COMMAND=''
    if [[ "$TERM" == "screen"* ]]; then
        screen_title_slicer() { echo "${1}"; }
        # shellcheck disable=SC1003
        screen_title_format='\ek%s\e\\'
        screen_group() { screen -t "$1" //group; }
        screen_mv() { screen -X group "$1"; }
    else
        screen_title_slicer() { echo "${1//[^[:print:]]/}"; } # Fix highlight on CentOS"
        screen_title_format='\033]0;%s\007'
    fi
fi

ready="Ready!"

shorten_long_paths() {
    result=""
    for dir in ${1//\// }; do
        if [ ${#dir} -gt 14 ]; then
            result="$result/${dir:0:5}..."
        else
            result="$result/$dir"
        fi
    done
    if [ ${#result} -gt 80 ]; then
        read -ra dirs <<< "${result//\// }"
        result="/${dirs[0]}/.../${dirs[-3]}/${dirs[-2]}/${dirs[-1]}"
    fi
    if [ "${1:0:1}" == / ]; then
        echo "${result}"
    else
        echo "${result:1}"
    fi
}

# Also saves history!
set_screen_window() {
    case $BASH_COMMAND in
        *.master_history) ;;
        mhistory*) ;;
        fhistory*) ;;
        *)
            echo "$BASH_COMMAND" >> ~/.master_history
    esac

    title_string=$1
    [ -z "$title_string" ] && title_string=$(screen_title_slicer "$BASH_COMMAND")
    [ "$title_string" = "fg" ] && read -ra job < <( jobs %% 2> /dev/null )
    [ "$title_string" = "fg " ] && read -ra job < <(jobs "${title_string:3} 2> /dev/null")
    if [ ${#job[@]} -gt 0 ]; then
        title_string=$(screen_title_slicer "${job[2]}")
    fi
    cwd=$PWD
    if [ "${title_string::3}" = "cd " ]; then
        cwd=$(  eval cd "$(awk '{print $2}' <<< "$BASH_COMMAND")" &> /dev/null && pwd)
        [ -z "$cwd" ] && cwd=$PWD
        title_string="$ready"
    fi
    [ "$title_string" = "cd" ] && title_string=$ready && cwd=$HOME
    wdir=${cwd//$HOME/\~}
    # shellcheck disable=SC2059
    printf "$screen_title_format" "$HOSTNAME -- $(shorten_long_paths "$wdir")> $title_string" > "$(tty)"
    unset job
    unset title_string
}
# Fix highlight on CentOS"

#Setup terminal
stty -ixon
#shellcheck disable=SC2016
export MYPS='$(echo -n "${PWD/#$HOME/\~}" | awk -F "/" '"'"'{
for (i=1; i<=NF; ++i)
    if(length($i) > 14)
        $i=substr($i,0,5) "..." substr($i,length($i)-5,length($i));
if (length($0) > 14) {
    if (NF>4) print $1 "/" $2 "/.../" $(NF-1) "/" $NF;
    else if (NF>3) print $1 "/" $2 "/.../" $NF;
    else print $1 "/.../" $NF;
}
else print $0;}'"'"')'
PS1='\[\e[1;34m\]$(eval "echo ${MYPS}")>\[\e[0m\]'

#general dirs
export PYTHONPATH=~/sources

#Useful variables
export EDITOR=vim
[ -f ~/.setup.py ] && export PYTHONSTARTUP=~/.setup.py

#Useful aliases
mhistory() {
    tail -n "${1:-10}" ~/.master_history
}
fhistory() {
    context=
    [ -n "$3" ] && context="-A$3 -B$3"
    if [ -n "$2" ]; then
        amount=$2
        [ -n "$context" ] && amount=$(( ($3*2+1) * amount))
        # shellcheck disable=SC2086
        grep --color $context -- "$1" ~/.master_history | uniq | tail -n "$amount"
    else
        # shellcheck disable=SC2086
        grep --color $context -- "$1" ~/.master_history | uniq
    fi
}

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
alias gitsha='git rev-parse --short HEAD'
alias cdgit='cd $(gitroot)'
alias ps2pdf="ps2pdf -dEPSFitPage"
alias pdflatex="pdflatex -synctex=1 -interaction=nonstopmode"
# shellcheck disable=SC2154
# No idea why it's complaining about 'x' not being assigned.
alias ps2pdfall='for x in *.ps; do ps2pdf $x; rm $x; done'

# Application aliases
alias py="python3"
alias rp="realpath"
alias vi="vim"
alias imagej="setsid imagej &> /dev/null"
alias gk="gitk --all &"
alias glog="git log --all --graph --pretty=format:'%C(auto) %h %d  %s %C(auto,yellow)(%ci) <%an>' --branches"
alias glogc="git log --graph --pretty=format:'%C(auto) %h %d  %s %C(auto,yellow)(%ci) <%an>'"
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
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=opt_"$1" "$1"
}

function append_path {
    PATH="$1:$PATH"
    for f in "$1"/*; do
        if [ -d "$f" ]; then
            append_path "$f"
        fi
    done 2> /dev/null
}
append_path ~/bin

# Transfer
# Suggested usage in local rc, using servers used:
#   declare -A servers
#   servers[SG4]='nmadmin@3.213.40.102'
#
#   for server in "${!servers[@]}"; do
#       # shellcheck disable=SC2139
#       # We want this to expand
#       alias "$server=ssh -X ${servers[$server]}"
#       eval function "put${server} { putserver \"${servers[$server]}\" \"\$@\"; }"
#       eval function "get${server} { getserver \"${servers[$server]}\" \"\$@\"; }"
#   done

function putserver {
    server=$1
    shift
    args=$(($#-1))
    [ "$args" -lt 1 ] && echo "Must provide out path explicitly" && return
    sources=( "$@" )
    o=${sources[${#sources[@]}-1]}
    unset 'sources[${#sources[@]}-1]'
    rsync -p -r -P -m "${sources[@]}" "$server:$o"
}

function getserver {
    server=$1
    shift
    o=$2;
    [ -z "$o" ] && o="./";
    rsync -p -r -P -m "$server:$1" "$o"
}

function listdisp {
  netstat -lnt | awk '
    sub(/.*:/,"",$4) && $4 >= 6000 && $4 < 6100 {
      print ($1 == "tcp6" ? "ip6-localhost:" : "localhost:") ($4 - 6000)
    }'
}

#Git completion
if [ -f /etc/bash_completion.d/git ]; then
    # shellcheck disable=SC1091
    . /etc/bash_completion.d/git
elif [ -f ~/.git_completion.bash ]; then
    . ~/.git_completion.bash
fi

if [ -f "${HOME}/.bashrc.private" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.bashrc.private"
fi
# shellcheck disable=SC2154
export https_proxy="$http_proxy"
export ftp_proxy="$http_proxy"

if [[ $(uname -r) = *microsoft-standard* ]]; then
    # WSL 2 + XMING shennenigans
    port=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf)
    export DISPLAY="${port}:0.0"
elif [ -z "$DISPLAY" ]; then
    export DISPLAY="localhost:0.0"
fi

userresources=.Xresources
if [ -f $userresources ]; then
    /usr/bin/xrdb -merge $userresources
fi
# xset b off
set_screen_window "$ready"
# shellcheck disable=SC2064
trap "set_screen_window $ready" ERR
trap set_screen_window DEBUG
