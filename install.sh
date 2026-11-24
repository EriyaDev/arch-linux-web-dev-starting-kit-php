#!/bin/bash
set -e

# Script Auto Install All-in-One untuk Developer (Arch Linux based)

echo -e "\033[1;36m"
echo "╔══════════════════════════════════════════════════╗"
echo "║           AUTO INSTALL DEVELOPER TOOLS           ║"
echo "║      PHP • APACHE • MARIADB • phpMyAdmin         ║"
echo "║      VS Code • Git • Composer • Node.js          ║"
echo "║                 (Arch Linux)                     ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "\033[0m"

sleep 2

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[1;31mPlease run as root (use sudo)\033[0m"
    exit 1
fi

# Check pacman
if ! command -v pacman >/dev/null 2>&1; then
    echo -e "\033[1;31mpacman not found. Script ini khusus Arch-based.\033[0m"
    exit 1
fi

HTTPD_CONF="/etc/httpd/conf/httpd.conf"
PHP_INI="/etc/php/php.ini"

# Update system
echo -e "\033[1;33m[1/10] Updating system packages...\033[0m"
pacman -Syu --noconfirm

# Install Apache
echo -e "\033[1;33m[2/10] Installing Apache Web Server...\033[0m"
pacman -S --needed --noconfirm apache
systemctl enable httpd
systemctl start httpd

# Install MariaDB (pengganti MySQL di Arch)
echo -e "\033[1;33m[3/10] Installing MariaDB Database Server...\033[0m"
pacman -S --needed --noconfirm mariadb
if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi
systemctl enable mariadb
systemctl start mariadb

# Secure MariaDB installation
echo -e "\033[1;33mSecuring MariaDB installation...\033[0m"
mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';"
mariadb -uroot -proot -e "DROP USER IF EXISTS ''@'localhost';"
mariadb -uroot -proot -e "DROP USER IF EXISTS ''@'$(hostname)';"
mariadb -uroot -proot -e "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mariadb -uroot -proot -e "DROP DATABASE IF EXISTS test;"
mariadb -uroot -proot -e "FLUSH PRIVILEGES;"

# Install PHP and extensions
echo -e "\033[1;33m[4/10] Installing PHP and extensions...\033[0m"
pacman -S --needed --noconfirm php php-apache php-gd php-sodium

# Enable PHP extensions (di Arch ekstensi harus di-uncomment manual di php.ini)
sed -i -E 's/^;(extension=(mysqli|pdo_mysql|gd|iconv|zip|curl|intl|bcmath|exif|sodium))$/\1/' "$PHP_INI"

# Konfigurasi Apache untuk mod_php (wajib MPM prefork)
sed -i 's/^LoadModule mpm_event_module/#LoadModule mpm_event_module/' "$HTTPD_CONF"
sed -i 's/^#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' "$HTTPD_CONF"
# mod_rewrite (dibutuhkan Laravel / .htaccess)
sed -i 's/^#LoadModule rewrite_module/LoadModule rewrite_module/' "$HTTPD_CONF"
# Hilangkan warning ServerName
grep -q "^ServerName" "$HTTPD_CONF" || echo "ServerName localhost" >> "$HTTPD_CONF"

if ! grep -q "libphp.so" "$HTTPD_CONF"; then
    # LoadModule php harus setelah LoadModule lain
    LAST_LOAD=$(grep -n "^LoadModule" "$HTTPD_CONF" | tail -n1 | cut -d: -f1)
    sed -i "${LAST_LOAD}a LoadModule php_module modules/libphp.so\nAddHandler php-script .php" "$HTTPD_CONF"
    echo "Include conf/extra/php_module.conf" >> "$HTTPD_CONF"
fi

# Izinkan .htaccess di document root (/srv/http)
if ! grep -q "# devkit-allowoverride" "$HTTPD_CONF"; then
    cat >> "$HTTPD_CONF" <<'EOF'

# devkit-allowoverride
<Directory "/srv/http">
    AllowOverride All
</Directory>
EOF
fi

# Install phpMyAdmin
echo -e "\033[1;33m[5/10] Installing phpMyAdmin...\033[0m"
pacman -S --needed --noconfirm phpmyadmin

# Set blowfish secret (wajib agar phpMyAdmin tidak error)
BLOWFISH=$(openssl rand -hex 16)
sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg['blowfish_secret'] = '${BLOWFISH}';/" /etc/webapps/phpmyadmin/config.inc.php

# Configure phpMyAdmin with Apache
cat > /etc/httpd/conf/extra/phpmyadmin.conf <<'EOF'
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.php
    AllowOverride All
    Options FollowSymlinks
    Require all granted
</Directory>
EOF
grep -q "extra/phpmyadmin.conf" "$HTTPD_CONF" || echo "Include conf/extra/phpmyadmin.conf" >> "$HTTPD_CONF"
systemctl restart httpd

# Install Visual Studio Code
# Catatan: 'code' di repo resmi Arch adalah Code - OSS (build open source).
# Untuk versi Microsoft, install dari AUR sebagai user biasa: yay -S visual-studio-code-bin
echo -e "\033[1;33m[6/10] Installing Visual Studio Code (Code - OSS)...\033[0m"
pacman -S --needed --noconfirm code

# Install Git
echo -e "\033[1;33m[7/10] Installing Git...\033[0m"
pacman -S --needed --noconfirm git

# Install Composer
echo -e "\033[1;33m[8/10] Installing Composer...\033[0m"
pacman -S --needed --noconfirm composer

# Install Node.js & npm
echo -e "\033[1;33m[9/10] Installing Node.js and npm...\033[0m"
pacman -S --needed --noconfirm nodejs npm

# Configure PHP
echo -e "\033[1;33m[10/10] Configuring PHP and finalizing...\033[0m"
sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$PHP_INI"
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 64M/' "$PHP_INI"
sed -i 's/^post_max_size = .*/post_max_size = 64M/' "$PHP_INI"

systemctl restart httpd

# Clean up (hapus orphan packages & cache lama)
ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    pacman -Rns --noconfirm $ORPHANS
fi
pacman -Sc --noconfirm >/dev/null 2>&1

# Display completion message
echo -e "\033[1;32m"
echo "╔══════════════════════════════════════════════════╗"
echo "║          INSTALLATION COMPLETED!                 ║"
echo "║                                                  ║"
echo "║   Your development environment is ready to use!  ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "\033[0m"

echo -e "\033[1;34m"
echo "Access your local server at: http://localhost  (root: /srv/http)"
echo "phpMyAdmin: http://localhost/phpmyadmin"
echo "MariaDB username: root"
echo "MariaDB password: root"
echo ""
echo "Installed tools:"
echo "- Apache Web Server (httpd)"
echo "- MariaDB Database"
echo "- PHP with extensions"
echo "- phpMyAdmin"
echo "- Visual Studio Code (Code - OSS)"
echo "- Git"
echo "- Composer"
echo "- Node.js & npm"
echo -e "\033[0m"