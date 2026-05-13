#!/bin/bash

set -e

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
PLAIN="\033[0m"

echo -e "${GREEN}=== Arturo 3X-UI automatinis diegimas ===${PLAIN}"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Paleisk kaip root!${PLAIN}"
    exit 1
fi

read -rp "Įvesk domeną, pvz. panel.tavodomenas.lt: " DOMAIN
read -rp "Įvesk el. paštą SSL sertifikatui: " EMAIL

if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
    echo -e "${RED}Domenas arba el. paštas neįvestas.${PLAIN}"
    exit 1
fi

echo -e "${YELLOW}Atnaujinami paketai...${PLAIN}"
apt update -y
apt install -y curl wget socat tar unzip cron

echo -e "${YELLOW}Diegiama 3X-UI panelė...${PLAIN}"
bash <(curl -Ls https://raw.githubusercontent.com/arturad/x-ui/main/install.sh)

echo -e "${YELLOW}Tikrinama ar x-ui įsidiegė...${PLAIN}"
if [ ! -f /usr/local/x-ui/bin/config.json ]; then
    echo -e "${RED}KLAIDA: nerasta /usr/local/x-ui/bin/config.json${PLAIN}"
    echo -e "${YELLOW}Pirma patikrink install.sh:${PLAIN}"
    echo "bash <(curl -Ls https://raw.githubusercontent.com/arturad/x-ui/main/install.sh)"
    exit 1
fi

echo -e "${GREEN}x-ui įdiegtas sėkmingai.${PLAIN}"

echo -e "${YELLOW}Diegiamas acme.sh...${PLAIN}"
curl https://get.acme.sh | sh

export PATH="/root/.acme.sh:$PATH"

~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --register-account -m "$EMAIL" || true

echo -e "${YELLOW}Stabdomas x-ui, kad 80 portas būtų laisvas...${PLAIN}"
systemctl stop x-ui || true

echo -e "${YELLOW}Generuojamas SSL sertifikatas domenui: $DOMAIN${PLAIN}"
~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --force

mkdir -p /etc/ssl/x-ui

~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
  --key-file /etc/ssl/x-ui/key.pem \
  --fullchain-file /etc/ssl/x-ui/cert.pem \
  --reloadcmd "systemctl restart x-ui"

echo -e "${YELLOW}Įrašomi SSL keliai į x-ui config.json...${PLAIN}"

CONFIG="/usr/local/x-ui/bin/config.json"

sed -i 's|"certFile": *"[^"]*"|"certFile": "/etc/ssl/x-ui/cert.pem"|g' "$CONFIG"
sed -i 's|"keyFile": *"[^"]*"|"keyFile": "/etc/ssl/x-ui/key.pem"|g' "$CONFIG"

echo -e "${YELLOW}Paleidžiama panelė...${PLAIN}"
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui

echo -e "${GREEN}======================================${PLAIN}"
echo -e "${GREEN}Diegimas baigtas.${PLAIN}"
echo -e "${GREEN}Domenas: https://$DOMAIN${PLAIN}"
echo -e "${YELLOW}Panelės duomenis rasi su komanda:${PLAIN}"
echo "x-ui"
echo "Tada rinkis: 10 View Current Settings"
echo -e "${GREEN}======================================${PLAIN}"
