#!/usr/bin/env bash
# ==============================================================================
# Setup VMware Workstation 16 (Tải, Giải nén & Cài đặt)
# ==============================================================================
set -eo pipefail

# 1. Colors & Logging Helpers
C_G="\033[32m" C_B="\033[34m" C_Y="\033[33m" C_R="\033[31m" C_GR="\033[90m" C_0="\033[0m" C_C="\033[36m"
ok()   { echo -e "${C_G}[OK]${C_0} $1"; }
info() { echo -e "${C_B}[INFO]${C_0} $1"; }
skip() { echo -e "${C_GR}[SKIP]${C_0} $1"; }
warn() { echo -e "${C_Y}[WARN]${C_0} $1"; }
err()  { echo -e "${C_R}[ERR]${C_0} $1"; }

echo -e "\n${C_C}====================================================${C_0}"
echo -e "${C_C}  🚀 CÀI ĐẶT VMWARE WORKSTATION 16${C_0}"
echo -e "${C_C}====================================================${C_0}\n"

# 2. Kiểm tra VMware đã được cài đặt trước đó chưa
VMWARE_PATHS=(
    "/c/Program Files (x86)/VMware/VMware Workstation/vmware.exe"
    "/c/Program Files/VMware/VMware Workstation/vmware.exe"
    "C:\\Program Files (x86)\\VMware\\VMware Workstation\\vmware.exe"
    "C:\\Program Files\\VMware\\VMware Workstation\\vmware.exe"
)

for p in "${VMWARE_PATHS[@]}"; do
    if [ -f "$p" ]; then
        skip "VMware Workstation đã được cài đặt tại: $p"
        echo -e "\n${C_G}✔ VMware đã có sẵn trên máy của bạn.${C_0}\n"
        exit 0
    fi
done

# 3. Định nghĩa đường dẫn tải & giải nén
ZIP_URL="https://devopsedu.vn/wp-content/uploads/2024/02/vmware-workstation-16.zip"
DOWNLOAD_DIR="./downloads"
ZIP_FILE="$DOWNLOAD_DIR/vmware-workstation-16.zip"
EXTRACT_DIR="$DOWNLOAD_DIR/vmware-workstation-16"

mkdir -p "$DOWNLOAD_DIR"

# 4. Tải file ZIP
if [ -f "$ZIP_FILE" ]; then
    skip "File ZIP đã tồn tại: $ZIP_FILE"
else
    info "Đang tải VMware Workstation 16 từ máy chủ..."
    info "URL: $ZIP_URL"
    if command -v curl >/dev/null 2>&1; then
        curl -fL -# -o "$ZIP_FILE" "$ZIP_URL"
    else
        powershell.exe -NoProfile -Command "
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri '$ZIP_URL' -OutFile '$ZIP_FILE'
        "
    fi
    ok "Đã tải xong file ZIP ($ZIP_FILE)"
fi

# 5. Giải nén file ZIP
if [ -d "$EXTRACT_DIR" ] && [ "$(ls -A "$EXTRACT_DIR" 2>/dev/null)" ]; then
    skip "Thư mục giải nén đã tồn tại: $EXTRACT_DIR"
else
    info "Đang giải nén file $ZIP_FILE..."
    # Nạp đường dẫn 7-Zip nếu có
    [ -d "/c/Program Files/7-Zip" ] && export PATH="$PATH:/c/Program Files/7-Zip"
    
    if command -v 7z >/dev/null 2>&1; then
        info "Giải nén nhanh bằng 7-Zip (7z)..."
        7z x -y -o"$EXTRACT_DIR" "$ZIP_FILE" >/dev/null
    elif command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$ZIP_FILE" -d "$EXTRACT_DIR"
    else
        powershell.exe -NoProfile -Command "
            Expand-Archive -Path '$ZIP_FILE' -DestinationPath '$EXTRACT_DIR' -Force
        "
    fi
    ok "Đã giải nén thành công vào $EXTRACT_DIR"
fi

# 6. Tìm kiếm file cài đặt .exe và file License/Key
INSTALLER_EXE=$(find "$EXTRACT_DIR" -type f \( -iname "*vmware*.exe" -o -iname "*setup*.exe" -o -iname "*.exe" \) | head -n 1)
KEY_FILE=$(find "$EXTRACT_DIR" -type f \( -iname "*key*.txt" -o -iname "*license*.txt" -o -iname "*read*.txt" -o -iname "*.txt" \) | head -n 1)

if [ -n "$KEY_FILE" ]; then
    echo -e "\n${C_Y}====================================================${C_0}"
    echo -e "${C_Y}  🔑 THÔNG TIN LICENSE / KEY ĐI KÈM:${C_0}"
    echo -e "${C_Y}====================================================${C_0}"
    cat "$KEY_FILE"
    echo -e "${C_Y}====================================================${C_0}\n"
fi

# 7. Khởi chạy cài đặt với quyền Administrator
if [ -n "$INSTALLER_EXE" ]; then
    info "Tìm thấy bộ cài: $INSTALLER_EXE"
    info "Đang khởi chạy trình cài đặt VMware với quyền Administrator (UAC)..."
    
    # Chuyển đổi đường dẫn sang dạng Windows path
    if command -v cygpath >/dev/null 2>&1; then
        WIN_EXE_PATH=$(cygpath -w "$INSTALLER_EXE")
    else
        WIN_EXE_PATH="$INSTALLER_EXE"
    fi

    # Kích hoạt UAC Administrator để cài đặt VMware không bị lỗi quyền
    powershell.exe -NoProfile -Command "
        Start-Process -FilePath '$WIN_EXE_PATH' -Verb RunAs
    "
    ok "Đã khởi chạy trình cài đặt VMware Workstation 16!"
    echo -e "\n${C_G}👉 Vui lòng làm theo hướng dẫn trên màn hình cài đặt của VMware.${C_0}\n"
else
    err "Không tìm thấy file cài đặt .exe trong thư mục giải nén ($EXTRACT_DIR)."
    exit 1
fi
