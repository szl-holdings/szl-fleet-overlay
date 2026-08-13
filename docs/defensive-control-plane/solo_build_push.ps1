param(
    [Parameter(Mandatory = $false)]
    [string] $TargetRepoRoot = "",

    [Parameter(Mandatory = $false)]
    [string] $TargetBranch = "main",

    [Parameter(Mandatory = $false)]
    [string] $RuntimeHost = "",

    [Parameter(Mandatory = $false)]
    [string] $CiWorkflow = "",

    [Parameter(Mandatory = $false)]
    [string] $Python = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
)

$ErrorActionPreference = "Stop"
$pythonPaths = @(
    $Python,
    "C:\Users\steph\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
)

function Resolve-Python {
    foreach ($candidate in $pythonPaths) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }
    return (Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
}

function Assert-TargetRepo {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "TargetRepoRoot was not provided. Set -TargetRepoRoot to a checked-out source root."
    }
    if (-not (Test-Path $Path)) {
        throw "TargetRepoRoot not found: $Path"
    }
    $gitDir = Join-Path $Path ".git"
    if (-not (Test-Path $gitDir)) {
        throw "TargetRepoRoot is not a git repo: $Path"
    }
}

function Invoke-CommandCapture {
    param([string]$Command, [string[]]$Arguments, [string]$WorkDir)
    $p = Start-Process -FilePath $Command -ArgumentList $Arguments -WorkingDirectory $WorkDir -Wait -PassThru -NoNewWindow -RedirectStandardOutput "out.tmp" -RedirectStandardError "err.tmp"
    $stdout = Get-Content "out.tmp" -Raw
    $stderr = Get-Content "err.tmp" -Raw
    Remove-Item "out.tmp","err.tmp" -ErrorAction SilentlyContinue
    return [pscustomobject]@{
        ExitCode = $p.ExitCode
        StdOut   = $stdout
        StdErr   = $stderr
    }
}

try {
    if (-not $TargetRepoRoot) {
        Write-Host "No target repo was supplied. This is the blocker for an actual push."
        Write-Host "Run with: .\solo_build_push.ps1 -TargetRepoRoot <path> -RuntimeHost <url> -CiWorkflow <name>"
        exit 1
    }

    Assert-TargetRepo -Path $TargetRepoRoot
    $pythonExe = Resolve-Python
    if (-not $pythonExe -or -not (Test-Path $pythonExe)) {
        throw "Python executable not found. Set -Python explicitly."
    }

    Write-Host "Target repo: $TargetRepoRoot"
    Write-Host "Target branch: $TargetBranch"
    if ($RuntimeHost) { Write-Host "Runtime host: $RuntimeHost" }
    if ($CiWorkflow) { Write-Host "CI workflow: $CiWorkflow" }
    Write-Host "Using Python: $pythonExe"

    Push-Location $TargetRepoRoot
    try {
        $status = git status --porcelain
        if ($status) {
            Write-Warning "Repository has uncommitted changes. Consider stashing or committing before push."
        }

        git checkout $TargetBranch | Out-Host
        git pull --ff-only | Out-Host

        Write-Host "Running local verification gate..."
        & $pythonExe -B -m unittest discover -s tests -v
        if ($LASTEXITCODE -ne 0) { throw "Unit tests failed" }

        Write-Host "Running package demo..."
        & $pythonExe -B -m defensive_control_plane demo
        if ($LASTEXITCODE -ne 0) { throw "Demo failed" }

        Write-Host "Running verify evidence script..."
        & $pythonExe -B verify.py
        if ($LASTEXITCODE -ne 0) { throw "verify.py failed" }

        if ($CiWorkflow) {
            Write-Host "CI trigger requested. Wire this manually for your CI platform:"
            Write-Host " - ensure verify.py gate is required"
        }

        if ($RuntimeHost) {
            Write-Host "Runtime target was provided. Add deployment step and smoke tests for: /livez, /readyz, /api/lanes."
        }

        $receipt = Join-Path $TargetRepoRoot "evidence/local-verification.json"
        if (Test-Path $receipt) {
            $h = (Get-FileHash $receipt -Algorithm SHA256).Hash.ToLowerInvariant()
            Write-Host "Evidence receipt hash: $h"
        } else {
            Write-Warning "Evidence receipt not found at expected path."
        }

        Write-Host "Gate complete. Review and commit only from observed diff. This script does not auto-push without your explicit branch policy checks."
    }
    finally {
        Pop-Location
    }
}
catch {
    Write-Error $_
    exit 1
}
