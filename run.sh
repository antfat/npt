
#!/bin/bash

# =====================================================
# 🚀 Neptune miner autoinstaller for HiveOS (Ubuntu 24.04)
# =====================================================

if [ -z "$1" ]; then
    echo "❌ Ошибка: укажите имя воркера при запуске."
    echo "Пример: ./run.sh myworker01"
    exit 1
fi

WORKER_NAME="$1"

cd $HOME
mkdir -p exec
cd exec

# =====================================================
# 🔍 Проверка и обновление GLIBC (только если нужно)
# =====================================================
echo "🔍 Проверка версии GLIBC..."
GLIBC_VER=$(ldd --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)

if [ -z "$GLIBC_VER" ]; then
    echo "⚠️ Не удалось определить версию glibc. Устанавливаю libc6..."
    apt update -y >/dev/null 2>&1
    apt install -y libc6 >/dev/null 2>&1
else
    if [[ $(echo "$GLIBC_VER < 2.38" | bc -l) -eq 1 ]]; then
        echo "⚠️ Найдена устаревшая версия GLIBC ($GLIBC_VER). Обновляем..."
        apt update -y >/dev/null 2>&1
        apt install -y --only-upgrade libc6 >/dev/null 2>&1
        echo "✅ GLIBC обновлена до версии:"
        ldd --version | head -n1
    else
        echo "✅ GLIBC версия $GLIBC_VER — в норме."
    fi
fi

# =====================================================
# ⚙️ Развёртывание и запуск майнера
# =====================================================
rm -rf executor

wget -q https://pub-e1b06c9c8c3f481d81fa9619f12d0674.r2.dev/image/v2/ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
tar -xzf ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
rm -f ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz

mv dr_neptune_prover executor
cd executor

# создаём каталог логов, если нет
mkdir -p /tmp/work/worker

# Создаём inner_guesser.sh заново
rm -f inner_guesser.sh

cat > inner_guesser.sh <<EOF
#!/bin/bash
accountname="mustfun.${WORKER_NAME}"

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
        nohup ./dr_neptune_prover --pool stratum+tcp://neptune.drpool.io:30127 --worker "\$accountname" >/tmp/work/worker/guesser.log 2>&1 &
        disown
        sleep 5
    fi
    sleep 60
done
EOF

chmod +x inner_guesser.sh start_guesser.sh stop_guesser.sh dr_neptune_prover

nohup ./inner_guesser.sh >/tmp/work/worker/inner.log 2>&1 &
disown

echo "⏳ Ожидание создания guesser.log..."
for i in {1..10}; do
    if [ -f "/tmp/work/worker/guesser.log" ]; then
        break
    fi
    sleep 2
done

tail -n 100 -f /tmp/work/worker/guesser.log