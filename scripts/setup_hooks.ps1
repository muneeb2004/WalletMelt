# One-time per clone: enable the versioned git hooks.
git config core.hooksPath .githooks
Write-Host "core.hooksPath -> .githooks (docs guard active)"
git lfs install
