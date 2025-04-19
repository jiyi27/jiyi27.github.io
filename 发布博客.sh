#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title 发布博客
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author David
# @raycast.authorURL https://raycast.com/shwezhu

hugo
cd public/
git switch master
git add .
git commit -m "$(date)"
git push origin master

