#!/bin/bash

clear
echo -e "\e[1;32m=== Arturo X-UI Setup ===\e[0m"
[[ $EUID -ne 0 ]] && echo "Run as root" && exit 1

read -p "Įveskite domeną (naudojamas per Cloudflare): " domain
read -p "Įveskite el. pašto adresą (SSL): " email
read -p "Įveskite prievadą (pvz. 443): " port

# 1. ACME įdiegimas
curl https://get.acme.sh | sh
source ~/.bashrc
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# 2. SSL sertifikato išdavimas
~/.acme.sh/acme.sh --issue --standalone -d $domain --keylength ec-256 --accountemail $email

# 3. Failų kopijavimas
mkdir -p /etc/ssl/x-ui
~/.acme.sh/acme.sh --install-cert -d $domain --ecc \
--fullchain-file /etc/ssl/x-ui/cert.pem \
--key-file /etc/ssl/x-ui/key.pem

# 4. X-UI diegimas
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 5. config.json nustatymas
CONFIG="/usr/local/x-ui/bin/config.json"
if [[ -f "$CONFIG" ]]; then
    jq ".ssl = true | .ssl_certificate = \"/etc/ssl/x-ui/cert.pem\" | .ssl_key = \"/etc/ssl/x-ui/key.pem\" | .port = $port" "$CONFIG" > temp.json && mv temp.json "$CONFIG"
fi

# 6. X-UI perkrovimas
x-ui restart

echo -e "\n\e[1;32mInstaliavimas baigtas. Atidarykite:\e[0m"
echo -e "https://$domain:$port/"
