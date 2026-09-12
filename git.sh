#!/usr/bin/env bash
set -euo pipefail

BRANCH="main"
REMOTE="git@github.com:Kaynin319/countdowns.git"

cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ "${EUID}" -eq 0 ]]; then
    echo "git.sh: this script must not be run with sudo/as root." >&2
    echo "        Run it as your normal macOS user." >&2
    exit 1
fi

if [[ ! -d ".git" ]]; then
    echo "git.sh: no .git repository found in $(pwd)." >&2
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "git.sh: warning — there are existing unstaged or staged changes."
fi

git remote get-url origin >/dev/null 2>&1 \
    && git remote set-url origin "${REMOTE}" \
    || git remote add origin "${REMOTE}"

git branch -M "${BRANCH}"

untrack_ignored_files() {
    local ignored_tracked

    ignored_tracked="$(git ls-files -ci --exclude-standard -z)"

    if [[ -n "${ignored_tracked}" ]]; then
        echo "git.sh: tracked files now excluded by .gitignore:"
        git ls-files -ci --exclude-standard | sed 's/^/  - /'

        printf '%s' "${ignored_tracked}" | \
            git rm -r --cached --quiet \
            --pathspec-from-file=- \
            --pathspec-file-nul
    fi
}

check_large_files() {
    local oversized

    oversized="$(
        find . \
            -path "./.git" -prune -o \
            -type f -size +100M -print
    )"

    if [[ -n "${oversized}" ]]; then
        echo "git.sh: these files exceed GitHub's 100 MiB file limit:" >&2
        echo "${oversized}" | sed 's/^/  - /' >&2
        echo >&2
        echo "Compress, remove, or move these files before pushing." >&2
        exit 1
    fi
}

edit_gitignore() {
    [[ -f ".gitignore" ]] || touch ".gitignore"

    read -rp "Path to file/folder relative to repo root, or leave blank to list .gitignore: " target

    if [[ -z "${target}" ]]; then
        echo
        echo "── .gitignore ──"
        cat ".gitignore"
        return
    fi

    clean_target="${target%/}"

    if [[ ! -e "${clean_target}" ]]; then
        echo "git.sh: '${target}' does not exist." >&2
        exit 1
    fi

    entry="${clean_target}"

    if [[ -d "${clean_target}" ]]; then
        entry="${clean_target}/"
    fi

    if grep -qxF "${entry}" ".gitignore"; then
        grep -vxF "${entry}" ".gitignore" > ".gitignore.tmp"
        mv ".gitignore.tmp" ".gitignore"
        echo "git.sh: removed '${entry}' from .gitignore."
    else
        printf '%s\n' "${entry}" >> ".gitignore"
        echo "git.sh: added '${entry}' to .gitignore."
    fi
}

push_changes() {
    untrack_ignored_files
    check_large_files

    git add -A

    if git diff --cached --quiet; then
        echo "git.sh: nothing to commit."
        exit 0
    fi

    echo
    echo "── Changes to be committed ──"
    git diff --cached --stat
    echo

    read -rp "Commit message: " msg

    if [[ -z "${msg}" ]]; then
        msg="Update $(date '+%Y-%m-%d %H:%M:%S')"
    fi

    git commit -m "${msg}"

    echo
    echo "git.sh: force-pushing local '${BRANCH}' over the GitHub repository."
    echo "git.sh: remote-only commits and files will be replaced."
    echo

    git push --force origin "${BRANCH}"

    echo
    echo "git.sh: push complete."
    echo "Local repository: $(pwd)"
    echo "Remote repository: ${REMOTE}"
}

echo "Kaynin319 countdowns — Git helper"
echo
echo "  1) Commit all local changes and force-push to GitHub"
echo "  2) Add or remove a path in .gitignore"
echo

read -rp "Choose an option [1-2]: " choice

case "${choice}" in
    1)
        push_changes
        ;;

    2)
        edit_gitignore
        ;;

    *)
        echo "git.sh: invalid option." >&2
        exit 1
        ;;
esac