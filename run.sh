#!/bin/bash

# =====================================================
# 🚀 Neptune Miner Autoinstaller (HiveOS-safe, local)
# Все файлы и логи — в $HOME/exe/executor
# =====================================================

if [ -z "$1" ]; then
    exit 1
fi

WORKER_NAME="$1"

# Папка установки
BASE_DIR="$HOME/exe/executor"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1

# =====================================================
# 🔍 Проверка и локальная установка GLIBC 2.39
# =====================================================
echo "🔍 Проверка версии GLIBC..."
GLIBC_VER=$(ldd --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)

if [[ -z "$GLIBC_VER" || $(echo "$GLIBC_VER < 2.38" | bc -l) -eq 1 ]]; then
    echo "⚠️ Найдена старая версия GLIBC ($GLIBC_VER). Устанавливаю glibc 2.39 локально..."

    apt update -y >/dev/null 2>&1
    apt install -y wget tar make gcc g++ >/dev/null 2>&1

    # Устанавливаем glibc в локальную директорию
    GLIBC_LOCAL="$BASE_DIR/glibc-2.39"
    mkdir -p "$GLIBC_LOCAL"
    cd "$BASE_DIR"
    wget -q https://ftp.gnu.org/gnu/libc/glibc-2.39.tar.gz
    tar -xzf glibc-2.39.tar.gz
    cd glibc-2.39
    mkdir build && cd build
    ../configure --prefix="$GLIBC_LOCAL" >/dev/null
    make -j$(nproc) >/dev/null 2>&1
    make install >/dev/null 2>&1

    echo "✅ GLIBC 2.39 установлена локально в $GLIBC_LOCAL"
else
    echo "✅ GLIBC версия $GLIBC_VER — в норме."
fi

cd "$BASE_DIR" || exit 1

# =====================================================
# ⚙️ Загрузка и запуск майнера
# =====================================================
echo "📦 Устанавливаю майнер..."
rm -f ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
wget -q https://pub-e1b06c9c8c3f481d81fa9619f12d0674.r2.dev/image/v2/ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz

# Распаковка прямо в текущую папку
tar -xzf ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
rm -f ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz

# Убедимся, что бинарь скопирован в текущую папку
if [ -d "$BASE_DIR/dr_neptune_prover" ]; then
    cp -r "$BASE_DIR/dr_neptune_prover/." "$BASE_DIR/" >/dev/null 2>&1
    rm -rf "$BASE_DIR/dr_neptune_prover"
fi

chmod +x dr_neptune_prover || true
rm -f inner_guesser.sh

# =====================================================
# 🧠 Создаём inner_guesser.sh
# =====================================================
cat > inner_guesser.sh <<EOF
#!/bin/bash
accountname="mustfun.${WORKER_NAME}"
GLIBC_PATH="$BASE_DIR/glibc-2.39/lib"

export LD_LIBRARY_PATH="\$GLIBC_PATH:\$LD_LIBRARY_PATH"

pids=\$(ps -ef | grep dr_neptune_prover | grep -v grep | awk '{print \$2}')
if [ -n "\$pids" ]; then
    echo "🧹 Завершаем старые процессы..."
    echo "\$pids" | xargs kill
    sleep 5
fi

echo "🚀 Запуск майнера: \$accountname"

while true; do
    target=\$(ps aux | grep dr_neptune_prover | grep -v grep)
    if [ -z "\$target" ]; then
        echo "💡 Перезапуск майнера..."
        nohup ./dr_neptune_prover --pool stratum+tcp://neptune.drpool.io:30127 --worker "\$accountname" >"$BASE_DIR/guesser.log" 2>&1 &
        disown
        sleep 5
    fi
    sleep 60
done
EOF

chmod +x inner_guesser.sh

# =====================================================
# 🚀 Запуск скрипта автоперезапуска
# =====================================================
nohup "$BASE_DIR/inner_guesser.sh" >"$BASE_DIR/inner.log" 2>&1 &
disown

echo "⏳ Ожидание появления логов..."
for i in {1..10}; do
    if [ -f "$BASE_DIR/guesser.log" ]; then
        break
    fi
    sleep 2
done

tail -n 100 -f "$BASE_DIR/guesser.log"