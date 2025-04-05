#!/bin/bash
# Wrapper for Sioyek to handle google-drive: URIs
# It creates a temporary directory and copies the file using its original (sanitised) name.

# Create a temporary directory
temp_dir=$(mktemp -d /tmp/sioyek.XXXXXX)

# Define a cleanup function to remove the temporary directory
cleanup() {
    # for 2nd and subsequent files `sioyek` ends immediately causing
    # race condition when file deleted before displayed. The hacky
    # workaround is to git it a few seconds to open befor cleanup.
    sleep 5
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
    fi
}

# Ensure cleanup occurs when the script exits
trap cleanup EXIT

if [[ "$1" == google-drive:* ]]; then
    # Query gio info to extract the display name
    original_name=$(gio info "$1" | awk -F ': ' '/standard::display-name/ {print $2; exit}')
    
    # Fallback if no display name is found in the metadata.
    if [[ -z "$original_name" ]]; then
        original_name="sioyek_temp.pdf"
    fi

    # Sanitize the file name:
    # Allow letters, numbers, spaces, underscores, dots, dashes and colons.
    original_name=$(echo "$original_name" | tr -cd '[:alnum:][:space:]_.-:')

    # Define the target file within the temporary directory
    target_file="${temp_dir}/${original_name}"
    
    # Copy the remote file locally using gio copy.
    gio copy "$1" "$target_file"
    
    # Open the copied file with Sioyek
    sioyek "$target_file"
else
    # For local files, just open directly with Sioyek.
    sioyek "$@"
fi
