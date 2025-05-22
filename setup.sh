#!/bin/bash

clear
echo -e "\e[1;32m=== Arturo X-UI diegimas ===\e[0m"

read -p "Įvesk domeną (pvz. vpn.tavo-domenas.com): " domain
read -p "Įvesk el. paštą (SSL registracijai): " email
read -p "Pasirink X-UI prisijungimo prievadą (pvz. 54321): " port

# Sistemos atnaujinimas ir reikalingų paketų diegimas
apt update && apt upgrade -y
apt install curl socat git -y

# Diegiam acme.sh
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m $email
~/.acme.sh/acme.sh --issue -d $domain --standalone --force
mkdir -p /root/cert
~/.acme.sh/acme.sh --install-cert -d $domain \
--key-file /root/cert/private.key \
--fullchain-file /root/cert/cert.crt

# Atsisiunčiam X-UI iš fork'o
cd /root
git clone https://github.com/arturad/-x-ui.git
cd arturo-x-ui

# Nustatom paleidimo portą
sed -i "s/54321/$port/g" install.sh

# Vykdom diegimą
bash install.sh

# Informacija
echo -e "\e[1;32mDiegimas baigtas.\e[0m"
echo -e "Adresas: https://$domain:$port"
