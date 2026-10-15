#!/usr/bin/env bash
# One-time per clone: enable the versioned git hooks.
git config core.hooksPath .githooks
echo "core.hooksPath -> .githooks (docs guard active)"
git lfs install
