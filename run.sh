#!/bin/bash
# ===== Cấu hình =====
USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"
WORK_DIR="$HOME_DIR/iniminer"
SCRIPT_PATH="$HOME_DIR/run_iniminer.sh"
MINER_BINARY="iniminer-linux-x64"
MINER_URL="https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64"
POOL="stratum+tcp://0x80b6D2c5bE4E52F10b2360c95AFeEAc9Efb0C0A3.Worker001@pool-b.yatespool.com:32488"
SERVICE_FILE="/etc/systemd/system/iniminer.service"
echo ">>> Bắt đầu cài đặt INI Miner..."
# ===== Tạo thư mục và tải miner nếu chưa có =====
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1
if [ ! -f "$MINER_BINARY" ]; then
echo ">>> Tải miner từ $MINER_URL"
wget "$MINER_URL" -O "$MINER_BINARY"
chmod +x "$MINER_BINARY"
else
echo ">>> Miner đã tồn tại, bỏ qua bước tải."
fi
# ===== Tạo script chạy miner =====
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
# ===== Tạo systemd service =====
echo ">>> Tạo file service tại $SERVICE_FILE"
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
# ===== Kích hoạt service =====
echo ">>> Kích hoạt và khởi động dịch vụ..."
sudo systemctl daemon-reload
sudo systemctl enable iniminer.service
sudo systemctl restart iniminer.service
echo "✅ Đã cài đặt xong INI Miner và khởi chạy!"
echo "➡️ Xem log: tail -f $WORK_DIR/miner.log"
echo "➡️ Quản lý: sudo systemctl status iniminer"
