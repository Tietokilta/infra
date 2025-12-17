#!/usr/bin/env -S bash -euo pipefail

if command -v tofu > /dev/null ; then
    tf_cmd=tofu
elif command -v terraform > /dev/null ; then
    tf_cmd=terraform
fi

if command -v nix > /dev/null ; then
    nix fmt -- --fail-on-change
elif [ -n "$tf_cmd" ] ; then
    if ! "$tf_cmd" fmt --recursive --check > /dev/null ; then
        echo "The following terraform files have changed:" >&2
        "$tf_cmd" fmt --recursive
        exit 1
    fi
else
    echo "No nix, terraform, or tofu found to run formatters" >&2
    exit 1
fi
