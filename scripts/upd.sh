#!/bin/bash

# Small houskeeping script to keep system packages up to date.
# One script for Ubuntu and macOS: keep it bash 3.2 compatible (macOS /bin/bash).

# Non-login shells (ssh commands, cron, some tool shells) don't have the
# Homebrew and cargo directories on PATH, so the checks below would silently
# skip those sections.  Add them when they exist and aren't already there.
for d in /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin "$HOME/.cargo/bin"; do
    case ":$PATH:" in
        *":$d:"*) ;;
        *) [ -d "$d" ] && PATH="$d:$PATH" ;;
    esac
done
export PATH

# True if command $1 exists.
have() { command -v "$1" >/dev/null 2>&1; }

case "$OSTYPE" in

    linux*)
        # boldly assuming Ubuntu
        echo "Updating Ubuntu packages"
        sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove
        echo "Updating Snap packages"
        sudo snap refresh
        #if have flatpak
        #then
        #    echo "Updating Flatpak packages"
        #    flatpak update
        #fi
        ;;

    darwin*)
        if have brew
        then
            echo "Updating Homebrew packages"
            brew update && brew upgrade
        else
            echo "Skipping Homebrew: brew not found"
        fi
        ;;
  *)        echo "Unsupported: $OSTYPE" ;;
esac

if have opam
then
    echo "Updating OPAM packages"
    opam update && opam upgrade
else
    echo "Skipping OPAM: opam not found"
fi

if have npm
then
    echo "Updating NPM packages"
    npm update
    rm -f package-lock.json
else
    echo "Skipping NPM: npm not found"
fi

if have rustup
then
    echo "Updating Rust"
    rustup update

    if have cargo
    then
        echo "Updating Cargo crates"
        cargo install cargo-update
        cargo install-update -a
    else
        echo "Skipping Cargo crates: cargo not found"
    fi
else
    echo "Skipping Rust: rustup not found"
fi


GOTOOLS=(
  github.com/ramonvermeulen/whosthere@latest
)

if have go
then
    echo "Updating Go packages"
    for t in "${GOTOOLS[@]}"; do
        echo "  Updating $t"
        go install "$t"
    done
else
    echo "Skipping Go packages: go not found"
fi



#if have pip3
#then
#    echo "Updating Python3 packages"
#    if have pip_upgrade_outdated
#    then
#        echo "Installing pip_upgrade_outdated"
#        pip3 install --user pip-upgrade-outdated
#    fi
#    pip_upgrade_outdated -3 -p -u
#fi


