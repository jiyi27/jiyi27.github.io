#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Publish Blogs
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author shwezhu
# @raycast.authorURL https://raycast.com/shwezhu

hugo
cd public/
git switch master
git add .
git commit -m "$(date)"
git push origin master

