#!/bin/sh -x

# Path to the Git hooks directory
GIT_HOOKS_DIR=./.git/hooks

echo "Installing the following pre-commit hook"
cat .pre-commit-hook.sh
install -m755 .pre-commit-hook.sh "$GIT_HOOKS_DIR"/pre-commit

echo "Pre-commit hook set up successfully."
