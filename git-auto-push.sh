#!/bin/bash
cd /www/wwwroot/suiguan.net/app

if [ ! -d ".git" ]; then
    exit 0
fi

CHANGES=$(git status --porcelain)
if [ -z "$CHANGES" ]; then
    exit 0
fi

git add -A
git commit -m "auto: $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null 2>&1
git push > /dev/null 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') pushed" >> /www/wwwroot/suiguan.net/app/git-auto-push.log
