#!/bin/bash
set -e

echo ">>> Обновляем систему..."
sudo pacman -Syu --noconfirm

# === Базовые пакеты (минимум) ===
echo ">>> Устанавливаем базовые пакеты..."
sudo pacman -S --noconfirm --needed \
    base-devel git wget curl \
    networkmanager \
    xdg-user-dirs xdg-utils \
    neovim nano

# === Включаем сеть ===
echo ">>> Включаем NetworkManager..."
sudo systemctl enable NetworkManager --now

# === Xorg + драйверы (для совместимости) ===
echo ">>> Устанавливаем Xorg и драйверы..."
sudo pacman -S --noconfirm --needed \
    xorg xorg-xinit mesa mesa-demos \
    vulkan-icd-loader \
    amd-ucode intel-ucode \
    nvidia nvidia-utils nvidia-settings lib32-nvidia-utils nvidia-prime

# === Hyprland ===
echo ">>> Устанавливаем Hyprland..."
sudo pacman -S --noconfirm --needed \
    hyprland waybar foot \
    xdg-desktop-portal xdg-desktop-portal-hyprland \
    grim slurp wl-clipboard \
    qt5-wayland qt6-wayland gtk3 gtk4

# === LightDM (для входа в систему) ===
echo ">>> Устанавливаем LightDM..."
sudo pacman -S --noconfirm --needed lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo sed -i 's/^#greeter-session=.*/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf || true
sudo systemctl enable lightdm

# === Hyprland desktop entry ===
sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=Dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF

# === Минимальная настройка Hyprland ===
mkdir -p ~/.config/hypr

cat > ~/.config/hypr/hyprland.conf <<EOF
monitor=,preferred,auto,auto

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}

exec-once = foot
EOF

echo ">>> Минимальная установка завершена!"
echo "Перезагрузи систему: sudo reboot"
echo "На экране входа выбери Hyprland."
