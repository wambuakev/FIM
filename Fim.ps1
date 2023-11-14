
Write-Host ""
Write-Host "What would you like to do?"
Write-Host ""
Write-Host "    A) Collect new Baseline?"
Write-Host "    B) Begin monitoring files with saved Baseline?"
Write-Host ""

$response = Read-Host -Prompt "Please Enter 'A' or 'B'"
Write-Host ""

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
    # Delete it
    Remove-Item -Path .\baseline.txt
    }
}

if ($response -eq "A".ToUpper()) {
    # Delete baseline if it already exists
    Erase-Baseline-If-Already-Exists
    # Calculate Hash from the target files and store in baseline.txt

    # Collect all files in the target folder
    $files = Get-ChildItem -Path .\Files

    # For each file, calculate the hash and write to baseline.txt
    foreach ($f in $files) {
      $hash = Calculate-File-Hash $f.FullName 
      "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}
elseif ($response -eq "B".ToUpper()) {
    
    $fileHashDictionary = @{}

    # Load file|hash from baseline.txt and store them in a dictionary
    $filePathesAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathesAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    # Begin continuously monitoring files with saved Baseline
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path .\Files
         
        # For each file, calculate the hash and write to baseline.txt
        foreach ($f in $files) {
          $hash = Calculate-File-Hash $f.FullName 
          #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append\

          # A new file has been created! Notify Admin
          if ($fileHashDictionary[$hash.Path] -eq $null) {
            Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
          }
          else {
              # Notify Admin if an existing file has been changed
              if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                # The files are not changed.
              }
              else {
                # A file has been compromised! Notify Admin
                Write-Host "$($hash.Path) has been changed!!" -ForegroundColor Yellow
              }
          }

        }

        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                # one of the baseline files must have been deleted! Notify Admin
                Write-Host "$($key) has been deleted!!!" -ForegroundColor DarkRed -BackgroundColor White
            }
        }
    }
} 
