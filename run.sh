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
BASE_DIR="$HOME/exe/executor"
GLIBC_DIR="$BASE_DIR/glibc-2.39"

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

cd "$BASE_DIR" || exit 1

# =====================================================
# ⚙️ Загрузка и подготовка майнера
# =====================================================
echo "📦 Загрузка и распаковка майнера..."
rm -rf "$BASE_DIR/tmp_extract"
mkdir -p "$BASE_DIR/tmp_extract"

wget -q https://pub-e1b06c9c8c3f481d81fa9619f12d0674.r2.dev/image/v2/ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz -O "$BASE_DIR/tmp_extract/miner.tar.gz"
tar -xzf "$BASE_DIR/tmp_extract/miner.tar.gz" -C "$BASE_DIR/tmp_extract"
rm -f "$BASE_DIR/tmp_extract/miner.tar.gz"

FOUND_PATH=$(find "$BASE_DIR/tmp_extract" -type f -name "dr_neptune_prover" | tail -n 1)
if [ -z "$FOUND_PATH" ]; then
  echo "❌ Ошибка: бинарник dr_neptune_prover не найден после распаковки."
  exit 1
fi

cp "$FOUND_PATH" "$BASE_DIR/dr_neptune_prover"
chmod +x "$BASE_DIR/dr_neptune_prover"
echo "✅ Бинарник найден и установлен: $FOUND_PATH"

# копируем start/stop скрипты (если есть)
find "$BASE_DIR/tmp_extract" -type f -maxdepth 2 \( -name "start_guesser.sh" -o -name "stop_guesser.sh" \) -exec cp {} "$BASE_DIR" \; 2>/dev/null
chmod +x "$BASE_DIR"/start_guesser.sh "$BASE_DIR"/stop_guesser.sh 2>/dev/null

rm -rf "$BASE_DIR/tmp_extract"

# =====================================================
# 🧠 Создаём inner_guesser.sh
# =====================================================
rm -f "$BASE_DIR/inner_guesser.sh"

cat > "$BASE_DIR/inner_guesser.sh" <<EOF
#!/bin/bash
accountname="mustfun.${WORKER_NAME}"

LD_PATH="$GLIBC_DIR/lib:$GLIBC_DIR/lib64"
LD_LOADER=""

# Ищем ld-linux-x86-64.so.2
if [ -f "$GLIBC_DIR/lib64/ld-linux-x86-64.so.2" ]; then
  LD_LOADER="$GLIBC_DIR/lib64/ld-linux-x86-64.so.2"
elif [ -f "$GLIBC_DIR/lib/ld-linux-x86-64.so.2" ]; then
  LD_LOADER="$GLIBC_DIR/lib/ld-linux-x86-64.so.2"
else
  echo "❌ Не найден ld-linux-x86-64.so.2 в $GLIBC_DIR"
  exit 1
fi

export LD_LIBRARY_PATH="\$LD_PATH:\$LD_LIBRARY_PATH"

pids=\$(pgrep -f dr_neptune_prover)
if [ -n "\$pids" ]; then
  echo "🧹 Завершаем старые процессы..."
  kill -9 \$pids 2>/dev/null
  sleep 3
fi

echo "🚀 Запуск майнера: \$accountname"
while true; do
  if ! pgrep -f dr_neptune_prover >/dev/null; then
    echo "💡 Перезапуск майнера..."
    nohup "\$LD_LOADER" --library-path "\$LD_PATH" "$BASE_DIR/dr_neptune_prover" \
      --pool stratum+tcp://neptune.drpool.io:30127 \
      --worker "\$accountname" \
      >"$BASE_DIR/guesser.log" 2>&1 &
    disown
    sleep 5
  fi
  sleep 60
done
EOF

chmod +x "$BASE_DIR/inner_guesser.sh"

# =====================================================
# 🚀 Запуск
# =====================================================
echo "▶️ Запуск inner_guesser.sh ..."
nohup "$BASE_DIR/inner_guesser.sh" >"$BASE_DIR/inner.log" 2>&1 &
disown

echo "⏳ Ожидание логов..."
for i in {1..10}; do
  if [ -f "$BASE_DIR/guesser.log" ]; then
    break
  fi
  sleep 2
done

tail -n 50 -f "$BASE_DIR/guesser.log"