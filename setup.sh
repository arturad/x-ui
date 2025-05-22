#!/bin/bash

echo -e "\033[1;32m===== X-UI automatizuotas SSL instaliavimas (RSA) =====\033[0m"

read -p "Įvesk domeną (pvz. vpn.tavodomenas.com): " DOMAIN
read -p "Įvesk el. paštą: " EMAIL
read -p "Įvesk Cloudflare API Key: " CF_API
read -p "Įvesk Cloudflare paskyros el. paštą: " CF_EMAIL

# 1. Įdiegiam acme.sh jei dar nėra
if [ ! -f ~/.acme.sh/acme.sh ]; then
    echo "Diegiam acme.sh..."
    curl https://get.acme.sh | sh
    source ~/.bashrc
fi

# 2. Nustatom Cloudflare API aplinką
export CF_Key="$CF_API"
export CF_Email="$CF_EMAIL"

# 3. Sugeneruojam RSA sertifikatą
~/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" --keylength 2048 --accountemail "$EMAIL" --force

# 4. Įrašom sertifikatus
mkdir -p /etc/ssl/x-ui/

~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
--cert-file /root/cert.crt \
--key-file /root/private.key \
--fullchain-file /etc/ssl/x-ui/cert.pem \
--reloadcmd "x-ui restart"

# 5. Įrašom į X-UI konfigūraciją
CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$CONFIG" ]; then
    apt install -y jq > /dev/null 2>&1
    jq --arg cert "/root/cert.crt" --arg key "/root/private.key" \
    '.ssl.cert = $cert | .ssl.key = $key' "$CONFIG" > temp && mv temp "$CONFIG"
    echo -e "\033[1;32mSertifikatų keliai įrašyti į $CONFIG\033[0m"
else
    echo -e "\033[1;31mKLAIDA: nerasta $CONFIG\033[0m"
    exit 1
fi

# 6. Perkraunam X-UI
x-ui restart
echo -e "\n\033[1;32m✅ Baigta! Dabar atsidaryk: https://$DOMAIN\033[0m"
