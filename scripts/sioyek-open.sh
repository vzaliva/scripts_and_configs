#!/bin/bash
# Wrapper for Sioyek to handle google-drive: URIs and clean up temporary files

# Define a cleanup function to remove the temporary file if it exists
cleanup() {
    if [[ -n "$temp_file" && -f "$temp_file" ]]; then
        rm -f "$temp_file"
    fi
}

# Set trap to execute cleanup on script exit
trap cleanup EXIT

if [[ "$1" == google-drive:* ]]; then
    # Create a temporary file with a .pdf extension
    temp_file=$(mktemp /tmp/sioyek_file.XXXXXX.pdf)
    
    # Copy the remote file locally using gio
    gio copy "$1" "$temp_file"
    
    # Open the temporary file with Sioyek
    sioyek "$temp_file"
else
    # For local files, open directly with Sioyek
    sioyek "$@"
fi

