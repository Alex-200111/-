#!/bin/bash

echo ">>> Обновление системы..."
sudo pacman -Syu --noconfirm

# === БАЗОВЫЕ ПАКЕТЫ ===
echo ">>> Установка базовых пакетов..."
sudo pacman -S --noconfirm \
    base-devel git wget curl unzip zip \
    neovim nano micro htop btop ranger \
    networkmanager network-manager-applet \
    pulseaudio pavucontrol pipewire pipewire-pulse alsa-utils \
    xdg-user-dirs xdg-utils

# === Xorg + драйверы ===
echo ">>> Установка Xorg и драйверов..."
sudo pacman -S --noconfirm \
    xorg xorg-xinit xorg-server \
    mesa vulkan-intel vulkan-radeon nvidia nvidia-utils

# === BSPWM ===
echo ">>> Установка BSPWM + инструменты..."
sudo pacman -S --noconfirm \
    bspwm sxhkd polybar rofi picom feh dmenu \
    lxappearance papirus-icon-theme alacritty

# === Hyprland ===
echo ">>> Установка Hyprland + инструменты..."
sudo pacman -S --noconfirm \
    hyprland waybar rofi foot \
    xdg-desktop-portal xdg-desktop-portal-hyprland \
    grim slurp wl-clipboard \
    qt5-wayland qt6-wayland gtk3 gtk4

# === LightDM ===
echo ">>> Установка LightDM..."
sudo pacman -S --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
sudo systemctl enable lightdm

# === Браузеры ===
echo ">>> Установка браузеров..."
sudo pacman -S --noconfirm firefox chromium

# === Файловый менеджер ===
echo ">>> Установка файлового менеджера..."
sudo pacman -S --noconfirm thunar thunar-volman

# === Bluetooth ===
echo ">>> Установка Bluetooth..."
sudo pacman -S --noconfirm bluez bluez-utils blueman
sudo systemctl enable bluetooth

# === Шрифты ===
echo ">>> Установка шрифтов..."
sudo pacman -S --noconfirm \
    ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji

# === Файловые утилиты ===
echo ">>> Установка файловых утилит..."
sudo pacman -S --noconfirm gvfs gvfs-mtp file-roller unzip p7zip unrar

# === Медиа ===
echo ">>> Установка медиа-плееров..."
sudo pacman -S --noconfirm mpv vlc

# === Диспетчер задач ===
echo ">>> Установка диспетчера задач..."
sudo pacman -S --noconfirm xfce4-taskmanager

# === Nerd Fonts ===
echo ">>> Установка Nerd Fonts..."
git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts
./install.sh FiraCode
./install.sh JetBrainsMono
./install.sh Hack
cd ..
rm -rf nerd-fonts

# === Zsh + Oh My Zsh ===
echo ">>> Установка Zsh и Oh My Zsh..."
sudo pacman -S --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting
chsh -s /bin/zsh
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Тема Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
sed -i 's|ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# === Создание папок ===
echo ">>> Создание стандартных папок пользователя..."
xdg-user-dirs-update

# === Настройка BSPWM ===
echo ">>> Настройка BSPWM..."
mkdir -p ~/.config/{bspwm,sxhkd,polybar,picom}

cat > ~/.config/bspwm/bspwmrc <<EOF
#!/bin/sh
# Запуск горячих клавиш
sxhkd &
# Прозрачности и тени
picom --config ~/.config/picom/picom.conf &
# Панель
polybar example &
# Обои
feh --bg-fill ~/Pictures/wallpapers/default.jpg &

# === Настройка раскладки клавиатуры (Alt+Shift = глобально, Shift+Alt = окно) ===
setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle"
xcape -e 'Shift_L=ISO_Next_Group'
EOF
chmod +x ~/.config/bspwm/bspwmrc

cat > ~/.config/sxhkd/sxhkdrc <<EOF
super + Return
    alacritty

super + q
    bspc node -c

super + r
    bspc wm -r
EOF

cat > ~/.config/polybar/config.ini <<EOF
[bar/example]
width = 100%
height = 24
background = #222
foreground = #fff
font-0 = "FiraCode Nerd Font:size=10"
modules-left = bspwm
modules-right = pulseaudio date

[module/bspwm]
type = internal/bspwm

[module/pulseaudio]
type = internal/pulseaudio

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d %H:%M
EOF

cat > ~/.config/picom/picom.conf <<EOF
backend = "glx";
vsync = true;
shadow = true;
fading = true;
EOF

# === Настройка Hyprland ===
echo ">>> Настройка Hyprland..."
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<EOF
# Базовая настройка Hyprland
monitor=,preferred,auto,auto

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}
EOF

# === Обои ===
echo ">>> Загрузка дефолтных обоев..."
mkdir -p ~/Pictures/wallpapers
wget -O ~/Pictures/wallpapers/default.jpg https://i.imgur.com/1ZQZ1Zq.jpg

# === Финал ===
echo ">>> Установка завершена!"
echo "Перезагрузи компьютер, выбери BSPWM или Hyprland в LightDM."
echo "Первый запуск Zsh откроет настройку Powerlevel10k."
