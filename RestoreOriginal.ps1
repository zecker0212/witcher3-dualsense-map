# Compatibility entry point. v1.0.1 requires its installation record for safe restore.
& (Join-Path $PSScriptRoot 'Setup.ps1') -Action Uninstall
exit $LASTEXITCODE
