#! /bin/bash

# default commit message
commit_message="checkpoint"

# if there is a command line argument, use it as the commit message
if [ -n "$1" ]; then
    commit_message="$1"
fi

git add .
git commit -m "$commit_message"
git push origin main