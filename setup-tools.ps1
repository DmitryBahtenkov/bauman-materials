# Workshop tools installer — ffuf + python requests
# Run: powershell -ExecutionPolicy Bypass -File setup-tools.ps1

$ErrorActionPreference = "Stop"

function ok   { Write-Host "[+] $args" -ForegroundColor Green }
function warn { Write-Host "[!] $args" -ForegroundColor Yellow }
function fail { Write-Host "[x] $args" -ForegroundColor Red; exit 1 }

Write-Host "`n=== Workshop Tools Setup ===`n" -ForegroundColor Cyan

# ─── ffuf ────────────────────────────────────────────────────────────────────
if (Get-Command ffuf -ErrorAction SilentlyContinue) {
    ok "ffuf already installed: $(ffuf -V 2>&1 | Select-Object -First 1)"
} else {
    warn "Installing ffuf..."

    $FFUF_VER = "2.1.0"
    $FFUF_ZIP = "ffuf_${FFUF_VER}_windows_amd64.zip"
    $FFUF_URL = "https://github.com/ffuf/ffuf/releases/download/v${FFUF_VER}/${FFUF_ZIP}"
    $DEST     = "$env:USERPROFILE\tools"

    New-Item -ItemType Directory -Force -Path $DEST | Out-Null
    Invoke-WebRequest -Uri $FFUF_URL -OutFile "$DEST\$FFUF_ZIP"
    Expand-Archive -Path "$DEST\$FFUF_ZIP" -DestinationPath $DEST -Force
    Remove-Item "$DEST\$FFUF_ZIP"

    # Add to PATH for current session
    $env:PATH += ";$DEST"

    # Add to user PATH permanently
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$DEST*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$DEST", "User")
        warn "Added $DEST to PATH. Restart terminal to take effect in future sessions."
    }

    ok "ffuf installed to $DEST\ffuf.exe"
}

# ─── Python venv + requests ───────────────────────────────────────────────────
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    fail "Python not found. Install Python 3.8+: https://www.python.org/downloads/ (check 'Add to PATH')"
}

$PYTHON_VER = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
ok "Python $PYTHON_VER found"

Write-Host ""
ok "All tools ready. Happy hacking!"
Write-Host ""
warn "To activate venv before running the exploit:"
Write-Host "    $VENV_DIR\Scripts\activate" -ForegroundColor Gray
Write-Host ""
