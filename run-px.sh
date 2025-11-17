#!/bin/bash

API_KEY="neptune0-f53b-27d7-5f99-a9a2a674ae0a"

WORKER_NAME="${1:-}"

if [[ -z "$WORKER_NAME" ]]; then
    echo "Укажите имя"
    exit 1
fi

WORKDIR="launcher"

apt update && apt install -y unzip wget

cd /tmp

if [ -d "$WORKDIR" ]; then
  rm -rf "$WORKDIR"
fi

mkdir -p "$WORKDIR"

cd "$WORKDIR"

wget -q https://github.com/h9-dev/neptune-miner/releases/download/v1.0.5/x-proxy-neptune-v1.0.5-1.zip
unzip -o x-proxy-neptune-v1.0.5-1.zip
rm -f x-proxy-neptune-v1.0.5-1.zip

mv x-proxy-neptune-linux-amd64 launch
chmod +x launch

CONFIG_FILE="./config.yaml"

cat > "$CONFIG_FILE" <<EOF
server:
    host: 0.0.0.0
    port: 9190
dbFile: "proxy.db"
chains:
    -
        chain: neptune
        apiKey: "$API_KEY"
proxy:
    url: ""
    username: ""
    password: ""
EOF

while true; do
    ./launch -apiKey "$API_KEY" || echo "перезапуск через 5 с"
    sleep 5
done