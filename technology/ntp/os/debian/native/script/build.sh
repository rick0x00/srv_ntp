#!/usr/bin/env bash

# ============================================================ #
# Tool Created date: 24 mai 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: NTP    Server                                     #
# Description: My tool to help for crete NTP server            #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_ntp     #
# Remote repository 2: https://gitlab.com/rick0x00/srv_ntp     #
# ============================================================ #
# base content:
#   https://www.ntpsec.org/
#   https://docs.ntpsec.org/latest/ntp_conf.html
#   https://ntp.br/guia/linux/
#   https://ntp.br/conteudo/ntp/
#   https://ntp.br/conteudo/tempo/

# ============================================================ #
# start root user checking
if [ $(id -u) -ne 0 ]; then
    echo "Please use root user to run the script."
    exit 1
fi
# end root user checking
# ============================================================ #
# start set variables

os_distribution="debian"
os_version=("11" "bullseye")

port[0]="123" # NTP number Port
port[1]="udp" # NTP protocol Port

workdir="/var/lib/ntp/"
persistence_volumes=("$workdit" "/var/log/")
expose_ports="${port[0]}/${port[1]}"
# end set variables
# ============================================================ #
# start definition functions
# ============================== #
# start complement functions

# end complement functions
# ============================== #
# start main functions
function pre_install_server () {
    apt update
    # install tools
    apt install -y wget curl cron iputils-ping iproute2 net-tools vim nano traceroute dnsutils tcpdump netcat
}

function install_server () {
    apt install -y ntp ntp-doc
    # apt install -y ntpsec-ntpdate ntpsec-ntpviz
}

function stop_server () {
    # Starting Service
    service ntp stop
    #systemctl stop ntp
    #/etc/init.d/ntp stop
}

function configure_server () {
    # desabilitando timesynk
    #systemctl disable --now systemd-timesynkd

    mv /etc/ntp.conf /etc/ntp.bkp

    echo "
    # define Leap Seconds file
    leapfile /usr/share/zoneinfo/leap-seconds.list

    # define remember the drift of the local clock
    driftfile /var/lib/ntp/ntp.drift

    # setting log file
    logfile /var/log/ntp.log

    # setting Statistics Files
    statsdir /var/log/ntpstats/
    statistics loopstats peerstats clockstats
    filegen loopstats file loopstats type day enable
    filegen peerstats file peerstats type day enable
    filegen clockstats file clockstats type day enable

    # Define upstream NTP server Sources
    server a.st1.ntp.br iburst
    server b.st1.ntp.br iburst
    server c.st1.ntp.br iburst
    server d.st1.ntp.br iburst
    server gps.ntp.br iburst
    server time.google.com iburst
    server time.cloudflare.com iburst
    server 0.pool.ntp.org iburst
    server 1.pool.ntp.org iburst    

    # ====== Setting restrictions ====== #
    # Restrct ALL
    restrict default ignore

    # Unrestrict(limited) sync NTP Server Sources
    restrict a.st1.ntp.br kod notrap nomodify nopeer noquery limited
    restrict b.st1.ntp.br kod notrap nomodify nopeer noquery limited
    restrict c.st1.ntp.br kod notrap nomodify nopeer noquery limited
    restrict d.st1.ntp.br kod notrap nomodify nopeer noquery limited
    restrict gps.ntp.br kod notrap nomodify nopeer noquery limited
    restrict time.google.com kod notrap nomodify nopeer noquery limited
    restrict time.cloudflare.com kod notrap nomodify nopeer noquery limited
    restrict 0.pool.ntp.org kod notrap nomodify nopeer noquery limited
    restrict 1.pool.ntp.org kod notrap nomodify nopeer noquery limited

    # Unrestrict(limited) queries for customer network
    restrict -4 172.16.0.0 mask 255.240.0.0 kod notrap nomodify nopeer noquery limited
    restrict -4 10.0.0.0 mask 255.0.0.0 kod notrap nomodify nopeer noquery limited
    restrict -4 192.168.0.0 mask 255.255.0.0 kod notrap nomodify nopeer noquery limited
    restrict -6 fc00::/7 kod notrap nomodify nopeer noquery limited

    # Allow Full Controll and acess for yourself
    restrict 127.0.0.1
    restrict ::1

    " > /etc/ntp.conf

    # Remobve a white apace from beginning of line
    sed -i 's/^ \+//' /etc/ntp.conf

    mkdir -p /var/log/ntpstats/
    touch /var/lib/ntp/ntp.drift

    #chown root:root /etc/ntp.conf
    #chown root:root /usr/share/zoneinfo/leap-seconds.list
    chown ntp:ntp -R /var/lib/ntp/
    #chown ntp:ntp /var/log/ntpstats/

    #chmod 644 /etc/ntp.conf
    #chmod 644 /usr/share/zoneinfo/leap-seconds.list
    #chmod 755 /var/lib/ntp/
    #chmod 755 /var/log/ntpstats/

    # set Timezone
    #timedatectl set-timezone America/Maceio
    rm /etc/localtime
    ln -s /usr/share/zoneinfo/America/Maceio /etc/localtime

    # setting system clock to hardware clock
    hwclock --systohc

}

function start_server () {
    # Starting Service
    service ntp start
    #systemctl start ntp
    #/etc/init.d/ntp start
    #/usr/sbin/ntpd -d -u ntp:ntp
}

function test_server () {
    # service running ?
    service ntp status
    #systemctl status --no-pager -l ntp
    #/etc/init.d/ntp status

    tail /var/log/ntp.log
    ps aux | grep ntp

    # service bindind ?
    netstat -pultan | grep :123

    #### Validating working
    # ckecking service
    ntpq -p
    ntpq -c rl
    ntpq -c sysinfo
    date
    hwclock
    hwclock --verbose

    # setting incorrect date    
    # (NOT run this command on Production servers)
    #date +%T --set="10:10:10"
    # check if date is adjusted running this command
    #date
}


# end main functions
# ============================== #
# end definition functions
# ============================================================ #
# start argument reading

# end argument reading
# ============================================================ #
# start main executions of code
pre_install_server;
install_server;
stop_server;
configure_server;
start_server;
test_server;

