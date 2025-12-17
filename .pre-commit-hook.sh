#!/usr/bin/env -S bash -euo pipefail

if command -v nix > /dev/null ; then
    nix fmt -- --fail-on-change
else
    if ! terraform fmt --recursive --check > /dev/null ; then
        echo "The following terraform files have changed:" >&2
        terraform fmt --recursive
        exit 1
    fi
fi
