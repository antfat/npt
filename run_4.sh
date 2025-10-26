#!/bin/bash
# =====================================================
# 🚀 Neptune Miner Autoinstaller (HiveOS-safe, final)
# Все файлы, glibc и логи находятся в $HOME/exe/executor
# =====================================================

if [ -z "$1" ]; then
  echo "❌ Укажите имя воркера. Пример: ./run.sh myminer01"
  exit 1
fi

WORKER_NAME="$1"
BASE_DIR="$HOME/exe"
WORKER_DIR="$BASE_DIR/executor"
MINER_ARCH="ubuntu_20-dr_neptune_prover-3.4.1.tar.gz"
MINER_URL="https://pub-e1b06c9c8c3f481d81fa9619f12d0674.r2.dev/image/v2/$MINER_ARCH"

# =====================================================
# ⚙️ Загрузка и подготовка майнера
# =====================================================
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1

# Распаковываем архив
wget -q "$MINER_URL"
tar -xzf "$MINER_ARCH"
mv dr_neptune_prover executor

# Удаляем архив после распаковки
rm -f "$MINER_ARCH"
cd executor || exit 1

# =====================================================
# 🧠 Создаём inner_guesser.sh
# =====================================================
rm -rf inner_guesser.sh
cat > inner_guesser.sh <<EOF
#!/bin/bash
# set your own drpool accountname
accountname="mustfun.${WORKER_NAME}"
pids=\$(ps -ef | grep dr_neptune_prover | grep -v grep | awk '{print \$2}')
if [ -n "\$pids" ]; then
  echo "\$pids" | xargs kill
  sleep 5
fi
while true; do
  target=\$(ps aux | grep dr_neptune_prover | grep -v grep)
  if [ -z "\$target" ]; then
    ./dr_neptune_prover -g 0,1,2,3 -m 1 --pool stratum+tcp://neptune.drpool.io:30127 --worker "\$accountname"
    sleep 5
  fi
  sleep 60
done
EOF

chmod +x inner_guesser.sh

# =====================================================
# 🚀 Запуск
# =====================================================
cd "$WORKER_DIR" || exit 1
./start_guesser.sh &

echo "⏳ Ожидание логов..."
for i in {1..10}; do
  if [ -f "$WORKER_DIR/guesser.log" ]; then
    break
  fi
  sleep 2
done

tail -n 50 -f "$WORKER_DIR/guesser.log"