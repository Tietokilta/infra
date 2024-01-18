#!/bin/sh -x

# Path to the Git hooks directory
GIT_HOOKS_DIR=./.git/hooks

# Create the pre-commit hook (this will run on each git commit)
cat > "$GIT_HOOKS_DIR/pre-commit" <<EOF
#!/bin/sh

# Run terraform fmt recursively
terraform fmt --recursive | xargs -r git add
EOF

# Make the hook executable
chmod +x "$GIT_HOOKS_DIR/pre-commit"

echo "Pre-commit hook set up successfully."
