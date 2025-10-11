#!/bin/bash

if [ -z "$1" ]; then
    exit 1
fi

WORKER_NAME="$1"

cd $HOME
mkdir -p exec
cd exec

wget -q https://pub-e1b06c9c8c3f481d81fa9619f12d0674.r2.dev/image/v2/ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
tar -xzf ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz
rm -f ubuntu_24_avx512-dr_neptune_prover-2.1.0.tar.gz

mv dr_neptune_prover executor
cd executor

rm -f inner_guesser.sh

cat > inner_guesser.sh <<EOF
#!/bin/bash
# ==========================================
# 🚀 Inner Guesser Auto-Restart Script
# ==========================================
# Автоматически перезапускает майнер dr_neptune_prover
# если он перестал работать.
# ==========================================

accountname="mustfun.${WORKER_NAME}"

pids=\$(ps -ef | grep dr_neptune_prover | grep -v grep | awk '{print \$2}')
if [ -n "\$pids" ]; then
    echo "🧹 Завершаем старые процессы dr_neptune_prover..."
    echo "\$pids" | xargs kill
    sleep 5
fi

echo "🚀 Запуск майнера с именем: \$accountname"

while true; do
    target=\$(ps aux | grep dr_neptune_prover | grep -v grep)
    if [ -z "\$target" ]; then
        nohup ./dr_neptune_prover --pool stratum+tcp://neptune.drpool.io:30127 --worker "\$accountname" >$HOME/exe/executor/guesser.log 2>&1 &
        disown
        sleep 5
    fi
    sleep 60
done
EOF

chmod +x inner_guesser.sh start_guesser.sh stop_guesser.sh dr_neptune_prover

nohup ./inner_guesser.sh >$HOME/exe/executor/inner.log 2>&1 &
disown

tail -n 100 -f $HOME/exe/executor/guesser.log