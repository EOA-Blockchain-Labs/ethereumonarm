#!/bin/bash

# Directories to sync
src="/etc/ethereum/"
dest="/home/ethereum/.etc/ethereum/"

# Ensure destination directory exists
mkdir -p "$dest"

# Use rsync to sync the directories
rsync -avz --delete "$src" "$dest"

# Print completion message
echo "Directories have been synced."

# End script
exit 0
