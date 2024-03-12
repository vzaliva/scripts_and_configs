alias x exit
alias al alias
alias e "emacsclient -n"

set -gx EDITOR 'emacsclient';
set -gx VISUAL 'emacsclient';

set fish_greeting

if test -d $HOME/.local/bin
  set PATH $HOME/.local/bin $PATH
end

if test -d $HOME/.cask/bin
  set PATH $HOME/.cask/bin $PATH
end

if test -d $HOME/.cargo/bin
  set PATH $HOME/.cargo/bin $PATH
end

if test -d $HOME/bin
  set PATH $HOME/bin $PATH
end

if test -d $HOME/go/bin
  set PATH $HOME/go/bin $PATH
end

# OPAM configuration
. ~/.opam/opam-init/init.fish > /dev/null 2> /dev/null; or true

# fix manpath after OPAM
if [ (uname) != Darwin ]
   set -gx MANPATH (/usr/bin/manpath -g) $MANPATH
end

set -g theme_display_date no
#set -g theme_powerline_fonts no
set -g theme_display_git_default_branch yes
set -g theme_git_default_branches master main
set -g theme_title_use_abbreviated_path yes
set -g theme_color_scheme solarized

function fish_right_prompt; end

if type -q ag
    alias ag 'ag --pager="less -XFR"'
end

if type -q batcat
    set BAT_CMD "batcat"
else if type -q bat
    set BAT_CMD "bat"
else
    set BAT_CMD ""
end

if test -n "$BAT_CMD"
    set -gx MANPAGER "sh -c 'col -bx | $BAT_CMD -l man -p'"
    set -gx MANROFFOPT "-c"    
    alias ag "ag --pager=\"$BAT_CMD -p\""
    alias less "$BAT_CMD"
end

if type -q eza
    # Use `eza` if present https://github.com/eza-community/eza
    set LS_CMD "eza"
else if type -q exa
    # fall back to `exa` (seems to be unmaintained) https://the.exa.website/
    set LS_CMD "exa"
else
    set LS_CMD ""
end

if test -n "$LS_CMD"
    alias ls "$LS_CMD"
    alias ll "$LS_CMD -snew -l"
else
    alias ll "ls -lFtr"
end

set NPM_PACKAGES "$HOME/.npm-packages"

set PATH $PATH $NPM_PACKAGES/bin

set MANPATH $NPM_PACKAGES/share/man $MANPATH  

alias c "cd ~/src/cerberus"
alias h "cd ~/src/helix"
alias p "cd ~/src/helix-journal-paper"

