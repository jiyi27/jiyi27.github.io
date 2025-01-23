#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Backup Blog
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author jiyi27

git switch hugo-blog
git add .
git commit -m "$(date)"
git push origin hugo-blog

