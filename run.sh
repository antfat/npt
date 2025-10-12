#!/bin/bash

# =====================================================
# 🚀 Neptune Miner Autoinstaller (HiveOS-safe, local)
# Всё хранится в $HOME/exe/executor
# =====================================================

if [ -z "$1" ]; then
    echo "❌ Ошибка: укажите имя воркера при запуске."
    echo "Пример: ./run.sh myminer01"
    exit 1
fi

WORKER_NAME="$1"
BASE_DIR="$HOME/exe/executor"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1

# =====================================================
# 🔍 Проверка GLIBC и установка при необходимости
# =====================================================
echo "🔍 Проверка версии GLIBC..."
GLIBC_VER=$(ldd --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)

if [[ -z "$GLIBC_VER" || $(echo "$GLIBC_VER < 2.38" | bc -l) -eq 1 ]]; then
    echo "⚠️ Найдена старая версия GLIBC ($GLIBC_VER). Устанавливаю glibc 2.39 локально..."
    apt update -y >/dev/null 2>&1
    apt install -y wget tar make gcc g++ >/dev/null 2>&1

    GLIBC_LOCAL="$BASE_DIR/glibc-2.39"
    if [ ! -d "$GLIBC_LOCAL/lib" ]; then
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
        echo "✅ GLIBC 2.39 уже установлена локально."
    fi
else
    echo "✅ GLIBC версия $GLIBC_VER — в норме."
fi

cd "$BASE_DIR" || exit 1

# =====================================================
# ⚙️ Загрузка и установка майнера
# =====================================================
echo "📦 Устанавливаю майнер..."
rm -rf "$BASE_DIR/dr_neptune_prover" "$BASE_DIR"/ubuntu_24_avx512-*

wget -q https://pub-e1b06c9c8c3f481d81fa9619f12d0674.r2.dev/image/v2/ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
tar -xzf ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
rm -f ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz

# Поиск бинарника dr_neptune_prover
FOUND_PATH=$(find "$BASE_DIR" -type f -name "dr_neptune_prover" | head -n 1)
if [ -z "$FOUND_PATH" ]; then
    echo "❌ Ошибка: бинарник dr_neptune_prover не найден после распаковки."
    exit 1
else
    cp "$FOUND_PATH" "$BASE_DIR/dr_neptune_prover"
    chmod +x "$BASE_DIR/dr_neptune_prover"
    echo "✅ Бинарник найден и установлен: $FOUND_PATH"
fi

# =====================================================
# 🧠 Создаём inner_guesser.sh
# =====================================================
rm -f "$BASE_DIR/inner_guesser.sh"

cat > "$BASE_DIR/inner_guesser.sh" <<EOF
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
        nohup "$BASE_DIR/dr_neptune_prover" --pool stratum+tcp://neptune.drpool.io:30127 --worker "\$accountname" >"$BASE_DIR/guesser.log" 2>&1 &
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
nohup "$BASE_DIR/inner_guesser.sh" >"$BASE_DIR/inner.log" 2>&1 &
disown

echo "⏳ Ожидание создания guesser.log..."
for i in {1..10}; do
    if [ -f "$BASE_DIR/guesser.log" ]; then
        break
    fi
    sleep 2
done

tail -n 100 -f "$BASE_DIR/guesser.log"