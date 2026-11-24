# Auto Install Developer Tools (Arch Linux)

An all-in-one automated setup script to configure a local web development environment on Arch Linux-based distributions (Arch, EndeavourOS, Manjaro, CachyOS, etc.).

## Installed Packages
- **Web Server:** Apache (`httpd`) with `mod_rewrite` & `AllowOverride All` enabled
- **Database:** MariaDB with basic security configuration
- **Languages & Runtimes:** PHP (latest stable version + common extensions), Node.js & npm
- **Database Manager:** phpMyAdmin
- **Tools:** Visual Studio Code (Code - OSS), Git, Composer

---

## Prerequisites
- An **Arch Linux-based** operating system (`pacman` available).
- Active internet connection.
- **root / sudo** privileges.

---

## How to Run

1. **Clone this repository:**
   ```bash
   git clone <your-repository-url>
   cd <repository-folder-name>
   ```
   *(If you downloaded the script file directly, skip to step 2).*

2. **Make the script executable:**
   ```bash
   chmod +x install.sh
   ```
   *(Replace `install.sh` with your actual script filename).*

3. **Run the script as root:**
   ```bash
   sudo ./install.sh
   ```

4. Wait for the installation and configuration to complete.

---

## Default Access & Credentials

Once the installation finishes, you can access the services using:

| Service | Address / Value |
|---|---|
| **Local Server** | `http://localhost` |
| **Document Root** | `/srv/http` |
| **phpMyAdmin** | `http://localhost/phpmyadmin` |
| **MariaDB User** | `root` |
| **MariaDB Password** | `root` |

---

## Important Notes
- **Local Development Only:** The MariaDB `root` password is set to `root` by default. Do not use this configuration on a public or production server.
- **VS Code Version:** The `code` package from the official Arch repository installs **Code - OSS**. If you need the official Microsoft build, install it from the AUR as a regular user (`yay -S visual-studio-code-bin`).
- **PHP & Node.js Versions:** Follows Arch Linux's rolling release model (always the latest stable versions). For multi-version setups, consider using `nvm`/`fnm` for Node.js or `php-legacy`/AUR packages for PHP.