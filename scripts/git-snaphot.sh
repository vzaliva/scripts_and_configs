#!/bin/bash
# git-snapshot: Backup changes only if they exist, without clearing workspace

# 1. Set the backup message (default to timestamp)
MESSAGE="${1:-"Snapshot backup $(date '+%Y-%m-%d %H:%M:%S')"}"

# 2. Try to create a stash commit object
# 'create' returns a hash if changes exist; otherwise, it returns nothing.
STASH_HASH=$(git stash create "$MESSAGE")

# 3. Handling: Exit if there are no uncommitted changes
if [ -z "$STASH_HASH" ]; then
    echo "No uncommitted changes detected. Stash not created."
    exit 0
fi

# 4. Store the hash into the stash reflog to make it permanent
git stash store -m "$MESSAGE" "$STASH_HASH"

echo "Backup saved: $MESSAGE"
echo "Check your backups with 'git stash list'"


