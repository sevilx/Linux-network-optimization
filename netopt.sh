#!/bin/bash

# 判断系统虚拟化技术

checkvirtual(){
	if [ -d /proc/vz ]; then
	return virtual="ovz"
	elif [ -d /proc/xen ]; then
	return virtual="xen"
	else
	return virtual="kvm"
	fi
	echo $virtual
}

checkvirtual

echo "ulimit -SHn 1024000" >> /etc/profile
ulimit -n 1024000
echo "* soft nofile 1024000" >> /etc/security/limits.conf
echo "* hard nofile 1024000" >> /etc/security/limits.conf

read -n1 -p  "已安装增强（魔改）版的BBR？(y/n)" ans
if [[ ${ans} =~ [yY] ]]; then

read -p "请选择你的位置和服务器之间的距离，处于同一洲按1，跨洲按2（ovz和xen架构机器无法开启hybla算法）" pick
[ -z "$pick" ]
expr ${pick} + 1 &>/dev/null
if [ $? -ne 0 ]; then
        echo -e "Input error, please input a number"
        continue
fi

if [[ ${virtual} == "ovz" ]] || [[ ${virtual} == "xen" ]] && [[ "${pick" == 1 ]]; then
	tcp_type="cubic"
else
	tcp_type="hybla"
fi

/sbin/modprobe tcp_$tcp_type
	
	cat > /etc/sysctl.conf<<-EOF
# max open files
fs.file-max = 1024000
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

# for high-latency network
net.ipv4.tcp_congestion_control = $tcp_type
# forward ipv4
net.ipv4.ip_forward = 1
EOF
fi
echo -e "\n"

