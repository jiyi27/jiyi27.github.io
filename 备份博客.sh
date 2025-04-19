#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title 备份博客
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author David
# @raycast.authorURL https://raycast.com/shwezhu

git add .
git commit -m "$(date)"
git push origin hugo-blog

