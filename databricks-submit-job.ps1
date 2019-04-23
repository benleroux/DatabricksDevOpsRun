param (
    [Parameter(Mandatory=$true)]
    [string]$token,
    [Parameter(Mandatory=$true)]
    [string]$notebook
 )

$urlRunsSubmit = "https://eastus2.azuredatabricks.net/api/2.0/jobs/runs/submit"
$urlRunsGet = "https://eastus2.azuredatabricks.net/api/2.0/jobs/runs/get"
$ContentType = "application/json"

try{    
  $json = @"
{
  "run_name": "my spark task",
  "existing_cluster_id": "0410-232610-acid490",
  "timeout_seconds": 3600,
  "notebook_task": {
    "notebook_path": "$($notebook)"
  }
}
"@

  Write-Host("Running notebook: " + $notebook + "  --  " + $(Get-Date -Format o))

  $post = Invoke-RestMethod -Method Post -Uri $urlRunsSubmit -Body $json -ContentType $ContentType -Headers @{"Authorization"="Bearer $token"}
  
  $urlRunsGet = $urlRunsGet + "?run_id=" + $post.run_id

  $message = ""

  DO {
    if ($message -ne "") {
      Start-Sleep -s 5
    }
    
    $post = Invoke-RestMethod -Method Get -Uri $urlRunsGet -ContentType $ContentType -Headers @{"Authorization"="Bearer $token"}

    if ($message -ne "Run ID: " + $post.run_id + " - Life cycle state: " + $post.state.life_cycle_state) {
      $message = "Run ID: " + $post.run_id + " - Life cycle state: " + $post.state.life_cycle_state

      Write-Host( $message  + "  --  " + $(Get-Date -Format o))
    }
    
  } While ( ($post.state.life_cycle_state -ne "TERMINATED") -and ($post.state.life_cycle_state -ne "INTERNAL_ERROR"))
  
  Write-Host("Life result state: " + $post.state.result_state + "  --  " + $(Get-Date -Format o))

  if ($post.state.result_state -eq "SUCCESS") {
    $LastExitCode = 1
  }else{  
    $LastExitCode = 0
    
    throw "Error: " + $post.state.state_message
  }

} catch {
    write-Error (Convertto-Json $_.Exception.Response)
    #$headers = $_.Exception.Response.Headers
    #$cookies = $_.Exception.Response.Cookies
    #$headers |% { write-host "$_=$($headers[$_])"}
    #$cookies |% { write-host "$_=$($cookies[$_])"}

    $LastExitCode = 0
}

exit $LastExitCode
