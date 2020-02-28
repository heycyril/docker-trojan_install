#!/bin/bash

#仅仅搞centos7
if [ ! -e '/etc/redhat-release' ]; then
echo "仅支持centos7"
exit
fi
if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
echo "仅支持centos7"
exit
fi

install_docker(){

	yum remove -y docker docker-client docker-client-latest docker-common docker-latest  docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine		
	yum install -y yum-utils device-mapper-persistent-data lvm2
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum makecache fast
	yum -y install docker-ce
	systemctl start docker
	systemctl enable docker

}

install_acme(){

    curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh  --issue  -d $domain  --standalone
    ~/.acme.sh/acme.sh  --installcert  -d  $domain   \
        --key-file   /usr/src/trojan/private.key \
        --fullchain-file /usr/src/trojan/fullchain.cer

}

config_website(){

	cd /usr/src/trojan/web
	wget https://github.com/atrandys/trojan/raw/master/index.zip
	unzip index.zip

}

uninstall_trojan(){
	docker update --restart=no trojan
	docker stop trojan
	docker rm trojan
	rm -rf /usr/src/trojan/
	echo "================="
	echo "    卸载完成"
	echo "================="
}

config_trojan(){

yum -y install  wget unzip vim tcl expect expect-devel
mkdir /usr/src/trojan
mkdir /usr/src/trojan/web
cd /usr/src/trojan
read -p "输入你的VPS绑定的域名：" domain

install_acme

cat > /usr/src/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "password1"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/src/trojan-cert/fullchain.cer",
        "key": "/usr/src/trojan-cert/private.key",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	    "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF

echo "============================"
echo " 设置密码，服务端和客户端使用相同密码"
echo "============================"
read -p "设置密码：" mypassword
sed -i "s/password1/$mypassword/" /usr/src/trojan/server.conf

}

start_docker(){

    #sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
	#sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
	#sudo firewall-cmd --reload
	docker run --name trojan --restart=always -d -p 80:80 -p 443:443 -v /usr/src/trojan:/usr/src/trojan  atrandys/trojan sh -c "/etc/init.d/nginx start && trojan -c /usr/src/trojan/server.conf"
	echo "============================"
	echo "       trojan启动完成"
	echo "============================"
}

start_menu(){
    clear
    echo "========================="
    echo " 介绍：适用于CentOS7"
    echo " 作者：ccc"
    echo " 网站：ccc"
    echo " Youtube：ccc"
    echo "========================="
    echo "1. 安装Trojan"
    echo "2. 卸载Trojan"
    echo "3. 退出"
    echo
    read -p "请输入数字:" num
    case "$num" in
    	1)
	install_docker
	config_trojan
	config_website
	start_docker
	;;
	2)
	uninstall_trojan
	;;
	3)
	exit 1
	;;
	*)
	clear
	echo "请输入正确数字"
	sleep 5s
	start_menu
	;;
    esac
}

start_menu
