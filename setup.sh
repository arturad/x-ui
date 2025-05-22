#!/bin/bash

echo -e "\033[1;32m====== X-UI instaliacija ir SSL sertifikato generavimas ======\033[0m"

# 1. Įvedami duomenys
read -p "Įveskite domeną (pvz. vpn.tavodomenas.com): " DOMAIN
read -p "Įveskite el. paštą (Let's Encrypt): " EMAIL

# 2. Įdiegiamos reikalingos priemonės
apt update -y
apt install -y curl tar socat jq

# 3. Įdiegiamas X-UI iš arturad/x-ui
cd /usr/local/
curl -L -o x-ui-linux-amd64.tar.gz https://github.com/arturad/x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz
tar -xzf x-ui-linux-amd64.tar.gz
cp x-ui/x-ui.sh /usr/bin/x-ui
chmod +x /usr/bin/x-ui
x-ui install

# 4. Įdiegiamas acme.sh
if [ ! -f ~/.acme.sh/acme.sh ]; then
    curl https://get.acme.sh | sh
    source ~/.bashrc
fi

# 5. Sugeneruojamas SSL sertifikatas (standalone)
~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --accountemail "$EMAIL" --keylength 2048 --force || {
  echo -e "\033[1;31mSertifikato generavimas nepavyko.\033[0m"
  exit 1
}

# 6. Įrašomi sertifikatai
mkdir -p /etc/ssl/x-ui/
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
--key-file /etc/ssl/x-ui/key.pem \
--fullchain-file /etc/ssl/x-ui/cert.pem

# 7. Įrašomi keliai į config.json
CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$CONFIG" ]; then
  jq --arg cert "/etc/ssl/x-ui/cert.pem" --arg key "/etc/ssl/x-ui/key.pem" \
  '.ssl.cert = $cert | .ssl.key = $key' "$CONFIG" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG"
  echo -e "\033[1;32mSertifikatų keliai įrašyti į $CONFIG\033[0m"
else
  echo -e "\033[1;31mKLAIDA: $CONFIG nerastas.\033[0m"
  exit 1
fi

# 8. Perkraunamas X-UI
x-ui restart
echo -e "\n\033[1;32m✅ Viskas baigta! Dabar galite atsidaryti: https://$DOMAIN\033[0m"
