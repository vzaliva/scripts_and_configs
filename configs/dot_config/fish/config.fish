alias x exit
alias al alias
alias ll "ls -al"
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

# OPAM configuration
. ~/.opam/opam-init/init.fish > /dev/null 2> /dev/null; or true

# fix manpath after OPAM
set -gx MANPATH (/usr/bin/manpath -g) $MANPATH

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

if type -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    alias ag 'ag --pager="bat -p"'
end

if type -q exa
    alias ls exa
end

set NPM_PACKAGES "$HOME/.npm-packages"

set PATH $PATH $NPM_PACKAGES/bin

set MANPATH $NPM_PACKAGES/share/man $MANPATH  

