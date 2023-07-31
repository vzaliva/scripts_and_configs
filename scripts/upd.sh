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

if command -v npm --version &> /dev/null
then
    echo "Updating NPM packages"
    npm update
    rm -f package-lock.json
fi

if command -v rustup --version &> /dev/null
then
    echo "Updating Rust"
    rustup update

    if command -v cargo --version &> /dev/null
    then
        echo "Updating Cargo crates"
        cargo install cargo-update
        cargo install-update -a 
    fi
fi


#if command -v pip3 --version &> /dev/null
#then
#    echo "Updating Python3 packages"
#    if command -v pip_upgrade_outdated --version &> /dev/null
#    then
#        echo "Installing pip_upgrade_outdated"
#        pip3 install --user pip-upgrade-outdated
#    fi
#    pip_upgrade_outdated -3 -p -u
#fi


