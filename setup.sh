#!/bin/bash

echo -e "\033[1;32m===== X-UI automatizuotas SSL instaliavimas (be Cloudflare) =====\033[0m"

read -p "Įvesk domeną (pvz. vpn.tavodomenas.com): " DOMAIN
read -p "Įvesk el. paštą: " EMAIL

# 1. Įdiegiam socat ir acme.sh
apt update -y
apt install socat curl jq -y

curl https://get.acme.sh | sh
source ~/.bashrc

# 2. Generuojam sertifikatą naudodami standalone metodą
~/.acme.sh/acme.sh --issue -d $DOMAIN --standalone --keylength 2048 --accountemail $EMAIL --force
if [ $? -ne 0 ]; then
  echo -e "\033[1;31mSertifikato generavimas nepavyko!\033[0m"
  exit 1
fi

# 3. Sukuriam katalogą sertifikatams
mkdir -p /etc/ssl/x-ui/

# 4. Įrašom sertifikatus
~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
--key-file /etc/ssl/x-ui/key.pem \
--fullchain-file /etc/ssl/x-ui/cert.pem \
--reloadcmd "x-ui restart"

# 5. Atnaujinam X-UI konfigūraciją
CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$CONFIG" ]; then
  jq --arg cert "/etc/ssl/x-ui/cert.pem" --arg key "/etc/ssl/x-ui/key.pem" \
  '.ssl.cert = $cert | .ssl.key = $key' "$CONFIG" > temp && mv temp "$CONFIG"
  echo -e "\033[1;32mSertifikatų keliai įrašyti į $CONFIG\033[0m"
else
  echo -e "\033[1;31mKLAIDA: nerasta $CONFIG\033[0m"
  exit 1
fi

# 6. Perkraunam X-UI
x-ui restart

echo -e "\n\033[1;32m✅ Baigta! Atidaryk naršyklę: https://$DOMAIN\033[0m"
