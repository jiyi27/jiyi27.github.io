#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Fetch and Merge
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🔄

# Documentation:
# @raycast.author David
# @raycast.authorURL https://raycast.com/shwezhu

# 确保我们在正确的分支上
git switch hugo-blog

# 获取远程仓库的最新更改
echo "Fetching remote changes..."
git fetch origin

# 显示本地与远程的差异
echo "Showing differences between local and remote..."
git status

# 合并远程分支的更改
echo "Merging changes from remote..."
git merge origin/hugo-blog

# 显示合并后的状态
echo "Current status after merge:"
git status