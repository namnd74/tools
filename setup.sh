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
    if [ -n "$APPDATA" ] && [ -d "$APPDATA/npm" ]; then
        export PATH="$PATH:$APPDATA/npm"
    fi
    # Thêm 7-Zip vào PATH trên Windows nếu có
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
    cmd.exe /c "winget $*" 2>/dev/null
}

# 2. Phát hiện OS & Package Manager
PKG="manual"
[[ "$OSTYPE" == "darwin"* ]] && PKG="brew"
[[ "$OSTYPE" == "msys"* || -n "$WINDIR" ]] && PKG="winget"
[[ -f /etc/debian_version ]] && PKG="apt"
[[ -f /etc/arch-release ]] && PKG="pacman"
info "Môi trường: ${C_G}${OSTYPE}${C_0} (Package Manager: ${C_G}${PKG}${C_0})"

# 3. Flags: --all, --gui-only, --cli-only
INSTALL_CLI=true; INSTALL_GUI=false
[[ "$*" == *"--all"* ]] && { INSTALL_CLI=true; INSTALL_GUI=true; }
[[ "$*" == *"--gui-only"* ]] && { INSTALL_CLI=false; INSTALL_GUI=true; }
[[ "$*" == *"--cli-only"* ]] && { INSTALL_CLI=true; INSTALL_GUI=false; }
if [ "$INSTALL_GUI" = false ] && [ "$INSTALL_CLI" = true ] && [ $# -eq 0 ]; then
    read -r -p "Bạn có muốn cài đặt luôn các ứng dụng Desktop (Claude, ChatGPT, VSCode)? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_GUI=true
fi

# ==============================================================================
# PHẦN 1: DEV RUNTIMES & AI CLI TOOLS
# ==============================================================================
if [ "$INSTALL_CLI" = true ]; then
    info "--- [1/3] Cài đặt Base Tools & Python ---"
    for tool in git curl; do
        has_cmd "$tool" && skip "$tool" || {
            info "Cài đặt $tool..."
            [ "$PKG" = "apt" ] && sudo apt-get install -y "$tool"
            [ "$PKG" = "pacman" ] && sudo pacman -S --noconfirm "$tool"
            [ "$PKG" = "brew" ] && brew install "$tool"
        }
    done

    # Hàm phát hiện Python thực tế (tránh dummy stub của WindowsApps)
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
        [ "$PKG" = "apt" ] && sudo apt-get install -y python3 python3-pip python3-venv
        [ "$PKG" = "brew" ] && brew install python
        # Phát hiện lại PY_CMD sau khi cài đặt
        PY_CMD=$(detect_python || echo "")
    fi

    # NVM & Node.js (Yêu cầu Node >= 22 cho Claude Code)
    info "--- [2/3] Cài đặt NVM & Node.js (>=22) ---"
    export NVM_DIR="$HOME/.nvm"
    [ -d "$NVM_DIR" ] && skip "NVM" || {
        info "Tải NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || true
    }
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

    NODE_VER=$(has_cmd node && node -v | sed 's/v//' | cut -d. -f1 || echo "0")
    if [ "$NODE_VER" -ge 22 ]; then
        skip "Node.js ($(node -v)) & NPM ($(npm -v))"
    else
        info "Cài đặt Node.js v22 qua NVM..."
        command -v nvm >/dev/null 2>&1 && { nvm install 22; nvm use 22; nvm alias default 22; } || warn "Vui lòng cài Node >= 22"
    fi

    refresh_path

    # AI CLI Tools (Claude, Codex, Antigravity)
    info "--- [3/3] Cài đặt AI CLI Tools (Claude, Codex, Antigravity) ---"

    # 1. Claude Code CLI
    if has_cmd claude; then
        skip "Claude Code CLI ($(claude --version 2>/dev/null || echo 'installed'))"
    else
        if has_cmd npm; then
            info "Cài đặt Claude Code CLI (@anthropic-ai/claude-code)..."
            npm install -g @anthropic-ai/claude-code
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
            info "Chạy installer chính thức của OpenAI Codex..."
            if powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://chatgpt.com/codex/install.ps1 | iex"; then
                refresh_path
            else
                warn "Official installer thất bại. Thử qua npm..."
                npm install -g @openai/codex
                refresh_path
            fi
        else
            npm install -g @openai/codex
            refresh_path
        fi

        if has_cmd codex; then
            ok "Codex CLI đã cài đặt thành công: $(codex --version 2>/dev/null || echo 'ready')"
        else
            warn "Codex đã được cài nhưng chưa có trong PATH hiện tại."
            warn "NPM global prefix: $(npm prefix -g 2>/dev/null || echo 'unknown')"
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
            npm install -g @google/antigravity 2>/dev/null || true
            refresh_path
        fi
    fi

    # Cấu hình Shell Profile
    for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
        [ ! -f "$rc" ] && touch "$rc" 2>/dev/null || true
        grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$rc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        if [ -n "$APPDATA" ]; then
            grep -qF 'APPDATA/npm' "$rc" 2>/dev/null || echo 'export PATH="$PATH:$APPDATA/npm"' >> "$rc"
        fi
        grep -qF 'export NVM_DIR="$HOME/.nvm"' "$rc" 2>/dev/null || echo -e '\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$rc"
    done
fi

# ==============================================================================
# PHẦN 2: CÀI ĐẶT DESKTOP APPS (CLAUDE, CHATGPT, VSCODE)
# ==============================================================================
if [ "$INSTALL_GUI" = true ]; then
    info "--- Cài đặt Desktop Apps ---"

    install_desktop_app() {
        local name="$1" win_id="$2" mac_cask="$3"
        if [ "$PKG" = "winget" ]; then
            if win_winget list --id "$win_id" 2>/dev/null | grep -qi "$win_id"; then
                skip "$name"
            else
                info "Đang cài đặt $name qua winget ($win_id)..."
                win_winget install -e --id "$win_id" --accept-package-agreements --accept-source-agreements || {
                    warn "Winget không thể tải $name. Bạn có thể mở web tải trực tiếp."
                }
            fi
        elif [ "$PKG" = "brew" ]; then
            brew list --cask "$mac_cask" 2>/dev/null && skip "$name" || brew install --cask "$mac_cask" || true
        fi
    }

    # 1. Claude Desktop App
    install_desktop_app "Claude Desktop App" "Anthropic.Claude" "claude"

    # 2. ChatGPT Desktop App
    install_desktop_app "ChatGPT Desktop App" "OpenAI.ChatGPT" "chatgpt"

    # 3. Visual Studio Code
    install_desktop_app "Visual Studio Code" "Microsoft.VisualStudioCode" "visual-studio-code"
fi

# ==============================================================================
# TỔNG KẾT
# ==============================================================================
refresh_path
echo -e "\n${C_G}====================================================${C_0}"
echo -e "${C_G}  ✔ HOÀN TẤT THIẾT LẬP!${C_0}"
echo -e "${C_G}====================================================${C_0}"
echo -e "  [CLI Tools]"
has_cmd git && echo -e "  - Git:            $(git --version)"
[ -n "$PY_CMD" ] && echo -e "  - Python:         $($PY_CMD --version 2>&1)"
has_cmd node && echo -e "  - Node.js:        $(node -v)"
has_cmd npm && echo -e "  - NPM:            $(npm -v)"
has_cmd claude && echo -e "  - Claude CLI:     ${C_G}Sẵn sàng (claude)${C_0}"
has_cmd codex && echo -e "  - Codex CLI:      ${C_G}Sẵn sàng (codex: $(codex --version 2>/dev/null || echo 'ok'))${C_0}"
has_cmd agy && echo -e "  - Antigravity:    ${C_G}Sẵn sàng (agy)${C_0}"

if [ "$INSTALL_GUI" = true ]; then
    echo -e "\n  [Desktop Apps]"
    [ -d "$LOCALAPPDATA/AnthropicClaude" ] && echo -e "  - Claude Desktop: ${C_G}Đã cài đặt${C_0}"
    win_winget list --id OpenAI.ChatGPT 2>/dev/null | grep -qi "OpenAI.ChatGPT" && echo -e "  - ChatGPT App:    ${C_G}Đã cài đặt${C_0}"
    has_cmd code && echo -e "  - VS Code:        ${C_G}Sẵn sàng (code)${C_0}"
fi

echo -e "\n${C_Y}Lưu ý:${C_0} Chạy '${C_B}source ~/.bashrc${C_0}' hoặc mở lại Terminal để cập nhật môi trường.\n"
