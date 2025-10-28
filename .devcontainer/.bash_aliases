# Start common aliases

alias ls='ls -G'
alias cp='cp -iv'                           # Preferred 'cp' implementation
alias mv='mv -iv'                           # Preferred 'mv' implementation
alias mkdir='mkdir -pv'                     # Preferred 'mkdir' implementation
alias ll='ls -FGlAhp'                       # Preferred 'ls' implementation
alias less='less -FSRXc'                    # Preferred 'less' implementation
cd() { builtin cd "$@"; ll; }               # Always list directory contents upon 'cd'
alias cd..='cd ../'                         # Go back 1 directory level (for fast typers)
alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels
alias .3='cd ../../../'                     # Go back 3 directory levels
alias .4='cd ../../../../'                  # Go back 4 directory levels
alias .5='cd ../../../../../'               # Go back 5 directory levels
alias .6='cd ../../../../../../'            # Go back 6 directory levels
alias edit='code'                           # edit:         Opens any file in Visual Studio Code editor
alias ~="cd ~"                              # ~:            Go Home
alias c='clear'                             # c:            Clear terminal display
#alias which='type -all'                     # which:        Find executables
alias path='echo -e ${PATH//:/\\n}'         # path:         Echo all executable Paths
alias show_options='shopt'                  # Show_options: display bash options settings
alias fix_stty='stty sane'                  # fix_stty:     Restore terminal settings when screwed up
alias cic='set completion-ignore-case On'   # cic:          Make tab-completion case-insensitive
mcd () { mkdir -p "$1" && cd "$1"; }        # mcd:          Makes new Dir and jumps inside
trash () { command mv "$@" ~/.Trash ; }     # trash:        Moves a file to the MacOS trash

#   lr:  Full Recursive Directory Listing
#   ------------------------------------------
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'

# End common aliases

# Start git aliases

gl()
{ 

    BRANCH_COLOR='\033[0;36m'
    NO_COLOR='\033[0m' 
    code=
    since=
    file=
    author=

    since=${since:-}
    code=${code:-}
    file=${file:-}
    message=${message:-}
    author=${author:-}
    
    graph="--graph"
    merges=

    NOGRAPH=0
    NOMERGE=0
    HELP=0
    
    while [ $# -gt 0 ]; do

        if [[ $1 == *"--"* ]]; then
                param="${1/--/}"
                if [[ "$param" = "help" ]]; then
                    HELP=1
                fi
                if [[ "$param" = "nograph" ]]; then
                    NOGRAPH=1
                fi
                if [[ "$param" = "nomerges" ]]; then
                    NOMERGE=1
                fi
                declare $param="$2"
                #echo $1 $2 // Optional to see the parameter:value result
        fi
        shift
    done

    if [[ "$HELP" -eq 1 ]]; then
       echo -e "${BRANCH_COLOR}"
       echo "Search git log for commits"
       echo "Returns abbreviated commit hash, commit message, date/time of commit, commit author"
       echo " - Parameters, can be combined"
       echo "   --author <commits by specific author>"
       echo "   --since <list commits since date specified, formatted as \"MM-DD-YYY\""
       echo "   --code <find commits with code snippet.  Be sure to wrap in quotes.  Can be slow if large repository.>"
       echo "   --message <find commits with commit message.>"
       echo "   --file <find commits that contain changes in a specific file.  Wrap in quotes if file name has spaces.>"
       echo "   --nograph <display results as a flat list instead of a git graph format"
       echo -e "${NO_COLOR}"
      return
    fi


    if [[ "$NOGRAPH" -eq 1 ]]; then
        graph=
    fi

    if [[ "$NOMERGE" -eq 1 ]]; then
        merges="--no-merges"
    fi

    if test -n "$since"; then
    since="--since='$since'"
    else
    since=
    fi

    if test -n "$code"; then
      code="-G'$code'"
    else
      code=
    fi

    if test -n "$file"; then
    file="-- $file"
    else
    file=
    fi

    if test -n "$author"; then
    author="--author $author"
    else
    author=
    fi

    if test -n "$message"; then
    message="--grep=\"$message\""
    else
    message=
    fi

    echo -e "${BRANCH_COLOR}Current branch is \"$(git branch --show-current)\"${NO_COLOR}"
    eval "git log $code $graph --pretty=format:'%Cred%h%Creset -%C(yellow) %s %Cgreen(%cd - %cr) %C(bold blue)<%an>%Creset'  --date-order --date=format:'%m-%d-%Y %I:%M %p' $author $since $file $message $merges"
 }


gdb() 
{ 
    branch=${branch:-}
    DELETEREMOTE=0
    
    while [ $# -gt 0 ]; do

        if [[ $1 == *"--"* ]]; then
                param="${1/--/}"
                if [[ "$param" = "help" ]]; then
                    HELP=1
                fi
                if [[ "$param" = "remote" ]]; then
                    DELETEREMOTE=1
                fi
                
                declare $param="$2"
                #echo $1 $2 // Optional to see the parameter:value result
        fi
        shift
    done

    git branch -D $branch


    if [[ "$DELETEREMOTE" -eq 1 ]]; then
        git push origin --delete $branch
    fi

}  

# End git aliases
