# Script to mutate watchers
Param(
    [string]$watcherHost,
    [bool]$watcherStatus,
    [string]$stepOutcome
)

# Debug
Write-Host @"
watcherHost   : $watcherHost
watcherStatus : $watcherStatus
stepOutcome   : $stepOutcome
"@ -f cyan; ''

try {
  if ($watcherStatus) {
    $res = irm "http://$watcherHost/watcher/$env:WATCHER_ID/stop" -method POST
    Write-Host "Watcher has been stopped." -f yellow

    # Get last step image and archive if pack was a failure
    if ($stepOutcome -eq "failure") {
      $watcher = irm "http://$watcherHost/watcher/$env:WATCHER_ID"

      # Get last step image
      Write-Host "> Getting last step image..." -f cyan
      iwr "http://$watcherHost/watcher/$env:WATCHER_ID/$($watcher.step)" -OutFile "final_step.png"

      # Get archive
      Write-Host "> Getting archive..." -f cyan
      iwr "http://$watcherHost/watcher/$env:WATCHER_ID/archive" -OutFile "watcher_archive.tar.bz2"
    }
    
  } else {
    Write-Host "Watcher was not started, nothing to do." -f yellow
  }            
} catch {
  throw "Error: $_"
} finally {
  # Destroy watcher in any case
  try {
    Write-Host "Destroying watcher..." -f cyan
    $res = irm "http://$watcherHost/watcher/$env:WATCHER_ID" -method DELETE
  } catch {
    Write-Host "Error in finally{}: $_" -f red
  }
}