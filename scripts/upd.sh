#!/bin/bash

# Small houskeeping script to keep system packages up to date

case "$OSTYPE" in
    
    linux*)
        # boldly assuming Ubuntu
        echo "Updating Ubuntu packages"
        sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove
        echo "Updating Snap packages"
        sudo snap refresh
        ;;
    
    darwin*)
        if command -v brew --version &> /dev/null
        then
            echo "Updating Homebrew packages"
            brew update && brew upgrade
        fi
        ;;
  *)        echo "Unsupported: $OSTYPE" ;;
esac

if command -v opam --version &> /dev/null
then
    echo "Updating OPAM packages"
    opam update && opam upgrade
fi

if command -v rustup --version &> /dev/null
then
    echo "Updating Rust"
    rustup update
fi


