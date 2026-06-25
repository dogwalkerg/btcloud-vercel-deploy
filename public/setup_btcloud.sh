#!/bin/bash
CLOUD_DOMAIN="bt5.cnam.ccwu.cc"
API_PORT="8099"
INSTALL_DIR="/www/btcloud"

if [ $(whoami) != "root" ];then echo "请用 root"; exit 1; fi

echo "安装 PHP 8.0+..."
PHP_BIN=""
for v in php8.3 php8.2 php8.1 php8.0 php; do
    command -v $v >/dev/null 2>&1 && { PHP_BIN=$v; break; }
done
if [ -z "$PHP_BIN" ]; then
    command -v apt-get >/dev/null && apt-get update -y && apt-get install -y php8.1 php8.1-cli php8.1-curl php8.1-mbstring php8.1-xml php8.1-zip php8.1-sqlite3 php8.1-gd unzip wget curl git
    command -v yum >/dev/null && yum install -y epel-release && yum module enable php:8.1 -y && yum install -y php php-cli php-curl php-mbstring php-xml php-zip php-sqlite3 php-gd unzip wget curl git
    PHP_BIN=$(command -v php8.1 php8.0 php 2>/dev/null | head -1)
fi
echo "PHP: $($PHP_BIN -v 2>&1 | head -1)"

echo "下载 btcloud..."
mkdir -p $INSTALL_DIR && cd $INSTALL_DIR
if [ -f /usr/bin/git ]; then
    git clone --depth 1 https://github.com/flucont/btcloud.git . 2>/dev/null || rm -rf ./* ./.??*
fi
if [ ! -f think ]; then
    wget -O btcloud.zip https://codeload.github.com/flucont/btcloud/zip/master 2>/dev/null || curl -sL -o btcloud.zip https://codeload.github.com/flucont/btcloud/zip/master
    [ -f btcloud.zip ] && unzip -o btcloud.zip && cp -r btcloud-main/* . && rm -rf btcloud-main btcloud.zip
fi
if [ ! -f think ]; then echo "btcloud 下载失败"; exit 1; fi

echo "配置 SQLite..."
cat > .env << 'EOF'
APP_DEBUG = false
[APP]
DEFAULT_TIMEZONE = Asia/Shanghai
[DATABASE]
TYPE = sqlite
HOSTNAME = 127.0.0.1
DATABASE = /www/btcloud/runtime/btcloud.db
USERNAME =
PASSWORD =
HOSTPORT = 3306
CHARSET = utf8mb4
PREFIX = cloud_
EOF
mkdir -p runtime

echo "初始化数据库..."
$PHP_BIN -r '
$db=new PDO("sqlite:/www/btcloud/runtime/btcloud.db");
$db->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
$db->exec("CREATE TABLE IF NOT EXISTS cloud_config(key_name VARCHAR(32) PRIMARY KEY,value VARCHAR(1000))");
$db->exec("CREATE TABLE IF NOT EXISTS cloud_record(id INTEGER PRIMARY KEY AUTOINCREMENT,ip VARCHAR(50) NOT NULL UNIQUE,addtime DATETIME NOT NULL,usetime DATETIME NOT NULL)");
$db->exec("CREATE TABLE IF NOT EXISTS cloud_log(id INTEGER PRIMARY KEY AUTOINCREMENT,uid TINYINT DEFAULT 1,action VARCHAR(40) NOT NULL,data VARCHAR(150),addtime DATETIME NOT NULL)");
$cfg=[["admin_username","admin"],["admin_password","btcloud123"],["syskey",substr(md5(time().rand()),0,16)],["new_version","11.8.0"],["whitelist","0"],["bt_type","0"],["bt_url",""],["bt_key",""]];
foreach($cfg as $c){$s=$db->prepare("INSERT OR REPLACE INTO cloud_config(key_name,value) VALUES(?,?)");$s->execute($c);}
echo "DB OK
";
'

echo "创建 systemd 服务..."
cat > start.sh << 'EOF'
#!/bin/bash
cd /www/btcloud
API_PORT=8099
exec php -S 0.0.0.0:$API_PORT -t public public/router.php
EOF
chmod +x start.sh

cat > /etc/systemd/system/btcloud.service << 'EOF'
[Unit]
Description=btcloud API
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/www/btcloud
ExecStart=/www/btcloud/start.sh
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable btcloud
systemctl start btcloud

command -v ufw >/dev/null 2>&1 && { ufw allow 8099/tcp 2>/dev/null; ufw reload 2>/dev/null; }

IP=$(curl -s http://ip.sb 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "192.168.1.100")
echo ""
echo "======================================="
echo " btcloud API 部署完成！"
echo "======================================="
echo " API: http://$IP:8099"
echo " 后台: http://$IP:8099/admin"
echo " 管理员: admin / btcloud123"
echo ""
echo "下一步:"
echo " 1. 打开后台 -> 面板设置"
echo "    地址: http://192.168.1.100:8888"
echo "    密钥: 本机面板 bt 获取"
echo " 2. 后台 -> 刷新插件列表"
echo " 3. 改 Vercel install_panel.sh Btapi_Url"
echo "    为 http://$IP:8099"
echo "======================================="
