#!/usr/bin/env bash
# Workshop tools installer — ffuf + python requests
# Supports: macOS (brew), Linux (apt/go), Windows Git Bash (winget/manual)

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { printf "${GREEN}[+]${RESET} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }
fail() { printf "${RED}[x]${RESET} %s\n" "$1"; exit 1; }

OS="$(uname -s 2>/dev/null || echo Windows)"

install_ffuf() {
    if command -v ffuf &>/dev/null; then
        ok "ffuf already installed: $(ffuf -V 2>&1 | head -1)"
        return
    fi

    echo ""
    warn "Installing ffuf..."

    case "$OS" in
        Darwin)
            if command -v brew &>/dev/null; then
                brew install ffuf
            else
                fail "Homebrew not found. Install it: https://brew.sh"
            fi
            ;;
        Linux)
            if command -v apt-get &>/dev/null; then
                sudo apt-get update -qq && sudo apt-get install -y ffuf
            elif command -v go &>/dev/null; then
                go install github.com/ffuf/ffuf/v2@latest
                export PATH="$PATH:$(go env GOPATH)/bin"
            else
                # Fallback: download binary from GitHub releases
                FFUF_VER="2.1.0"
                ARCH=$(uname -m)
                [ "$ARCH" = "x86_64" ] && ARCH="amd64"
                [ "$ARCH" = "aarch64" ] && ARCH="arm64"
                URL="https://github.com/ffuf/ffuf/releases/download/v${FFUF_VER}/ffuf_${FFUF_VER}_linux_${ARCH}.tar.gz"
                warn "Downloading ffuf binary from GitHub..."
                curl -sL "$URL" | tar xz -C /usr/local/bin ffuf
                chmod +x /usr/local/bin/ffuf
            fi
            ;;
        Windows*)
            if command -v winget &>/dev/null; then
                winget install ffuf
            else
                warn "Install manually: https://github.com/ffuf/ffuf/releases"
                warn "Download ffuf_*_windows_amd64.zip, extract ffuf.exe to a folder in PATH"
                exit 1
            fi
            ;;
        *)
            fail "Unknown OS: $OS"
            ;;
    esac

    ok "ffuf installed: $(ffuf -V 2>&1 | head -1)"
}

echo ""
echo "${BOLD}=== Workshop Tools Setup ===${RESET}"
echo ""

install_ffuf

echo ""
ok "All tools ready. Happy hacking!"
echo ""
