#! /usr/bin/env bash

set -e
set -u
set -x

# check dependencies
git --version
gh2md --version
pandoc --version

if ! (git branch --format="%(refname)" | grep -q -x "refs/heads/github-issues"); then
  echo creating orphan branch github-issues
  git branch --copy master master-temp-copy
  git worktree add github-issues master-temp-copy
  git -C github-issues switch --orphan github-issues
  git branch --delete master-temp-copy
else
  echo mounting branch github-issues
  git worktree add github-issues github-issues || true
fi

# run gh2md
git -C github-issues rm -rf ghmd || true
rm -rf github-issues/ghmd || true
gh2md --multiple-files --file-extension .ghmd --idempotent btdig/dhtcrawler2 github-issues/ghmd

# convert ghmd to md files
git -C github-issues rm -rf md || true
rm -rf github-issues/md || true
mkdir github-issues/md || true
find github-issues/ghmd -type f -name "*.ghmd" | while read ghmd_path; do
  md_path=${ghmd_path%.*}.md
  md_path=github-issues/md/${md_path#*/*/}
  pandoc -f gfm -t commonmark "$ghmd_path" -o "$md_path" --wrap=none
done

# remove ghmd files to save space
git -C github-issues rm -rf ghmd || true
rm -rf github-issues/ghmd || true

git -C github-issues add .
git -C github-issues commit -m "update github issues"
