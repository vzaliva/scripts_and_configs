#!/bin/bash

# Small houskeeping screipt to keep system packages up to date

case "$OSTYPE" in
    
    linux*)
        # boldly assuming Ubuntu
        echo "Updating Ubuntu packages"
        sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove
        echo "Updating Snap packages"
        sudo snap refresh
        ;;
    
    darwin*)
        echo "Updating Homebrew packages"
        brew update && brew upgrade
        ;;
  *)        echo "Unsupported: $OSTYPE" ;;
esac

echo "Updating OPAM packages"
opam update && opam upgrade
