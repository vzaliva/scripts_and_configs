# File: .bash_profile 
# Author: Vadim Zaliva lord@crocodile.org
# History:
# 2014-01-08: Translated from .cshrc which I was using for 20+ years. With kind help from Vlad Karpinsky

extrapaths="/usr/local/bin
/usr/local/bin/X11
${HOME}/bin
/Applications/Aquamacs.app/Contents/MacOS/bin
/Applications/MacPorts/Emacs.app/Contents/MacOS/bin
/Applications/Graphviz.app/Contents/MacOS
/opt/local/bin
/opt/local/sbin
${HOME}/pebble-dev/PebbleSDK-3.0/bin
${HOME}/.cabal/bin"

extramanpaths="${HOME}/man
/usr/man
/usr/local/man
/usr/share/man
/usr/X11R6/man
/opt/local/share/man
/opt/local/man"

add_path() {
   test -d $1 || return
   case ":${PATH}:" in
        *:"$1":*)
        ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
        ;;
    esac
}

# shameful copy-paste, but my bash skills are not up to defining finction which takes
# name of variable as an arugment (lord, jan 2014).
add_man_path() {
   test -d $1 || return
   case ":${MANPATH}:" in
        *:"$1":*)
        ;;
        *)
            if [ "$2" = "after" ] ; then
                MANPATH=$MANPATH:$1
            else
                MANPATH=$1:$MANPATH
            fi
        ;;
    esac
}

for i in $extrapaths; do
    add_path $i
done
unset extrapaths

for i in $extramanpaths; do
    add_man_path $i
done
unset extramanpaths

umask 007

alias al=alias
alias h=history		
alias x=exit
alias l="ls --color=auto -al"
alias ltr="ls --color=auto -altr"
alias ls='ls --color=auto'
alias svngrep="grep --exclude=\*~ --exclude=\*.svn\*"

if [ ! -f ~/bin/m ]; then
    alias m="clear;make" 
fi

function svndiff()
{
    svn diff --diff-cmd `which diff` -x "-uw" $1 | less
}

if which vim >& /dev/null ; then
    alias vi=vim
fi

if which emacs >& /dev/null ; then
    export VISUAL=emacs
    export EDITOR=emacs
else
    export VISUAL=vi
    export EDITOR=vi
fi

export CLICOLOR=1
export LSCOLORS="Gxfxcxdxbxegedabagacad"

export CVS_RSH=ssh

# Java

if [ -f /usr/libexec/java_home ]; then
    export JAVA_HOME=`/usr/libexec/java_home`
fi

if [ -n "$JAVA_HOME" ]; then
    add_path $JAVA_HOME/bin
fi

# Android

if [ -d ~/java/android-sdk-mac_x86 ]; then
    export ANDROID_HOME=$HOME/java/android-sdk-mac_x86/
fi

if [ -d ~/java/android-ndk-r10e ]; then 
    export ANDROID_NDK_ROOT=$HOME/java/android-ndk-r10e
    add_path $ANDROID_NDK_ROOT
fi

if [ -d ~/.local/share/umake/android/android-sdk ]; then
    ANDROID_HOME=$HOME/.local/share/umake/android/android-sdk
fi

if [ -n "$ANDROID_HOME" ]; then
    add_path $ANDROID_HOME/tools
    add_path $ANDROID_HOME/platform-tools
fi

if [ -d /usr/local/cuda ]; then
	add_path /usr/local/cuda/bin
    export DYLD_LIBRARY_PATH=/usr/local/cuda/lib
fi

if [ -e /home/lord/.nix-profile/etc/profile.d/nix.sh ]; then
    . /home/lord/.nix-profile/etc/profile.d/nix.sh
fi 

if [ -f ~/.opam/opam-init/init.sh ]; then
  . ~/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true
fi

if [ "$TERM_PROGRAM" = "Apple_Terminal"  -o  "$TERM_PROGRAM" = "iTerm.app" ] ; then 
	export TERM=xterm-256color
	export DISPLAY=":0"
fi

if [ -n "$PS1" ] # no prompt?
then
  # Only for interactive shells
  if [ $TERM = "dumb" ]
  then
     export PS1='$ '
  else
    export bldylw='\e[1;33m' # Yellow
    export txtrst='\e[0m'    # Text Reset
    export PS1="\h \w\[${bldylw}\]\\\$\[${txtrst}\] "
  fi
fi

#colorized man pages
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            man "$@"
}

export PATH
export MANPATH

