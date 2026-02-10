#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Args
# =========================
if [[ $# -lt 1 ]]; then
  echo "❌ Укажите номер воркера (например: 01, 02, 03)"
  exit 1
fi

WORKER_SUFFIX="$1"
if ! [[ "$WORKER_SUFFIX" =~ ^[0-9]{1,3}$ ]]; then
  echo "❌ Номер воркера должен быть числом"
  exit 1
fi

WORKER_NAME="v0$WORKER_SUFFIX"

# =========================
# Const
# =========================
WORKDIR="$HOME/work"
GPU_WORKERDIR="$WORKDIR/gpu"
CPU_WORKERDIR="$WORKDIR/cpu"
RESTART_DELAY=15

mkdir -p "$WORKDIR" "$GPU_WORKERDIR" "$CPU_WORKERDIR"

# =========================
# Config: GPU
# =========================
GPU_WALLET="mustfun"
GPU_POOL="coinsforall.io"
GPU_PORT="6666"

# =========================
# Config: CPU (без изменений)
# =========================
CPU_MINER_URL="https://github.com/doktor83/SRBMiner-Multi/releases/download/3.1.1/SRBMiner-Multi-3-1-1-Linux.tar.gz"
CPU_ARCHIVE="$CPU_WORKERDIR/SRBMiner-Multi-3-1-1-Linux.tar.gz"
CPU_PUBKEY="0x4f752c9f474da78330b7c92e45217f0234004862"
CPU_POOL="eu.0xpool.io:3333"
CPU_ALGO="randomx"
CPU_LOGFILE="$CPU_WORKERDIR/cpu_miner.log"

# =========================
# Helpers
# =========================
log() {
  echo -e "[$(date '+%H:%M:%S')] $*"
}

download_if_needed() {
  [[ -s "$2" ]] || wget -q --show-progress -O "$2" "$1"
}

extract_clean() {
  rm -rf "$2/extract"
  mkdir -p "$2/extract"
  tar -xzf "$1" -C "$2/extract"
}

# =========================
# GPU Install / Build
# =========================
prepare_gpu() {
  log "🔧 Installing GPU dependencies"
  apt update
  apt install -y \
    libzmq3-dev protobuf-compiler libprotobuf-dev \
    libcurl4-openssl-dev libgmp-dev libgmpxx4ldbl \
    libjansson-dev ocl-icd-opencl-dev libssl-dev \
    cmake build-essential nvidia-cuda-toolkit git

  if [[ ! -d "$GPU_WORKERDIR/xpmclient" ]]; then
    log "⬇ Cloning xpmclient"
    git clone https://github.com/primecoin/xpmclient.git "$GPU_WORKERDIR/xpmclient"
  fi

  cd "$GPU_WORKERDIR/xpmclient"
  mkdir -p build
  cd build

  log "⚙ Building xpmclientnv"
  cmake ../src -DCMAKE_BUILD_TYPE=Release
  make -j"$(nproc)"

  log "📝 Writing config.txt"
  cat > config.txt <<EOF
mode = "pool";
rpcurl = "";
rpcuser = "";
rpcpass = "";
wallet = "";
server = "coinsforall.io";
port = "6666";
address = "mustfun";
onCrash = "0";
cpuload = "1";
target = "auto";
sieveSize = "630";
weaveDepth = "45056";
width = "auto";
windowSize = "12288";
multiplierLimits = ["24", "31", "35"];

devices = ["1","1","1","1","1","1","1","1"];
sievePerRound = ["5","5","5","5","5","5","5","5"];

corefreq  = ["-1","-1","-1","-1","-1","-1","-1","-1"];
memfreq   = ["-1","-1","-1","-1","-1","-1","-1","-1"];
powertune = ["-1","-1","-1","-1","-1","-1","-1","-1"];
fanspeed  = ["-1","-1","-1","-1","-1","-1","-1","-1"];
EOF
}

GPU_BIN="$GPU_WORKERDIR/xpmclient/build/xpmclientnv"

# =========================
# CPU Install (без изменений)
# =========================
download_if_needed "$CPU_MINER_URL" "$CPU_ARCHIVE"
extract_clean "$CPU_ARCHIVE" "$CPU_WORKERDIR"

CPU_BIN="$(find "$CPU_WORKERDIR/extract" -type f -name SRBMiner-MULTI -print -quit)"
chmod +x "$CPU_BIN"

# =========================
# Cleanup
# =========================
GPU_PID=""
CPU_PID=""

cleanup() {
  log "🛑 Stopping miners..."
  [[ -n "$GPU_PID" ]] && kill "$GPU_PID" 2>/dev/null || true
  [[ -n "$CPU_PID" ]] && kill "$CPU_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  log "✅ Stopped"
}

trap cleanup INT TERM EXIT

# =========================
# Run GPU (LOGS TO CONSOLE)
# =========================
run_gpu() {
  while true; do
    log "🚀 GPU miner start"
    set +e
    "$GPU_BIN"
    EXIT_CODE=$?
    set -e
    log "⚠ GPU miner exited code=$EXIT_CODE, restart in ${RESTART_DELAY}s"
    sleep "$RESTART_DELAY"
  done
}

# =========================
# Run CPU (LOGS TO FILE ONLY)
# =========================
run_cpu() {
  while true; do
    log "🚀 CPU miner start"
    set +e
    "$CPU_BIN" \
      --algorithm "$CPU_ALGO" \
      --pool "$CPU_POOL" \
      --wallet "$CPU_PUBKEY" \
      --password "$WORKER_NAME" \
      >>"$CPU_LOGFILE" 2>&1
    EXIT_CODE=$?
    set -e
    echo "CPU exited code=$EXIT_CODE, restart in ${RESTART_DELAY}s" >>"$CPU_LOGFILE"
    sleep "$RESTART_DELAY"
  done
}

# =========================
# Start
# =========================
prepare_gpu

log "▶ Starting miners"
run_gpu & GPU_PID=$!
run_cpu & CPU_PID=$!

log "✅ GPU_PID=$GPU_PID CPU_PID=$CPU_PID"
log "ℹ Ctrl+C to stop"
wait