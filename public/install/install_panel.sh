#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

MAC_OS_CHECK=$(uname -a|grep Darwin)
if [ "${MAC_OS_CHECK}" ];then
    echo "褰撳墠绯荤粺涓簃acOS锛屾棤娉曞畨瑁呭疂濉旈潰鏉匡紝璇蜂娇鐢↙inux绯荤粺(鏈嶅姟鍣ㄧ増鏈Debian/Centos)瀹夎瀹濆闈㈡澘"
	echo "鎴栦娇鐢―ocker瀹夎瀹濆闈㈡澘"
    exit 1
fi

INSTALL_LOGFILE="/tmp/btpanel-install.log"
if [ -f "$INSTALL_LOGFILE" ];then
    rm -f $INSTALL_LOGFILE
fi
exec > >(tee -a "$INSTALL_LOGFILE") 2>&1 

Btapi_Url='https://YOUR_DOMAIN.vercel.app'
# Check_Api=$(curl -Ss --connect-timeout 5 -m 2 $Btapi_Url/api/SetupCount)
# if [ "$Check_Api" != 'ok' ];then
# 	Red_Error "姝ゅ疂濉旂涓夋柟浜戠鏃犳硶杩炴帴锛屽洜姝ゅ畨瑁呰繃绋嬪凡涓锛?;
# fi

if [ $(whoami) != "root" ];then
	echo "璇蜂娇鐢╮oot鏉冮檺鎵ц瀹濆瀹夎鍛戒护锛?
	exit 1;
fi

MEM_TOTAL=$(free -m|grep Mem|awk '{print $2}')
if [ "${MEM_TOTAL}" ] ;then
	if [ "${MEM_TOTAL}" -lt "450" ];then
		echo "====================================================="
		free -m
		echo "褰撳墠鏈嶅姟鍣ㄥ唴瀛樹负:${MEM_TOTAL}MB"
		echo "妫€娴嬪埌褰撳墠鏈嶅姟鍣ㄥ唴瀛樺皬浜?50MB锛屾棤娉曞畨瑁呭疂濉旈潰鏉?
		echo "寤鸿鏇存崲鍐呭瓨澶т簬绛変簬512MB鐨勬湇鍔″櫒瀹夎瀹濆闈㈡澘"
		echo "====================================================="
		exit 1
	fi
fi

Fix_Apt_Lock(){
    [ ! -f "/usr/bin/apt-get" ] && return 0
    
    echo "妫€鏌?apt/dpkg 閿佺姸鎬?.."
    
    # # 1. 鍋滄鑷姩鏇存柊鏈嶅姟
    # if systemctl is-active --quiet unattended-upgrades 2>/dev/null; then
    #     echo "鍋滄 unattended-upgrades 鏈嶅姟..."
    #     systemctl stop unattended-upgrades 2>/dev/null
    #     systemctl disable unattended-upgrades 2>/dev/null
    #     sleep 2
    # fi
    
    # 2. 绛夊緟鍏朵粬 apt/dpkg 杩涚▼锛堟渶澶氱瓑寰?0绉掞級
    local wait=0
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
          fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
          fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        
        if [ ${wait} -eq 0 ]; then
            echo "妫€娴嬪埌 apt/dpkg 姝ｅ湪浣跨敤涓紝绛夊緟瀹屾垚..."
            ps aux | grep -E 'apt-get|apt |dpkg|unattended' | grep -v grep | awk '{print "  PID "$2": "$11}' || true
        fi
        
        [ ${wait} -ge 60 ] && break
        sleep 3
        wait=$((wait + 3))
    done
    
    # 3. 濡傛灉杩樻湁閿侊紝寮哄埗娓呯悊
    if fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
       fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
       fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
       fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
        
        echo "寮哄埗娓呯悊 apt/dpkg 閿?.."
        
        # 寮哄埗缁堟杩涚▼
        pkill -9 unattended-upgr 2>/dev/null
        pkill -9 apt-get 2>/dev/null
        pkill -9 apt 2>/dev/null
        pkill -9 dpkg 2>/dev/null
        sleep 1
        
        # 鍒犻櫎鎵€鏈夐攣鏂囦欢
        rm -f /var/lib/dpkg/lock-frontend
        rm -f /var/lib/dpkg/lock
        rm -f /var/lib/apt/lists/lock
        rm -f /var/cache/apt/archives/lock
        
        # 淇 dpkg 鐘舵€?        echo "淇 dpkg 鐘舵€?.."
        dpkg --configure -a 2>/dev/null || true
        apt-get install -f -y 2>/dev/null || true
    fi
    
    echo "apt/dpkg 閿佹鏌ュ畬鎴?
    return 0
}




is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ];then
	echo "鎶辨瓑, 褰撳墠闈㈡澘鐗堟湰涓嶆敮鎸?2浣嶇郴缁? 璇蜂娇鐢?4浣嶇郴缁熸垨瀹夎瀹濆5.9!";
	exit 1
fi

Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
if [ "${Centos6Check}" ];then
	echo "Centos6涓嶆敮鎸佸畨瑁呭疂濉旈潰鏉匡紝璇锋洿鎹entos7/8瀹夎瀹濆闈㈡澘"
	exit 1
fi 

UbuntuCheck=$(cat /etc/issue|grep Ubuntu|awk '{print $2}'|cut -f 1 -d '.')
if [ "${UbuntuCheck}" ] && [ "${UbuntuCheck}" -lt "16" ];then
	echo "Ubuntu ${UbuntuCheck}涓嶆敮鎸佸畨瑁呭疂濉旈潰鏉匡紝寤鸿鏇存崲Ubuntu18/20瀹夎瀹濆闈㈡澘"
	exit 1
fi
HOSTNAME_CHECK=$(cat /etc/hostname)
if [ -z "${HOSTNAME_CHECK}" ];then
	echo "localhost" > /etc/hostname
	# echo "褰撳墠涓绘満鍚峢ostname涓虹┖鏃犳硶瀹夎瀹濆闈㈡澘锛岃鍜ㄨ鏈嶅姟鍣ㄨ繍钀ュ晢璁剧疆濂絟ostname鍚庡啀閲嶆柊瀹夎"
	# exit 1
fi

UBUNTU_NO_LTS=$(cat /etc/issue|grep Ubuntu|grep -E "19|21|23|25")
if [ "${UBUNTU_NO_LTS}" ];then
	echo "褰撳墠鎮ㄤ娇鐢ㄧ殑闈濽buntu-lts鐗堟湰锛屾棤娉曡繘琛屽疂濉旈潰鏉跨殑瀹夎"
	echo "璇蜂娇鐢║buntu-20/20/22/24杩涜瀹夎瀹濆闈㈡澘"
	exit 1
fi

DEBIAN_9_C=$(cat /etc/issue|grep Debian|grep -E "7 |8 |9 ")
if [ "${DEBIAN_9_C}" ];then
	echo "褰撳墠鎮ㄤ娇鐢ㄧ殑Debian-7/8/9锛屽畼鏂瑰凡缁忓仠姝㈡敮鎸併€佹棤娉曡繘琛屽疂濉旈潰鏉跨殑瀹夎"
	echo "寤鸿浣跨敤Debian-11/12/13杩涜瀹夎瀹濆闈㈡澘"
	exit 1
fi

cd ~
setup_path="/www"
python_bin=$setup_path/server/panel/pyenv/bin/python
cpu_cpunt=$(cat /proc/cpuinfo|grep processor|wc -l)
panelPort=$(expr $RANDOM % 55535 + 10000)
# if [ "$1" ];then
# 	IDC_CODE=$1
# fi

#2026-03-14鏂板涓嬭浇鍏辩敤鍑芥暟
Download_File(){
	# 鍙傛暟1锛氫富涓嬭浇鍩熷悕锛堝http://download.bt.cn锛?	# 鍙傛暟2锛氬鐢ㄤ笅杞藉煙鍚嶏紙濡俬ttp://download.bt.com锛?	# 鍙傛暟3锛氭枃浠惰矾寰勶紙濡?src/file.tar.gz锛?	# 鍙傛暟4锛氫繚瀛樿矾寰勶紙濡?tmp/file.tar.gz锛?	# 绀轰緥璋冪敤锛欴ownload_File "http://download.bt.cn" "http://download.bt.com" "/src/file.tar.gz" "/tmp/file.tar.gz"
	# 鏅鸿兘涓嬭浇鍑芥暟锛屾敮鎸乧url鍜寃get锛岃嚜鍔ㄩ噸璇曪紝楠岃瘉鏂囦欢澶у皬锛岀‘淇濅笅杞芥垚鍔?    local primary_domain=$1
    local backup_domain=$2
    local file_path=$3
    local save_path=$4
    
    local max_retry=2
	local connect_timeout=15
    local timeout=20
    local min_speed=60000
    local retry_count=0
    local download_success=0
    local current_url=""
    
	
    echo "姝ｅ湪涓嬭浇: $(basename ${save_path})"
    
    while [ ${retry_count} -lt ${max_retry} ]; do
        if [ -f "${save_path}" ]; then
            rm -f "${save_path}"
        fi
        
        if [ ${retry_count} -eq 0 ]; then
            current_url="${primary_domain}${file_path}"
            #echo "浣跨敤涓讳笅杞借妭鐐? ${primary_domain}"
        else
            current_url="${backup_domain}${file_path}"
            #echo "鍒囨崲鍒板鐢ㄤ笅杞借妭鐐? ${backup_domain}"
        fi
        
        if command -v curl >/dev/null 2>&1; then
            curl -fL --connect-timeout ${connect_timeout} --speed-limit ${min_speed} --speed-time 10 -o "${save_path}" "${current_url}"
            if [ $? -eq 0 ] && [ -f "${save_path}" ]; then
                file_size=$(du -b "${save_path}" 2>/dev/null | awk '{print $1}')
                if [ "${file_size}" -gt 100 ]; then
                    download_success=1
                    break
                fi
            fi
		elif command -v wget >/dev/null 2>&1; then
            wget --connect-timeout=${connect_timeout} --read-timeout=10 --tries=1 --progress=bar:force -O "${save_path}" "${current_url}" 2>&1
            if [ $? -eq 0 ] && [ -f "${save_path}" ]; then
                file_size=$(du -b "${save_path}" 2>/dev/null | awk '{print $1}')
                if [ "${file_size}" -gt 100 ]; then
                    download_success=1
                    break
                fi
            fi
        else
            echo "閿欒: 鏈壘鍒癱url鎴杦get涓嬭浇宸ュ叿"
            return 1
        fi
        
        retry_count=$((retry_count + 1))
        if [ ${retry_count} -lt ${max_retry} ]; then
            echo "涓嬭浇澶辫触锛?{retry_count}/${max_retry} 娆￠噸璇曚腑..."
            sleep 2
        fi
    done
    
    if [ ${download_success} -eq 0 ]; then
        echo "閿欒: 涓嬭浇澶辫触锛屽凡閲嶈瘯 ${max_retry} 娆?
        #echo "涓昏妭鐐? ${primary_domain}${file_path}"
        #echo "澶囩敤鑺傜偣: ${backup_domain}${file_path}"
        return 1
    fi


	if [ ${retry_count} -gt 0 ] && [ ${download_success} -eq 1 ]; then
		download_Url=${backup_domain}
	fi
    
    #echo "涓嬭浇鎴愬姛: $(basename ${save_path})"
    return 0
}

Ready_Check(){
    WWW_DISK_SPACE=$(df |grep /www|awk '{print $4}')
    ROOT_DISK_SPACE=$(df |grep /$|awk '{print $4}')
 
   if [ "${ROOT_DISK_SPACE}" -le 412000 ];then
	df -h
        echo -e "绯荤粺鐩樺墿浣欑┖闂翠笉瓒?00M 鏃犳硶缁х画瀹夎瀹濆闈㈡澘锛?
        echo -e "璇峰皾璇曟竻鐞嗙鐩樼┖闂村悗鍐嶉噸鏂拌繘琛屽畨瑁?
        exit 1
    fi
    if [ "${WWW_DISK_SPACE}" ] && [ "${WWW_DISK_SPACE}" -le 412000 ] ;then
        echo -e "/www鐩樺墿浣欑┖闂翠笉瓒?00M 鏃犳硶缁х画瀹夎瀹濆闈㈡澘锛?
        echo -e "璇峰皾璇曟竻鐞嗙鐩樼┖闂村悗鍐嶉噸鏂拌繘琛屽畨瑁?
        exit 1
    fi

    # ROOT_DISK_INODE=$(df -i|grep /$|awk '{print $2}')
	# if [ "${ROOT_DISK_INODE}" != "0" ];then
	# 	ROOT_DISK_INODE_FREE=$(df -i|grep /$|awk '{print $4}')
	# 	if [ "${ROOT_DISK_INODE_FREE}" -le 1000 ];then
	# 		echo -e "绯荤粺鐩樺墿浣檌nodes绌洪棿涓嶈冻1000,鏃犳硶缁х画瀹夎锛?
	# 		echo -e "璇峰皾璇曟竻鐞嗙鐩樼┖闂村悗鍐嶉噸鏂拌繘琛屽畨瑁?
	# 		exit 1
	# 	fi
	# fi

	# WWW_DISK_INODE==$(df -i|grep /www|awk '{print $2}')
	# if [ "${WWW_DISK_INODE}" ] && [ "${WWW_DISK_INODE}" != "0" ] ;then
	# 	WWW_DISK_INODE_FREE=$(df -i|grep /www|awk '{print $4}')
	# 	if [ "${WWW_DISK_INODE_FREE}" ] && [ "${WWW_DISK_INODE_FREE}" -le 1000 ] ;then
	# 		echo -e "/www鐩樺墿浣檌nodes绌洪棿涓嶈冻1000, 鏃犳硶缁х画瀹夎锛?
	# 		echo -e "璇峰皾璇曟竻鐞嗙鐩樼┖闂村悗鍐嶉噸鏂拌繘琛屽畨瑁?
	# 		exit 1
	# 	fi
	# fi
}

GetSysInfo(){
	if [ -s "/etc/redhat-release" ];then
		SYS_VERSION=$(cat /etc/redhat-release)
	elif [ -s "/etc/issue" ]; then
		SYS_VERSION=$(cat /etc/issue)
	fi
	SYS_INFO=$(uname -a)
	SYS_BIT=$(getconf LONG_BIT)
	MEM_TOTAL=$(free -m|grep Mem|awk '{print $2}')
	CPU_INFO=$(getconf _NPROCESSORS_ONLN)


	# if [ -f "/etc/apt/sources.list.d/ubuntu.sources" ];then
	# 	cat /etc/apt/sources.list.d/ubuntu.sources
	# 	apt-get update -y
	# 	apt-get install unzip -y
	# fi

	echo -e ${SYS_VERSION}
	echo -e Bit:${SYS_BIT} Mem:${MEM_TOTAL}M Core:${CPU_INFO}
	echo -e ${SYS_INFO}
	echo -e "============================================"
	echo -e "璇锋埅鍥句互涓婃姤閿欎俊鎭彂甯栬嚦璁哄潧www.bt.cn/bbs姹傚姪"
	echo -e "============================================"
	
	if [ -f "/etc/redhat-release" ];then
		Centos7Check=$(cat /etc/redhat-release | grep ' 7.' | grep -iE 'centos')
		echo -e "============================================"
		echo -e "Centos7/8瀹樻柟宸茬粡鍋滄鏀寔"
		echo -e "濡傛槸鏂板畨瑁呯郴缁熸湇鍔″櫒寤鸿鏇存崲鑷矰ebian-12/Ubuntu-22/Centos-9绯荤粺瀹夎瀹濆闈㈡澘"
		echo -e "============================================"
	fi

	
	if [ -f "/usr/sbin/setstatus" ] || [ -f "/usr/sbin/setstatus" ];then
		echo -e "=================================================="
		echo -e "  妫€娴嬪埌涓洪簰楹熺郴缁燂紝鍙兘榛樿寮€鍚畨鍏ㄥ姛鑳藉鑷村畨瑁呭け璐?
		echo -e "  璇锋墽琛屼互涓嬪懡浠ゅ叧闂畨鍏ㄥ姞鍥哄悗锛屽啀閲嶆柊瀹夎瀹濆闈㈡澘鐪嬫槸鍚︽甯?
		echo -e "  鍛戒护锛歴udo setstatus softmode -p"
		echo -e "=================================================="
	fi  

	#2026-3-14鏂板甯哥敤鍛戒护妫€娴?	CORE_TOOLS="wget tar xz unzip"
	NO_EXIST_TOOL=""

	for tool in $CORE_TOOLS; do
		if ! command -v "$tool" >/dev/null 2>&1; then
			if [ "${PM}" = "apt-get" ] && [ "$tool" = "xz" ]; then
				NO_EXIST_TOOL="$NO_EXIST_TOOL xz-utils"
			else
				NO_EXIST_TOOL="$NO_EXIST_TOOL $tool"
			fi
		fi
	done

	if [ -n "$NO_EXIST_TOOL" ]; then
		if [ "${PM}" = "yum" ]; then
			yum install -y $NO_EXIST_TOOL
		elif [ "${PM}" = "apt-get" ]; then
			apt-get update -y
			apt-get install -y $NO_EXIST_TOOL
		fi
	fi

	if [ -n "$NO_EXIST_TOOL" ]; then
		NO_EXIST_TOOL="${NO_EXIST_TOOL# }"
		echo "========================================================"
		echo "  妫€娴嬪埌缂哄皯蹇呰鐨勭郴缁熷伐鍏? $NO_EXIST_TOOL"
		echo "  瀹濆闈㈡澘瀹夎杩囩▼涓細灏濊瘯淇绯荤粺婧愬苟瀹夎杩欎簺宸ュ叿锛?
		echo "  浣嗘湰娆″畨瑁呮湭鑳芥垚鍔燂紝鍙兘鏄敱浜庣郴缁熸簮鎴栫綉缁滈棶棰樺鑷淬€?
		echo "  寤鸿鎮ㄥ厛鑷鎺掓煡鎴栦娇鐢?AI 鍗忓姪瑙ｅ喅闂鍚庯紝鍐嶉噸鏂板畨瑁呭疂濉旈潰鏉裤€?
		echo "  璇锋敞鎰忥細鎵ц涓嬮潰鍛戒护鏃朵骇鐢熺殑鎶ラ敊淇℃伅鏄帓鏌ラ棶棰樼殑鍏抽敭淇℃伅锛?
		echo "  璇锋牴鎹姤閿欎俊鎭繘琛屽鐞嗗悗鍐嶅皾璇曞畨瑁呫€?
		echo "  鎮ㄥ彲浠ヤ娇鐢ㄤ互涓嬪懡浠ゆ墜鍔ㄥ畨瑁呯己灏戠殑宸ュ叿锛?
		if [ -f "/usr/bin/yum" ]; then
			echo "  瀹夎鍛戒护: yum install $NO_EXIST_TOOL -y"
		elif [ -f "/usr/bin/apt-get" ]; then
			echo "  瀹夎鍛戒护: apt-get install $NO_EXIST_TOOL -y"
		else
			echo "  绯荤粺鏈瘑鍒紝璇锋墜鍔ㄥ畨瑁呬笂杩板伐鍏?
		fi
		echo "========================================================"
	fi

	SYS_SSL_LIBS=$(pkg-config --list-all | grep -q libssl)
	if [ -z "$SYS_SSL_LIBS" ] && [ -z "$NO_EXIST_TOOL" ];then
		echo "妫€娴嬪埌缂哄皯绯荤粺ssl鐩稿叧渚濊禆锛屽彲鎵ц涓嬮潰鍛戒护瀹夎渚濊禆鍚庡啀閲嶆柊瀹夎瀹濆鐪嬫槸鍚︽甯?
		echo "鎵ц鍓嶈纭繚绯荤粺婧愭甯?
		if [ -f "/usr/bin/yum" ];then
			echo "瀹夎渚濊禆鍛戒护: yum install openssl-devel -y"
		elif [ -f "/usr/bin/apt-get" ];then
			echo "瀹夎渚濊禆鍛戒护: apt-get install libssl-dev -y"
		fi
		rm -rf /www/server/panel/pyenv 
		echo -e "=================================================="
	fi
}
Red_Error(){
	echo '=================================================';
	printf '\033[1;31;40m%b\033[0m\n' "$@";
	GetSysInfo
	exit 1;
}
Lock_Clear(){
	if [ -f "/etc/bt_crack.pl" ];then
		chattr -R -ia /www
		chattr -ia /etc/init.d/bt
		\cp -rpa /www/backup/panel/vhost/* /www/server/panel/vhost/
		mv /www/server/panel/BTPanel/__init__.bak /www/server/panel/BTPanel/__init__.py
		rm -f /etc/bt_crack.pl
	fi
}
Install_Check(){
	if [ "${INSTALL_FORCE}" ];then
		return
	fi
	echo -e "----------------------------------------------------"
	echo -e "妫€鏌ュ凡鏈夊叾浠朩eb/mysql鐜锛屽畨瑁呭疂濉斿彲鑳藉奖鍝嶇幇鏈夌珯鐐瑰強鏁版嵁"
	echo -e "Web/mysql service is alreday installed,Can't install panel"
	echo -e "----------------------------------------------------"
	echo -e "宸茬煡椋庨櫓/Enter yes to force installation"
	read -p "杈撳叆yes寮哄埗瀹夎: " yes;
	if [ "$yes" != "yes" ];then
		echo -e "------------"
		echo "鍙栨秷瀹夎"
		exit;
	fi
	INSTALL_FORCE="true"
}
System_Check(){
	MYSQLD_CHECK=$(ps -ef |grep mysqld|grep -v grep|grep -v /www/server/mysql)
	PHP_CHECK=$(ps -ef|grep php-fpm|grep master|grep -v /www/server/php)
	NGINX_CHECK=$(ps -ef|grep nginx|grep master|grep -v /www/server/nginx)
	HTTPD_CHECK=$(ps -ef |grep -E 'httpd|apache'|grep -v /www/server/apache|grep -v grep)
	if [ "${PHP_CHECK}" ] || [ "${MYSQLD_CHECK}" ] || [ "${NGINX_CHECK}" ] || [ "${HTTPD_CHECK}" ];then
		Install_Check
	fi
}
Set_Ssl(){
    SET_SSL=true
    if [ "${SSL_PL}" ];then
    	SET_SSL=""
    fi
}
Add_lib_Install(){
	if [ -f "/etc/os-release" ];then
		. /etc/os-release
		OS_V=${VERSION_ID%%.*}
		if [ "${ID}" == "debian" ] && [[ "${OS_V}" =~ ^(11|12|13)$ ]];then
			OS_NAME=${ID}
		elif [ "${ID}" == "ubuntu" ] && [[ "${OS_V}" =~ ^(22|24)$ ]];then
			OS_NAME=${ID}
		elif [ "${ID}" == "centos" ] && [[ "${OS_V}" =~ ^(7)$ ]];then
			OS_NAME="el"
		elif [ "${ID}" == "opencloudos" ] && [[ "${OS_V}" =~ ^(9)$ ]];then
			OS_NAME=${ID}
		elif [ "${ID}" == "tencentos" ] && [[ "${OS_V}" =~ ^(4)$ ]];then
			OS_NAME=${ID}
		elif [ "${ID}" == "hce" ] && [[ "${OS_V}" =~ ^(2)$ ]];then
		    OS_NAME=${ID}
        elif { [ "${ID}" == "almalinux" ] || [ "${ID}" == "centos" ] || [ "${ID}" == "rocky" ]; } && [[ "${OS_V}" =~ ^(9)$ ]]; then
            OS_NAME="el"
		fi
	fi

	X86_CHECK=$(uname -m|grep x86_64)

	if [ "${OS_NAME}" ] && [ "${X86_CHECK}" ];then
		if [ "${PM}" = "yum" ]; then
			mtype="1"
		elif [ "${PM}" = "apt-get" ]; then
			mtype="4"
		fi
		cd /www/server/panel/class
		btpython -c "import panelPlugin; plugin = panelPlugin.panelPlugin(); plugin.check_install_lib('${mtype}')"
		echo "True" > /tmp/panelTask.pl
		echo "True" > /www/server/panel/install/ins_lib.pl
	fi
}
Get_Pack_Manager(){
	if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
		PM="yum"
	elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
		PM="apt-get"		
	fi
}
Check_And_Fix_Debian_Ubuntu_Source(){
	#2026-3-12鏃ユ洿鏂?	# 浣滅敤锛氭鏌ebian/Ubuntu绯荤粺婧愰厤缃紝鑷姩鏇挎崲杩囨棫鐨勭増鏈唬鍙蜂负褰撳墠绯荤粺鐗堟湰鐨勬纭唬鍙凤紝淇濇寔杈冩柊鐗堟湰浠ｅ彿涓嶅彉锛岄伩鍏嶅紩鍏ヤ笉鍏煎鐨勮蒋浠跺寘
	# 鍦烘櫙锛氱敤鎴风郴缁熷崌绾у悗锛宻ources.list涓粛鐒朵繚鐣欎簡鏃х増鏈殑浠ｅ彿锛屽鑷村畨瑁呰繃绋嬩腑鏃犳硶鎵惧埌姝ｇ‘鐨勮蒋浠跺寘锛屽畨瑁呭け璐?    [ ! -f "/usr/bin/apt-get" ] && return 0
    [ ! -f "/etc/os-release" ] && return 0
    
    . /etc/os-release
    
    # 鍙鐞咲ebian鍜孶buntu
    if [ "${ID}" != "debian" ] && [ "${ID}" != "ubuntu" ]; then
        return 0
    fi
    echo "=================================================="
    echo "妫€鏌?{ID}绯荤粺婧愰厤缃?.."
    
    # 瀹氫箟鐗堟湰浠ｅ彿鏄犲皠锛堟寜鐗堟湰椤哄簭锛?    local correct_codename=""
    local version_order=""
    local version_index=0
    
    if [ "${ID}" = "debian" ]; then
        case "${VERSION_ID%%.*}" in
            10) correct_codename="buster"; version_index=10 ;;
            11) correct_codename="bullseye"; version_index=11 ;;
            12) correct_codename="bookworm"; version_index=12 ;;
            13) correct_codename="trixie"; version_index=13 ;;
        esac
        # 瀹氫箟鐗堟湰椤哄簭鏄犲皠 (codename:version_number)
        declare -A debian_versions=(
            # ["jessie"]=8
            # ["stretch"]=9
            ["buster"]=10
            ["bullseye"]=11
            ["bookworm"]=12
            ["trixie"]=13
        )
        
    elif [ "${ID}" = "ubuntu" ]; then
        case "${VERSION_ID}" in
            18.04) correct_codename="bionic"; version_index=1804 ;;
            20.04) correct_codename="focal"; version_index=2004 ;;
            22.04) correct_codename="jammy"; version_index=2204 ;;
            24.04) correct_codename="noble"; version_index=2404 ;;
        esac
        # 瀹氫箟鐗堟湰椤哄簭鏄犲皠
        declare -A ubuntu_versions=(
            # ["trusty"]=1404
            # ["xenial"]=1604
            ["bionic"]=1804
            ["focal"]=2004
            ["jammy"]=2204
            ["noble"]=2404
        )
    fi
    
    if [ -z "${correct_codename}" ]; then
        echo "鏈瘑鍒殑${ID}鐗堟湰: ${VERSION_ID}"
        return 0
    fi
    
    echo "褰撳墠绯荤粺: ${ID} ${VERSION_ID} -> 姝ｇ‘: ${correct_codename}"
    
    # 妫€鏌ources.list
    sources_file="/etc/apt/sources.list"
    if [ ! -f "${sources_file}" ]; then
        echo "婧愭枃浠?${sources_file} 涓嶅瓨鍦紝璺宠繃妫€鏌?
        return 0
    fi
    
    # 鏀堕泦闇€瑕佹浛鎹㈢殑鏃т唬鍙?    need_fix=0
    old_codenames=""
    
    if [ "${ID}" = "debian" ]; then
        for codename in "${!debian_versions[@]}"; do
            local codename_version=${debian_versions[$codename]}
            # 鍙鐞嗘瘮褰撳墠鐗堟湰鏃х殑浠ｅ彿
            if [ ${codename_version} -lt ${version_index} ]; then
                if grep -q "[[:space:]]${codename}[[:space:]]" "${sources_file}" 2>/dev/null; then
                    echo "鍙戠幇鏃х増鏈唬鍙? ${codename} (鐗堟湰${codename_version} < 褰撳墠${version_index})"
                    old_codenames="${old_codenames} ${codename}"
                    need_fix=1
                fi
            elif [ ${codename_version} -gt ${version_index} ] && [ ${codename_version} -lt 99 ]; then
                if grep -q "[[:space:]]${codename}[[:space:]]" "${sources_file}" 2>/dev/null; then
                    echo "妫€娴嬪埌杈冩柊鐗堟湰浠ｅ彿: ${codename} (鐗堟湰${codename_version} > 褰撳墠${version_index})锛岃烦杩囨浛鎹?
                fi
            fi
        done
        
    elif [ "${ID}" = "ubuntu" ]; then
        for codename in "${!ubuntu_versions[@]}"; do
            local codename_version=${ubuntu_versions[$codename]}
            # 鍙鐞嗘瘮褰撳墠鐗堟湰鏃х殑浠ｅ彿
            if [ ${codename_version} -lt ${version_index} ]; then
                if grep -q "[[:space:]]${codename}[[:space:]]" "${sources_file}" 2>/dev/null; then
                    echo "鍙戠幇鏃х増鏈唬鍙? ${codename} (鐗堟湰${codename_version} < 褰撳墠${version_index})"
                    old_codenames="${old_codenames} ${codename}"
                    need_fix=1
                fi
            elif [ ${codename_version} -gt ${version_index} ]; then
                if grep -q "[[:space:]]${codename}[[:space:]]" "${sources_file}" 2>/dev/null; then
                    echo "妫€娴嬪埌杈冩柊鐗堟湰浠ｅ彿: ${codename} (鐗堟湰${codename_version} > 褰撳墠${version_index})锛岃烦杩囨浛鎹?
                fi
            fi
        done
    fi
    
    if [ ${need_fix} -eq 0 ]; then
        #echo "绯荤粺婧愰厤缃纭紝鏃犻渶淇"
        return 0
    fi
    
    # 澶囦唤骞朵慨澶?    echo "=================================================="
    echo "妫€娴嬪埌绯荤粺婧愰厤缃娇鐢ㄤ簡鏃х殑鐗堟湰鏈嶅姟鍣ㄤ唬鍙凤紒"
    echo "褰撳墠绯荤粺: ${ID} ${VERSION_ID} 搴斾娇鐢ㄦ湇鍔″櫒浠ｅ彿: ${correct_codename}"
    echo "姝ｅ湪鑷姩淇鏃х増鏈湇鍔″櫒浠ｅ彿..."
    echo "=================================================="
    
    # 澶囦唤鍘熸枃浠?    backup_file="${sources_file}.bak.$(date +%Y%m%d_%H%M%S)"
    \cp -p "${sources_file}" "${backup_file}"
    echo "宸插浠藉埌: ${backup_file}"
    
    # 鍙浛鎹㈡棫鐗堟湰鐨勪唬鍙?    for wrong_codename in ${old_codenames}; do
        sed -ri "/^[[:space:]]*(deb|deb-src) / s/${wrong_codename}/${correct_codename}/g" "${sources_file}"
        echo "宸叉浛鎹? ${wrong_codename} -> ${correct_codename}"
    done
    
    echo "婧愰厤缃凡淇锛屾洿鏂拌蒋浠跺寘鍒楄〃..."
    apt-get update -y 2>&1 | head -n 20
    
    if [ $? -eq 0 ]; then
        echo "婧愭洿鏂版垚鍔燂紒"
    else
        echo "璀﹀憡: apt-get update 鎵ц澶辫触锛屽彲鑳介渶瑕佹墜鍔ㄦ鏌?
        echo "濡傞渶鍥炴粴锛屽浠芥枃浠跺湪: ${backup_file}"
    fi
    
    return 0
}
Set_Repo_Url(){
	if [ "${PM}"="apt-get" ];then

		if [ -f "/etc/os-release" ];then
			. /etc/os-release
			OS_V=${VERSION_ID%%.*}
			if [ "${ID}" == "debian" ] && [ "${OS_V}" = "10" ];then
				apt-get update -y
				if [ "$?" != "0" ];then
					echo "deb https://mirrors.aliyun.com/debian-archive/debian/ buster main contrib non-free" > /etc/apt/sources.list
					echo "deb-src https://mirrors.aliyun.com/debian-archive/debian/ buster main contrib non-free" >> /etc/apt/sources.list
					echo "deb https://mirrors.aliyun.com/debian-archive/debian-security/ buster/updates main contrib non-free" >> /etc/apt/sources.list
					echo "deb-src https://mirrors.aliyun.com/debian-archive/debian-security/ buster/updates main contrib non-free" >> /etc/apt/sources.list
					apt-get update -y
				fi
				return
			fi
		fi

		ALI_CLOUD_CHECK=$(grep Alibaba /etc/motd)
		Tencent_Cloud=$(cat /etc/hostname |grep -E VM-[0-9]+-[0-9]+)
		VELINUX_CHECK=$(grep veLinux /etc/os-release)
		if [ "${ALI_CLOUD_CHECK}" ] || [ "${Tencent_Cloud}" ] || [ "${VELINUX_CHECK}" ];then
			return
		fi

		CN_CHECK=$(curl -sS --connect-timeout 10 -m 10 https://api.bt.cn/api/isCN)
		if [ "${CN_CHECK}" == "True" ];then
			SOURCE_URL_CHECK=$(grep -E 'security.ubuntu.com|archive.ubuntu.com|security.debian.org|deb.debian.org' /etc/apt/sources.list)
			if [ -f "/etc/apt/sources.list.d/ubuntu.sources" ];then
				SOURCE_URL_CHECK=$(grep -E 'security.ubuntu.com|archive.ubuntu.com|security.debian.org|deb.debian.org' /etc/apt/sources.list.d/ubuntu.sources)
			fi
		fi

		#GET_SOURCES_URL=$(cat /etc/apt/sources.list|grep ^deb|head -n 1|awk -F[/:] '{print $4}')
		GET_SOURCES_URL=$(cat /etc/apt/sources.list|grep ^deb|head -n 1|sed -E 's|^[^ ]+ https?://([^/]+).*|\1|')
		if [ -f "/etc/apt/sources.list.d/ubuntu.sources" ];then
			GET_SOURCES_URL=$(cat /etc/apt/sources.list.d/ubuntu.sources|grep ^URIs:|head -n 1|sed -E 's|^[^ ]+ https?://([^/]+).*|\1|')
		fi
		NODE_CHECK=$(curl --connect-timeout 3 -m 3 2>/dev/null -w "%{http_code} %{time_total}" ${GET_SOURCES_URL} -o /dev/null)
		NODE_STATUS=$(echo ${NODE_CHECK}|awk '{print $1}')
		TIME_TOTAL=$(echo ${NODE_CHECK}|awk '{print $2 * 1000}'|cut -d '.' -f 1)

		if { [ "${NODE_STATUS}" != "200" ] && [ "${NODE_STATUS}" != "301" ]; } || [ "${TIME_TOTAL}" -ge "500" ] || [ "${SOURCE_URL_CHECK}" ]; then
			\cp -rpa /etc/apt/sources.list /etc/apt/sources.list.btbackup
			apt_lists=(mirrors.cloud.tencent.com  mirrors.163.com repo.huaweicloud.com mirrors.tuna.tsinghua.edu.cn mirrors.aliyun.com mirrors.ustc.edu.cn )
			apt_lists=(mirrors.cloud.tencent.com repo.huaweicloud.com mirrors.aliyun.com mirrors.ustc.edu.cn mirrors.163.com)
			for list in ${apt_lists[@]};
			do
				NODE_CHECK=$(curl --connect-timeout 3 -m 3 2>/dev/null -w "%{http_code} %{time_total}" ${list} -o /dev/null)
				NODE_STATUS=$(echo ${NODE_CHECK}|awk '{print $1}')
				TIME_TOTAL=$(echo ${NODE_CHECK}|awk '{print $2 * 1000}'|cut -d '.' -f 1)
				if [ "${NODE_STATUS}" == "200" ] || [ "${NODE_STATUS}" == "301" ];then
					if [ "${TIME_TOTAL}" -le "150" ];then
						if [ -f "/etc/apt/sources.list" ];then
							sed -i "s/${GET_SOURCES_URL}/${list}/g" /etc/apt/sources.list
							sed -i "s/cn.security.ubuntu.com/${list}/g" /etc/apt/sources.list
							sed -i "s/cn.archive.ubuntu.com/${list}/g" /etc/apt/sources.list
							sed -i "s/security.ubuntu.com/${list}/g" /etc/apt/sources.list
							sed -i "s/archive.ubuntu.com/${list}/g" /etc/apt/sources.list
							sed -i "s/security.debian.org/${list}/g" /etc/apt/sources.list
							sed -i "s/deb.debian.org/${list}/g" /etc/apt/sources.list
						fi
						if [ -f "/etc/apt/sources.list.d/ubuntu.sources" ];then
							\cp -rpa /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak
							sed -i "s/${GET_SOURCES_URL}/${list}/g" /etc/apt/sources.list.d/ubuntu.sources
							sed -i "s/cn.security.ubuntu.com/${list}/g" /etc/apt/sources.list.d/ubuntu.sources
							sed -i "s/cn.archive.ubuntu.com/${list}/g" /etc/apt/sources.list.d/ubuntu.sources
							sed -i "s/security.ubuntu.com/${list}/g" /etc/apt/sources.list.d/ubuntu.sources
							sed -i "s/archive.ubuntu.com/${list}/g" /etc/apt/sources.list.d/ubuntu.sources
							sed -i "s/security.debian.org/${list}/g" /etc/apt/sources.list.d/ubuntu.sources
							sed -i "s/deb.debian.org/${list}/g" /etc/apt/sources.list.d/ubuntu.sources
							sleep 3
							apt-get update -y
							if [ $? != "0" ];then
								\cp -rpa /etc/apt/sources.list.d/ubuntu.sources.bak  /etc/apt/sources.list.d/ubuntu.sources
								apt-get update -y
						    fi 
						fi
						break;
					fi
				fi
			done
		fi
	fi
}
Auto_Swap()
{
	swap=$(free |grep Swap|awk '{print $2}')
	if [ "${swap}" -gt 1 ];then
		echo "Swap total sizse: $swap";
		return;
	fi
	if [ ! -d /www ];then
		mkdir /www
	fi
	echo "姝ｅ湪璁剧疆铏氭嫙鍐呭瓨锛岃绋嶇瓑..........";
	echo '---------------------------------------------';
	swapFile="/www/swap"
	dd if=/dev/zero of=$swapFile bs=1M count=1025
	mkswap -f $swapFile
	swapon $swapFile
	echo "$swapFile    swap    swap    defaults    0 0" >> /etc/fstab
	swap=`free |grep Swap|awk '{print $2}'`
	if [ $swap -gt 1 ];then
		KERNEL_MAJOR_VERSION=$(uname -r | cut -d '-' -f1 | awk -F. '{print $1}')
		KERNEL_MINOR_VERSION=$(uname -r | cut -d '-' -f1 | awk -F. '{print $2}')
		if [ -f "/etc/sysctl.conf" ]; then
			sed -i "/vm.swappiness/d" /etc/sysctl.conf
		fi
		if [ "$KERNEL_MAJOR_VERSION" -lt 3 ]; then
			sysctl -w vm.swappiness=1
			echo "vm.swappiness=1" >> /etc/sysctl.conf
		elif [ "$KERNEL_MAJOR_VERSION" = "3" ] && [ "$KERNEL_MINOR_VERSION" -lt 5 ]; then
			sysctl -w vm.swappiness=1
			echo "vm.swappiness=1" >> /etc/sysctl.conf
		else
			sysctl -w vm.swappiness=0
			echo "vm.swappiness=0" >> /etc/sysctl.conf
		fi
		echo "Swap total sizse: $swap";
		return;
	fi
	
	sed -i "/\/www\/swap/d" /etc/fstab
	rm -f $swapFile
}
Service_Add(){
	if [ "${PM}" == "yum" ] || [ "${PM}" == "dnf" ]; then
		chkconfig --add bt
		chkconfig --level 2345 bt on
		Centos9Check=$(cat /etc/redhat-release |grep ' 9')
		if [ "${Centos9Check}" ];then
            wget -O /usr/lib/systemd/system/btpanel.service ${download_Url}/init/systemd/btpanel.service
			systemctl enable btpanel
		fi		
	elif [ "${PM}" == "apt-get" ]; then
		update-rc.d bt defaults
	fi 
}
Set_Centos7_Repo(){
# 	CN_YUM_URL=$(grep -E "aliyun|163|tencent|tsinghua" /etc/yum.repos.d/CentOS-Base.repo)
# 	if [ -z "${CN_YUM_URL}" ];then
# 		if [ -z "${download_Url}" ];then
# 			download_Url="http://download.bt.cn"
# 		fi
# 		curl -Ss --connect-timeout 3 -m 60 ${download_Url}/install/vault-repo.sh|bash
# 		return
# 	fi
	MIRROR_CHECK=$(cat /etc/yum.repos.d/CentOS-Base.repo |grep "[^#]mirror.centos.org")
	if [ "${MIRROR_CHECK}" ] && [ "${is64bit}" == "64" ];then
		\cp -rpa /etc/yum.repos.d/ /etc/yumBak
		sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
		sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
	fi

	TSU_MIRROR_CHECK=$(cat /etc/yum.repos.d/CentOS-Base.repo |grep "tuna.tsinghua.edu.cn")
	if [ "${TSU_MIRROR_CHECK}" ];then
		\cp -rpa /etc/yum.repos.d/ /etc/yumBak
		sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
		sed -i 's|#baseurl=https://mirrors.tuna.tsinghua.edu.cn|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
		sed -i 's|#baseurl=http://mirrors.tuna.tsinghua.edu.cn|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
		sed -i 's|baseurl=https://mirrors.tuna.tsinghua.edu.cn|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
		sed -i 's|baseurl=http://mirrors.tuna.tsinghua.edu.cn|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
	fi

	ALI_CLOUD_CHECK=$(grep Alibaba /etc/motd)
	Tencent_Cloud=$(cat /etc/hostname |grep -E VM-[0-9]+-[0-9]+)
	if [ "${ALI_CLOUD_CHECK}" ] || [ "${Tencent_Cloud}" ];then
		return
	fi

	yum install unzip -y
	if [ "$?" != "0" ] ;then
		TAR_CHECK=$(which tar)
		if [ "$?" == "0" ] ;then
			\cp -rpa /etc/yum.repos.d/ /etc/yumBak
			if [ -z "${download_Url}" ];then
				download_Url="http://download.bt.cn"
			fi
			curl -Ss --connect-timeout 5 -m 60 -O ${download_Url}/src/el7repo.tar.gz
			rm -f /etc/yum.repos.d/*.repo
			tar -xvzf el7repo.tar.gz -C /etc/yum.repos.d/
		fi
	fi

	yum install unzip -y
	if [ "$?" != "0" ] ;then
		sed -i "s/vault.epel.cloud/mirrors.cloud.tencent.com/g" /etc/yum.repos.d/*.repo
	fi
}
Set_Centos8_Repo(){
	HUAWEI_CHECK=$(cat /etc/motd |grep "Huawei Cloud")
	if [ "${HUAWEI_CHECK}" ] && [ "${is64bit}" == "64" ];then
		\cp -rpa /etc/yum.repos.d/ /etc/yumBak
		sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
		sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
		rm -f /etc/yum.repos.d/epel.repo
		rm -f /etc/yum.repos.d/epel-*
	fi
	ALIYUN_CHECK=$(cat /etc/motd|grep "Alibaba Cloud ")
	if [  "${ALIYUN_CHECK}" ] && [ "${is64bit}" == "64" ] && [ ! -f "/etc/yum.repos.d/Centos-vault-8.5.2111.repo" ];then
		rename '.repo' '.repo.bak' /etc/yum.repos.d/*.repo
		wget https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo -O /etc/yum.repos.d/Centos-vault-8.5.2111.repo
		wget https://mirrors.aliyun.com/repo/epel-archive-8.repo -O /etc/yum.repos.d/epel-archive-8.repo
		sed -i 's/mirrors.cloud.aliyuncs.com/url_tmp/g'  /etc/yum.repos.d/Centos-vault-8.5.2111.repo &&  sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo && sed -i 's/url_tmp/mirrors.aliyun.com/g' /etc/yum.repos.d/Centos-vault-8.5.2111.repo
		sed -i 's/mirrors.aliyun.com/mirrors.cloud.aliyuncs.com/g' /etc/yum.repos.d/epel-archive-8.repo
	fi
	MIRROR_CHECK=$(cat /etc/yum.repos.d/CentOS-Linux-AppStream.repo |grep "[^#]mirror.centos.org")
	if [ "${MIRROR_CHECK}" ] && [ "${is64bit}" == "64" ];then
		\cp -rpa /etc/yum.repos.d/ /etc/yumBak
		sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
		sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
	fi

	yum install unzip tar -y
	if [ "$?" != "0" ] ;then

		if [ -d "/etc/yum.repos.d" ];then
			mkdir -p /etc/yum.repos.d
		fi

		if [ -z "${download_Url}" ];then
			download_Url="http://download.bt.cn"
		fi
		if [ ! -f "/usr/bin/tar" ]  || [ ! -f "/usr/sbin/tar" ];then
			curl -Ss --connect-timeout 5 -m 60 -O ${download_Url}/src/tar-1.30-5.el8.x86_64.rpm
			yum install tar-1.30-5.el8.x86_64.rpm -y
			if [ "$?" != "0" ] ;then
				rpm -ivh --nodeps --force tar-1.30-5.el8.x86_64.rpm
			fi
		fi
		\cp -rpa /etc/yum.repos.d/ /etc/yumBak
		curl -Ss --connect-timeout 5 -m 60 -O ${download_Url}/src/el8repo.tar.gz
		rm -f /etc/yum.repos.d/*.repo
		tar -xvzf el8repo.tar.gz -C /etc/yum.repos.d/
	fi

	yum install unzip tar -y
	if [ "$?" != "0" ] ;then
		sed -i "s/vault.epel.cloud/mirrors.cloud.tencent.com/g" /etc/yum.repos.d/*.repo
	fi
}
get_node_url(){
    if [ "${PM}" = "yum" ]; then
        yum install wget -y
		if [ ! -f "/usr/sbin/wget" ] && [ ! -f "/usr/bin/wget" ];then
            yum reinstall wget -y
        fi
    fi
	if [ ! -f /bin/curl ];then
		if [ "${PM}" = "yum" ]; then
			yum install curl -y
		elif [ "${PM}" = "apt-get" ]; then
			apt-get install curl -y
		fi
	fi

	if [ -f "/www/node.pl" ];then
		download_Url=$(cat /www/node.pl)
		echo "Download node: $download_Url";
		echo '---------------------------------------------';
		return
	fi
	
	echo '---------------------------------------------';
	echo "Selected download node...";
	nodes=(https://dg2.bt.cn https://download.bt.cn https://download-cdn1.bt.cn https://ctcc1-node.bt.cn https://cmcc1-node.bt.cn https://ctcc2-node.bt.cn https://hk1-node.bt.cn https://na1-node.bt.cn https://jp1-node.bt.cn https://cf1-node.aapanel.com https://download-cdn1.bt.cn);
	
	CURL_CHECK=$(which curl)
	if [ "$?" == "0" ];then
		CN_CHECK=$(curl -sS --connect-timeout 10 -m 10 https://api.bt.cn/api/isCN)
		if [ "${CN_CHECK}" == "True" ];then
			nodes=(https://dg2.bt.cn https://download-cdn1.bt.cn https://download.bt.cn https://ctcc1-node.bt.cn https://cmcc1-node.bt.cn http://download-cdn1.bt.cn https://ctcc2-node.bt.cn https://hk1-node.bt.cn);
		else
			PING6_CHECK=$(ping6 -c 2 -W 2 download.bt.cn &> /dev/null && echo "yes" || echo "no")
			if [ "${PING6_CHECK}" == "yes" ];then
				nodes=(https://dg2.bt.cn https://download.bt.cn https://cf1-node.aapanel.com https://download-cdn1.bt.cn);
			else
				#nodes=(https://cf1-node.aapanel.com https://download.bt.cn https://na1-node.bt.cn https://jp1-node.bt.cn https://dg2.bt.cn);
				nodes=(https://cf1-node.aapanel.com https://cf1-node.aapanel.com https://jp1-node.bt.cn https://download.bt.cn https://dg2.bt.cn https://download-cdn1.bt.cn);
			fi
		fi
	fi

	if [ "$1" ];then
		nodes=($(echo ${nodes[*]}|sed "s#${1}##"))
	fi

	tmp_file1=/dev/shm/net_test1.pl
	tmp_file2=/dev/shm/net_test2.pl
	[ -f "${tmp_file1}" ] && rm -f ${tmp_file1}
	[ -f "${tmp_file2}" ] && rm -f ${tmp_file2}
	touch $tmp_file1
	touch $tmp_file2
	for node in ${nodes[@]};
	do
		if [ "${node}" == "https://cf1-node.aapanel.com" ];then
			NODE_CHECK=$(curl --connect-timeout 3 -m 3 2>/dev/null -w "%{http_code} %{time_total}" ${node}/1net_test|xargs)
		else
			NODE_CHECK=$(curl --connect-timeout 3 -m 3 2>/dev/null -w "%{http_code} %{time_total}" ${node}/net_test|xargs)
		fi
		RES=$(echo ${NODE_CHECK}|awk '{print $1}')
		NODE_STATUS=$(echo ${NODE_CHECK}|awk '{print $2}')
		TIME_TOTAL=$(echo ${NODE_CHECK}|awk '{print $3 * 1000 - 500 }'|cut -d '.' -f 1)
		if [ "${NODE_STATUS}" == "200" ];then
			if [ $TIME_TOTAL -lt 300 ];then
				if [ $RES -ge 1500 ];then
					echo "$RES $node" >> $tmp_file1
				fi
			else
				if [ $RES -ge 1500 ];then
					echo "$TIME_TOTAL $node" >> $tmp_file2
				fi
			fi

			i=$(($i+1))
			if [ $TIME_TOTAL -lt 300 ];then
				if [ $RES -ge 2390 ];then
					break;
				fi
			fi	
		fi
	done

	NODE_URL=$(cat $tmp_file1|sort -r -g -t " " -k 1|head -n 1|awk '{print $2}')
	if [ -z "$NODE_URL" ];then
		NODE_URL=$(cat $tmp_file2|sort -g -t " " -k 1|head -n 1|awk '{print $2}')
		if [ -z "$NODE_URL" ];then
			NODE_URL='https://download.bt.cn';
		fi
	fi
	rm -f $tmp_file1
	rm -f $tmp_file2
	download_Url=$NODE_URL
	echo "Download node: $download_Url";
	echo '---------------------------------------------';
}
Remove_Package(){
	local PackageNmae=$1
	if [ "${PM}" == "yum" ];then
		isPackage=$(rpm -q ${PackageNmae}|grep "not installed")
		if [ -z "${isPackage}" ];then
			yum remove ${PackageNmae} -y
		fi 
	elif [ "${PM}" == "apt-get" ];then
		isPackage=$(dpkg -l|grep ${PackageNmae})
		if [ "${PackageNmae}" ];then
			apt-get remove ${PackageNmae} -y
		fi
	fi
}
Install_RPM_Pack(){
	yumPath=/etc/yum.conf

	CentosStream8Check=$(cat /etc/redhat-release |grep Stream|grep 8)
	if [ "${CentosStream8Check}" ];then
		MIRROR_CHECK=$(cat /etc/yum.repos.d/CentOS-Stream-AppStream.repo|grep "[^#]mirror.centos.org")
		if [ "${MIRROR_CHECK}" ] && [ "${is64bit}" == "64" ];then
			\cp -rpa /etc/yum.repos.d/ /etc/yumBak
			sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
			sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.epel.cloud|g' /etc/yum.repos.d/CentOS-*.repo
		fi
	fi

	Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
	if [ "${Centos8Check}" ];then
		Set_Centos8_Repo
	fi	
	Centos7Check=$(cat /etc/redhat-release | grep ' 7.' | grep -iE 'centos|Red Hat')
	if [ "${Centos7Check}" ];then
		Set_Centos7_Repo
	fi
	isExc=$(cat $yumPath|grep httpd)
	if [ "$isExc" = "" ];then
		echo "exclude=httpd nginx php mysql mairadb python-psutil python2-psutil" >> $yumPath
	fi

	if [ -f "/etc/redhat-release" ] && [ $(cat /etc/os-release|grep PLATFORM_ID|grep -oE "el8") ];then
		yum config-manager --set-enabled powertools
		yum config-manager --set-enabled PowerTools
	fi

	if [ -f "/etc/redhat-release" ] && [ $(cat /etc/os-release|grep PLATFORM_ID|grep -oE "el9") ];then
		dnf config-manager --set-enabled crb -y
	fi

	#SYS_TYPE=$(uname -a|grep x86_64)
	#yumBaseUrl=$(cat /etc/yum.repos.d/CentOS-Base.repo|grep baseurl=http|cut -d '=' -f 2|cut -d '$' -f 1|head -n 1)
	#[ "${yumBaseUrl}" ] && checkYumRepo=$(curl --connect-timeout 5 --head -s -o /dev/null -w %{http_code} ${yumBaseUrl})	
	#if [ "${checkYumRepo}" != "200" ] && [ "${SYS_TYPE}" ];then
	#	curl -Ss --connect-timeout 3 -m 60 http://download.bt.cn/install/yumRepo_select.sh|bash
	#fi
	
	#灏濊瘯鍚屾鏃堕棿(浠巄t.cn)
	echo 'Synchronizing system time...'
	getBtTime=$(curl -sS --connect-timeout 3 -m 60 https://www.bt.cn/api/index/get_time)
	if [ "${getBtTime}" ];then	
		date -s "$(date -d @$getBtTime +"%Y-%m-%d %H:%M:%S")"
	fi

	if [ -z "${Centos8Check}" ]; then
		yum install ntp -y
		rm -rf /etc/localtime
		ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

		#灏濊瘯鍚屾鍥介檯鏃堕棿(浠巒tp鏈嶅姟鍣?
		ntpdate 0.asia.pool.ntp.org
		setenforce 0
	fi

	startTime=`date +%s`

	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	#yum remove -y python-requests python3-requests python-greenlet python3-greenlet
	yumPacks="libcurl-devel wget tar gcc make zip unzip openssl openssl-devel gcc libxml2 libxml2-devel libxslt* zlib zlib-devel libjpeg-devel libpng-devel libwebp libwebp-devel freetype freetype-devel lsof pcre pcre-devel vixie-cron crontabs icu libicu-devel c-ares libffi-devel bzip2-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel qrencode at rsyslog net-tools firewalld"
	yum install -y ${yumPacks}

	for yumPack in ${yumPacks}
	do
		rpmPack=$(rpm -q ${yumPack})
		packCheck=$(echo ${rpmPack}|grep not)
		if [ "${packCheck}" ]; then
			yum install ${yumPack} -y
		fi
	done
	if [ -f "/usr/bin/dnf" ]; then
		dnf install -y redhat-rpm-config
	fi

	# if [ ! -f "/usr/bin/mysql" ] && [ -f "/usr/sbin/mysql" ];then
	# 	yum install 
	# fi

	ALI_OS=$(cat /etc/redhat-release |grep "Alibaba Cloud Linux release 3")
	if [ -z "${ALI_OS}" ];then 
		yum install epel-release -y
	fi
}
Install_Deb_Pack(){
	ln -sf bash /bin/sh
	UBUNTU_22=$(cat /etc/issue|grep "Ubuntu 22")
	UBUNTU_24=$(cat /etc/issue|grep "Ubuntu 24")
	if [ "${UBUNTU_22}" ] || [ "${UBUNTU_24}" ];then
		apt-get remove needrestart -y
	fi
	ALIYUN_CHECK=$(cat /etc/motd|grep "Alibaba Cloud ")
	if [ "${ALIYUN_CHECK}" ] && [ "${UBUNTU_22}" ];then
		apt-get remove libicu70 -y
	fi
	apt-get update -y

	FNOS_CHECK=$(cat /etc/issue|grep fnOS)
	if [ "${FNOS_CHECK}" ];then
		apt-get install libc6 --allow-change-held-packages -y
		apt-get install libc6-dev --allow-change-held-packages -y
	fi

	apt-get install bash -y
	if [ -f "/usr/bin/bash" ];then
		ln -sf /usr/bin/bash /bin/sh
		ln -sf /usr/bin/bash /usr/bin/sh
	fi
	apt-get install ruby -y
	apt-get install lsb-release -y
	#apt-get install ntp ntpdate -y
	#/etc/init.d/ntp stop
	#update-rc.d ntp remove
	#cat >>~/.profile<<EOF
	#TZ='Asia/Shanghai'; export TZ
	#EOF
	#rm -rf /etc/localtime
	#cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	#echo 'Synchronizing system time...'
	#ntpdate 0.asia.pool.ntp.org
	#apt-get upgrade -y
	LIBCURL_VER=$(dpkg -l|grep libcurl4|awk '{print $3}')
	if [ "${LIBCURL_VER}" == "7.68.0-1ubuntu2.8" ];then
		apt-get remove libcurl4 -y
		apt-get install curl -y
	fi

	debPacks="wget curl libcurl4-openssl-dev gcc make zip unzip tar openssl libssl-dev gcc libxml2 libxml2-dev zlib1g zlib1g-dev libjpeg-dev libpng-dev lsof libpcre3 libpcre3-dev cron net-tools swig build-essential libffi-dev libbz2-dev libncurses-dev libsqlite3-dev libreadline-dev tk-dev libgdbm-dev libdb-dev libdb++-dev libpcap-dev xz-utils git qrencode sqlite3 at rsyslog net-tools ufw";
	apt-get install -y $debPacks --force-yes

	for debPack in ${debPacks}
	do
		packCheck=$(dpkg -l|grep ${debPack})
		if [ "$?" -ne "0" ] ;then
			apt-get install -y $debPack
		fi
	done
	
	if [ ! -f "/usr/bin/mysql" ] && [ -f "/usr/sbin/mysql" ];then
		apt-get install mysql-client -y
	fi
	
	if [ ! -d '/etc/letsencrypt' ];then
		mkdir -p /etc/letsencryp
		mkdir -p /var/spool/cron
		if [ ! -f '/var/spool/cron/crontabs/root' ];then
			echo '' > /var/spool/cron/crontabs/root
			chmod 600 /var/spool/cron/crontabs/root
		fi	
	fi
}

Install_Other_Pack(){
	if [ -f "/sbin/apk" ];then
		sed -i 's/dl-cdn.alpinelinux.org/mirrors.tencent.com/g' /etc/apk/repositories
		apk update
		apk upgrade
		apk add openrc openssh curl curl-dev libffi-dev openssl-dev shadow bash zlib-dev g++ make sqlite-dev libpcap-dev jpeg-dev dos2unix libev-dev build-base linux-headers gd-dev bash openssl libxml2-dev libxslt-dev jemalloc-dev luajit luajit-dev
		LOCK_PIP="True"
	fi
}

Get_Versions(){
	redhat_version_file="/etc/redhat-release"
	deb_version_file="/etc/issue"

	if [[ $(grep Anolis /etc/os-release) ]] && [[ $(grep VERSION /etc/os-release|grep 8.8) ]];then
		if [ -f "/usr/bin/yum" ];then
			os_type="anolis"
			os_version="8"
			return
		fi
	fi


	if [ -f "/etc/os-release" ];then
		. /etc/os-release
		OS_V=${VERSION_ID%%.*}
		if [ "${ID}" == "opencloudos" ] && [[ "${OS_V}" =~ ^(9)$ ]];then
			os_type="opencloudos"
			os_version="9"
			pyenv_tt="true"
		elif { [ "${ID}" == "almalinux" ] || [ "${ID}" == "centos" ] || [ "${ID}" == "rocky" ]; } && [[ "${OS_V}" =~ ^(9|10)$ ]]; then
			os_type="el"
			os_version="9"
			pyenv_tt="true"
		elif [ "${ID}" == "alinux" ] && [[ "${OS_V}" =~ ^(4)$ ]];then
			os_type="alinux"
			os_version="4"
			pyenv_tt="true"
		fi
		if [ "${pyenv_tt}" ];then
			return
		fi
	fi
    
	if [ -f $redhat_version_file ];then
		os_type='el'
		is_aliyunos=$(cat $redhat_version_file|grep Aliyun)
		if [ "$is_aliyunos" != "" ];then
			return
		fi

		if [[ $(grep "Alibaba Cloud" /etc/redhat-release) ]] && [[ $(grep al8 /etc/os-release) ]];then
			os_type="ali-linux-"
			os_version="al8"
			return
		fi

		if [[ $(grep "TencentOS Server" /etc/redhat-release|grep 3.1) ]];then
			os_type="TencentOS-"
			os_version="3.1"
			return
		fi

		os_version=$(cat $redhat_version_file|grep CentOS|grep -Eo '([0-9]+\.)+[0-9]+'|grep -Eo '^[0-9]')
		if [ "${os_version}" = "5" ];then
			os_version=""
		fi
		if [ -z "${os_version}" ];then
			os_version=$(cat /etc/redhat-release |grep Stream|grep -oE 8)
		fi
	else
		os_type='ubuntu'
		os_version=$(cat $deb_version_file|grep Ubuntu|grep -Eo '([0-9]+\.)+[0-9]+'|grep -Eo '^[0-9]+')
		if [ "${os_version}" = "" ];then
			os_type='debian'
			os_version=$(cat $deb_version_file|grep Debian|grep -Eo '([0-9]+\.)+[0-9]+'|grep -Eo '[0-9]+')
			if [ "${os_version}" = "" ];then
				os_version=$(cat $deb_version_file|grep Debian|grep -Eo '[0-9]+')
			fi
			if [ "${os_version}" = "8" ];then
				os_version=""
			fi
			if [ "${is64bit}" = '32' ];then
				os_version=""
			fi
		else
			if [ "$os_version" = "14" ];then
				os_version=""
			fi
			if [ "$os_version" = "12" ];then
				os_version=""
			fi
			if [ "$os_version" = "19" ];then
				os_version=""
			fi
			if [ "$os_version" = "21" ];then
				os_version=""
			fi
			if [ "$os_version" = "20" ];then
				os_version2004=$(cat /etc/issue|grep 20.04)
				if [ -z "${os_version2004}" ];then
					os_version=""
				fi
			fi
		fi
	fi
}
Install_Python_Lib(){

	if [ -f "/www/server/panel/pyenv/bin/python3.7" ];then
		python_file_date=$(date -r /www/server/panel/pyenv/bin/python3.7  +"%Y")
		if [ "${python_file_date}" -lt "2021" ];then
			rm -rf /www/server/panel/pyenv
		fi
	fi
	
	curl -Ss --connect-timeout 3 -m 60 $download_Url/install/pip_select.sh|bash
	if [ "${LOCK_PIP}" ];then
		if [ ! -d ~/.pip ];then
		mkdir -p ~/.pip
		fi
		cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://mirrors.tencent.com/pypi/simple

[install]
trusted-host = mirrors.tencent.com
EOF
	fi
	
	pyenv_path="/www/server/panel"
	if [ -f $pyenv_path/pyenv/bin/python ];then
	 	is_ssl=$($python_bin -c "import ssl" 2>&1|grep cannot)
		$pyenv_path/pyenv/bin/python3.7 -V
		if [ $? -eq 0 ] && [ -z "${is_ssl}" ];then
			chmod -R 700 $pyenv_path/pyenv/bin
			is_package=$($python_bin -m psutil 2>&1|grep package)
			if [ "$is_package" = "" ];then
				wget -O $pyenv_path/pyenv/pip.txt $download_Url/install/pyenv/pip.txt -T 15
				$pyenv_path/pyenv/bin/pip install -U pip
				$pyenv_path/pyenv/bin/pip install -U setuptools==65.5.0
				$pyenv_path/pyenv/bin/pip install -r $pyenv_path/pyenv/pip.txt
			fi
			source $pyenv_path/pyenv/bin/activate
			chmod -R 700 $pyenv_path/pyenv/bin
			return
		else
			rm -rf $pyenv_path/pyenv
		fi
	fi

	is_loongarch64=$(uname -a|grep loongarch64)
	if [ "$is_loongarch64" != "" ] && [ -f "/usr/bin/yum" ];then
		yumPacks="python3-devel python3-pip python3-psutil python3-gevent python3-pyOpenSSL python3-paramiko python3-flask python3-rsa python3-requests python3-six python3-websocket-client"
		yum install -y ${yumPacks}
		for yumPack in ${yumPacks}
		do
			rpmPack=$(rpm -q ${yumPack})
			packCheck=$(echo ${rpmPack}|grep not)
			if [ "${packCheck}" ]; then
				yum install ${yumPack} -y
			fi
		done

		pip3 install -U pip
		pip3 install Pillow psutil pyinotify pycryptodome upyun oss2 pymysql qrcode qiniu redis pymongo Cython configparser cos-python-sdk-v5 supervisor gevent-websocket pyopenssl
		pip3 install flask==1.1.4
		pip3 install Pillow -U

		pyenv_bin=/www/server/panel/pyenv/bin
		mkdir -p $pyenv_bin
		ln -sf /usr/local/bin/pip3 $pyenv_bin/pip
		ln -sf /usr/local/bin/pip3 $pyenv_bin/pip3
		ln -sf /usr/local/bin/pip3 $pyenv_bin/pip3.7

		if [ -f "/usr/bin/python3.7" ];then
			ln -sf /usr/bin/python3.7 $pyenv_bin/python
			ln -sf /usr/bin/python3.7 $pyenv_bin/python3
			ln -sf /usr/bin/python3.7 $pyenv_bin/python3.7
		elif [ -f "/usr/bin/python3.6"  ]; then
			ln -sf /usr/bin/python3.6 $pyenv_bin/python
			ln -sf /usr/bin/python3.6 $pyenv_bin/python3
			ln -sf /usr/bin/python3.6 $pyenv_bin/python3.7
		fi

		echo > $pyenv_bin/activate

		return
	fi

	py_version="3.7.16"
	mkdir -p $pyenv_path
	echo "True" > /www/disk.pl
	if [ ! -w /www/disk.pl ];then
		Red_Error "ERROR: Install python env fielded." "ERROR: /www鐩綍鏃犳硶鍐欏叆锛岃妫€鏌ョ洰褰?鐢ㄦ埛/纾佺洏鏉冮檺锛?
	fi
	os_type='el'
	os_version='7'
	is_export_openssl=0
	Get_Versions

	echo "OS: $os_type - $os_version"
	is_aarch64=$(uname -a|grep aarch64)
	if [ "$is_aarch64" != "" ];then
		is64bit="aarch64"
	fi
	
	if [ -f "/www/server/panel/pymake.pl" ];then
		os_version=""
		rm -f /www/server/panel/pymake.pl
	fi	
	echo "==============================================="
	echo "姝ｅ湪涓嬭浇闈㈡澘杩愯鐜锛岃绋嶇瓑..............."
	echo "==============================================="
	if [ "${os_version}" != "" ];then
		pyenv_file="/www/pyenv.tar.gz"
		#Download_File ${download_Url} ${backup_Url} "/install/pyenv/pyenv-${os_type}${os_version}-x${is64bit}.tar.gz" $pyenv_file
		wget -O $pyenv_file $download_Url/install/pyenv/pyenv-${os_type}${os_version}-x${is64bit}.tar.gz -T 20
		if [ "$?" != "0" ];then
			get_node_url $download_Url
			wget -O $pyenv_file $download_Url/install/pyenv/pyenv-${os_type}${os_version}-x${is64bit}.tar.gz -T 20
		fi
		tmp_size=$(du -b $pyenv_file|awk '{print $1}')
		if [ $tmp_size -lt 703460 ];then
			rm -f $pyenv_file
			echo "ERROR: Download python env fielded."
		else
			echo "Install python env..."
			tar zxvf $pyenv_file -C $pyenv_path/ > /dev/null
			chmod -R 700 $pyenv_path/pyenv/bin
			if [ ! -f $pyenv_path/pyenv/bin/python ];then
				rm -f $pyenv_file
				Red_Error "ERROR: Install python env fielded." "ERROR: 涓嬭浇瀹濆杩愯鐜澶辫触锛岃灏濊瘯閲嶆柊瀹夎锛? 
			fi
			$pyenv_path/pyenv/bin/python3.7 -V
			if [ $? -eq 0 ];then
				rm -f $pyenv_file
				ln -sf $pyenv_path/pyenv/bin/pip3.7 /usr/bin/btpip
				ln -sf $pyenv_path/pyenv/bin/python3.7 /usr/bin/btpython
				source $pyenv_path/pyenv/bin/activate
				return
			else
				rm -f $pyenv_file
				rm -rf $pyenv_path/pyenv
			fi
		fi
	fi

	cd /www
	python_src='/www/python_src.tar.xz'
	python_src_path="/www/Python-${py_version}"
	wget -O $python_src $download_Url/src/Python-${py_version}.tar.xz -T 15
	tmp_size=$(du -b $python_src|awk '{print $1}')
	if [ $tmp_size -lt 10703460 ];then
		rm -f $python_src
		Red_Error "ERROR: Download python source code fielded." "ERROR: 涓嬭浇瀹濆杩愯鐜澶辫触锛岃灏濊瘯閲嶆柊瀹夎锛?
	fi
	tar xvf $python_src
	rm -f $python_src
	cd $python_src_path
	./configure --prefix=$pyenv_path/pyenv
	make -j$cpu_cpunt
	make install
	if [ ! -f $pyenv_path/pyenv/bin/python3.7 ];then
		rm -rf $python_src_path
		Red_Error "ERROR: Make python env fielded." "ERROR: 缂栬瘧瀹濆杩愯鐜澶辫触锛?
	fi
	cd ~
	rm -rf $python_src_path
	wget -O $pyenv_path/pyenv/bin/activate $download_Url/install/pyenv/activate.panel -T 20
	wget -O $pyenv_path/pyenv/pip.txt $download_Url/install/pyenv/pip-3.7.16.txt -T 20
	ln -sf $pyenv_path/pyenv/bin/pip3.7 $pyenv_path/pyenv/bin/pip
	ln -sf $pyenv_path/pyenv/bin/python3.7 $pyenv_path/pyenv/bin/python
	ln -sf $pyenv_path/pyenv/bin/pip3.7 /usr/bin/btpip
	ln -sf $pyenv_path/pyenv/bin/python3.7 /usr/bin/btpython
	chmod -R 700 $pyenv_path/pyenv/bin
	$pyenv_path/pyenv/bin/pip install -U pip
	$pyenv_path/pyenv/bin/pip install -U setuptools==65.5.0
	$pyenv_path/pyenv/bin/pip install -U wheel==0.34.2 
	$pyenv_path/pyenv/bin/pip install -r $pyenv_path/pyenv/pip.txt

	wget -O pip-packs.txt $download_Url/install/pyenv/pip-packs.txt
	echo "姝ｅ湪鍚庡彴瀹夎pip渚濊禆璇风◢绛?........."
	PIP_PACKS=$(cat pip-packs.txt)
	for P_PACK in ${PIP_PACKS};
	do
		btpip show ${P_PACK} > /dev/null 2>&1
		if [ "$?" == "1" ];then
			btpip install ${P_PACK}
		fi 
	done

	rm -f pip-packs.txt

	source $pyenv_path/pyenv/bin/activate

	btpip install psutil
	btpip install gevent

	is_gevent=$($python_bin -m gevent 2>&1|grep -oE package)
	is_psutil=$($python_bin -m psutil 2>&1|grep -oE package)
	if [ "${is_gevent}" != "${is_psutil}" ];then
		Red_Error "ERROR: psutil/gevent install failed!"
	fi
}
Install_Bt(){
	if [ -f ${setup_path}/server/panel/data/port.pl ];then
		panelPort=$(cat ${setup_path}/server/panel/data/port.pl)
	fi
	if [ "${PANEL_PORT}" ];then
		panelPort=$PANEL_PORT
	fi
	mkdir -p ${setup_path}/server/panel/logs
	mkdir -p ${setup_path}/server/panel/vhost/apache
	mkdir -p ${setup_path}/server/panel/vhost/nginx
	mkdir -p ${setup_path}/server/panel/vhost/rewrite
	mkdir -p ${setup_path}/server/panel/install
	mkdir -p /www/server
	mkdir -p /www/wwwroot
	mkdir -p /www/wwwlogs
	mkdir -p /www/backup/database
	mkdir -p /www/backup/site

	if [ ! -d "/etc/init.d" ];then
		mkdir -p /etc/init.d
	fi

	if [ -f "/etc/init.d/bt" ]; then
		/etc/init.d/bt stop
		sleep 1
	fi

	wget -O /etc/init.d/bt ${download_Url}/install/src/bt6.init -T 15
	wget -O /www/server/panel/install/public.sh ${Btapi_Url}/install/public.sh -T 15
	echo "=============================================="
	echo "姝ｅ湪涓嬭浇闈㈡澘鏂囦欢,璇风◢绛?.................."
	echo "=============================================="
	wget -O panel.zip ${Btapi_Url}/install/src/panel6.zip -T 15

	if [ -f "${setup_path}/server/panel/data/default.db" ];then
		if [ -d "/${setup_path}/server/panel/old_data" ];then
			rm -rf ${setup_path}/server/panel/old_data
		fi
		mkdir -p ${setup_path}/server/panel/old_data
		d_format=$(date +"%Y%m%d_%H%M%S")
		\cp -arf ${setup_path}/server/panel/data/default.db ${setup_path}/server/panel/data/default_backup_${d_format}.db
		mv -f ${setup_path}/server/panel/data/default.db ${setup_path}/server/panel/old_data/default.db
		mv -f ${setup_path}/server/panel/data/system.db ${setup_path}/server/panel/old_data/system.db
		mv -f ${setup_path}/server/panel/data/port.pl ${setup_path}/server/panel/old_data/port.pl
		mv -f ${setup_path}/server/panel/data/admin_path.pl ${setup_path}/server/panel/old_data/admin_path.pl
		
		if [ -d "${setup_path}/server/panel/data/db" ];then
			\cp -r ${setup_path}/server/panel/data/db ${setup_path}/server/panel/old_data/
		fi
		
	fi

	if [ ! -f "/usr/bin/unzip" ]; then
		if [ "${PM}" = "yum" ]; then
			yum install unzip -y
		elif [ "${PM}" = "apt-get" ]; then
			apt-get update
			Fix_Apt_Lock
			apt-get install unzip -y 2>&1|tee /tmp/apt_install_log.log
			UNZIP_CHECK=$(which unzip)
			if [ "$?" != "0" ];then
				RECONFIGURE_CHECK=$(grep "dpkg --configure -a" /tmp/apt_install_log.log)
				if [ "${RECONFIGURE_CHECK}" ];then
					dpkg --configure -a
				fi
				APT_LOCK_CHECH=$(grep "/var/lib/dpkg/lock" /tmp/apt_install_log.log)
				if [ "${APT_LOCK_CHECH}" ];then
					pkill dpkg
					pkill apt-get
					pkill apt
					[ -e /var/lib/dpkg/lock-frontend ] && rm -f /var/lib/dpkg/lock-frontend
					[ -e /var/lib/dpkg/lock ] && rm -f /var/lib/dpkg/lock
					[ -e /var/lib/apt/lists/lock ] && rm -f /var/lib/apt/lists/lock
					[ -e /var/cache/apt/archives/lock ] && rm -f /var/cache/apt/archives/lock
					dpkg --configure -a
				fi
				sleep 5
				apt-get install unzip -y
			fi
		fi
	fi

	unzip -o panel.zip -d ${setup_path}/server/ > /dev/null

	if [ -d "${setup_path}/server/panel/old_data" ];then
		mv -f ${setup_path}/server/panel/old_data/default.db ${setup_path}/server/panel/data/default.db
		mv -f ${setup_path}/server/panel/old_data/system.db ${setup_path}/server/panel/data/system.db
		mv -f ${setup_path}/server/panel/old_data/port.pl ${setup_path}/server/panel/data/port.pl
		mv -f ${setup_path}/server/panel/old_data/admin_path.pl ${setup_path}/server/panel/data/admin_path.pl
		
		if [ -d "${setup_path}/server/panel/old_data/db" ];then
			\cp -r ${setup_path}/server/panel/old_data/db ${setup_path}/server/panel/data/
		fi
		
		if [ -d "/${setup_path}/server/panel/old_data" ];then
			rm -rf ${setup_path}/server/panel/old_data
		fi
	fi

	if [ ! -f ${setup_path}/server/panel/tools.py ] || [ ! -f ${setup_path}/server/panel/BT-Panel ];then
		ls -lh panel.zip
		Red_Error "ERROR: Failed to download, please try install again!" "ERROR: 涓嬭浇瀹濆澶辫触锛岃灏濊瘯閲嶆柊瀹夎锛?
	fi
    
    SYS_LOG_CHECK=$(grep ^weekly /etc/logrotate.conf)
    if [ "${SYS_LOG_CHECK}" ];then
        sed -i 's/rotate [0-9]*/rotate 8/g' /etc/logrotate.conf 
    fi

	rm -f panel.zip
	rm -f ${setup_path}/server/panel/class/*.pyc
	rm -f ${setup_path}/server/panel/*.pyc

	chmod +x /etc/init.d/bt
	chmod -R 600 ${setup_path}/server/panel
	chmod -R +x ${setup_path}/server/panel/script
	chmod -R 700 $pyenv_path/pyenv/bin
	ln -sf /etc/init.d/bt /usr/bin/bt
	chmod +x /www/server/panel/script/btcli.py
	ln -sf /www/server/panel/script/btcli.py /usr/bin/btcli
	echo "${panelPort}" > ${setup_path}/server/panel/data/port.pl
	wget -O /etc/init.d/bt ${download_Url}/install/src/bt7.init -T 15
	wget -O /www/server/panel/init.sh ${download_Url}/install/src/bt7.init -T 15
	if [ -f "/www/server/panel/config/default_soft_list.conf" ];then
		\cp -rpa /www/server/panel/config/default_soft_list.conf /www/server/panel/data/softList.conf
	else
		wget -O /www/server/panel/data/softList.conf ${download_Url}/install/conf/softListtls10.conf
	fi

	rm -rf /www/server/panel/plugin/webssh/
	rm -f /www/server/panel/class/*.so
	if [ ! -f /www/server/panel/data/not_workorder.pl ]; then
		echo "True" > /www/server/panel/data/not_workorder.pl
	fi
	if [ ! -f /www/server/panel/data/not_panelai.pl ]; then
		echo "True" > /www/server/panel/data/not_panelai.pl
	fi
	if [ ! -f /www/server/panel/data/not_evaluate.pl ]; then
		echo "True" > /www/server/panel/data/not_evaluate.pl
	fi
	if [ ! -f /www/server/panel/data/userInfo.json ]; then
		echo "{\"uid\":1,\"username\":\"Administrator\",\"address\":\"127.0.0.1\",\"access_key\":\"test\",\"secret_key\":\"123456\",\"ukey\":\"123456\",\"state\":1}" > /www/server/panel/data/userInfo.json
	fi
	if [ ! -f /www/server/panel/data/panel_nps.pl ]; then
		echo "" > /www/server/panel/data/panel_nps.pl
	fi
	if [ ! -f /www/server/panel/data/btwaf_nps.pl ]; then
		echo "" > /www/server/panel/data/btwaf_nps.pl
	fi
	if [ ! -f /www/server/panel/data/tamper_proof_nps.pl ]; then
		echo "" > /www/server/panel/data/tamper_proof_nps.pl
	fi
	if [ ! -f /www/server/panel/data/total_nps.pl ]; then
		echo "" > /www/server/panel/data/total_nps.pl
	fi
}
Set_Bt_Panel(){
	Run_User="www"
	wwwUser=$(cat /etc/passwd|cut -d ":" -f 1|grep ^www$)
	if [ "${wwwUser}" != "www" ];then
		groupadd ${Run_User}
		useradd -s /sbin/nologin -g ${Run_User} ${Run_User}
	fi

	password=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
	if [ "$PANEL_PASSWORD" ];then
		password=$PANEL_PASSWORD
	fi
	sleep 1
	admin_auth="/www/server/panel/data/admin_path.pl"
	if [ ! -f ${admin_auth} ];then
		auth_path=$(cat /dev/urandom | head -n 16 | md5sum | head -c 8)
		echo "/${auth_path}" > ${admin_auth}
	fi
	if [ "${SAFE_PATH}" ];then
		auth_path=$SAFE_PATH
		echo "/${auth_path}" > ${admin_auth}
	fi

	btpip install asn1crypto==1.5.1 cbor2==5.4.6 
	btpip install openai==1.39.0 numpy==1.21.6
	if [ ! -f "/www/server/panel/pyenv/n.pl" ];then
		btpip install docxtpl==0.16.7
		/www/server/panel/pyenv/bin/pip3 install pymongo
		/www/server/panel/pyenv/bin/pip3 install psycopg2-binary
		/www/server/panel/pyenv/bin/pip3 install flask -U
		/www/server/panel/pyenv/bin/pip3 install flask-sock
		/www/server/panel/pyenv/bin/pip3 install -I gevent
		btpip install simple-websocket==0.10.0
		btpip install natsort
		btpip uninstall enum34 -y
		btpip install geoip2==4.7.0
		btpip install brotli
		btpip install PyMySQL
	fi
	auth_path=$(cat ${admin_auth})
	cd ${setup_path}/server/panel/
	/etc/init.d/bt start
	$python_bin -m py_compile tools.py
	$python_bin tools.py username
	username=$($python_bin tools.py panel ${password})
	if [ "$PANEL_USER" ];then
		username=$PANEL_USER
	fi
	cd ~
	echo "${password}" > ${setup_path}/server/panel/default.pl
	chmod 600 ${setup_path}/server/panel/default.pl
	sleep 3
	if [ "$SET_SSL" == true ]; then
		if [ ! -f "/www/server/panel/pyenv/n.pl" ];then
        	btpip install -I pyOpenSSl 2>/dev/null
    	fi
    	# echo "========================================"
    	# echo "姝ｅ湪寮€鍚潰鏉縎SL锛岃绋嶇瓑............ "
    	# echo "========================================"
		CERT_FILE="/www/server/panel/ssl/certificate.pem"
		echo -n " -4 " > /www/server/panel/data/v4.pl
		if [ ! -f "${CERT_FILE}" ]; then
        	SSL_STATUS=$(btpython /www/server/panel/tools.py ssl)
        	if [ "${SSL_STATUS}" == "0" ] ;then
        		btpython /www/server/panel/tools.py ssl
        	fi
		else
			echo -n "True" > /www/server/panel/data/ssl.pl
		fi
    	# echo "璇佷功寮€鍚垚鍔燂紒"
    	# echo "========================================"
    fi
# 	btpip install Flask-SQLAlchemy==2.5.1 SQLAlchemy==1.3.24
	/etc/init.d/bt stop
	sleep 5
	if [ ! -f "/www/server/panel/data/port.pl" ];then
		echo "8888" > /www/server/panel/data/port.pl
	fi
	/etc/init.d/bt start 	
	sleep 5
	isStart=$(ps aux |grep 'BT-Panel'|grep -v grep|awk '{print $2}')
	
	if [ -f "/www/server/panel/data/ssl.pl" ];then
		LOCAL_CURL=$(curl -k https://127.0.0.1:${panelPort}/login 2>&1 |grep -i html)
	else
		LOCAL_CURL=$(curl 127.0.0.1:${panelPort}/login 2>&1 |grep -i html)
	fi

	if [ -z "${isStart}" ] && [ -z "${LOCAL_CURL}" ];then
		/etc/init.d/bt restart
		sleep 5
		isStart=$(ps -ef|grep /www/server/panel/BT-Panel|grep -v grep)
		if [ -z "${isStart}" ];then
			#/etc/init.d/bt 22
			cd /www/server/panel/pyenv/bin
			touch t.pl
			ls -al python3.7 python
			lsattr python3.7 python
			if [ -f "/www/server/panel/pyenv/bin/python3.7" ];then
				/www/server/panel/pyenv/bin/python3.7 -c "print('test')"
				/www/server/panel/pyenv/bin/python3.7 -V
				ls -la /www/server/panel/pyenv/lib/python3.7/encodings*|grep utf|grep 8
			fi
			# btpython /www/server/panel/BT-Panel
			Red_Error "ERROR: The BT-Panel service startup failed." "ERROR: 瀹濆鍚姩澶辫触"
		fi
	fi

	if [ "$PANEL_USER" ];then
		cd ${setup_path}/server/panel/
		btpython -c 'import tools;tools.set_panel_username("'$PANEL_USER'")'
		cd ~
	fi
	if [ -f "/usr/bin/sqlite3" ] ;then
	    sqlite3 /www/server/panel/data/db/panel.db "UPDATE config SET status = '1' WHERE id = '1';"  > /dev/null 2>&1
    fi
}
Set_Firewall(){
	sshPort=$(cat /etc/ssh/sshd_config | grep 'Port '|awk '{print $2}')
	if [ "${PM}" = "apt-get" ]; then
		#apt-get install -y ufw
		if [ -f "/usr/sbin/ufw" ];then
			if [ "${PANEL_PORT}" ];then
				ufw allow ${PANEL_PORT}/tcp
			fi 
			ufw allow 20/tcp
			ufw allow 21/tcp
			ufw allow 22/tcp
			ufw allow 80/tcp
			ufw allow 443/tcp
			ufw allow 888/tcp
			ufw allow 8888/tcp
			ufw allow ${panelPort}/tcp
			ufw allow ${sshPort}/tcp
			ufw allow 39000:40000/tcp
			ufw_status=`ufw status`
			echo y|ufw enable
			ufw default deny
			ufw reload
		fi
	else
		if [ -f "/etc/init.d/iptables" ];then
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 20 -j ACCEPT
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 21 -j ACCEPT
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport ${panelPort} -j ACCEPT
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport ${sshPort} -j ACCEPT
			iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 39000:40000 -j ACCEPT
			#iptables -I INPUT -p tcp -m state --state NEW -m udp --dport 39000:40000 -j ACCEPT
			iptables -A INPUT -p icmp --icmp-type any -j ACCEPT
			iptables -A INPUT -s localhost -d localhost -j ACCEPT
			iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
			iptables -P INPUT DROP
			service iptables save
			sed -i "s#IPTABLES_MODULES=\"\"#IPTABLES_MODULES=\"ip_conntrack_netbios_ns ip_conntrack_ftp ip_nat_ftp\"#" /etc/sysconfig/iptables-config
			iptables_status=$(service iptables status | grep 'not running')
			if [ "${iptables_status}" == '' ];then
				service iptables restart
			fi
		else
			AliyunCheck=$(cat /etc/redhat-release|grep "Aliyun Linux")
			[ "${AliyunCheck}" ] && return
			#yum install firewalld -y
			[ "${Centos8Check}" ] && yum reinstall python3-six -y
			systemctl enable firewalld
			systemctl start firewalld
			firewall-cmd --set-default-zone=public > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=20/tcp > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=21/tcp > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=22/tcp > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=80/tcp > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=443/tcp > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=8888/tcp > /dev/null 2>&1
			if [ "${PANEL_PORT}" ];then
				firewall-cmd --permanent --zone=public --add-port=${PANEL_PORT}/tcp > /dev/null 2>&10
			fi
			firewall-cmd --permanent --zone=public --add-port=${panelPort}/tcp > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=${sshPort}/tcp > /dev/null 2>&1
			firewall-cmd --permanent --zone=public --add-port=39000-40000/tcp > /dev/null 2>&1
			#firewall-cmd --permanent --zone=public --add-port=39000-40000/udp > /dev/null 2>&1
			firewall-cmd --reload
		fi
	fi
}
Get_Ip_Address(){
	getIpAddress=""
	#getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress)

	ipv4_address=""
	ipv6_address=""

	ipv4_address=$(curl -4 -sS --connect-timeout 4 -m 5 https://api.bt.cn/Api/getIpAddress 2>&1)
	if [ -z "${ipv4_address}" ];then
			ipv4_address=$(curl -4 -sS --connect-timeout 4 -m 5 https://www.bt.cn/Api/getIpAddress 2>&1)
			if [ -z "${ipv4_address}" ];then
					ipv4_address=$(curl -4 -sS --connect-timeout 4 -m 5 https://www.aapanel.com/api/common/getClientIP 2>&1)
			fi
	fi
	IPV4_REGEX="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
	if ! [[ $ipv4_address =~ $IPV4_REGEX ]]; then
			ipv4_address=""
	fi

	ipv6_address=$(curl -6 -sS --connect-timeout 4 -m 5 https://www.bt.cn/Api/getIpAddress 2>&1)
	IPV6_REGEX="^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$"
	if ! [[ $ipv6_address =~ $IPV6_REGEX ]]; then
			ipv6_address=""
	else
			if [[ ! $ipv6_address =~ ^\[ ]]; then
					ipv6_address="[$ipv6_address]"
			fi
	fi

	if [ "${ipv4_address}" ];then
		getIpAddress=$ipv4_address
	elif [ "${ipv6_address}" ];then
		getIpAddress=$ipv6_address
	fi


	if [ -z "${getIpAddress}" ] || [ "${getIpAddress}" = "0.0.0.0" ]; then
		isHosts=$(cat /etc/hosts|grep 'www.bt.cn')
		if [ -z "${isHosts}" ];then
			echo "" >> /etc/hosts
			getIpAddress=$(curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress)
			if [ -z "${getIpAddress}" ];then
				sed -i "/bt.cn/d" /etc/hosts
			fi
		fi
	fi
	
	CN_CHECK=$(curl -sS --connect-timeout 10 -m 10 http://www.example.com/api/isCN)
	if [ "${CN_CHECK}" == "True" ];then
        	echo "True" > /www/server/panel/data/domestic_ip.pl
	else
		echo "True" > /www/server/panel/data/foreign_ip.pl
	fi

	ipv4Check=$($python_bin -c "import re; print(re.match('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$','${getIpAddress}'))")
	if [ "${ipv4Check}" == "None" ];then
		ipv6Address=$(echo ${getIpAddress}|tr -d "[]")
		ipv6Check=$($python_bin -c "import re; print(re.match('^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$','${ipv6Address}'))")
		if [ "${ipv6Check}" == "None" ]; then
			getIpAddress="SERVER_IP"
		else
			echo "True" > ${setup_path}/server/panel/data/ipv6.pl
			sleep 1
			/etc/init.d/bt restart
			getIpAddress=$(echo "[$getIpAddress]")
		fi
	fi

	if [ "${getIpAddress}" != "SERVER_IP" ];then
		echo "${getIpAddress}" > ${setup_path}/server/panel/data/iplist.txt
	fi
	LOCAL_IP=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^127\.|^255\.|^0\." | head -n 1)
}
Setup_Count(){
	curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/SetupCount?type=Linux\&o=$1 > /dev/null 2>&1
	if [ "$1" != "" ];then
		echo $1 > /www/server/panel/data/o.pl
		cd /www/server/panel
		$python_bin tools.py o
	fi
	echo /www > /var/bt_setupPath.conf
}

Start_Ip_Cert_Async(){
    IP_SSL_PID=""
    if [ -z "${ipv4_address}" ];then
        return
    fi

    if [ "$SET_SSL" == "true" ];then
        if [ -f "/www/server/panel/script/auto_apply_ip_ssl.py" ];then
             acme_connect_url="https://acme-v02.api.letsencrypt.org"
             acme_http_code=$(curl -sS --connect-timeout 2 -m 60 -o /dev/null -w "%{http_code}" "$acme_connect_url")
             if [ "$acme_http_code" == "200" ];then
                echo "姝ｅ湪鍚庡彴寮€鍚彈淇′换瀹濆闈㈡澘ip璇佷功..."
                (
                    timeout 60 $pyenv_path/pyenv/bin/python3.7 /www/server/panel/script/auto_apply_ip_ssl.py -ips ${ipv4_address} -path /www/server/panel/ssl > /tmp/auto_apply_ip_ssl.log 2>&1
                    echo $? > /tmp/ip_ssl_exit_code.pl
                ) &
                IP_SSL_PID=$!
             fi
        fi
    fi
}

Check_Ip_Cert_Async(){
	if [ "$SET_SSL" != "true" ];then
		return
	fi
    if [ -z "$IP_SSL_PID" ]; then
		if [ "$acme_http_code" != "200" ];then
			echo "鍙椾俊ip璇佷功鐢宠澶辫触锛宔xit code=$acme_http_code"
			echo "杞负浣跨敤榛樿鑷璇佷功锛屽悗缁彲鎵嬪姩鍦ㄩ潰鏉胯缃腑閲嶆柊浣跨敤Let's encrypt鐢宠ip璇佷功"
			return
		fi
		echo "鍙椾俊瀹濆闈㈡澘ip璇佷功寮€鍚垚鍔?
        /etc/init.d/bt restart
        return
    fi

	echo "姝ｅ湪妫€鏌ュ彈淇″疂濉旈潰鏉縤p璇佷功寮€鍚姸鎬?.."
    wait $IP_SSL_PID
    
    if [ -f "/tmp/ip_ssl_exit_code.pl" ]; then
        rc=$(cat /tmp/ip_ssl_exit_code.pl)
        rm -f /tmp/ip_ssl_exit_code.pl
    else
        rc=1
    fi

    if [ $rc -eq 0 ]; then
        echo "鍙椾俊瀹濆闈㈡澘ip璇佷功寮€鍚垚鍔?
        /etc/init.d/bt restart
    elif [ $rc -eq 124 ]; then
        echo "鍙椾俊ip璇佷功鐢宠瓒呮椂锛?0绉掞級"
        echo "杞负浣跨敤榛樿鑷璇佷功锛屽悗缁彲鎵嬪姩鍦ㄩ潰鏉胯缃腑閲嶆柊浣跨敤Let's encrypt鐢宠ip璇佷功"
    else
        echo "鍙椾俊ip璇佷功鐢宠澶辫触锛宔xit code=$rc"
        echo "杞负浣跨敤榛樿鑷璇佷功锛屽悗缁彲鎵嬪姩鍦ㄩ潰鏉胯缃腑閲嶆柊浣跨敤Let's encrypt鐢宠ip璇佷功"
    fi
}
Install_Main(){
	Ready_Check
	Set_Ssl
	startTime=`date +%s`
	Lock_Clear
	System_Check
	Get_Pack_Manager
	Set_Repo_Url
	Check_And_Fix_Debian_Ubuntu_Source
	get_node_url

	MEM_TOTAL=$(free -g|grep Mem|awk '{print $2}')
	if [ "${MEM_TOTAL}" -le "1" ];then
		Auto_Swap
	fi
	
	if [ "${PM}" = "yum" ]; then
		Install_RPM_Pack
	elif [ "${PM}" = "apt-get" ]; then
		Install_Deb_Pack
	else
		Install_Other_Pack
	fi

	Set_Firewall
	Install_Python_Lib
	Install_Bt

    Get_Ip_Address
	Start_Ip_Cert_Async

	Set_Bt_Panel
	Service_Add

    Check_Ip_Cert_Async
	Setup_Count ${IDC_CODE}
	#Add_lib_Install
}

echo "
+----------------------------------------------------------------------
| Bt-WebPanel FOR CentOS/Ubuntu/Debian
+----------------------------------------------------------------------
| Copyright 漏 2015-2099 BT-SOFT(http://www.bt.cn) All rights reserved.
+----------------------------------------------------------------------
| The WebPanel URL will be http://SERVER_IP:${panelPort} when installed.
+----------------------------------------------------------------------
| 涓轰簡鎮ㄧ殑姝ｅ父浣跨敤锛岃纭繚浣跨敤鍏ㄦ柊鎴栫函鍑€鐨勭郴缁熷畨瑁呭疂濉旈潰鏉匡紝涓嶆敮鎸佸凡閮ㄧ讲椤圭洰/鐜鐨勭郴缁熷畨瑁?+----------------------------------------------------------------------
"


while [ ${#} -gt 0 ]; do
	case $1 in
		-u|--user)
			PANEL_USER=$2
			shift 1
			;;
		-p|--password)
			PANEL_PASSWORD=$2
			shift 1
			;;
		-P|--port)
			PANEL_PORT=$2
			shift 1
			;;
		--safe-path)
			SAFE_PATH=$2
			shift 1
			;;
		--ssl-disable)
			SSL_PL="disable"
			;;
		-y)
			go="y"
			;;
		*)
			IDC_CODE=$1
			;;
	esac
	shift 1
done

while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "Do you want to install Bt-Panel to the $setup_path directory now?(y/n): " go;
done

if [ "$go" == 'n' ];then
	exit;
fi

if [ -f "/www/server/panel/BT-Panel" ];then
	AAPANEL_CHECK=$(grep www.aapanel.com /www/server/panel/BT-Panel)
	if [ "${AAPANEL_CHECK}" ];then
		echo -e "----------------------------------------------------"
		echo -e "妫€鏌ュ凡瀹夎鏈塧apanel锛屾棤娉曡繘琛岃鐩栧畨瑁呭疂濉旈潰鏉?
		echo -e "濡傜户缁墽琛屽畨瑁呭皢绉诲幓aapanel闈㈡澘鏁版嵁锛堝浠借嚦/www/server/aapanel璺緞锛?鍏ㄦ柊瀹夎瀹濆闈㈡澘"
		echo -e "aapanel is alreday installed,Can't install panel"
		echo -e "is install Baota panel,  aapanel data will be removed (backed up to /www/server/aapanel)"
		echo -e "Beginning new Baota panel installation."
		echo -e "----------------------------------------------------"
		echo -e "宸茬煡椋庨櫓/Enter yes to force installation"
		read -p "杈撳叆yes寮€濮嬪畨瑁? " yes;
		if [ "$yes" != "yes" ];then
			echo -e "------------"
			echo "鍙栨秷瀹夎"
			exit;
		fi
		bt stop
		sleep 1
		mv /www/server/panel /www/server/aapanel
	fi
fi


ARCH_LINUX=$(cat /etc/os-release |grep "Arch Linux")
if [ "${ARCH_LINUX}" ] && [ -f "/usr/bin/pacman" ];then
	pacman -Sy 
	pacman -S curl wget unzip firewalld openssl pkg-config make gcc cmake libxml2 libxslt libvpx gd libsodium oniguruma sqlite libzip autoconf inetutils sudo --noconfirm
fi

Install_Main

PANEL_SSL=$(cat /www/server/panel/data/ssl.pl 2> /dev/null)
if [ "${PANEL_SSL}" == "True" ];then
	HTTP_S="https"
else
	HTTP_S="http"
fi 

echo "瀹夎鍩虹缃戠珯娴侀噺缁熻绋嬪簭..."
wget -O site_new_total.sh ${download_Url}/site_total/install.sh &> /dev/null 
bash site_new_total.sh &> /dev/null
rm -f site_new_total.sh
echo "瀹夎鍩虹缃戠珯娴侀噺缁熻绋嬪簭瀹屾垚"

echo > /www/server/panel/data/bind.pl
echo -e "=================================================================="
echo -e "\033[32mCongratulations! Installed successfully!\033[0m"
echo -e "========================闈㈡澘璐︽埛鐧诲綍淇℃伅=========================="
echo -e ""
echo -e " 銆愪簯鏈嶅姟鍣ㄣ€戣鍦ㄥ畨鍏ㄧ粍鏀捐 $panelPort 绔彛"
if [ -z "${ipv4_address}" ] && [ -z "${ipv6_address}" ];then
    echo -e " 澶栫綉闈㈡澘鍦板潃:      ${HTTP_S}://SERVER_IP:${panelPort}${auth_path}"
fi
if [ "${ipv4_address}" ];then
    echo -e " 澶栫綉ipv4闈㈡澘鍦板潃: ${HTTP_S}://${ipv4_address}:${panelPort}${auth_path}"
fi
if [ "${ipv6_address}" ];then
    echo -e " 澶栫綉ipv6闈㈡澘鍦板潃: ${HTTP_S}://${ipv6_address}:${panelPort}${auth_path}"
fi
echo -e " 鍐呯綉闈㈡澘鍦板潃:     ${HTTP_S}://${LOCAL_IP}:${panelPort}${auth_path}"
echo -e " username: $username"
echo -e " password: $password"
echo -e ""
echo -e "=================================================================="
endTime=`date +%s`
((outTime=($endTime-$startTime)/60))
if [ "${outTime}" -le "5" ];then
    echo ${download_Url} > /www/server/panel/install/d_node.pl
fi
if [ "${outTime}" == "0" ];then
	((outTime=($endTime-$startTime)))
	echo -e "Time consumed:\033[32m $outTime \033[0mseconds!"
else
	echo -e "Time consumed:\033[32m $outTime \033[0mMinute!"
fi



