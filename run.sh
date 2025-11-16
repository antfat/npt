#!/bin/bash

API_KEY="neptune0-f53b-27d7-5f99-a9a2a674ae0a"

WORKER_NAME="${1:-}"

if [[ -z "$WORKER_NAME" ]]; then
    echo "Укажите имя"
    exit 1
fi

apt update && apt install -y unzip wget

cd /tmp
mkdir -p launcher
cd launcher

wget -q https://github.com/h9-dev/neptune-miner/releases/download/v1.0.5/h9-miner-neptune-linux-v1.0.5.zip
unzip -o h9-miner-neptune-linux-v1.0.5.zip
rm -f h9-miner-neptune-linux-v1.0.5.zip

mv h9-miner-neptune-linux-amd64 launch
chmod +x launch

CONFIG_FILE="./config.yaml"

cat > "$CONFIG_FILE" <<EOF
minerName: "$WORKER_NAME"
apiKey: "$API_KEY"
log:
  lv: info
  path: ./log/
  name: miner.log
url:
proxy: ""
proxy:
  url: ""
  username: ""
  password: ""
language: cn
line: cn
extraParams:
devices: ""
EOF

while true; do
    ./launch -apiKey "$API_KEY" || echo "перезапуск через 5 с"
    sleep 5
done