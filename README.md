# 🚀 Dev Setup & Bootstrap Toolset

Bộ công cụ script tự động thiết lập toàn bộ môi trường lập trình, AI Assistant, NVM + Node.js 22+, PNPM, và các phần mềm ảo hóa khi đổi máy hoặc cài lại hệ điều hành.

---

## 📁 Danh sách các Script

### 1. `setup.sh` - Dev Environment & AI CLI Assistants (Cross-platform)
Tự động cài đặt & cấu hình:
- **Dev Runtimes**: 
  - Git (tự động cập nhật / upgrade bản mới nhất).
  - Python 3 & pip.
  - **NVM (Node Version Manager) & Node.js 22+ (>= 22.23)**: Tự động cài đặt NVM, tải bản Node.js 22 LTS mới nhất, set alias `default 22` và thiết lập alias trong shell profile (`node22`, `node-lts`).
  - **PNPM**: Trình quản lý gói cực nhanh, tự động cài đặt và nạp `PNPM_HOME` vào PATH.
- **AI CLI Tools**: Claude Code CLI, OpenAI Codex CLI (Official Installer), Antigravity CLI (`agy`).
- **Shell Config**: Tự động cấu hình PATH và môi trường vào `~/.bashrc`, `~/.bash_profile`, `~/.zshrc`.

```bash
# Chạy cài đặt môi trường lập trình
chmod +x setup.sh
./setup.sh
```

---

### 2. `Install-NVM-Node.bat` / `Install-NVM-Node.ps1` - Cài đặt NVM, Node.js 22.23+ & PNPM (Windows 1-Click)
Script chuyên dụng cho Windows (tự động xin quyền Administrator):
- Cài đặt **NVM for Windows** qua winget (`CoreyButler.NVMforWindows`).
- Tự động nạp biến môi trường (`NVM_HOME`, `NVM_SYMLINK`, `PATH`).
- Cài đặt **Node.js 22 (>= 22.23)**: `nvm install 22`.
- Kích hoạt và đặt làm mặc định: `nvm use 22`.
- Cài đặt **PNPM** (`@pnpm/exe`).
- Cấu hình alias trong PowerShell profile (`node22`, `node-lts`).

```cmd
:: Chạy file .bat (Click đúp chuột hoặc chạy từ cmd)
Install-NVM-Node.bat
```

---

### 3. `Update-Git.bat` / `Update-Git.ps1` - Nâng cấp Git mới nhất (Windows 1-Click)
Tự động tắt các tiến trình git đang chạy để tránh khóa file và nâng cấp Git qua winget.

```cmd
Update-Git.bat
```

---

### 4. `setup_vmware.sh` - VMware Workstation 16 Pro
Script chuyên dụng chạy riêng để cài đặt **VMware Workstation 16**:
- Tự động kiểm tra nếu VMware đã cài đặt trước đó -> `[SKIP]`.
- Tự động tải file zip, giải nén, đọc License Key và kích hoạt cài đặt với quyền Administrator (UAC).

```bash
chmod +x setup_vmware.sh
./setup_vmware.sh
```

---

### 5. `setup-kali-wsl.sh` - Kali WSL Setup & TryHackMe VPN
Thiết lập môi trường Kali Linux trên WSL2 kèm các công cụ Pentest / Red Team cơ bản và cấu hình OpenVPN TryHackMe.

```bash
chmod +x setup-kali-wsl.sh
./setup-kali-wsl.sh
```
