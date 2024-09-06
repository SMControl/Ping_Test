Write-Host "Ping_Test.ps1 - ScriptVersion 1.01" -ForegroundColor Green
# -----
# - Pings the provided hostname indefinitely and logs results to a daily file
# - Deletes old logs if there are more than 30 files
# - Runs the script as a background job
# - Provides an option to stop the job if already running
# - Creates a new log file every day

# Part 1 - Define working directory, variables, and check if the script is already running
# PartVersion 1.01
# -----
# This part sets up the necessary variables and checks for a running job.

$workingDirectory = "C:\winsm\pingtest"
$maxLogFiles = 30
$jobName = "PingTestJob"

# Ensure the working directory exists
if (!(Test-Path $workingDirectory)) {
    New-Item -ItemType Directory -Path $workingDirectory
}

# Check if job is already running
$existingJob = Get-Job -Name $jobName -ErrorAction SilentlyContinue
if ($existingJob) {
    $choice = Read-Host "The ping test is already running. Do you want to stop it? (y/n)"
    if ($choice -eq 'y') {
        Stop-Job -Name $jobName
        Remove-Job -Name $jobName
        Write-Host "Ping test stopped." -ForegroundColor Red
        exit
    } else {
        Write-Host "Ping test continues running." -ForegroundColor Green
        exit
    }
}

# Part 2 - Get hostname and define logging function
# PartVersion 1.01
# -----
# This part asks for the hostname and sets up the logging function with a timestamp.

$hostname = Read-Host "Enter the hostname or IP to ping"

function Log-PingResult {
    param ($logFile, $pingResult)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $pingResult"
}

# Part 3 - Create and start pinging job
# PartVersion 1.01
# -----
# This part runs the ping command as a job, logging output to the daily file.

Start-Job -Name $jobName -ScriptBlock {
    param ($hostname, $workingDirectory, $maxLogFiles)
    
    function Log-PingResult {
        param ($logFile, $pingResult)
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "$timestamp - $pingResult"
    }

    while ($true) {
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        $logFile = Join-Path $workingDirectory "$currentDate-$hostname.log"

        # Pinging and capturing the output line by line
        $pingResult = ping -t $hostname | ForEach-Object {
            Log-PingResult -logFile $logFile -pingResult $_
        }

        # Delete old logs
        $logFiles = Get-ChildItem -Path $workingDirectory -Filter "*.log" | Sort-Object CreationTime
        if ($logFiles.Count -gt $maxLogFiles) {
            Remove-Item $logFiles[0].FullName
        }

        # Wait for midnight to create a new log file
        $midnight = [datetime]::Today.AddDays(1)
        while ((Get-Date) -lt $midnight) {
            Start-Sleep -Seconds 60
        }
    }
} -ArgumentList $hostname, $workingDirectory, $maxLogFiles

Write-Host "Ping test started as background job." -ForegroundColor Green

# Part 4 - Optional part for monitoring the job status
# PartVersion 1.01
# -----
# This part provides the ability to monitor and check the status of the background job.

$job = Get-Job -Name $jobName
if ($job.State -eq 'Running') {
    Write-Host "Ping test is running in the background." -ForegroundColor Green
} else {
    Write-Host "Ping test is not running." -ForegroundColor Red
}