#!/usr/bin/env bash

# ==============================================================================
# Sway + Waybar + Foot Setup Script (Arch Linux)
# ==============================================================================
# This script installs and configures Sway, Waybar, and Foot with sensible
# defaults. It also installs a minimal launcher, notification daemon, and
# essential utilities.
# ==============================================================================

set -euo pipefail

# --- Helper Functions ---
info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$1"; }
success() { printf "\033[1;32m[OK]\033[0m %s\n" "$1"; }
error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2; exit 1; }

# --- Check for Arch-based system ---
if ! command -v pacman &>/dev/null; then
    error "This script is intended for Arch Linux and Arch-based distributions."
fi

# --- Package Installation ---
info "Updating system and installing required packages..."

# Core Wayland / Sway stack
PACKAGES=(
    sway
    swaybg
    swayidle
    swaylock
    waybar
    foot
    fuzzel
    mako
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    pavucontrol
    network-manager-applet
    polkit-gnome
    xdg-desktop-portal-wlr
    qt5-wayland
    qt6-wayland
)

# Install packages using pacman
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"

success "All packages installed successfully."

# --- Configuration Directory Setup ---
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CONFIG_DIR"/{sway,waybar,foot}

# ==============================================================================
# Sway Configuration
# ==============================================================================
info "Creating Sway configuration..."

cat > "$CONFIG_DIR/sway/config" << 'EOF'
# Sway Config
# For more information, see: man 5 sway

### Variables
set $mod Mod4
set $term foot
set $menu fuzzel
set $lock swaylock -f -c 000000

### Output
# Set your monitor name. Use `swaymsg -t get_outputs` to find it.
# output * bg ~/Wallpapers/wallpaper.jpg fill

### Input
input * {
    xkb_layout us
    xkb_variant intl
    xkb_options caps:escape
    tap enabled
    natural_scroll enabled
}

### Keybindings
# Basics
bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+Shift+q kill
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -b 'Yes' 'swaymsg exit'

# Lock screen
bindsym $mod+Escape exec $lock

# Focus
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Move
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspaces
bindsym $mod+1 workspace 1
bindsym $mod+2 workspace 2
bindsym $mod+3 workspace 3
bindsym $mod+4 workspace 4
bindsym $mod+5 workspace 5
bindsym $mod+6 workspace 6
bindsym $mod+7 workspace 7
bindsym $mod+8 workspace 8
bindsym $mod+9 workspace 9
bindsym $mod+0 workspace 10

# Move container to workspace
bindsym $mod+Shift+1 move container to workspace 1
bindsym $mod+Shift+2 move container to workspace 2
bindsym $mod+Shift+3 move container to workspace 3
bindsym $mod+Shift+4 move container to workspace 4
bindsym $mod+Shift+5 move container to workspace 5
bindsym $mod+Shift+6 move container to workspace 6
bindsym $mod+Shift+7 move container to workspace 7
bindsym $mod+Shift+8 move container to workspace 8
bindsym $mod+Shift+9 move container to workspace 9
bindsym $mod+Shift+0 move container to workspace 10

# Layout
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+f fullscreen toggle
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle

# Screenshots
bindsym Print exec grim -g "$(slurp)" - | wl-copy
bindsym $mod+Print exec grim - | wl-copy

### Autostart
exec_always --no-startup-id waybar
exec_always --no-startup-id mako
exec_always --no-startup-id swaybg -i ~/Wallpapers/wallpaper.jpg -m fill
exec_always --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec_always --no-startup-id nm-applet --indicator

### Gaps & Borders
gaps inner 8
gaps outer 4
default_border pixel 2
default_floating_border pixel 2
font pango:JetBrainsMono Nerd Font 10
EOF

success "Sway configuration created at $CONFIG_DIR/sway/config"

# ==============================================================================
# Waybar Configuration
# ==============================================================================
info "Creating Waybar configuration..."

# Waybar config.jsonc
cat > "$CONFIG_DIR/waybar/config.jsonc" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["sway/window"],
    "modules-right": ["cpu", "memory", "temperature", "battery", "clock", "tray"],

    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}",
        "on-click": "activate"
    },
    "sway/mode": {
        "format": "{}"
    },
    "sway/window": {
        "max-length": 50
    },
    "cpu": {
        "interval": 10,
        "format": " {usage}%",
        "on-click": "foot -e htop"
    },
    "memory": {
        "interval": 30,
        "format": " {percentage}%",
        "on-click": "foot -e htop"
    },
    "temperature": {
        "critical-threshold": 80,
        "format": " {temperatureC}°C"
    },
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰂄 {capacity}%",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    "clock": {
        "format": "{:%H:%M  %a %d %b}",
        "tooltip-format": "{:%Y-%m-%d %H:%M}"
    },
    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF

# Waybar style.css
cat > "$CONFIG_DIR/waybar/style.css" << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(20, 20, 30, 0.95);
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #cdd6f4;
    border-bottom: 2px solid transparent;
}

#workspaces button.focused {
    color: #89b4fa;
    border-bottom: 2px solid #89b4fa;
}

#workspaces button.urgent {
    color: #f38ba8;
}

#mode {
    background: #f9e2af;
    color: #1e1e2e;
    padding: 0 8px;
    margin: 0 4px;
}

#cpu, #memory, #temperature, #battery, #clock, #tray {
    padding: 0 10px;
    margin: 0 2px;
    background: transparent;
}

#battery.warning {
    color: #f9e2af;
}

#battery.critical {
    color: #f38ba8;
}

#clock {
    color: #89b4fa;
}
EOF

success "Waybar configuration created at $CONFIG_DIR/waybar/"

# ==============================================================================
# Foot Configuration
# ==============================================================================
info "Creating Foot configuration..."

cat > "$CONFIG_DIR/foot/foot.ini" << 'EOF'
[main]
font=JetBrainsMono Nerd Font:size=11
dpi-aware=yes
pad=10x10
term=foot

[colors]
background=1e1e2e
foreground=cdd6f4
regular0=45475a
regular1=f38ba8
regular2=a6e3a1
regular3=f9e2af
regular4=89b4fa
regular5=f5c2e7
regular6=94e2d5
regular7=bac2de
bright0=585b70
bright1=f38ba8
bright2=a6e3a1
bright3=f9e2af
bright4=89b4fa
bright5=f5c2e7
bright6=94e2d5
bright7=a6adc8
EOF

success "Foot configuration created at $CONFIG_DIR/foot/foot.ini"

# ==============================================================================
# Final Steps
# ==============================================================================
info "Setup complete!"

echo -e "\n\033[1;33mNext steps:\033[0m"
echo "1. Create a wallpaper directory and add an image:"
echo "   mkdir -p ~/Wallpapers && cp /path/to/your/image.jpg ~/Wallpapers/wallpaper.jpg"
echo "2. Update the wallpaper path in $CONFIG_DIR/sway/config if needed."
echo "3. If you are not using the 'us intl' keyboard layout, edit the 'input' section in Sway config."
echo "4. Log out and select 'Sway' from your display manager, or run 'sway' from a TTY."
echo -e "\nEnjoy your new Sway setup! 🚀"