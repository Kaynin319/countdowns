#!/bin/bash

set -e

REPO_DIR="/Users/canaan/Documents/kaynin-git/countdowns"
REMOTE="git@github.com:Kaynin319/countdowns.git"
BRANCH="main"

cd "$REPO_DIR"

if [ ! -d ".git" ]; then
    echo "Error: $REPO_DIR is not a Git repository."
    exit 1
fi

git remote set-url origin "$REMOTE"
git branch -M "$BRANCH"

echo "Repository: $REPO_DIR"
echo "Remote: $REMOTE"
echo
echo "The remote branch will be completely replaced with this local folder."
echo "This includes additions, modifications, and deletions."
echo

read -r -p "Enter commit message: " COMMIT_MESSAGE

if [ -z "$COMMIT_MESSAGE" ]; then
    echo "Error: Commit message cannot be empty."
    exit 1
fi

echo
echo "Files that will be committed:"
git status --short
echo

read -r -p "Type OVERWRITE to continue: " CONFIRM

if [ "$CONFIRM" != "OVERWRITE" ]; then
    echo "Cancelled."
    exit 1
fi

git add -A

if git diff --cached --quiet; then
    echo "No file changes to commit."
    exit 0
fi

git commit -m "$COMMIT_MESSAGE"
git push --force origin "$BRANCH"

echo
echo "Done. The remote main branch now matches the local folder."
