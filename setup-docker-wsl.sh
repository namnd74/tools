#!/usr/bin/env bash
# ==============================================================================
# setup-docker-wsl.sh
# Cai dat Docker Engine (khong phai Docker Desktop) ben trong Ubuntu WSL2
#
# Chay TRONG Ubuntu WSL:
#   chmod +x setup-docker-wsl.sh
#   ./setup-docker-wsl.sh
#
# Hoac chay tu PowerShell Windows (sau khi Install-WSL-Docker.ps1 da cai Ubuntu):
#   wsl -d Ubuntu-22.04 -- bash /mnt/f/tools/setup-docker-wsl.sh
#
# Sau khi cai xong, kiem tra:
#   docker version
#   docker run --rm hello-world
# ==============================================================================

set -Eeuo pipefail

# ---------- Colors ----------
C_G="\033[32m"; C_B="\033[34m"; C_Y="\033[33m"; C_R="\033[31m"; C_GR="\033[90m"; C_0="\033[0m"
ok()   { echo -e "${C_G}[OK]${C_0}   $*"; }
info() { echo -e "${C_B}[INFO]${C_0} $*"; }
warn() { echo -e "${C_Y}[WARN]${C_0} $*"; }
err()  { echo -e "${C_R}[ERR]${C_0}  $*" >&2; }
skip() { echo -e "${C_GR}[SKIP]${C_0} $*"; }

trap 'err "Loi tai dong $LINENO. Command: $BASH_COMMAND"' ERR

# ---------- Kiem tra WSL ----------
if ! grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    warn "Khong phat hien WSL. Script nay nen chay ben trong WSL2 Ubuntu."
fi

# ---------- Quyen sudo ----------
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

echo
echo -e "${C_B}=============================================${C_0}"
echo -e "${C_B}   CAI DAT DOCKER ENGINE TREN UBUNTU WSL2   ${C_0}"
echo -e "${C_B}=============================================${C_0}"
echo "Distro : $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Unknown}")"
echo "Kernel : $(uname -r)"
echo "User   : $(whoami)"
echo

# ==============================================================================
# BUOC 1: Go bo phien ban cu (neu co)
# ==============================================================================
info "=== 1/5 Go bo phien ban Docker cu (neu co) ==="
OLD_PKGS=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)
for pkg in "${OLD_PKGS[@]}"; do
    if dpkg -l "$pkg" &>/dev/null 2>&1; then
        $SUDO apt-get remove -y "$pkg" 2>/dev/null || true
        skip "Da go: $pkg"
    fi
done
ok "Sach phien ban Docker cu"

# ==============================================================================
# BUOC 2: Cai dat dependencies
# ==============================================================================
info "=== 2/5 Cap nhat apt va cai dependencies ==="
$SUDO apt-get update -qq
$SUDO apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https
ok "Dependencies da san sang"

# ==============================================================================
# BUOC 3: Them Docker GPG key va repository
# ==============================================================================
info "=== 3/5 Them Docker GPG key & repository ==="

$SUDO install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    ok "Da them Docker GPG key"
else
    skip "Docker GPG key da ton tai"
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

DOCKER_REPO="deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable"

if ! grep -rq "download.docker.com" /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "$DOCKER_REPO" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
    ok "Da them Docker repository (${CODENAME})"
else
    skip "Docker repository da ton tai"
fi

$SUDO apt-get update -qq

# ==============================================================================
# BUOC 4: Cai dat Docker Engine
# ==============================================================================
info "=== 4/5 Cai dat Docker Engine, CLI, Containerd, Compose ==="

DOCKER_PKGS=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

$SUDO apt-get install -y "${DOCKER_PKGS[@]}"
ok "Docker Engine da duoc cai dat"

# ==============================================================================
# BUOC 5: Cau hinh Docker daemon & quyen user
# ==============================================================================
info "=== 5/5 Cau hinh Docker ==="

# Them user hien tai vao nhom docker (khong can sudo khi chay docker)
CURRENT_USER="$(whoami)"
if [[ "$CURRENT_USER" != "root" ]]; then
    $SUDO usermod -aG docker "$CURRENT_USER"
    ok "Da them '$CURRENT_USER' vao nhom docker"
fi

# Tao thu muc daemon config
$SUDO mkdir -p /etc/docker

# Cau hinh Docker daemon toi uu cho WSL2
DAEMON_CONFIG='{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}'

if [[ ! -f /etc/docker/daemon.json ]]; then
    echo "$DAEMON_CONFIG" | $SUDO tee /etc/docker/daemon.json > /dev/null
    ok "Da tao /etc/docker/daemon.json"
else
    skip "/etc/docker/daemon.json da ton tai, bo qua ghi de"
fi

# Khoi dong Docker service
if $SUDO service docker start 2>/dev/null; then
    ok "Docker service da khoi dong"
elif $SUDO dockerd &>/dev/null & then
    sleep 2
    ok "Docker daemon da chay (manual)"
else
    warn "Khong the tu dong khoi dong dockerd. Chay tay: sudo service docker start"
fi

# Them auto-start vao .bashrc / .zshrc (WSL khong dung systemd mac dinh)
SHELL_PROFILE="$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && SHELL_PROFILE="$HOME/.zshrc"

DOCKER_START_BLOCK="# Auto-start Docker service in WSL"
if ! grep -qF "$DOCKER_START_BLOCK" "$SHELL_PROFILE"; then
    cat >> "$SHELL_PROFILE" << 'EOF'

# Auto-start Docker service in WSL
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    if ! pgrep dockerd > /dev/null 2>&1; then
        sudo service docker start > /dev/null 2>&1 &
    fi
fi
EOF
    ok "Da them auto-start Docker vao $SHELL_PROFILE"
else
    skip "Auto-start Docker da co trong $SHELL_PROFILE"
fi

# ==============================================================================
# KIEM TRA CUOI
# ==============================================================================
echo
echo -e "${C_G}=============================================${C_0}"
echo -e "${C_G}  DOCKER ENGINE CAI DAT HOAN TAT!           ${C_0}"
echo -e "${C_G}=============================================${C_0}"

sleep 1

if docker version &>/dev/null 2>&1; then
    docker version --format "  Client: {{.Client.Version}}\n  Server: {{.Server.Version}}" 2>/dev/null || true
    ok "Docker hoat dong binh thuong"
else
    warn "Docker chua san sang ngay bay gio. Thu:"
    echo "  sudo service docker start"
    echo "  docker version"
fi

if docker compose version &>/dev/null 2>&1; then
    ok "Docker Compose: $(docker compose version --short 2>/dev/null || docker compose version)"
fi

echo
echo "Kiem tra nhanh (chay container test):"
echo "  docker run --rm hello-world"
echo
echo "Neu gap loi 'permission denied', logout va login lai WSL:"
echo "  exit"
echo "  wsl --shutdown"
echo "  wsl -d Ubuntu-22.04"
echo
