#!/bin/bash

echo ">>> Установка начинается..."

# === Создание нужных папок ===
sudo mkdir -p /usr/share/icons
sudo mkdir -p /usr/share/themes
sudo mkdir -p /usr/share/backgrounds
mkdir -p ~/.config

# === Установка BSPWM dotfiles ===
echo ">>> Скачиваю и устанавливаю bspwm-dots..."
git clone https://github.com/mmsaeed509/bspwm-dots.git
cd bspwm-dots
chmod +x install_arch_packages
sudo ./install_arch_packages
cp misc/* ~/
sudo cp bin/* /bin
cp -r config/* ~/.config
cd ..
rm -rf bspwm-dots

# === Установка обоев ===
echo ">>> Скачиваю и устанавливаю обои..."
git clone https://github.com/Exodia-OS/exodia-backgrounds.git
cd exodia-backgrounds/backgrounds
sudo cp -r * /usr/share/backgrounds/
cd ../..
rm -rf exodia-backgrounds

# === Установка иконок ===
echo ">>> Скачиваю и устанавливаю иконки..."
git clone https://github.com/Exodia-OS/exodia-icons.git
cd exodia-icons/files
sudo cp -r * /usr/share/icons/
cd ../..
rm -rf exodia-icons

# === Установка тем ===
echo ">>> Скачиваю и устанавливаю темы..."
git clone https://github.com/Exodia-OS/exodia-themes.git
cd exodia-themes/files
sudo cp -r * /usr/share/themes/
cd ../..
rm -rf exodia-themes

echo ">>> Установка завершена! Перезапусти сессию и включи BSPWM."
