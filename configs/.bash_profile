# File: .bash_profile 
# Author: Vadim Zaliva lord@crocodile.org
# History:
# 2014-01-08: Translated from .cshrc which I was using for 20+ years. With kind help from Vlad Karpinsky

extrapaths="/usr/local/sbin
/usr/local/bin
/usr/local/bin/X11
${HOME}/bin
${HOME}/.local/bin
/Applications/MacPorts/Emacs.app/Contents/MacOS/bin
/Applications/Graphviz.app/Contents/MacOS
/opt/local/bin
/opt/local/sbin
${HOME}/.cabal/bin
${HOME}/.cask/bin
/usr/local/Cellar/llvm/7.0.0/bin/
${HOME}/go/bin"

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

if ls --color=auto > /dev/null 2>&1 ; then
   alias l="ls --color=auto -al" 
   alias ltr="ls --color=auto -altr"
   alias ls='ls --color=auto'
else
   alias l="ls -al"
   alias ltr="ls -altr"
fi

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

if which emacsclient >& /dev/null ; then
    export VISUAL=emacsclient 
    export EDITOR=emacsclient
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
      # Generated with http://ezprompt.net/

      # get current branch in git repo
      function parse_git_branch() {
	      BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	      if [ ! "${BRANCH}" == "" ]
	      then
		      STAT=`parse_git_dirty`
		      echo "[${BRANCH}${STAT}]"
	      else
		      echo ""
	      fi
      }

      # get current status of git repo
      function parse_git_dirty {
	      status=`git status 2>&1 | tee`
	      dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
	      untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
	      ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
	      newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
	      renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
	      deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
	      bits=''
	      if [ "${renamed}" == "0" ]; then
		      bits=">${bits}"
	      fi
	      if [ "${ahead}" == "0" ]; then
		      bits="*${bits}"
	      fi
	      if [ "${newfile}" == "0" ]; then
		      bits="+${bits}"
	      fi
	      if [ "${untracked}" == "0" ]; then
		      bits="?${bits}"
	      fi
	      if [ "${deleted}" == "0" ]; then
		      bits="x${bits}"
	      fi
	      if [ "${dirty}" == "0" ]; then
		      bits="!${bits}"
	      fi
	      if [ ! "${bits}" == "" ]; then
		      echo " ${bits}"
	      else
		      echo ""
	      fi
      }

      export PS1="\[\e[35m\]\h\[\e[m\] \[\e[34m\]\w\[\e[m\]\[\e[36m\]\`parse_git_branch\`\[\e[m\]\[\e[33m\]\\$\[\e[m\] "
  fi
fi


if command -v ag &> /dev/null
then
  alias ag='\ag --pager="less -XFR"'
fi

if command -v batcat &> /dev/null
then
    BAT_CMD="batcat"
    alias bat="batcat"
elif command -v bat &> /dev/null
then
    BAT_CMD="bat"
else
    BAT_CMD=""
fi

if [ -n "$BAT_CMD" ]
then
    alias less="$BAT_CMD"
    export MANPAGER="sh -c 'col -bx | $BAT_CMD -l man -p'"
    export MANROFFOPT="-c"
    alias ag='\ag --pager="$BAT_CMD -p"'
fi

if command -v eza &> /dev/null
then
    # Use `eza` if present https://github.com/eza-community/eza
    LS_CMD="eza"
elif command -v exa &> /dev/null
then
    # fall back to `exa` (seems to be unmaintained) https://the.exa.website/
    LS_CMD="exa"
else
    LS_CMD=""
fi

if [ -n "$LS_CMD" ]
then
    alias ls="$LS_CMD"
    alias ll="$LS_CMD -snew -l"
else
    alias ll="ls -lFtr"
fi

export PATH
export MANPATH


if [ -f ~/.config/broot/launcher/bash/br ]; then
    source ~/.config/broot/launcher/bash/br
fi

if [[ $OSTYPE == 'darwin'* ]]; then
    export BASH_SILENCE_DEPRECATION_WARNING=1
fi
. "$HOME/.cargo/env"

if [ -x "/usr/bin/wezterm" ]; then
    export TERMINAL="/usr/bin/wezterm"
fi

source /home/lord/.config/broot/launcher/bash/br
