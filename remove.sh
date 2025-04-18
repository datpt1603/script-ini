#!/bin/bash

set -e

echo "🚮 Removing old Docker and containerd (if any)..."
sudo systemctl stop docker || true
sudo apt remove -y docker docker.io docker-engine containerd containerd.io runc || true
sudo apt purge -y docker docker.io docker-engine containerd containerd.io runc || true
sudo apt autoremove -y || true

echo "🔧 Unmasking Docker and containerd services..."
sudo systemctl unmask docker.service || true
sudo systemctl unmask docker.socket || true
sudo systemctl unmask containerd.service || true

echo "🧹 Removing old Android Studio (if exists)..."
sudo rm -rf /opt/google/android-studio
sudo rm -rf /opt/google/Android

echo "📦 Installing official Docker from Docker repository..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "📂 Creating /home/docker-data as Docker data directory..."
sudo mkdir -p /home/docker-data
sudo chown -R root:root /home/docker-data

echo "🛠️ Configuring Docker to use /home/docker-data..."
sudo mkdir -p /etc/docker
echo '{
  "data-root": "/home/docker-data"
}' | sudo tee /etc/docker/daemon.json

echo "⚙️ Overriding docker.service to disable socket activation..."
sudo mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF | sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --host=unix:///var/run/docker.sock --containerd=/run/containerd/containerd.sock
EOF

echo "🔄 Reloading systemd and starting Docker..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl disable docker.socket || true
sudo systemctl enable docker.service
sudo systemctl restart docker.service

echo "✅ Docker installation complete. Data directory:"
docker info | grep "Docker Root Dir"

echo "🚀 Running test container (hello-world)..."
docker run --rm hello-world

