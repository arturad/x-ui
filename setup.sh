#!/bin/bash

echo -e "\033[1;32m===== X-UI pilnas diegimas su Let's Encrypt SSL (be API) =====\033[0m"

read -p "Įveskite savo domeną (pvz. vpn.tavodomenas.com): " DOMAIN
read -p "Įveskite savo el. paštą (Let's Encrypt paskyrai): " EMAIL

# 1. Atnaujinimai ir priklausomybės
apt update -y
apt install -y curl tar socat jq

# 2. Įdiegiame X-UI 
bash <(curl -Ls https://raw.githubusercontent.com/arturad/x-ui/main/install.sh)

# 3. Įdiegiame acme.sh
if [ ! -f ~/.acme.sh/acme.sh ]; then
  curl https://get.acme.sh | sh
  source ~/.bashrc
fi

# 4. Naudojame Let's Encrypt, ne ZeroSSL
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# 5. Generuojame sertifikatą
~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --accountemail "$EMAIL" --keylength 2048 --force
if [ $? -ne 0 ]; then
  echo -e "\033[1;31mSertifikato generavimas nepavyko.\033[0m"
  exit 1
fi

# 6. Sukuriame katalogą
mkdir -p /etc/ssl/x-ui/

# 7. Įrašome sertifikatus
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
--key-file /etc/ssl/x-ui/key.pem \
--fullchain-file /etc/ssl/x-ui/cert.pem

# 8. Atnaujiname X-UI config.json
CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$CONFIG" ]; then
  jq --arg cert "/etc/ssl/x-ui/cert.pem" --arg key "/etc/ssl/x-ui/key.pem" \
  '.ssl.cert = $cert | .ssl.key = $key' "$CONFIG" > temp && mv temp "$CONFIG"
  echo -e "\033[1;32mKeliai įrašyti į $CONFIG\033[0m"
else
  echo -e "\033[1;31mKLAIDA: nerasta $CONFIG\033[0m"
  exit 1
fi

# 9. Perkraunam X-UI
x-ui restart

echo -e "\n\033[1;32m✅ Baigta! Atidarykite: https://$DOMAIN\033[0m"
