#!/bin/bash

# Kiểm tra xem thư mục project có tồn tại không
if [ ! -d "project" ]; then
    mkdir project
fi

# Di chuyển vào thư mục project
cd project

# Tải file từ Github nếu chưa có
if [ ! -f "iniminer-linux-x64" ]; then
    wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64
    chmod +x iniminer-linux-x64
fi

# Chạy miner
sudo ./iniminer-linux-x64 --pool stratum+tcp://0x7d97f01d69a7b0eB7C4cA9AC80Deb609A885996f.Woker001@pool-b.yatespool.com:32488
