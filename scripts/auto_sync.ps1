param (
    [string]$TargetBranch = ""
)

$ErrorActionPreference = "Stop"

# Ensure we run in repo root
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

# Determine current branch if not provided
if (-not $TargetBranch) {
    $TargetBranch = (git branch --show-current).Trim()
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Git Auto-Sync: Updating '$TargetBranch' with 'origin/main'" -ForegroundColor Cyan
Write-Host " Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Fetch remote updates
Write-Host "[1/4] Fetching latest commits from GitHub..." -ForegroundColor Yellow
git fetch origin --prune

# 2. Check for local modifications
$hasChanges = (git status --porcelain).Trim().Length -gt 0
$stashed = $false

if ($hasChanges) {
    Write-Host "[2/4] Stashing local working changes..." -ForegroundColor Yellow
    git stash push -m "auto_sync_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $stashed = $true
} else {
    Write-Host "[2/4] Working tree is clean." -ForegroundColor Green
}

# 3. Merge origin/main
Write-Host "[3/4] Merging origin/main into $TargetBranch..." -ForegroundColor Yellow
try {
    git merge origin/main --no-edit
    Write-Host "Successfully merged latest changes from origin/main!" -ForegroundColor Green
} catch {
    Write-Host "Merge conflict encountered. Please inspect git status." -ForegroundColor Red
    if ($stashed) {
        git stash pop
    }
    exit 1
}

# Restore stash if needed
if ($stashed) {
    Write-Host "Restoring stashed changes..." -ForegroundColor Yellow
    git stash pop
}

# 4. Push to remote
Write-Host "[4/4] Pushing updated $TargetBranch to GitHub origin..." -ForegroundColor Yellow
try {
    git push origin $TargetBranch
    Write-Host "Branch '$TargetBranch' is now fully updated and synced with GitHub!" -ForegroundColor Green
} catch {
    Write-Host "Push failed: $_" -ForegroundColor Yellow
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Auto-Sync completed successfully." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
