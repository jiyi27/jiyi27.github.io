#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Publish Blog
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author jiyi27

hugo
cd public/
git switch master
git add .
git commit -m "$(date)"
git push origin master

