#!/usr/bin/env bash
# Turn a Raspberry Pi 5 into a Vibe studio projector box.
#
# Run once on the Pi (Raspberry Pi OS with desktop, Bookworm or later):
#   bash pi/setup-kiosk.sh
# then reboot. The Pi boots straight into Vibe studio, full screen, mic on.
#
# What it sets up:
#   1. A tiny local web server, so the page is served from http://localhost
#      (a file:// copy can't ask for the mic) and works with no internet.
#   2. Chromium in kiosk mode on login, with the mic permission pre-approved.
#   3. Screen blanking off, so the projector never goes dark mid-show.
#
# Change the look or render height below, then run the script again.

set -euo pipefail

LOOK="newsprint"        # a preset id from presets/library.json
RENDER=720              # render height; the projector stretches it to 1080p
PORT=8000
REPO_URL="https://github.com/stackadapt-kezia/vibe-studio"
APP_DIR="${APP_DIR:-$HOME/vibe-studio}"

echo "== Vibe studio kiosk setup =="

# --- 1. the app ------------------------------------------------------------
if [ ! -f "$APP_DIR/index.html" ]; then
  echo "Getting Vibe studio into $APP_DIR"
  git clone --depth 1 "$REPO_URL" "$APP_DIR"
else
  echo "Using the copy already in $APP_DIR (run 'git -C $APP_DIR pull' to update it)"
fi

# --- 2. local web server, started at boot ------------------------------------
# Bound to 127.0.0.1, so only the Pi itself can reach it.
sudo tee /etc/systemd/system/vibe-server.service >/dev/null <<EOF
[Unit]
Description=Vibe studio local web server
After=network.target

[Service]
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 -m http.server $PORT --bind 127.0.0.1
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now vibe-server.service
echo "Web server running on http://localhost:$PORT"

# --- 3. Chromium kiosk on login -----------------------------------------------
BROWSER="$(command -v chromium || command -v chromium-browser || true)"
if [ -z "$BROWSER" ]; then
  echo "Chromium isn't installed. Install it with: sudo apt install chromium" >&2
  exit 1
fi

LAUNCH="$HOME/.local/bin/vibe-kiosk"
mkdir -p "$(dirname "$LAUNCH")"
cat > "$LAUNCH" <<EOF
#!/usr/bin/env bash
# Wait for the local server, then open Vibe studio full screen.
for i in \$(seq 1 30); do
  curl -fs "http://localhost:$PORT/index.html" >/dev/null && break
  sleep 1
done
exec "$BROWSER" \\
  --kiosk "http://localhost:$PORT/index.html?playback&render=$RENDER&look=$LOOK" \\
  --noerrdialogs --disable-infobars --disable-session-crashed-bubble \\
  --use-fake-ui-for-media-stream \\
  --autoplay-policy=no-user-gesture-required \\
  --password-store=basic \\
  --check-for-update-interval=31536000
EOF
chmod +x "$LAUNCH"

# Raspberry Pi OS desktop runs labwc (Bookworm, late 2024 on) or wayfire (older).
if [ -d "$HOME/.config/labwc" ] || command -v labwc >/dev/null; then
  mkdir -p "$HOME/.config/labwc"
  AUTO="$HOME/.config/labwc/autostart"
  touch "$AUTO"
  grep -q vibe-kiosk "$AUTO" || echo "$LAUNCH &" >> "$AUTO"
  echo "Kiosk added to $AUTO"
else
  INI="$HOME/.config/wayfire.ini"
  touch "$INI"
  if ! grep -q vibe-kiosk "$INI"; then
    grep -q '^\[autostart\]' "$INI" || printf '\n[autostart]\n' >> "$INI"
    sed -i "/^\[autostart\]/a vibe = $LAUNCH" "$INI"
  fi
  echo "Kiosk added to $INI"
fi

# --- 4. keep the screen on ------------------------------------------------------
if command -v raspi-config >/dev/null; then
  sudo raspi-config nonint do_blanking 1 && echo "Screen blanking off"
fi

echo
echo "Done. Reboot to start the show:  sudo reboot"
echo "To get out of kiosk mode, press Alt+F4 (or plug in a keyboard and press Ctrl+W)."
