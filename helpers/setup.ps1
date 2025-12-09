param(
    [switch]$InstallVcXsrv,
    [switch]$PullDeepStreamImage
)

function Write-Step { param($msg) ; Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Warn { param($msg) ; Write-Host "!!  $msg" -ForegroundColor Yellow }

# Require admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warn "Please run this script in an elevated PowerShell."
    exit 1
}

# Enable WSL2 + VM Platform
Write-Step "Enabling WSL and VirtualMachinePlatform (no reboot triggered)..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

# Set default WSL version to 2
Write-Step "Setting default WSL version to 2..."
wsl --set-default-version 2 | Out-Null

# Ensure Ubuntu 22.04 is installed
$ubuntuName = "Ubuntu-22.04"
$installedDistros = (wsl -l -q) 2>$null
if ($installedDistros -notcontains $ubuntuName) {
    Write-Step "Installing $ubuntuName (this may prompt once, then complete silently)..."
    wsl --install -d $ubuntuName
    Write-Warn "If this was just installed, open $ubuntuName once to finish initialization, then re-run this script."
    exit 0
} else {
    Write-Step "$ubuntuName already installed."
}

# Install Docker Desktop via winget (if missing)
$dockerExe = "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerExe)) {
    Write-Step "Installing Docker Desktop via winget..."
    winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
    Write-Warn "Log out/in or reboot may be required. After that, open Docker Desktop once so it finalizes setup."
} else {
    Write-Step "Docker Desktop already installed."
}

# Optionally install VcXsrv for X11
if ($InstallVcXsrv) {
    Write-Step "Installing VcXsrv via winget..."
    winget install -e --id marha.VcXsrv --accept-source-agreements --accept-package-agreements
}

# Ensure WSL base packages (inside Ubuntu)
Write-Step "Updating Ubuntu packages and installing dev essentials inside WSL..."
$aptCmd = @"
set -e
sudo apt-get update -y
DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y
sudo add-apt-repository -y universe
sudo apt-get update -y
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y build-essential cmake git python3 python3-pip python3-venv
"@
$aptCmd = $aptCmd -replace "`r", ""
wsl -d $ubuntuName -e bash -lc "$aptCmd"

# Quick NVIDIA visibility check inside WSL
Write-Step "Checking GPU visibility inside WSL (nvidia-smi)..."
wsl -d $ubuntuName -e bash -lc "nvidia-smi" || Write-Warn "nvidia-smi failed. Ensure latest NVIDIA Windows driver and reboot if needed."

# Docker GPU test
Write-Step "Testing Docker GPU passthrough (may download ~300MB CUDA base image)..."
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi || Write-Warn "Docker GPU test failed. Ensure Docker Desktop is running with WSL2 + GPU enabled."

# Optionally pull DeepStream image (x86_64)
if ($PullDeepStreamImage) {
    Write-Step "Pulling DeepStream x86_64 image (nvcr.io/nvidia/deepstream:6.4-triton-devel)..."
    docker pull nvcr.io/nvidia/deepstream:6.4-triton-devel
}

Write-Step "Done. If features were just enabled or drivers updated, reboot may be required."
