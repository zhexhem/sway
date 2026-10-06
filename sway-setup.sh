#!/usr/bin/env bash
# ==============================================================================
# Sway + Waybar + Foot Setup (Interactive with gum)
# ==============================================================================
# A guided installer for a modern Sway desktop, using Charm's gum.
# Includes optional swtchr (window switcher) built from source.
# ==============================================================================

set -euo pipefail

# --- Constants & Styling ---
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# --- Ensure gum is installed ---
if ! command -v gum &>/dev/null; then
    echo "gum is required. Install with: sudo pacman -S gum"
    exit 1
fi

# --- Header ---
clear
gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 70 --margin "1 2" --padding "1 2" \
    'Sway + Waybar + Foot Setup' \
    'A modern Wayland desktop installer'

# ==============================================================================
# 0. Pre-flight checks
# ==============================================================================
if ! command -v pacman &>/dev/null; then
    gum style --foreground 196 "Error: Requires Arch-based distribution (pacman)."
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    gum style --foreground 196 "Error: Do not run as root."
    exit 1
fi

# ==============================================================================
# 1. Configuration choices
# ==============================================================================
gum style --foreground 212 --bold "Step 1: Configure your setup"

MODIFIER=$(gum choose --header "Choose your modifier key:" "Mod4 (Super/Windows)" "Mod1 (Alt)")
case "$MODIFIER" in
    "Mod4"*) MOD="Mod4" ;;
    "Mod1"*) MOD="Mod1" ;;
esac

KB_LAYOUT=$(gum input --header "Keyboard layout (e.g. us, gb, de):" --placeholder "us" --value "us")
KB_VARIANT=$(gum input --header "Keyboard variant (empty for none):" --placeholder "intl")

THEME=$(gum choose --header "Choose a colour theme:" "Catppuccin Mocha" "Catppuccin Macchiato" "Nord" "Gruvbox Dark" "Tokyo Night")

case "$THEME" in
    "Catppuccin Mocha")
        BG="1e1e2e"; FG="cdd6f4"; ACCENT="89b4fa"; ACCENT2="f5c2e7"; WARN="f9e2af"; ERR="f38ba8"; OK="a6e3a1"
        ;;
    "Catppuccin Macchiato")
        BG="24273a"; FG="cad3f5"; ACCENT="8aadf4"; ACCENT2="f5bde6"; WARN="eed49f"; ERR="ed8796"; OK="a6da95"
        ;;
    "Nord")
        BG="2e3440"; FG="d8dee9"; ACCENT="88c0d0"; ACCENT2="b48ead"; WARN="ebcb8b"; ERR="bf616a"; OK="a3be8c"
        ;;
    "Gruvbox Dark")
        BG="282828"; FG="ebdbb2"; ACCENT="83a598"; ACCENT2="d3869b"; WARN="fabd2f"; ERR="fb4934"; OK="b8bb26"
        ;;
    "Tokyo Night")
        BG="1a1b26"; FG="c0caf5"; ACCENT="7aa2f7"; ACCENT2="bb9af7"; WARN="e0af68"; ERR="f7768e"; OK="9ece6a"
        ;;
esac

WALLPAPER_DIR=$(gum input --header "Wallpaper directory:" --value "$HOME/Wallpapers")

# Multi-select components (including swtchr)
COMPONENTS=$(gum choose --no-limit --header "Select extra components to install:" \
    "swtchr (window switcher)" \
    "Waybar extras (media, network, backlight modules)" \
    "Mako (notifications)" \
    "Fuzzel (launcher)" \
    "Swaylock (screen lock)" \
    "Swayidle (idle management)" \
    "Screenshot tools (grim, slurp)" \
    "Helper scripts (theme switcher, wallpaper randomizer)" \
    "Audio/brightness control (pamixer, brightnessctl)" \
    "Tray applets (nm-applet, polkit-gnome)" \
    "Nerd Font (JetBrainsMono)")

HAS_COMPONENT() { [[ "$COMPONENTS" == *"$1"* ]]; }

# ==============================================================================
# 2. Summary and confirmation
# ==============================================================================
gum style --foreground 212 --bold "Step 2: Review your choices"
gum style --border rounded --padding "1 2" --margin "1 0" \
    "Modifier:       $MOD" \
    "Keyboard:       $KB_LAYOUT ${KB_VARIANT:+(variant: $KB_VARIANT)}" \
    "Theme:          $THEME" \
    "Wallpapers:     $WALLPAPER_DIR" \
    "Components:     $(echo "$COMPONENTS" | wc -l) selected"

if ! gum confirm "Proceed with installation?"; then
    gum style --foreground 214 "Aborted by user."
    exit 0
fi

# ==============================================================================
# 3. Package Installation
# ==============================================================================
gum style --foreground 212 --bold "Step 3: Installing packages"

CORE_PKGS=(sway swaybg foot fuzzel grim slurp wl-clipboard xdg-desktop-portal-wlr qt5-wayland qt6-wayland)
EXTRA_PKGS=()

HAS_COMPONENT "Mako" && EXTRA_PKGS+=(mako)
HAS_COMPONENT "Fuzzel" && EXTRA_PKGS+=(fuzzel)
HAS_COMPONENT "Swaylock" && EXTRA_PKGS+=(swaylock)
HAS_COMPONENT "Swayidle" && EXTRA_PKGS+=(swayidle)
HAS_COMPONENT "Audio/brightness" && EXTRA_PKGS+=(pamixer brightnessctl playerctl pavucontrol)
HAS_COMPONENT "Tray applets" && EXTRA_PKGS+=(network-manager-applet polkit-gnome)
HAS_COMPONENT "Nerd Font" && EXTRA_PKGS+=(ttf-jetbrains-mono-nerd)

ALL_PKGS=("${CORE_PKGS[@]}" "${EXTRA_PKGS[@]}" waybar)

gum spin --spinner dot --title "Updating package database..." -- sudo pacman -Sy --noconfirm
gum spin --spinner dot --title "Installing ${#ALL_PKGS[@]} packages..." -- \
    sudo pacman -S --needed --noconfirm "${ALL_PKGS[@]}"

gum style --foreground "$OK" "✓ Packages installed"

# ==============================================================================
# 4. swtchr: build from source (if selected)
# ==============================================================================
if HAS_COMPONENT "swtchr"; then
    gum style --foreground 212 --bold "Step 4: Building swtchr from source"

    # Install build dependencies
    SWTCHR_DEPS=(rust gtk4 gtk4-layer-shell)
    gum spin --spinner dot --title "Installing swtchr build dependencies..." -- \
        sudo pacman -S --needed --noconfirm "${SWTCHR_DEPS[@]}"

    # Build with cargo (installs to ~/.cargo/bin)
    gum spin --spinner dot --title "Compiling swtchr (this may take a few minutes)..." -- \
        cargo install swtchr

    # Ensure ~/.cargo/bin is on PATH for the current session
    if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
        gum style --foreground 214 "  Note: Added ~/.cargo/bin to PATH for this session."
        gum style --foreground 245 "  Add 'export PATH=\"\$HOME/.cargo/bin:\$PATH\"' to your shell rc to make it permanent."
    fi

    gum style --foreground "$OK" "✓ swtchr and swtchrd installed to ~/.cargo/bin"
fi

# ==============================================================================
# 5. Directory setup
# ==============================================================================
mkdir -p "$CONFIG_DIR"/{sway/scripts,waybar,foot}
HAS_COMPONENT "Mako" && mkdir -p "$CONFIG_DIR/mako"
HAS_COMPONENT "Fuzzel" && mkdir -p "$CONFIG_DIR/fuzzel"
HAS_COMPONENT "Swaylock" && mkdir -p "$CONFIG_DIR/swaylock"
HAS_COMPONENT "Swayidle" && mkdir -p "$CONFIG_DIR/swayidle"
HAS_COMPONENT "swtchr" && mkdir -p "$CONFIG_DIR/swtchr"
mkdir -p "$WALLPAPER_DIR"

backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "${1}${BACKUP_SUFFIX}"
        gum style --foreground 214 "  Backed up: $1"
    fi
}

# ==============================================================================
# 6. Write Sway config
# ==============================================================================
gum style --foreground 212 --bold "Step 5: Writing configurations"

backup_file "$CONFIG_DIR/sway/config"

cat > "$CONFIG_DIR/sway/config" <<EOF
# Sway config — generated by sway-setup.sh
set \$mod $MOD
set \$term foot
set \$menu fuzzel
set \$lock swaylock -f -c $BG

### Input
input * {
    xkb_layout $KB_LAYOUT
    ${KB_VARIANT:+xkb_variant $KB_VARIANT}
    tap enabled
    natural_scroll enabled
}

### Keybindings
bindsym \$mod+Return exec \$term
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+q kill
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -b 'Yes' 'swaymsg exit'
bindsym \$mod+Escape exec \$lock

# Focus
bindsym \$mod+Left focus left
bindsym \$mod+Down focus down
bindsym \$mod+Up focus up
bindsym \$mod+Right focus right

# Move
bindsym \$mod+Shift+Left move left
bindsym \$mod+Shift+Down move down
bindsym \$mod+Shift+Up move up
bindsym \$mod+Shift+Right move right

# Workspaces
$(for i in {1..10}; do
  n=$((i % 10))
  echo "bindsym \$mod+$n workspace $i"
  echo "bindsym \$mod+Shift+$n move container to workspace $i"
done)

# Layout
bindsym \$mod+b splith
bindsym \$mod+v splitv
bindsym \$mod+f fullscreen toggle
bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split
bindsym \$mod+Shift+space floating toggle
bindsym \$mod+space focus mode_toggle

# Media/brightness
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

# Screenshots
bindsym Print exec grim -g "\$(slurp)" - | wl-copy
bindsym \$mod+Print exec grim - | wl-copy

### Autostart
exec_always --no-startup-id waybar
$(HAS_COMPONENT "Mako" && echo "exec_always --no-startup-id mako")
$(HAS_COMPONENT "Swayidle" && echo "exec_always --no-startup-id swayidle -w")
$(HAS_COMPONENT "Tray applets" && echo "exec_always --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
$(HAS_COMPONENT "Tray applets" && echo "exec_always --no-startup-id nm-applet --indicator")

# swtchr daemon
$(HAS_COMPONENT "swtchr" && echo "exec_always --no-startup-id ~/.cargo/bin/swtchrd")

### Wallpaper
exec_always --no-startup-id swaybg -i "$WALLPAPER_DIR/wallpaper.jpg" -m fill

### Gaps & Borders
gaps inner 8
gaps outer 4
default_border pixel 2
default_floating_border pixel 2
font pango:JetBrainsMono Nerd Font 10

### Window rules
for_window [app_id="pavucontrol"] floating enable, resize set 800 600
for_window [app_id="nm-connection-editor"] floating enable, resize set 800 600
for_window [title="Picture-in-Picture"] floating enable, sticky enable, resize set 480 270

### Helper keybindings
$(HAS_COMPONENT "Helper scripts" && echo "bindsym \$mod+Shift+t exec ~/.config/sway/scripts/theme-switcher.sh")
$(HAS_COMPONENT "Helper scripts" && echo "bindsym \$mod+Shift+w exec ~/.config/sway/scripts/wallpaper-random.sh")

### swtchr keybindings
$(HAS_COMPONENT "swtchr" && cat <<'SWTCHR'
bindsym $mod+Tab mode swtchr; exec ~/.cargo/bin/swtchr
bindsym $mod+Shift+Tab mode swtchr; exec ~/.cargo/bin/swtchr

# This is important! Exits the swtchr mode on Backspace.
mode swtchr {
    bindsym Backspace mode default
}
SWTCHR
)
EOF

gum style --foreground "$OK" "✓ Sway config written (with swtchr mode)"

# ==============================================================================
# 7. Write Waybar config
# ==============================================================================
backup_file "$CONFIG_DIR/waybar/config.jsonc"
backup_file "$CONFIG_DIR/waybar/style.css"

RIGHT_MODULES='["cpu", "memory"'
HAS_COMPONENT "Waybar extras" && RIGHT_MODULES=', "network", "pulseaudio", "backlight", "idle_inhibitor", "custom/media"'
RIGHT_MODULES+=', "battery", "clock", "tray"]'

cat > "$CONFIG_DIR/waybar/config.jsonc" <<EOF
{
    "layer": "top",
    "position": "top",
    "height": 32,
    "spacing": 4,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["sway/window"],
    "modules-right": $RIGHT_MODULES,

    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}"
    },
    "sway/mode": { "format": "{}" },
    "sway/window": { "max-length": 50 },
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
        "states": { "warning": 30, "critical": 15 },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰂄 {capacity}%",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    "clock": {
        "format": "{:%H:%M  %a %d %b}",
        "tooltip-format": "{:%Y-%m-%d %H:%M}"
    },
    "tray": { "icon-size": 18, "spacing": 10 },
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": { "activated": "", "deactivated": "" }
    },
    "custom/media": {
        "format": "{icon} {}",
        "format-icons": [""],
        "exec": "playerctl metadata --format '{{artist}} - {{title}}'",
        "exec-if": "playerctl status",
        "on-click": "playerctl play-pause",
        "max-length": 30
    },
    "network": {
        "format-wifi": "  {essid}",
        "format-ethernet": "  {ifname}",
        "format-disconnected": "⚠  Offline",
        "on-click": "nm-connection-editor"
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " Muted",
        "format-icons": { "default": ["", "", ""] },
        "on-click": "pavucontrol",
        "on-scroll-up": "pamixer -i 5",
        "on-scroll-down": "pamixer -d 5"
    },
    "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": ["", ""],
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
    }
}
EOF

cat > "$CONFIG_DIR/waybar/style.css" <<EOF
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba($(printf '%d' 0x${BG:0:2}), $(printf '%d' 0x${BG:2:2}), $(printf '%d' 0x${BG:4:2}), 0.95);
    color: #$FG;
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #$FG;
    border-bottom: 2px solid transparent;
}
#workspaces button.focused {
    color: #$ACCENT;
    border-bottom: 2px solid #$ACCENT;
}
#workspaces button.urgent { color: #$ERR; }

#mode {
    background: #$WARN;
    color: #$BG;
    padding: 0 8px;
    margin: 0 4px;
}

#cpu, #memory, #temperature, #battery, #clock, #tray, #network,
#pulseaudio, #backlight, #idle_inhibitor, #custom-media {
    padding: 0 10px;
    margin: 0 2px;
    background: transparent;
}

#battery.warning { color: #$WARN; }
#battery.critical { color: #$ERR; }
#clock { color: #$ACCENT; }
#network.disconnected { color: #$ERR; }
#pulseaudio.muted { color: #$ERR; }
#idle_inhibitor.activated { color: #$OK; }
EOF

# ==============================================================================
# 8. Write Foot config
# ==============================================================================
backup_file "$CONFIG_DIR/foot/foot.ini"

cat > "$CONFIG_DIR/foot/foot.ini" <<EOF
[main]
font=JetBrainsMono Nerd Font:size=11
dpi-aware=yes
pad=10x10
term=foot

[colors]
background=$BG
foreground=$FG
regular0=45475a
regular1=$ERR
regular2=$OK
regular3=$WARN
regular4=$ACCENT
regular5=$ACCENT2
regular6=94e2d5
regular7=bac2de
bright0=585b70
bright1=$ERR
bright2=$OK
bright3=$WARN
bright4=$ACCENT
bright5=$ACCENT2
bright6=94e2d5
bright7=a6adc8
EOF

gum style --foreground "$OK" "✓ Core configs written"

# ==============================================================================
# 9. Optional component configs
# ==============================================================================

if HAS_COMPONENT "Mako"; then
    backup_file "$CONFIG_DIR/mako/config"
    cat > "$CONFIG_DIR/mako/config" <<EOF
font=JetBrainsMono Nerd Font 10
background-color=#$BG
text-color=#$FG
border-color=#$ACCENT
border-size=2
border-radius=8
padding=10
margin=10
width=300
anchor=top-right
default-timeout=5000
max-visible=5
group-by=app-name
EOF
    gum style --foreground "$OK" "✓ Mako configured"
fi

if HAS_COMPONENT "Fuzzel"; then
    backup_file "$CONFIG_DIR/fuzzel/fuzzel.ini"
    cat > "$CONFIG_DIR/fuzzel/fuzzel.ini" <<EOF
[main]
font=JetBrainsMono Nerd Font:size=12
dpi-aware=yes
prompt="❯ "
terminal=foot
lines=10
width=40
horizontal-pad=20
vertical-pad=20
inner-pad=10

[colors]
background=${BG}cc
text=${FG}ff
match=${ACCENT}ff
selection=585b70ff
selection-text=${FG}ff
border=${ACCENT}ff
EOF
    gum style --foreground "$OK" "✓ Fuzzel configured"
fi

if HAS_COMPONENT "Swaylock"; then
    backup_file "$CONFIG_DIR/swaylock/config"
    cat > "$CONFIG_DIR/swaylock/config" <<EOF
color=$BG
inside-color=$BG
ring-color=$ACCENT
key-hl-color=$OK
bs-hl-color=$ERR
separator-color=00000000
text-color=$FG
text-caps-lock-color=$WARN
line-color=00000000
line-ver-color=$ACCENT
line-wrong-color=$ERR
ring-ver-color=$ACCENT
ring-wrong-color=$ERR
inside-ver-color=$BG
inside-wrong-color=$BG
font=JetBrainsMono Nerd Font
indicator-radius=100
indicator-thickness=10
EOF
    gum style --foreground "$OK" "✓ Swaylock configured"
fi

if HAS_COMPONENT "Swayidle"; then
    backup_file "$CONFIG_DIR/swayidle/config"
    cat > "$CONFIG_DIR/swayidle/config" <<EOF
timeout 300 'swaylock -f'
timeout 600 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"'
before-sleep 'swaylock -f'
EOF
    gum style --foreground "$OK" "✓ Swayidle configured"
fi

# ==============================================================================
# 10. Helper scripts
# ==============================================================================
if HAS_COMPONENT "Helper scripts"; then
    cat > "$CONFIG_DIR/sway/scripts/theme-switcher.sh" <<'EOF'
#!/usr/bin/env bash
# Toggle between dark and light themes
STATE_FILE="$HOME/.config/sway/current_theme"
if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" = "dark" ]; then
    echo "light" > "$STATE_FILE"
    notify-send "Theme" "Switched to light theme"
else
    echo "dark" > "$STATE_FILE"
    notify-send "Theme" "Switched to dark theme"
fi
pkill -SIGUSR2 waybar
EOF
    chmod +x "$CONFIG_DIR/sway/scripts/theme-switcher.sh"

    cat > "$CONFIG_DIR/sway/scripts/wallpaper-random.sh" <<EOF
#!/usr/bin/env bash
WALLPAPER_DIR="$WALLPAPER_DIR"
if [ -d "\$WALLPAPER_DIR" ]; then
    WALLPAPER=\$(find "\$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
    if [ -n "\$WALLPAPER" ]; then
        swaymsg output "*" bg "\$WALLPAPER" fill
        notify-send "Wallpaper" "Set to \$(basename "\$WALLPAPER")"
    fi
fi
EOF
    chmod +x "$CONFIG_DIR/sway/scripts/wallpaper-random.sh"

    gum style --foreground "$OK" "✓ Helper scripts installed"
fi

# ==============================================================================
# 11. Wallpaper prompt
# ==============================================================================
if [ ! -f "$WALLPAPER_DIR/wallpaper.jpg" ]; then
    gum style --foreground 214 "No wallpaper.jpg found in $WALLPAPER_DIR"
    if gum confirm "Would you like to copy an image now?"; then
        SRC=$(gum file --file --header "Select an image:" "$HOME")
        if [ -n "$SRC" ]; then
            cp "$SRC" "$WALLPAPER_DIR/wallpaper.jpg"
            gum style --foreground "$OK" "✓ Wallpaper copied"
        fi
    fi
fi

# ==============================================================================
# 12. Font check
# ==============================================================================
if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    gum style --foreground 214 "⚠ JetBrainsMono Nerd Font not detected. Install with:"
    gum style --foreground 245 "  sudo pacman -S ttf-jetbrains-mono-nerd"
fi

# ==============================================================================
# 13. Review the Sway config
# ==============================================================================
if gum confirm "Would you like to review the generated Sway config?"; then
    gum pager < "$CONFIG_DIR/sway/config"
fi

# ==============================================================================
# 14. Final message
# ==============================================================================
gum style \
    --border double --border-foreground "$ACCENT" \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    --foreground "$OK" --bold \
    "Setup Complete! 🚀" \
    "" \
    "Modifier: $MOD  |  Terminal: foot  |  Launcher: fuzzel" \
    "Theme: $THEME"

gum style --foreground 212 --bold "Next steps:"
gum style \
    "  1. Log out and select 'Sway' from your display manager." \
    "  2. Or run 'sway' from a TTY." \
    "  3. Configs live in: $CONFIG_DIR/{sway,waybar,foot}"

if HAS_COMPONENT "swtchr"; then
    gum style --foreground 245 "  swtchr: Mod+Tab to open the window switcher."
fi

if HAS_COMPONENT "Helper scripts"; then
    gum style --foreground 245 "  Mod+Shift+t = switch theme   |   Mod+Shift+w = random wallpaper"
fi