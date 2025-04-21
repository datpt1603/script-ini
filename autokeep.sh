#!/bin/bash

set -e

# =============================================
# 0. Khai báo chung
# =============================================
USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"
WORK_DIR="$HOME_DIR/iniminer"
SCRIPT_PATH="$HOME_DIR/run_iniminer.sh"
MINER_BINARY="iniminer-linux-x64"
MINER_URL="https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64"
POOL="stratum+tcp://0xc4b20dd83e9de7cb829dea7e6beba5cd58e1c757.Worker001@pool-b.yatespool.com:32488"
SERVICE_FILE="/etc/systemd/system/iniminer.service"
MONITOR_SCRIPT="$HOME_DIR/monitor.sh"

# =============================================
# 1. Thiết lập Miner chạy nền bằng systemd
# =============================================
echo "✅ Thiết lập Miner..."

if [ ! -f "$WORK_DIR/$MINER_BINARY" ]; then
    echo "⚡ Miner chưa tồn tại, tải về..."

    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || exit 1

    wget "$MINER_URL" -O "$MINER_BINARY"
    chmod +x "$MINER_BINARY"

    cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash
cd "$WORK_DIR" || exit 1
while true; do
    echo "Starting miner..."
    ./"$MINER_BINARY" --pool "$POOL"
    echo "Miner crashed. Restarting in 5 seconds..."
    sleep 5
done
EOF

    chmod +x "$SCRIPT_PATH"
else
    echo "✔ Miner đã tồn tại, bỏ qua tải lại."
fi

if [ ! -f "$SERVICE_FILE" ]; then
    echo "⚡ Tạo systemd service cho miner..."

    sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=INI Miner Service
After=network.target

[Service]
User=$USER_NAME
Environment=HOME=$HOME_DIR
WorkingDirectory=$HOME_DIR
ExecStart=/bin/bash $SCRIPT_PATH
Restart=always
RestartSec=5
StandardOutput=append:$WORK_DIR/miner.log
StandardError=append:$WORK_DIR/miner_error.log

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable iniminer.service
fi

sudo systemctl restart iniminer.service
echo "✔ Miner đang chạy. (sudo systemctl status iniminer)"

# =============================================
# 2. Thiết lập monitor.sh tự động (không hỏi)
# =============================================
echo
echo "==== SCRIPT TỰ ĐỘNG THIẾT LẬP GIÁM SÁT VNC ===="

# Lấy URL từ biến môi trường VNC_URL hoặc dùng mặc định
URL="${VNC_URL:-https://cloudworkstations.dev/vnc.html?autoconnect=true&resize=remote}"

echo "⚡ Sử dụng URL VNC: $URL"

cat > "$MONITOR_SCRIPT" << EOL
#!/bin/bash
URL="$URL"
curl -s "\$URL" > /dev/null 2>&1
echo "\$(date '+%Y-%m-%d %H:%M:%S') - Đã kết nối đến \$URL" >> "$HOME_DIR/vnc_monitor.log"
tail -n 1000 "$HOME_DIR/vnc_monitor.log" > "$HOME_DIR/vnc_monitor.log.tmp"
mv "$HOME_DIR/vnc_monitor.log.tmp" "$HOME_DIR/vnc_monitor.log"
EOL

chmod +x "$MONITOR_SCRIPT"

# Cập nhật crontab
(crontab -l 2>/dev/null | grep -v "$MONITOR_SCRIPT" ; echo "*/1 * * * * $MONITOR_SCRIPT") | crontab -

echo "✔ Đã thiết lập monitor.sh với URL: $URL"

# =============================================
# 3. Cài caffeine (nếu chưa) và chạy ngầm
# =============================================
if ! command -v caffeine &> /dev/null; then
    echo ">>> Cài đặt caffeine..."
    sudo apt update
    sudo apt install -y caffeine
fi

caffeine & disown > /dev/null 2>&1

# =============================================
# 4. Thông báo hoàn tất
# =============================================
echo
echo "🚀 Setup hoàn tất!"
echo "⚡ Xem log miner: tail -f $WORK_DIR/miner.log"
echo "⚡ Xem log VNC: tail -f $HOME_DIR/vnc_monitor.log"
