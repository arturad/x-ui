#!/bin/bash

echo -e "\033[1;32m===== Arturo X-UI instaliavimas + SSL (standalone) =====\033[0m"

read -p "Įvesk domeną (pvz. vpn.tavodomenas.com): " DOMAIN
read -p "Įvesk el. paštą (Let's Encrypt): " EMAIL

# 0. Įdiegiame X-UI iš tavo repozitorijos
bash <(curl -Ls https://raw.githubusercontent.com/arturad/x-ui/main/install.sh)

# 1. Atnaujinam ir įdiegiame reikalingas priemones
apt update -y
apt install socat curl jq -y

# 2. Įdiegiame acme.sh
curl https://get.acme.sh | sh
source ~/.bashrc

# 3. Generuojame sertifikatą
~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone --keylength 2048 --accountemail $EMAIL --force
if [ $? -ne 0 ]; then
  echo -e "\033[1;31mSertifikato generavimas nepavyko.\033[0m"
  exit 1
fi

# 4. Įrašome sertifikatus
mkdir -p /etc/ssl/x-ui/
~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
--key-file /etc/ssl/x-ui/key.pem \
--fullchain-file /etc/ssl/x-ui/cert.pem \
--reloadcmd "x-ui restart"

# 5. Konfigūruojame config.json
CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$CONFIG" ]; then
  jq --arg cert "/etc/ssl/x-ui/cert.pem" --arg key "/etc/ssl/x-ui/key.pem" \
  '.ssl.cert = $cert | .ssl.key = $key' "$CONFIG" > temp && mv temp "$CONFIG"
  echo -e "\033[1;32mSertifikatų keliai įrašyti į $CONFIG\033[0m"
else
  echo -e "\033[1;31mKlaida: nerasta $CONFIG\033[0m"
  exit 1
fi

# 6. Perkrauname X-UI
x-ui restart

echo -e "\n\033[1;32m✅ Viskas baigta! Atidaryk naršyklę: https://$DOMAIN\033[0m"
