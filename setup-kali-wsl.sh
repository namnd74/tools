#!/usr/bin/env bash
# ==============================================================================
# Kali WSL Red Team / TryHackMe Setup
# Run this INSIDE Kali WSL, not in PowerShell.
#
# One-time Windows PowerShell setup (Run as Administrator):
#   wsl --update --web-download
#   wsl --shutdown
#   wsl --install -d kali-linux --web-download
#   wsl --set-default kali-linux
#
# Then enter Kali:
#   wsl -d kali-linux --cd ~
#
# Usage:
#   chmod +x setup-kali-wsl.sh
#   ./setup-kali-wsl.sh
#
# Optional:
#   ./setup-kali-wsl.sh --windows-user Admin
#   ./setup-kali-wsl.sh --ovpn /mnt/c/Users/Admin/Downloads/your-file.ovpn
#   ./setup-kali-wsl.sh --connect
#   ./setup-kali-wsl.sh --ovpn /path/to/file.ovpn --connect
#
# Security:
# - Only use scanning/security tools against systems you own or are authorized
#   to test (e.g. your TryHackMe target).
# - Do not share your .ovpn file.
# ==============================================================================

set -Eeuo pipefail

# ---------- Colors ----------
C_G="\033[32m"
C_B="\033[34m"
C_Y="\033[33m"
C_R="\033[31m"
C_GR="\033[90m"
C_0="\033[0m"

ok()   { echo -e "${C_G}[OK]${C_0} $*"; }
info() { echo -e "${C_B}[INFO]${C_0} $*"; }
warn() { echo -e "${C_Y}[WARN]${C_0} $*"; }
err()  { echo -e "${C_R}[ERROR]${C_0} $*" >&2; }
skip() { echo -e "${C_GR}[SKIP]${C_0} $*"; }

trap 'err "Lỗi tại dòng $LINENO. Command: $BASH_COMMAND"' ERR

# ---------- Args ----------
WINDOWS_USER=""
OVPN_FILE=""
CONNECT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --windows-user)
            WINDOWS_USER="${2:-}"
            shift 2
            ;;
        --ovpn)
            OVPN_FILE="${2:-}"
            shift 2
            ;;
        --connect)
            CONNECT=true
            shift
            ;;
        -h|--help)
            sed -n '1,40p' "$0"
            exit 0
            ;;
        *)
            err "Tham số không hợp lệ: $1"
            exit 1
            ;;
    esac
done

# ---------- Basic checks ----------
if ! grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    warn "Không phát hiện WSL. Script này được thiết kế cho Kali chạy trong WSL."
fi

if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        err "Không có sudo. Hãy chạy script bằng root hoặc cài sudo."
        exit 1
    fi
fi

echo
info "=== 1/5 Kiểm tra môi trường ==="
echo "User     : $(whoami)"
echo "Kernel   : $(uname -r)"
echo "Distro   : $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Unknown}")"

if uname -r | grep -qi 'WSL2'; then
    ok "Đang chạy WSL2"
else
    warn "Không thấy chuỗi WSL2 trong kernel. OpenVPN/TUN có thể bị giới hạn."
fi

# ---------- Install tools ----------
info "=== 2/5 Cài tool cơ bản ==="

PACKAGES=(
    openvpn
    nmap
    git
    curl
    wget
    python3
    python3-pip
    ffuf
    gobuster
    netcat-openbsd
    iproute2
    iputils-ping
    dnsutils
    jq
    unzip
    p7zip-full
)

$SUDO apt-get update

for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        skip "$pkg (đã có)"
    else
        info "Cài $pkg..."
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "$pkg"
    fi
done

echo
ok "OpenVPN: $(openvpn --version 2>/dev/null | head -n1 || echo 'không tìm thấy')"
ok "Nmap:    $(nmap --version 2>/dev/null | head -n1 || echo 'không tìm thấy')"
ok "Python:  $(python3 --version 2>/dev/null || echo 'không tìm thấy')"

# ---------- Check TUN ----------
info "=== 3/5 Kiểm tra /dev/net/tun ==="

if [[ -c /dev/net/tun ]]; then
    ok "/dev/net/tun tồn tại"
    ls -l /dev/net/tun
else
    err "/dev/net/tun không tồn tại."
    echo "Trong PowerShell Administrator thử:"
    echo "  wsl --shutdown"
    echo "Sau đó mở lại Kali và chạy script lại."
    exit 1
fi

# ---------- Detect Windows user / .ovpn ----------
info "=== 4/5 Tìm file TryHackMe .ovpn ==="

if [[ -z "$WINDOWS_USER" ]]; then
    # Prefer the current Windows USERNAME if visible through powershell.exe
    if command -v powershell.exe >/dev/null 2>&1; then
        WINDOWS_USER="$(
            powershell.exe -NoProfile -Command '[Environment]::UserName' 2>/dev/null \
            | tr -d '\r' | tail -n1
        )"
    fi
fi

if [[ -n "$WINDOWS_USER" ]]; then
    info "Windows user: $WINDOWS_USER"
fi

if [[ -z "$OVPN_FILE" && -n "$WINDOWS_USER" ]]; then
    SEARCH_DIRS=(
        "/mnt/c/Users/$WINDOWS_USER/Downloads"
        "/mnt/c/Users/$WINDOWS_USER/Desktop"
        "/mnt/c/Users/$WINDOWS_USER/Documents"
    )

    for d in "${SEARCH_DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        candidate="$(find "$d" -maxdepth 2 -type f -iname '*.ovpn' -print -quit 2>/dev/null || true)"
        if [[ -n "$candidate" ]]; then
            OVPN_FILE="$candidate"
            break
        fi
    done
fi

LOCAL_OVPN="$HOME/tryhackme.ovpn"

if [[ -n "$OVPN_FILE" && -f "$OVPN_FILE" ]]; then
    info "Tìm thấy VPN config: $OVPN_FILE"
    cp -f "$OVPN_FILE" "$LOCAL_OVPN"
    chmod 600 "$LOCAL_OVPN"
    ok "Đã copy vào: $LOCAL_OVPN"
else
    warn "Chưa tìm thấy file .ovpn."
    echo
    echo "Tải file VPN từ TryHackMe bằng browser Windows, rồi chạy lại ví dụ:"
    echo "  ./setup-kali-wsl.sh --ovpn /mnt/c/Users/Admin/Downloads/your-file.ovpn"
    echo
    echo "Hoặc tìm file từ Kali:"
    echo "  find /mnt/c/Users -maxdepth 4 -type f -iname '*.ovpn' 2>/dev/null"
fi

# ---------- Connect ----------
info "=== 5/5 TryHackMe VPN ==="

if [[ "$CONNECT" == true ]]; then
    if [[ ! -f "$LOCAL_OVPN" ]]; then
        err "--connect được yêu cầu nhưng chưa có $LOCAL_OVPN"
        exit 1
    fi

    echo
    warn "OpenVPN sẽ chạy foreground. Giữ terminal này mở."
    echo "Mở terminal Kali thứ hai để kiểm tra:"
    echo "  ip addr show tun0"
    echo "  ip route"
    echo
    exec $SUDO openvpn --config "$LOCAL_OVPN"
else
    if [[ -f "$LOCAL_OVPN" ]]; then
        echo
        echo "Để kết nối TryHackMe:"
        echo "  sudo openvpn --config ~/tryhackme.ovpn"
        echo
        echo "Hoặc:"
        echo "  ./setup-kali-wsl.sh --connect"
    fi
fi

echo
echo -e "${C_G}====================================================${C_0}"
echo -e "${C_G}  ✔ KALI WSL SETUP HOÀN TẤT${C_0}"
echo -e "${C_G}====================================================${C_0}"
echo
echo "PowerShell lần sau vào Kali:"
echo "  wsl -d kali-linux --cd ~"
echo
echo "Đặt Kali làm WSL mặc định (PowerShell):"
echo "  wsl --set-default kali-linux"
echo
echo "Sau khi kết nối VPN thành công, kiểm tra:"
echo "  ip addr show tun0"
echo "  ip route"
echo
echo "Backup Kali WSL (chạy từ PowerShell sau khi 'wsl --shutdown'):"
echo "  wsl --export kali-linux C:\\kali-redteam.tar"
echo
