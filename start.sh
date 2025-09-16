#!/usr/bin/env bash
set -euo pipefail

# Настройки
FORCE_CLONE=false          # true - удаляет старые клоны перед git clone
INSTALL_HYPRLAND=false     # true - пробовать ставить Hyprland (можно включить вручную)
PACKAGES_EXTRA=()          # сюда можно добавить свои пакеты

info(){ echo ">>> $*"; }

# Проверка сети (github)
if ! ping -c1 8.8.8.8 >/dev/null 2>&1; then
  echo "Нет интернета! Подключись и попробуй снова."
  exit 1
fi

info "Обновление базы pacman..."
sudo pacman -Syu --noconfirm

# --- Базовые пакеты (список) ---
PACKAGES=(
  base-devel git wget curl unzip zip
  neovim nano micro htop btop ranger
  networkmanager network-manager-applet
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol
  xdg-user-dirs xdg-utils
  feh rofi dmenu lxappearance
  alacritty kitty
  firefox chromium
  thunar thunar-volman file-roller gvfs gvfs-mtp
  bluez bluez-utils blueman
  mpv vlc xfce4-taskmanager
  ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji
  unzip p7zip unrar zsh
)
PACKAGES+=("${PACKAGES_EXTRA[@]}")

# Попытка массовой установки, если падает — пробуем по одному
info "Устанавливаем базовые пакеты..."
if ! sudo pacman -S --noconfirm --needed "${PACKAGES[@]}"; then
  info "Пробую ставить по одному, чтобы пропускать отсутствующие пакеты..."
  for p in "${PACKAGES[@]}"; do
    if ! sudo pacman -S --noconfirm --needed "$p"; then
      echo "  (пропущен) $p"
    fi
  done
fi

# --- Определяем GPU и ставим драйверы только нужные ---
info "Определяем GPU..."
GPU_INFO="$(lspci 2>/dev/null || true)"
DRIVERS=(mesa vulkan-icd-loader)
if echo "$GPU_INFO" | grep -qi nvidia; then
  info "NVIDIA обнаружена -> установлю nvidia пакеты"
  DRIVERS=(nvidia nvidia-utils nvidia-settings lib32-nvidia-utils nvidia-prime)
elif echo "$GPU_INFO" | grep -Ei "amd|radeon" >/dev/null; then
  info "AMD обнаружена -> установлю mesa + vulkan-radeon"
  DRIVERS+=(vulkan-radeon lib32-vulkan-radeon amd-ucode)
elif echo "$GPU_INFO" | grep -Ei "intel" >/dev/null; then
  info "Intel обнаружен -> установлю mesa + vulkan-intel"
  DRIVERS+=(vulkan-intel lib32-vulkan-intel intel-ucode)
else
  info "GPU не определён точно — ставлю Mesa (универсально)."
fi

info "Устанавливаю драйверы: ${DRIVERS[*]}"
if ! sudo pacman -S --noconfirm --needed "${DRIVERS[@]}"; then
  echo "Внимание: не все драйверы установлены (возможно пакет отсутствует в репо)."
fi

# --- Xorg + утилиты (нужны для bspwm) ---
info "Устанавливаем Xorg и утилиты..."
sudo pacman -S --noconfirm --needed xorg xorg-xinit xorg-server xorg-setxkbmap xorg-xprop xorg-xrandr

# --- BSPWM и утилиты ---
info "Устанавливаем BSPWM + утилиты..."
sudo pacman -S --noconfirm --needed bspwm sxhkd polybar picom

# --- Hyprland (опционально) ---
if [ "${INSTALL_HYPRLAND}" = true ]; then
  info "Попытка установить Hyprland (опция включена)..."
  if ! sudo pacman -S --noconfirm --needed hyprland waybar foot xdg-desktop-portal xdg-desktop-portal-wlr grim slurp wl-clipboard qt5-wayland qt6-wayland gtk3 gtk4; then
    echo "Hyprland либо недоступен в репозитории — нужно ставить из AUR вручную."
  fi
else
  info "Hyprland пропущён (INSTALL_HYPRLAND=false)."
fi

# --- LightDM и greeter ---
info "Устанавливаем LightDM..."
sudo pacman -S --noconfirm --needed lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
# создаём conf.d файл чтобы гарантированно применить greeter
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/50-my-greeter.conf > /dev/null <<EOF
[Seat:*]
greeter-session=lightdm-gtk-greeter
# don't autologin by default
EOF
sudo systemctl enable lightdm

# --- Создаём wrapper для bspwm (чтобы sxhkd/picom/polybar запускались корректно) ---
info "Создаю /usr/local/bin/bspwm-session ..."
sudo tee /usr/local/bin/bspwm-session > /dev/null <<'EOS'
#!/bin/sh
# wrapper for display manager session
# start hotkeys and other startup tools, then exec bspwm
[ -x /usr/bin/sxhkd ] && setsid -f sxhkd >/dev/null 2>&1 || true
[ -x /usr/bin/picom ] && (picom --config "$HOME/.config/picom/picom.conf" &)
[ -x /usr/bin/polybar ] && (polybar example &)
# source user's bspwmrc if present
if [ -f "$HOME/.config/bspwm/bspwmrc" ]; then
  # do not exec here; source to set env if needed
  . "$HOME/.config/bspwm/bspwmrc"
fi
exec bspwm
EOS
sudo chmod +x /usr/local/bin/bspwm-session

# --- Desktop entries (bspwm + hyprland if installed) ---
info "Создаю desktop entry для bspwm..."
sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null <<EOF
[Desktop Entry]
Name=BSPWM
Comment=Binary space partitioning window manager
Exec=/usr/local/bin/bspwm-session
Type=Application
EOF

# hyprland desktop entry (если есть бинарный hyprland)
if command -v Hyprland >/dev/null 2>&1 || command -v hyprland >/dev/null 2>&1; then
  HYPR_BIN="$(command -v Hyprland || true)"
  [ -z "$HYPR_BIN" ] && HYPR_BIN="$(command -v hyprland || true)"
  sudo mkdir -p /usr/share/wayland-sessions
  sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=Dynamic tiling Wayland compositor
Exec=${HYPR_BIN}
Type=Application
EOF
  info "Hyprland desktop entry создан."
fi

# --- Раскладка и ~/.config файлы ---
info "Создаём конфиги и раскладки..."
mkdir -p ~/.config/{bspwm,sxhkd,polybar,picom,hyprland}
# простой bspwmrc (пример)
cat > ~/.config/bspwm/bspwmrc <<'BSPCM'
#!/bin/sh
# minimal bspwmrc
sxhkd &
# picom and polybar are started by wrapper too; this is fallback
[ -x /usr/bin/picom ] && picom --config ~/.config/picom/picom.conf &
[ -x /usr/bin/polybar ] && polybar example &
feh --bg-fill ~/Pictures/wallpapers/default.jpg &
# keyboard layout: Alt+Shift toggles group
setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle"
BSPCM
chmod +x ~/.config/bspwm/bspwmrc

# hyprland config (если захотим hyprland)
cat > ~/.config/hyprland/hyprland.conf <<'HYPRC'
monitor=,preferred,auto,auto
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}
HYPRC

# --- Polybar config (шрифт — из ttf-dejavu, чтобы не ломалось) ---
cat > ~/.config/polybar/config.ini <<'POLY'
[bar/example]
width = 100%
height = 24
background = #222
foreground = #fff
font-0 = "DejaVu Sans Mono:size=10"
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
POLY

# Picom config
cat > ~/.config/picom/picom.conf <<'PC'
backend = "glx";
vsync = true;
shadow = true;
fading = true;
PC

# --- Темы/иконки/обои (клонируем аккуратно) ---
clone_and_copy(){
  url="$1"; src_subpath="$2"; dest="$3"
  tmpdir="$(mktemp -d)"
  if [ "$FORCE_CLONE" = true ]; then rm -rf "$tmpdir"; fi
  git clone --depth=1 "$url" "$tmpdir" || { echo "Не удалось клонировать $url"; rm -rf "$tmpdir"; return 1; }
  if [ -d "$tmpdir/$src_subpath" ]; then
    sudo mkdir -p "$dest"
    sudo cp -r "$tmpdir/$src_subpath"/* "$dest"/ || true
  fi
  rm -rf "$tmpdir"
}

info "Качаем обои/иконки/темы (если доступны)..."
clone_and_copy "https://github.com/Exodia-OS/exodia-backgrounds.git" "backgrounds" "/usr/share/backgrounds" || true
clone_and_copy "https://github.com/Exodia-OS/exodia-icons.git" "files" "/usr/share/icons" || true
clone_and_copy "https://github.com/Exodia-OS/exodia-themes.git" "files" "/usr/share/themes" || true

# --- Oh My Zsh (с осторожностью) ---
info "Устанавливаем Oh My Zsh (если zsh установлен)..."
if command -v zsh >/dev/null 2>&1; then
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
  if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" || true
  fi
  git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" || true
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" || true

  # аккуратно правим .zshrc или создаём новый
  if [ -f "$HOME/.zshrc" ]; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc" 2>/dev/null || true
    if ! grep -q "zsh-autosuggestions" "$HOME/.zshrc" 2>/dev/null; then
      echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
    fi
  else
    cat > "$HOME/.zshrc" <<'ZRC'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
ZRC
  fi
  chsh -s /bin/zsh || true
fi

# --- Стандартные папки и обои ---
xdg-user-dirs-update || true
mkdir -p ~/Pictures/wallpapers
curl -fsSL -o ~/Pictures/wallpapers/default.jpg https://i.imgur.com/1ZQZ1Zq.jpg || true

info "Установка завершена!"
echo "Перезагрузи компьютер: sudo reboot"
echo "На экране входа выбери BSPWM или (если ставилась) Hyprland."
