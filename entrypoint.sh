#! /bin/bash
if [ ! -d "/v2raybin" ]; then

if [[ -z "${UUID}" ]]; then
  UUID="4890bd47-5180-4b1c-9a5d-3ef686543112"
fi

if [[ -z "${VER}" ]]; then
  VER="v4.22.1"
fi

if [[ -z "${AlterID}" ]]; then
  AlterID="10"
fi

if [[ -z "${V2_Path}" ]]; then
  V2_Path="/FreeApp"
fi

if [[ -z "${V2_QR_Path}" ]]; then
  V2_QR_Code="1234"
fi

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
date -R

SYS_Bit="$(getconf LONG_BIT)"
[[ "$SYS_Bit" == '32' ]] && BitVer='_linux_386.tar.gz'
[[ "$SYS_Bit" == '64' ]] && BitVer='_linux_amd64.tar.gz'

if [ "$VER" = "latest" ]; then
  V_VER=`wget -qO- "https://api.github.com/repos/v2ray/v2ray-core/releases/latest" | grep 'tag_name' | cut -d\" -f4`
else
  V_VER="$VER"
fi
C_VER=`wget -qO- "https://api.github.com/repos/mholt/caddy/releases/latest" | grep 'tag_name' | cut -d\" -f4`

mkdir /v2raybin
cd /v2raybin
wget --no-check-certificate -qO 'v2ray.zip' "https://github.com/v2ray/v2ray-core/releases/download/$V_VER/v2ray-linux-$SYS_Bit.zip"
unzip v2ray.zip -d v2ray-linux
rm -rf v2ray.zip
chmod +x /v2raybin/v2ray-linux

mkdir /caddybin
cd /caddybin
wget --no-check-certificate -qO 'caddy.tar.gz' "https://github.com/mholt/caddy/releases/download/$C_VER/caddy_$C_VER$BitVer"
tar xvf caddy.tar.gz
rm -rf caddy.tar.gz
chmod +x caddy
cd /root
mkdir /wwwroot
cd /wwwroot

wget --no-check-certificate -qO 'demo.tar.gz' "https://github.com/jiujiu185/v2ray-heroku-undone/raw/master/demo.tar.gz"
tar xvf demo.tar.gz
rm -rf demo.tar.gz
rm -rf favicon.ico

cat <<-EOF > /v2raybin/v2ray-linux/config.json
{
    "log":{
        "loglevel":"warning"
    },
    "inbounds":[{
        "protocol":"vmess",
        "listen":"127.0.0.1",
        "port":2333,
        "settings":{
            "clients":[
                {
                    "id":"${UUID}",
                    "level":1,
                    "alterId":${AlterID}
                }
            ]
        },
        "streamSettings":{
            "network":"ws",
            "wsSettings":{
                "path":"${V2_Path}"
            }
        }
    }],
    "outbounds":[{
        "protocol":"freedom",
        "settings":{
        }
    }]
}
EOF

cat <<-EOF > /caddybin/Caddyfile
http://0.0.0.0:${PORT}
{
	root /wwwroot
	index index.html
	timeouts none
	proxy ${V2_Path} localhost:2333 {
		websocket
		header_upstream -Origin
	}
}
EOF

cd /v2raybin/v2ray-linux
./v2ray &
cd /caddybin
./caddy -conf="Caddyfile"
else
cd /v2raybin/v2ray-linux
./v2ray &
cd /caddybin
./caddy -conf="Caddyfile"
fi
