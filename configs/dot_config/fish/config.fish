alias x exit
alias al alias
alias ll "ls -al"
alias e "emacsclient -n"

set fish_greeting

if test -d $HOME/.local/bin
  set PATH $HOME/.local/bin $PATH
end

if test -d $HOME/.cask/bin
  set PATH $HOME/.cask/bin $PATH
end

# OPAM configuration
. ~/.opam/opam-init/init.fish > /dev/null 2> /dev/null; or true

