# 🚀 Dev Setup & Bootstrap Toolset

Bộ công cụ script tự động thiết lập toàn bộ môi trường lập trình, AI Assistant, và các phần mềm ảo hóa khi đổi máy hoặc cài lại hệ điều hành.

---

## 📁 Danh sách các Script

### 1. `setup.sh` - Dev Environment & AI Assistants
Tự động cài đặt:
- **Dev Runtimes**: Git, Python 3, Node.js (>=22 via NVM).
- **AI CLI Tools**: Claude Code CLI, OpenAI Codex CLI (Official Installer), Antigravity CLI.
- **Desktop Apps**: Claude Desktop App, ChatGPT Desktop App, Visual Studio Code.
- **Shell Config**: Tự động cấu hình PATH (`$APPDATA/npm`, `~/.local/bin`) vào `~/.bashrc`, `~/.zshrc`.

```bash
# Chạy cài đặt môi trường lập trình
./setup.sh
```

---

### 2. `setup_vmware.sh` - VMware Workstation 16 Pro
Script chuyên dụng chạy riêng để cài đặt **VMware Workstation 16**:
- Tự động kiểm tra nếu VMware đã cài đặt trước đó -> `[SKIP]`.
- Tự động tải file zip từ `https://devopsedu.vn/wp-content/uploads/2024/02/vmware-workstation-16.zip`.
- Tự động giải nén (hỗ trợ cả `unzip` lẫn `PowerShell Expand-Archive`).
- Tự động đọc và hiển thị file Key / License đi kèm trên màn hình Terminal.
- Tự động kích hoạt file `.exe` cài đặt với quyền **Administrator (UAC)**.

```bash
# Chạy cài đặt VMware Workstation 16
chmod +x setup_vmware.sh
./setup_vmware.sh
```
