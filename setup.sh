#!/usr/bin/env bash
# ==============================================================================
# Fast & Clean Dev Setup (Windows / macOS / Linux)
# ==============================================================================
set -eo pipefail

# 1. Colors & Helpers
C_G="\033[32m" C_B="\033[34m" C_Y="\033[33m" C_R="\033[31m" C_GR="\033[90m" C_0="\033[0m"
ok()   { echo -e "${C_G}[OK]${C_0} $1"; }
info() { echo -e "${C_B}[INFO]${C_0} $1"; }
skip() { echo -e "${C_GR}[SKIP]${C_0} $1 (đã có)"; }
warn() { echo -e "${C_Y}[WARN]${C_0} $1"; }
err()  { echo -e "${C_R}[ERR]${C_0} $1"; }

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Cập nhật lại PATH và xóa cache lệnh trong phiên hiện tại
refresh_path() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 2>/dev/null || true

    if [ -n "$APPDATA" ] && [ -d "$APPDATA/nvm" ]; then
        export PATH="$PATH:$APPDATA/nvm"
    fi
    if [ -d "/c/Program Files/nodejs" ]; then
        export PATH="/c/Program Files/nodejs:$PATH"
    elif [ -d "C:\\Program Files\\nodejs" ]; then
        export PATH="C:\\Program Files\\nodejs:$PATH"
    fi
    if [ -n "$APPDATA" ] && [ -d "$APPDATA/npm" ]; then
        export PATH="$PATH:$APPDATA/npm"
    fi
    if [ -n "$LOCALAPPDATA" ] && [ -d "$LOCALAPPDATA/agy/bin" ]; then
        export PATH="$PATH:$LOCALAPPDATA/agy/bin"
    fi
    if [ -d "$HOME/AppData/Local/agy/bin" ]; then
        export PATH="$PATH:$HOME/AppData/Local/agy/bin"
    fi
    if [ -n "$LOCALAPPDATA" ] && [ -d "$LOCALAPPDATA/pnpm" ]; then
        export PATH="$PATH:$LOCALAPPDATA/pnpm:$LOCALAPPDATA/pnpm/bin"
    fi
    if [ -d "$HOME/AppData/Local/pnpm" ]; then
        export PATH="$PATH:$HOME/AppData/Local/pnpm:$HOME/AppData/Local/pnpm/bin"
    fi
    if [ -d "$HOME/.local/share/pnpm" ]; then
        export PNPM_HOME="$HOME/.local/share/pnpm"
        export PATH="$PNPM_HOME:$PATH"
    fi
    if [ -d "/c/Program Files/7-Zip" ]; then
        export PATH="$PATH:/c/Program Files/7-Zip"
    elif [ -d "C:\\Program Files\\7-Zip" ]; then
        export PATH="$PATH:C:\\Program Files\\7-Zip"
    fi
    export PATH="$PATH:$HOME/.local/bin"
    hash -r 2>/dev/null || true
}

# Wrapper chạy winget trên Windows qua cmd.exe (tránh lỗi Permission Denied trong Git Bash)
win_winget() {
    cmd.exe /c "winget $*" 2>/dev/null || return 1
}

# 2. Phát hiện OS & Package Manager
PKG="manual"
[[ "$OSTYPE" == "darwin"* ]] && PKG="brew"
[[ "$OSTYPE" == "msys"* || -n "$WINDIR" ]] && PKG="winget"
[[ -f /etc/debian_version ]] && PKG="apt"
[[ -f /etc/arch-release ]] && PKG="pacman"
info "Môi trường: ${C_G}${OSTYPE}${C_0} (Package Manager: ${C_G}${PKG}${C_0})"

refresh_path

# ==============================================================================
# PHẦN 1: DEV RUNTIMES & BASE TOOLS (GIT, CURL, PYTHON)
# ==============================================================================
info "--- [1/3] Cài đặt & Nâng cấp Git, Base Tools & Python ---"

# 1. Git (Luôn nâng cấp / upgrade thay vì skip)
if has_cmd git; then
    info "Đang kiểm tra & nâng cấp Git lên phiên bản mới nhất..."
    if [ "$PKG" = "winget" ]; then
        win_winget upgrade --id Git.Git --accept-package-agreements --accept-source-agreements 2>/dev/null || true
    elif [ "$PKG" = "brew" ]; then
        brew upgrade git 2>/dev/null || true
    elif [ "$PKG" = "apt" ]; then
        sudo apt-get update -y 2>/dev/null && sudo apt-get install --only-upgrade -y git 2>/dev/null || true
    elif [ "$PKG" = "pacman" ]; then
        sudo pacman -S --noconfirm git 2>/dev/null || true
    fi
    ok "Git: $(git --version 2>/dev/null || echo 'ready')"
else
    info "Cài đặt Git..."
    if [ "$PKG" = "winget" ]; then
        win_winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements || true
    elif [ "$PKG" = "brew" ]; then
        brew install git || true
    elif [ "$PKG" = "apt" ]; then
        sudo apt-get update -y && sudo apt-get install -y git || true
    elif [ "$PKG" = "pacman" ]; then
        sudo pacman -S --noconfirm git || true
    fi
    refresh_path
    has_cmd git && ok "Git: $(git --version 2>/dev/null || echo 'ready')" || warn "Chưa tìm thấy Git sau khi cài đặt"
fi

# 2. Curl
if has_cmd curl; then
    skip "curl"
else
    info "Cài đặt curl..."
    [ "$PKG" = "winget" ] && win_winget install -e --id cURL.cURL --accept-package-agreements --accept-source-agreements || true
    [ "$PKG" = "apt" ] && sudo apt-get install -y curl || true
    [ "$PKG" = "pacman" ] && sudo pacman -S --noconfirm curl || true
    [ "$PKG" = "brew" ] && brew install curl || true
fi

# 3. Python
detect_python() {
    for c in py python python3; do
        if command -v "$c" >/dev/null 2>&1 && "$c" -c "import sys" 2>/dev/null; then
            echo "$c"
            return 0
        fi
    done
    return 1
}

PY_CMD=$(detect_python || echo "")
if [ -n "$PY_CMD" ]; then
    skip "Python ($($PY_CMD --version 2>&1))"
else
    info "Cài đặt Python 3..."
    [ "$PKG" = "winget" ] && win_winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements || true
    [ "$PKG" = "apt" ] && sudo apt-get install -y python3 python3-pip python3-venv || true
    [ "$PKG" = "pacman" ] && sudo pacman -S --noconfirm python python-pip || true
    [ "$PKG" = "brew" ] && brew install python || true
    PY_CMD=$(detect_python || echo "")
fi

# ==============================================================================
# PHẦN 2: NODE.JS & NVM
# ==============================================================================
info "--- [2/3] Cài đặt & Cấu hình NVM, Node.js (>= 22.23) & Alias ---"

# 1. Cài đặt / Tải NVM nếu chưa có
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
fi

if ! has_cmd nvm && [ ! -s "$NVM_DIR/nvm.sh" ]; then
    info "Cài đặt NVM (Node Version Manager)..."
    if [ "$PKG" = "winget" ]; then
        win_winget install -e --id CoreyButler.NVMforWindows --accept-package-agreements --accept-source-agreements 2>/dev/null || true
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh 2>/dev/null | bash 2>/dev/null || true
    elif [ "$PKG" = "brew" ]; then
        brew install nvm 2>/dev/null || curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 2>/dev/null || true
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || true
    fi
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
    refresh_path
fi

# 2. Kiểm tra phiên bản Node hiện tại
get_node_major() {
    has_cmd node && node -v 2>/dev/null | tr -d 'v' | cut -d. -f1 || echo "0"
}
get_node_minor() {
    has_cmd node && node -v 2>/dev/null | tr -d 'v' | cut -d. -f2 || echo "0"
}

is_node_valid() {
    local maj min
    maj=$(get_node_major)
    min=$(get_node_minor)
    if [ "$maj" -gt 22 ]; then
        return 0
    elif [ "$maj" -eq 22 ] && [ "$min" -ge 23 ]; then
        return 0
    fi
    return 1
}

# 3. Cài đặt Node 22 (>= 22.23) và cấu hình default alias
if is_node_valid; then
    skip "Node.js ($(node -v 2>/dev/null)) & NPM ($(npm -v 2>/dev/null || echo 'ok')) [>= 22.23]"
else
    info "Đang cài đặt Node.js 22 (>= 22.23) qua NVM..."
    if command -v nvm >/dev/null 2>&1 || [ -s "$NVM_DIR/nvm.sh" ]; then
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
        nvm install 22 || true
        nvm use 22 || true
        nvm alias default 22 2>/dev/null || true
        nvm alias node 22 2>/dev/null || true
    elif has_cmd nvm.exe || [ -f "$APPDATA/nvm/nvm.exe" ]; then
        cmd.exe /c "nvm install 22 && nvm use 22" 2>/dev/null || true
    elif [ "$PKG" = "winget" ]; then
        win_winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements || true
    elif [ "$PKG" = "brew" ]; then
        brew install node || true
    fi
    refresh_path
fi

# Đảm bảo set alias default cho nvm
if command -v nvm >/dev/null 2>&1; then
    nvm alias default 22 >/dev/null 2>&1 || true
    nvm alias node 22 >/dev/null 2>&1 || true
fi

has_cmd node && ok "Node.js: $(node -v 2>/dev/null) | NPM: $(npm -v 2>/dev/null || echo 'ok')" || warn "Chưa tìm thấy Node.js sau khi cài đặt"

# 4. Cài đặt PNPM
if has_cmd pnpm; then
    skip "PNPM ($(pnpm -v 2>/dev/null || echo 'ok'))"
else
    info "Cài đặt PNPM..."
    if [ "$PKG" = "winget" ]; then
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb https://get.pnpm.io/install.ps1 | iex" 2>/dev/null || {
            has_cmd npm && npm install -g pnpm 2>/dev/null || true
        }
    elif has_cmd curl; then
        curl -fsSL https://get.pnpm.io/install.sh | sh - 2>/dev/null || {
            has_cmd npm && npm install -g pnpm 2>/dev/null || true
        }
    elif has_cmd npm; then
        npm install -g pnpm 2>/dev/null || true
    fi
    refresh_path
    has_cmd pnpm && ok "PNPM: $(pnpm -v 2>/dev/null || echo 'ready')" || warn "Chưa tìm thấy pnpm trong PATH"
fi

refresh_path

# ==============================================================================
# PHẦN 3: AI CLI TOOLS (CLAUDE, CODEX, ANTIGRAVITY)
# ==============================================================================
info "--- [3/3] Cài đặt AI CLI Tools (Claude, Codex, Antigravity) ---"

# 1. Claude Code CLI
if has_cmd claude; then
    skip "Claude Code CLI ($(claude --version 2>/dev/null || echo 'installed'))"
else
    if has_cmd npm; then
        info "Cài đặt Claude Code CLI (@anthropic-ai/claude-code)..."
        npm install -g @anthropic-ai/claude-code || true
        refresh_path
        has_cmd claude && ok "Claude Code CLI: $(claude --version 2>/dev/null || echo 'ready')" || warn "Chưa tìm thấy lệnh 'claude' trong PATH"
    else
        warn "NPM không khả dụng, bỏ qua Claude Code CLI"
    fi
fi

# 2. Codex CLI (OpenAI Official Installer on Windows / NPM Fallback)
if has_cmd codex; then
    skip "Codex CLI ($(codex --version 2>/dev/null || echo 'installed'))"
else
    info "Cài đặt OpenAI Codex CLI..."
    if [ "$PKG" = "winget" ]; then
        info "Chạy installer OpenAI Codex qua PowerShell..."
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://chatgpt.com/codex/install.ps1 | iex" 2>/dev/null || {
            warn "PowerShell installer không thành công. Thử cài đặt qua npm..."
            npm install -g @openai/codex || true
        }
        refresh_path
    else
        npm install -g @openai/codex || true
        refresh_path
    fi

    if has_cmd codex; then
        ok "Codex CLI: $(codex --version 2>/dev/null || echo 'ready')"
    else
        warn "Codex CLI chưa tìm thấy trong PATH hiện tại (có thể cần mở lại terminal)."
    fi
fi

# 3. OpenAI Python SDK
if [ -n "$PY_CMD" ]; then
    if "$PY_CMD" -m pip show openai >/dev/null 2>&1; then
        skip "OpenAI Python package"
    else
        info "Cài đặt OpenAI Python SDK..."
        "$PY_CMD" -m pip install --user openai >/dev/null 2>&1 || true
    fi
fi

# 4. Antigravity CLI (agy)
if has_cmd agy; then
    skip "Antigravity CLI (agy)"
else
    if has_cmd npm; then
        info "Cài đặt Antigravity CLI (@google/antigravity)..."
        npm install -g @google/antigravity 2>/dev/null || true
        refresh_path
    fi
    if has_cmd agy; then
        ok "Antigravity CLI (agy): sẵn sàng"
    else
        warn "Antigravity CLI (agy) chưa có trong PATH"
    fi
fi

# Cấu hình Shell Profile
for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
    [ ! -f "$rc" ] && touch "$rc" 2>/dev/null || true
    grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$rc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    if [ -n "$APPDATA" ]; then
        grep -qF 'APPDATA/npm' "$rc" 2>/dev/null || echo 'export PATH="$PATH:$APPDATA/npm"' >> "$rc"
        grep -qF 'APPDATA/nvm' "$rc" 2>/dev/null || echo 'export PATH="$PATH:$APPDATA/nvm"' >> "$rc"
    fi
    if [ -n "$LOCALAPPDATA" ] && [ -d "$LOCALAPPDATA/pnpm" ]; then
        grep -qF 'LOCALAPPDATA/pnpm' "$rc" 2>/dev/null || echo 'export PATH="$PATH:$LOCALAPPDATA/pnpm:$LOCALAPPDATA/pnpm/bin"' >> "$rc"
    fi
    if [ -d "$HOME/.local/share/pnpm" ]; then
        grep -qF 'export PNPM_HOME=' "$rc" 2>/dev/null || echo -e '\nexport PNPM_HOME="$HOME/.local/share/pnpm"\nexport PATH="$PNPM_HOME:$PATH"' >> "$rc"
    fi
    if [ -d "/c/Program Files/nodejs" ] || [ -d "C:\\Program Files\\nodejs" ]; then
        grep -qF 'Program Files/nodejs' "$rc" 2>/dev/null || echo 'export PATH="/c/Program Files/nodejs:$PATH"' >> "$rc"
    fi
    if [ -d "$HOME/AppData/Local/agy/bin" ]; then
        grep -qF 'agy/bin' "$rc" 2>/dev/null || echo 'export PATH="$PATH:$HOME/AppData/Local/agy/bin"' >> "$rc"
    fi
    grep -qF 'export NVM_DIR="$HOME/.nvm"' "$rc" 2>/dev/null || echo -e '\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$rc"
    grep -qF 'alias node22=' "$rc" 2>/dev/null || echo 'alias node22="nvm use 22"' >> "$rc"
    grep -qF 'alias node-lts=' "$rc" 2>/dev/null || echo 'alias node-lts="nvm use --lts"' >> "$rc"
done

# ==============================================================================
# TỔNG KẾT
# ==============================================================================
refresh_path
echo -e "\n${C_G}====================================================${C_0}"
echo -e "${C_G}  ✔ HOÀN TẤT THIẾT LẬP!${C_0}"
echo -e "${C_G}====================================================${C_0}"
echo -e "  [CLI Tools]"
has_cmd git && echo -e "  - Git:            $(git --version 2>/dev/null)"
[ -n "$PY_CMD" ] && echo -e "  - Python:         $($PY_CMD --version 2>&1)"
has_cmd node && echo -e "  - Node.js:        $(node -v 2>/dev/null)"
has_cmd npm && echo -e "  - NPM:            $(npm -v 2>/dev/null)"
has_cmd pnpm && echo -e "  - PNPM:           $(pnpm -v 2>/dev/null)"
has_cmd claude && echo -e "  - Claude CLI:     ${C_G}Sẵn sàng (claude)${C_0}"
has_cmd codex && echo -e "  - Codex CLI:      ${C_G}Sẵn sàng (codex: $(codex --version 2>/dev/null || echo 'ok'))${C_0}"
has_cmd agy && echo -e "  - Antigravity:    ${C_G}Sẵn sàng (agy)${C_0}"

echo -e "\n${C_Y}Lưu ý:${C_0} Chạy '${C_B}source ~/.bashrc${C_0}' hoặc mở lại Terminal để cập nhật môi trường.\n"
