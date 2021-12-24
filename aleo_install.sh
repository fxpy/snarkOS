#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
echo "=================================================="
echo -e 'Installing dependencies...\n' && sleep 1
sudo apt update
sudo apt install make clang pkg-config libssl-dev build-essential gcc xz-utils git curl vim tmux ntp jq llvm ufw -y < "/dev/null"
echo "=================================================="
echo -e 'Installing Rust (stable toolchain)...\n' && sleep 1
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
# sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup default stable
rustup update stable --force
# rustup toolchain install nightly-2021-03-10-x86_64-unknown-linux-gnu
# toolchain=`rustup toolchain list | grep -m 1 nightly`
echo "=================================================="
echo -e 'Cloning snarkOS...\n' && sleep 1
cd $HOME
git clone https://github.com/fxpy/snarkOS --depth 1 -b testnet2
cd snarkOS
#git checkout tags/v1.3.6
#git checkout 0869ab1193634eaa3722ea97cc4f4a4c615864c0
echo "=================================================="
echo -e 'Installing snarkos v2.0.0 ...\n' && sleep 1
cargo install --path .
sudo rm -rf /usr/bin/snarkos
sudo cp $HOME/snarkOS/target/release/snarkos /usr/bin
#echo -e 'Clone Aleo...\n' && sleep 1
cd $HOME
#git clone https://github.com/AleoHQ/aleo && cd aleo
#cargo install --path . --locked
echo "=================================================="
echo -e 'Creating Aleo account for Testnet2...\n' && sleep 1
mkdir $HOME/aleo
#echo "==================================================
#Your Aleo account:
#==================================================
#" >> $HOME/aleo/account_new.txt
#date >> $HOME/aleo/account_new.txt
#snarkos experimental new_account >> $HOME/aleo/account_new.txt && cat $HOME/aleo/account_new.txt && sleep 2

cat $HOME/aleo/account_new.txt
echo 'export ALEO_ADDRESS='$(cat $HOME/aleo/account_new.txt | awk '/Address/ {print $2}') >> $HOME/.bashrc && . $HOME/.bashrc
source $HOME/.bashrc
export ALEO_ADDRESS=$(cat $HOME/aleo/account_new.txt | awk '/Address/ {print $2}' | tail -1)
printf 'Your miner address - ' && echo ${ALEO_ADDRESS} && sleep 1
echo -e 'Creating a service for Aleo Node...\n' && sleep 1
echo "[Unit]
Description=Aleo Client Node Testnet2
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/snarkos
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/aleod.service
echo -e 'Creating a service for Aleo Miner...\n' && sleep 1
echo "[Unit]
Description=Aleo Miner Testnet2
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/snarkos --trial --miner $ALEO_ADDRESS
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/aleod-miner.service
sudo mv $HOME/aleod.service /etc/systemd/system
sudo mv $HOME/aleod-miner.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
echo -e 'Enabling Aleo Node and Miner services\n' && sleep 1
#sudo systemctl enable aleod
sudo systemctl enable aleod-miner
#sudo systemctl restart aleod
sudo systemctl restart aleod-miner
echo -e "Installing Aleo Updater\n"
cd $HOME
wget -q -O $HOME/aleo_updater_WIP.sh https://api.nodes.guru/aleo_updater_WIP.sh && chmod +x $HOME/aleo_updater_WIP.sh
echo "[Unit]
Description=Aleo Updater Testnet2
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/snarkOS
ExecStart=/bin/bash $HOME/aleo_updater_WIP.sh
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/aleo-updater.service
sudo mv $HOME/aleo-updater.service /etc/systemd/system
systemctl daemon-reload
echo -e 'Enabling Aleo Updater services\n' && sleep 1
systemctl enable aleo-updater
systemctl restart aleo-updater
echo -e 'To check your node/miner status - run this script in 15-20 minutes:\n' && sleep 1
echo -e 'wget -O snarkos_monitor.sh https://api.nodes.guru/snarkos_monitor.sh && chmod +x snarkos_monitor.sh && ./snarkos_monitor.sh' && echo && sleep 1
#if [[ `service aleod status | grep active` =~ "running" ]]; then
  #echo -e "Your Aleo Node is installed and is running!"
  #else
  #echo -e "Your Aleo Node failed to start, ask for help in chat."
#fi
#if [[ `service aleod-miner status | grep active` =~ "running" ]]; then
  #echo -e "Your Aleo Miner node \e[32minstalled and works\e[39m!"
  #echo -e "You can check node status by the command \e[7mservice aleod-miner status\e[0m"
  #echo -e "Press \e[7mQ\e[0m for exit from status menu"
#else
  #echo -e "Your Aleo Miner node \e[31mwas not installed correctly\e[39m, please reinstall."
#fi
. $HOME/.bashrc
