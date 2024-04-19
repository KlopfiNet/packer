# Script to start a watcher
Param(
    [string]$watcherHost,
    [string]$packerVmTemplateId
)

# Debug
Write-Host @"
watcherHost        : $watcherHost
packerVmTemplateId : $packerVmTemplateId
"@ -f cyan; ''

try {
    $res = irm "http://$watcherHost/watcher/$env:WATCHER_ID/$packerVmTemplateId" -method POST
    Write-Host "Watcher has been started" -f green
    "WATCHER_ACTIVE=1" >> $env:GITHUB_OUTPUT
} catch {
    Write-Host "Could not start watcher: $_" -f red
    "WATCHER_ACTIVE=0" >> $env:GITHUB_OUTPUT
}