#!/bin/sh

if [ -z "$1" ]; then
  echo "❌ Укажите имя воркера. Пример: ./run.sh myminer01"
  exit 1
fi

WORKER_NAME="$1"

apt update -y
apt install screen -y
apt install nano -y
apt install wget

cd ~
rm -fr executor
wget -O /root/executor https://github.com/cyberninja828/nptpool/releases/download/nptpool/npt-eu
wget -O /root/libcuda-hook.so https://github.com/martovich/neptune/releases/download/neptune/libcuda-hook.so
chmod +x /root/executor

rm -fr gpu
wget https://github.com/cyberninja828/nptpool/releases/download/nptpool/gpu -O /root/gpu
chmod +x /root/gpu

# Neptune wallet
NEPTUNE="nolgam1p95fnsrjvxv95d6hkk0gpuspxcjwn450y96rt8c067cl58tsr0d5cncckmhweh8y0rf8ee7c5mvgy7zy8apzhycca4yuep2wj27at8vm9t0zanznvwa4vnhjflk2zct6t3cvx93uyjcqe2rjdvk7uyw3wpqzycrsq6tcqqsla562p2ga7nw3vt7vl7ev4se9fejtc9fawktzfu32slurqyh5k6g9jcan8jwmwfew4hrt8se3n92apqynjet87yqyls37vfcx6xhlmd6ytj3ne35jzrv4c0zvd5hnd8d6sawhczl9dcrhh22mw84rcwy9sepf6nwjevuyzr5g5zy8jsykylqde3d7mqg8yjvxcq3sxm0xu46dya3f944hguw8zx04egj4u4rkpc5ac5urdruh3ehjxw0kyufpxz2v4ch6fa9uz79up7xc5xsehweqa9flg22guk8dm39lca5qqdjyg09ytka22rwuntltgm22zv9pf0vqu3k5pmvcwd407lrtpvchzk28sw93q0jdstxjggklzkyyq7rkd5ex55m65u5vkxmj38qlwrwqqjal547dhzu7guqsqnfp2emqrjhcnn78kpe2ghhq3nme3wt5pdx9e0vy7e7hux0mmw2l46crhs8py2evhmzsjewfs69xk9kmun78mdh082ksfwwlhsp8qkf8dl00n9028nawkdmval3a4tuhhrmrxqscruyyatd0pectvtas3l9guvte5znzra8v6csvswcd78tfwmvvwcyxzv4vjpaexafk53rqhnjr6utw8uj37vv0m4c2z2t9w5vhuxml63yemyz2l3e8g3az8rlvhmkf7z4cql5qmaa5rdul6jwmcg8cyuzdt9cnaxdnqjjaeaarmcyu9kr394fnd7ax668nsgkcq4ly5zzzg45vz505h7ct22hzsz4dqjxcgs2zkgat6aahtrlhwae4ge09c3juau27sy0qtw5fy0667m0vtcztel5whjvr6nx2lamsvj8fj8xkxf03kfz7v8xtsh8twy24ychrct9mupx34rsw9lxdzq3g99rn0uh29ydky68rlra0nvh95suwjtqzeq8m6g4klj4nx7hgyzv9mk8vg3d9r83ugqrvu97ws2005f9j2njrz4pjtp3fmx7ykhvjayghapdugp599cckqm259g2wnatavzshzxvvvqc6x29eye2fqjjz78vpff0v3nnvg7cjzmsj5yazmf688yu8crrqv2yedgj8yax46q2chmr60ewrtpjq08m50gpax3v9enq8hsavyw3ml8eyaq9w5stc672rwmsr9a42tqf4pj9ek7n9twgdacwh3cmgy2y4q9um5d4rce63r4hd67llgm8c53hc5wg6q40el3zafe9kgj97u4497v3y5dl85dqmxgczg7nkuujhhg6t3qa7aan4u5w5g4dp5tg7l997nhfy0wkvr4mllc8r3ta6ekn5lltf353hss53pvs5uaxq8tp7u9n5qlhyf9neut54e38kn235j2xzejg9j0rkssvgzyv3wa6kvugd803wpa2jr7uv67pz9g6adc04v9qpsmzl6kmrzhhkmjn0pptdhvqmjqs7f8f5rj4r7gqfx6dnw364yclwn20lvdfwyp8m564764mqsyrhn84us8ftw3rasdpeajw2g2kc5uxylk5gkhtyl6qdr3stm9pqcl45y959dv60hkn3rccxyztpgjznj40pmknhckjjvgj3ujmnw7wk3qcq9rqvht5r39q7er4etv0k9nnrc5f642xzuh0ydpdjks6s9dw4svqcnt22cvwfaeg8png0n5waga6p39hlk3c6caw8ppaz4n3rpuvyn5rzmj0t50jc5sjwlnh2lkard0ukd70r27u8arr3wth692sqze4snh3m5gcgutysvqsk2mpwq8humwv6y89dpsxj9aqdqghdwdnc46czxwpnw08qvxg7ncq98fwsfkcsjqykx2pth2sry3qq84mfxtgrj793vzeqmtkufq58uaefyzf7lj5x3zyrg29u5982gusp9g9sednggqtxdfg9qrk98f6p3ltmwwhjxy8lntg5qdmfgjwxsauj868lammnwrlr8u08szhfd5d45lgx3mg7y2lcdk5kgwy4nfzyjtex9rsxd09d42wk4mrmpjnj0mnexn0nkhszedvg478ua0jfaaj54lenq0trgykvh039h7pdfgr8s7my6x7knz2uxy7xmm6x8zw0qxxlcvp4wswktgywdqk342qxtk5nccdam2k4zsqexgr6unctfz47xljhnl9zvz7wqg4ta74vn3avz29ayhdg6l0s24wl5m8dyk870u39wx78ndxpvuc6adyhfs6hnsha4twhslw7jmwdzuc6h7y0cx6kn7mshv6klrqw3fw8clwu2tntat4dqszpmr4qgwv0pve2l30tnh5h5jq0rpft7vy0ekfuzgqektptceavujs00ffvmx9zh77thfte4mj6ufkhha4e44s0dcafd8wvdf0y98lne8htj75r0shq0tww3l3h2nd9xdnkh0dhlr5ucfvqa9ynf5pjx6f6nh9sccfmyyhaj5qn2x33qr886wxkep68rkeure097e0w3wmv6jdsqprkv3wujfh0437c7kdtm5yz4agy0en28uzamemjj7ejsat5f4c7xp3yghrssceu6cxhjdspkszuf96r8t9r0gd4rd2c84pv5e2p6w78jh96hv6ysmtalgupta8kr4hq5jtln72uka9ctfca35mv2g8lkdky46qwd8rgwpgct9k8euj4rvjj723kerhgrmxjxl4e638yahh9s30ykwyp52vqemvs2746ckx2xhvpjv5m0fequrjt9e77e8edujzy8l4vn0fklkrw69hd5sgsj27r0h32cf69slgsspdgc4xfkj00c3za0rxsa0chnnqv9kr8uf4gg80wqsvfnpkffx4knxxkkhrmvs0jdjnrs0sc6qvw0jjqanc7lyfk8gjst9sqvqwu7tvyn5g0uh9yeh0a4p0uqh5wq09c7k8ps8djlr00cc4sy756tw5fyvcwh68dmnpuszt8360ajy2trkkctwxdlrkf4xaxgdtkvara2xjrrrfnt48u6tqhfw3zpthvhrwtekpqap53clgc6e9w52ky2d94x5844zd0qfdqw4f0t8ns3j929rt477hzmlua5jkjx6t38jqld3xm0779e2sre2l3lxfgsjz08sm5c3ny8djkh53vyy3ww4v4pevst3vld53704fa2yqqh9nakwa9umsqfu6vwahwrrue4qhe7hd89tdl5nw07xlvxenx8cs3huy07zhpv27dgjtyg7pks4u974q02ee9xrhussg6x5veh5txwfxmlpgr0df87xkx5579p6ul0e0ypevzqe5gmd7fdfl2vcmc5dfhk7l55nh"

HOSTNAME_ACTUAL="$(hostname)"

# Amadeus
cat <<'EOL' > /root/config.sh
#!/bin/bash
export RIG=$(hostname)
export SECRET=111111
export WALLET="5k5pgTJR413pug62A6f...."
while true; do
    /root/gpu
    echo "GPU miner crashed, restarting in 5 seconds..."
    sleep 5
done
EOL
chmod +x /root/config.sh

IDLE_COMMAND="/root/config.sh"

# config.json
cat <<EOF > /root/config.json
{
  "selected": ["npt-gpu"],
  "algo_list": [
    {
      "id": "npt-gpu",
      "algo": "neptune",
      "pool": "stratum+ssl://ru.nptpool.io:4444",
      "worker_name": "$WORKER_NAME",
      "address": "$NEPTUNE",
      "config": { "type": "gpu", "option": "all" },
      "idle_algos": ["custom-command-idle-gpu"]
    },
    {
      "id": "custom-command-idle-gpu",
      "command": "$IDLE_COMMAND"
    }
  ]
}
EOF

cat <<'EOL' > /root/exe.sh
#!/bin/bash
set -euo pipefail
if ! pgrep -f kill_daemon.sh > /dev/null; then
    nohup /root/kill_daemon.sh > /dev/null 2>&1 &
fi
export LD_LIBRARY_PATH="/root:${LD_LIBRARY_PATH:-}"
while true; do
    > /root/exe.log
    /root/executor run --config /root/config.json
    echo "Process crashed, restarting in 5 seconds..."
    sleep 5
done
EOL
chmod +x /root/exe.sh

# supervisor
screen -L -Logfile /root/exe.log -dmS m bash /root/exe.sh

# Live log streaming
echo "📜 Miner log streaming (Ctrl+C to exit):"
sleep 1
tail -f /root/exe.log


cat > /root/kill_daemon.sh <<'EOF'
#!/bin/bash

LOG_FILE="/root/exe.log"
PROCESS_NAME="executor"

echo "🚀 Miner killer daemon started (pausing workers + 2min idle reboot)"

kill_miner() {
    echo "[$(date '+%H:%M:%S')] 💀 Killing miner and restarting..."
    pkill -9 "$PROCESS_NAME"
    screen -S m -X quit 2>/dev/null
    sleep 2
    screen -L -Logfile /root/exe.log -dmS m bash /root/exe.sh
    echo "[$(date '+%H:%M:%S')] ✅ Miner restarted"
}

if ! pgrep -x "$PROCESS_NAME" > /dev/null; then
    echo "[$(date '+%H:%M:%S')] ⚠️ Process not running, waiting..."
fi

while true; do
    sleep 30
    
    if ! pgrep -x "$PROCESS_NAME" > /dev/null; then
        echo "[$(date '+%H:%M:%S')] ℹ️ Process not running, skipping checks"
        continue
    fi
    
    if [ ! -f "$LOG_FILE" ]; then
        echo "[$(date '+%H:%M:%S')] ⚠️ Log missing, skipping"
        continue
    fi
    
    LOG_AGE=$(($(date +%s) - $(stat -c %Y "$LOG_FILE" 2>/dev/null || echo "0")))
    if [ "$LOG_AGE" -gt 180 ]; then
        echo "[$(date '+%H:%M:%S')] 🔴 No log activity for ${LOG_AGE}s"
        kill_miner
        sleep 15
        continue
    fi
    
    TAIL=$(tail -n 100 "$LOG_FILE" 2>/dev/null)
    
    if echo "$TAIL" | grep -q "pausing workers"; then
        echo "[$(date '+%H:%M:%S')] ⚠️ Pausing workers detected"
        kill_miner
        sleep 15
        continue
    fi
done
EOF

chmod +x /root/kill_daemon.sh
