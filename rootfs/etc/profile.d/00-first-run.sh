#!/bin/bash
# First-run user onboarding fallback for 'wsl --import'
if [ "$(id -u)" -eq 0 ] && ! id -u 1000 >/dev/null 2>&1; then
    if [ -t 0 ] && [ -x /usr/libexec/cloud-distro-oobe ]; then
        echo ""
        echo "=========================================================="
        echo " Welcome to CloudDistro (Debian 13 trixie WSL2)!"
        echo " No default user was detected. Starting initial user setup..."
        echo "=========================================================="
        echo ""
        /usr/libexec/cloud-distro-oobe
        NEW_USER="$(id -un 1000 2>/dev/null || true)"
        if [ -n "$NEW_USER" ]; then
            if ! grep -q '^\[user\]' /etc/wsl.conf 2>/dev/null; then
                printf '\n[user]\ndefault=%s\n' "$NEW_USER" >> /etc/wsl.conf
            fi
            echo ""
            echo "User '$NEW_USER' created and set as default in /etc/wsl.conf."
            echo "Run 'wsl --shutdown' from Windows PowerShell to apply default user."
            echo ""
        fi
    fi
fi
