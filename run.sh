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
MINER_ARCH="ubuntu_20-dr_neptune_prover-3.3.1.tar.gz"
MINER_URL="https://pub-e1b06c9c8c3f481d81fa9619f12d0674.r2.dev/image/v2/$MINER_ARCH"


GLIBC_DIR="$BASE_DIR/glibc-2.39"

# ==== ОБНОВЛЕНИЕ ПАПКИ ====
if [ -d "$BASE_DIR" ]; then
  rm -rf "$BASE_DIR"
fi
mkdir -p "$BASE_DIR"

cd "$BASE_DIR" || exit 1

# =====================================================
# 🔍 Проверка и установка GLIBC (локально)
# =====================================================
echo "🔍 Проверка версии GLIBC..."
GLIBC_VER=$(ldd --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)

if [[ -z "$GLIBC_VER" || $(echo "$GLIBC_VER < 2.38" | bc -l) -eq 1 ]]; then
  if [ ! -f "$GLIBC_DIR/lib64/ld-linux-x86-64.so.2" ]; then
    echo "⚙️ Старая glibc ($GLIBC_VER). Устанавливаю локально glibc 2.39..."
    apt update -y >/dev/null 2>&1
    apt install -y wget tar make gcc g++ >/dev/null 2>&1

    cd "$BASE_DIR"
    wget -q https://ftp.gnu.org/gnu/libc/glibc-2.39.tar.gz
    tar -xzf glibc-2.39.tar.gz
    cd glibc-2.39
    mkdir build && cd build
    ../configure --prefix="$GLIBC_DIR" >/dev/null
    make -j$(nproc) >/dev/null 2>&1
    make install >/dev/null 2>&1
    echo "✅ GLIBC 2.39 установлена в $GLIBC_DIR"
  else
    echo "✅ GLIBC 2.39 уже установлена локально."
  fi
else
  echo "✅ GLIBC версия $GLIBC_VER — в норме."
fi


# =====================================================
# ⚙️ Загрузка и подготовка майнера
# =====================================================
# Создаём директории
mkdir -p "$WORKER_DIR"
cd "$BASE_DIR" || exit 1

# Скачиваем архив в BASE_DIR
wget -q -O "$BASE_DIR/$MINER_ARCH" "$MINER_URL"

# Распаковываем архив в WORKER_DIR
tar -xzf "$BASE_DIR/$MINER_ARCH" -C "$WORKER_DIR"

# Удаляем архив после распаковки
rm -f "$BASE_DIR/$MINER_ARCH"

cd "$WORKER_DIR" || exit 1

# =====================================================
# 🧠 Создаём inner_guesser.sh
# =====================================================
rm -f "$WORKER_DIR/inner_guesser.sh"

cat > "$WORKER_DIR/inner_guesser.sh" <<EOF
#!/bin/bash

# set your own drpool accountname
accountname="mustfun.${WORKER_NAME}"

pids=$(ps -ef | grep dr_neptune_prover | grep -v grep | awk '{print $2}')
if [ -n "$pids" ]; then
    echo "$pids" | xargs kill
    sleep 5
fi

while true; do
    target=$(ps aux | grep dr_neptune_prover | grep -v grep)
    if [ -z "$target" ]; then
        ./dr_neptune_prover --pool stratum+tcp://neptune.drpool.io:30127 --worker $accountname
        sleep 5
    fi
    sleep 60
done
EOF

chmod +x "$WORKER_DIR/inner_guesser.sh"

# =====================================================
# 🚀 Запуск
# =====================================================
echo "▶️ Запуск ..."
nohup "$WORKER_DIR/start_guesser.sh" >"$WORKER_DIR/executor.log" 2>&1 &
disown

echo "⏳ Ожидание логов..."
for i in {1..10}; do
  if [ -f "$WORKER_DIR/executor.log" ]; then
    break
  fi
  sleep 2
done

tail -n 50 -f "$WORKER_DIR/executor.log"