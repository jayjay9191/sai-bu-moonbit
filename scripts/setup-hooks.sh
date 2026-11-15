#!/bin/sh
# 启用本仓库的 git hooks（只需跑一次）：
#   bash scripts/setup-hooks.sh
#
# 作用：git config core.hooksPath .githooks，让提交前自动跑
# .githooks/pre-commit（moon test，失败阻止提交）。
#
# 注意两点：
# 1. core.hooksPath 是本地仓库配置，不进 git；换电脑或重克隆后要重跑一次。
# 2. git 默认不提交 .git/hooks 下的钩子，所以钩子放在 .githooks 里随仓库走，
#    这个脚本只是把本地仓库指向它。
set -e
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
echo "已启用：core.hooksPath = .githooks（pre-commit 会在每次提交前跑 moon test）"
