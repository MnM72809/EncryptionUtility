param (
    [string]$os = "both",
    [string]$serverAlias = "sm",
    [string]$remoteDir = "/home/moriaan/programmeren/c/projects/terminalApp",
    [switch]$noPwdLocal,
    [string]$localDir,
    [string]$program = "app",
    [switch]$help
)


function help {
    Write-Host "Usage: compile.ps1 [-os <os>] [-serverAlias <serverAlias>] [-remoteDir <remoteDir>] [-noPwdLocal] [-localDir <localDir>] [-help]"
    Write-Host "  -os <os>          The operating system of the server. Default is 'both'."
    Write-Host "  -serverAlias <serverAlias>  The alias of the server. Default is 'sm'."
    Write-Host "  -remoteDir <remoteDir>      The directory on the server where the files will be uploaded. Default is '/home/moriaan/programmeren/c/projects/terminalApp'."
    Write-Host "  -noPwdLocal       If set, the local directory will not be set to the current directory."
    Write-Host "  -localDir <localDir>        The local directory where the files will be uploaded. Default is the current directory."
    Write-Host "  -program <program>          The name of the program to compile. Default is 'app'."
    Write-Host "  -help             Display this help message."
    exit 0    
}

function Get-Executable {
    param (
        [string]$serverAlias,
        [string]$remoteDir,
        [string]$localDir,
        [string]$program
    )
    Write-Host "Downloading executable..."
    scp "${serverAlias}:${remoteDir}/${program}" "$localDir"
    $scpExitCode1 = $LASTEXITCODE
    scp "${serverAlias}:${remoteDir}/${program}.exe" "$localDir"
    $scpExitCode2 = $LASTEXITCODE
    if ($scpExitCode1 -eq 0) {
        Write-Host "Executable $program downloaded." -ForegroundColor Green
    }
    elseif ($scpExitCode2 -eq 0) {
        Write-Host "Executable $program.exe downloaded." -ForegroundColor Green
    }
    else {
        Write-Host "Executable download failed." -ForegroundColor Red
        exit 1
    }
}



# If noPwdLocal is not set, set the local directory to the current directory
if (-not $noPwdLocal) {
    $localDir = (Get-Location).Path
}

# Determine the files to upload by searching for the files in the current directory (.c and .h files)
$filesToUpload = Get-ChildItem -Path . -Recurse -Include *.c, *.h

Write-Host "Compressing files..."

$zipFileName = "source.zip"
# Create a zip file with the files to upload
Compress-Archive -Path $filesToUpload -DestinationPath $zipFileName -Force

# Upload the zip file to the server
Write-Host "Uploading $zipFileName to the server..."

$zipPath = "$localDir\$zipFileName"
# Upload the zip file to the server (port 22)
scp $zipPath "${serverAlias}:${remoteDir}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Upload failed." -ForegroundColor Red
    exit 1
}

Write-Host "Decompressing on remote..."
ssh $serverAlias "unzip -o $remoteDir/$zipFileName -d $remoteDir && rm $remoteDir/$zipFileName"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Decompression on remote failed." -ForegroundColor Red
    exit 1
}

Write-Host "Compilation on remote..."

$linuxCommand = "gcc -o $program `$(ls *.c)` -g -lssl -lcrypto"
$windowsCommand = "x86_64-w64-mingw32-gcc -o $program.exe `$(ls *.c)` -g -lws2_32 -lwinmm -lssl -lcrypto -DWINDOWS -std=c99"

if ($os -eq "windows") {
    $compileCommand = "cd $remoteDir && echo Compiling for Windows... && $windowsCommand"
}
elseif ($os -eq "linux") {
    $compileCommand = "cd $remoteDir && echo Compiling for Linux... && $linuxCommand"
}
else {
    # Compile for both Windows and Linux
    $compileCommand = "cd $remoteDir && echo Compiling for Windows... && $windowsCommand && echo Compiling for Linux... && $linuxCommand"
}

ssh $serverAlias $compileCommand
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation on remote failed." -ForegroundColor Red
    exit 1
}

Write-Host "Compilation successful." -ForegroundColor Green


Get-Executable -serverAlias $serverAlias -remoteDir $remoteDir -localDir $localDir -program $program
Write-Host "Program compiled and ready to run." -ForegroundColor Green