#!/bin/bash
git checkout main
git pull
git remote prune origin
git branch --merged main | grep -v "main" | xargs -r git branch -d
