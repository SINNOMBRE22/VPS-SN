#!/bin/bash
# VPS-SN - Instalador Completo
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 03:25:37 UTC

clear && clear
colores="$(pwd)/colores"
rm -rf ${colores}
wget -O ${colores} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module" &>/dev/null
[[ ! -e ${colores} ]] && exit
chmod +x ${colores} &>/dev/null
source ${colores}

CTRL_C() {
  rm -rf ${colores}
  rm -rf /etc/VPS-SN
  exit
}

trap "CTRL_C" INT TERM EXIT
rm $(pwd)/$0 &>/dev/null

# Verificar ROOT
if [ $(whoami) != 'root' ]; then
  echo ""
  echo -e "\e[1;31m NECESITAS SER USER ROOT PARA EJECUTAR EL SCRIPT \n\n\e[97m                DIGITE: \e[1;32m sudo su\n"
  exit
fi

VPS_SN="/etc/VPS-SN" && [[ ! -d ${VPS_SN} ]] && mkdir ${VPS_SN}
VPS_inst="${VPS_SN}/install" && [[ ! -d ${VPS_inst} ]] && mkdir ${VPS_inst}
SCPinstal="$HOME/install"

rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime &>/dev/null

stop_install(){
  title "INSTALACION CANCELADA"
  exit
}

time_reboot(){
  clear && clear
  msgi -bar
  echo -e "\e[1;93m     CONTINUARA INSTALACION DESPUES DEL REBOOT"
  echo -e "\e[1;93m         O EJECUTE EL COMANDO: \e[1;92mVPS-SN -c "
  msgi -bar
  REBOOT_TIMEOUT="$1"
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    print_center -ne "-$REBOOT_TIMEOUT-\r"
    sleep 1
    : $((REBOOT_TIMEOUT--))
  done
  reboot
}

os_system(){
  system=$(cat -n /etc/issue | grep 1 | cut -d ' ' -f6,7,8 | sed 's/1//' | sed 's/      //')
  distro=$(echo "$system" | awk '{print $1}')

  case $distro in
  Debian) vercion=$(echo $system | awk '{print $3}' | cut -d '.' -f1) ;;
  Ubuntu) vercion=$(echo $system | awk '{print $2}' | cut -d '.' -f1,2) ;;
  esac
}

repo(){
  link="https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Repositorios/$1.list"
  case $1 in
  8 | 9 | 10 | 11 | 16.04 | 18.04 | 20.04 | 20.10 | 21.04 | 21.10 | 22.04) wget -O /etc/apt/sources.list ${link} &>/dev/null ;;
  esac
}

fun_ip(){
  TUIP=$(wget -qO- ifconfig.me)
  echo "$TUIP" >/root/.ssh/authrized_key.reg
  echo -e "\e[1;97m ESTA ES TU IP PUBLICA? \e[32m$TUIP"
  msgi -bar2
  echo -ne "\e[1;97m Seleccione  \e[1;31m[\e[1;93m S \e[1;31m/\e[1;93m N \e[1;31m]\e[1;97m: \e[1;93m" && read tu_ip
  [[ "$tu_ip" = "n" || "$tu_ip" = "N" ]] && fun_ip
}

pass_root(){
  msgi -bar
  echo -ne "\e[1;97m DIGITE NUEVA CONTRASEÑA:  \e[1;31m" && read pass
  (
    echo $pass
    echo $pass
  ) | passwd root 2>/dev/null
  sleep 1s
  msgi -bar
  echo -e "\e[1;94m     CONTRASEÑA AGREGADA O EDITADA CORECTAMENTE"
  echo -e "\e[1;97m TU CONTRASEÑA ROOT AHORA ES: \e[41m $pass \e[0;37m"
}

install_inicial(){
  clear && clear
  v1=$(curl -sSL "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/version" 2>/dev/null || echo "1.0")
  echo "$v1" >/etc/version_instalacion
  v22=$(cat /etc/version_instalacion)
  vesaoSCT="\e[1;31m [ \e[1;32m( $v22 )\e[1;97m\e[1;31m ]"

  os_system
  repo "${vercion}"
  msgi -bar2
  echo -e " \e[5m\e[1;100m   =====>> ►►     VPS-SN INSTALLER     ◄◄ <<=====    \e[1;37m"
  msgi -bar2
  msgi -ama "   PREPARANDO INSTALACION | VERSION: $vesaoSCT"
  echo ""
  echo -e "\e[1;97m         🔎 IDENTIFICANDO SISTEMA OPERATIVO"
  echo -e "\e[1;32m                 | $distro $vercion |"
  echo ""
  msgi -bar2
  fun_ip
  msgi -bar2
  echo -e "\e[1;93m             AGREGAR Y EDITAR PASS ROOT\e[1;97m"
  msgi -bar
  echo -e "\e[1;97m CAMBIAR PASS ROOT? \e[32m"
  msgi -bar2
  echo -ne "\e[1;97m Seleccione  \e[1;31m[\e[1;93m S \e[1;31m/\e[1;93m N \e[1;31m]\e[1;97m: \e[1;93m" && read pass_root
  [[ "$pass_root" = "s" || "$pass_root" = "S" ]] && pass_root
  msgi -bar2
  echo -e "\e[1;93m\a\a\a      SE PROCEDERA A INSTALAR LAS ACTUALIZACIONES\n PERTINENTES DEL SISTEMA, ESTE PROCESO PUEDE TARDAR\n VARIOS MINUTOS Y PUEDE PEDIR ALGUNAS CONFIRMACIONES \e[0;37m"
  msgi -bar
  read -t 120 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
  clear && clear
  apt update -y
  apt upgrade -y
}

dependencias(){
  rm -rf /root/paknoinstall.log >/dev/null 2>&1
  rm -rf /root/packinstall.log >/dev/null 2>&1
  dpkg --configure -a >/dev/null 2>&1
  apt -f install -y >/dev/null 2>&1
  soft="sudo bsdmainutils zip screen unzip ufw curl python python3 python3-pip openssl cron iptables lsof pv boxes at mlocate gawk bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat apache2"

  for i in $soft; do
    paquete="$i"
    echo -e "\e[1;97m        INSTALANDO PAQUETE \e[93m ------ \e[36m $i"
    if apt-get install $i -y &>/dev/null; then
      echo -e "\e[1;32m ✓ $i instalado"
    else
      echo -e "\e[1;31m ✗ Error en $i (continuando...)"
    fi
  done
  rm -rf /root/paknoinstall.log >/dev/null 2>&1
  rm -rf /root/packinstall.log >/dev/null 2>&1
}

install_paquetes(){
  clear && clear
  /bin/cp /etc/skel/.bashrc ~/
  msgi -bar2
  echo -e " \e[5m\e[1;100m   =====>> ►►     VPS-SN INSTALLER     ◄◄ <<=====    \e[1;37m"
  msgi -bar
  echo -e "   \e[1;41m    -- INSTALACION PAQUETES FALTANTES --    \e[49m"
  msgi -bar
  dependencias
  sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf >/dev/null 2>&1
  service apache2 restart >/dev/null 2>&1
  [[ $(sudo lsof -i :81 2>/dev/null) ]] && ESTATUSP=$(echo -e "\e[1;92m          PUERTO APACHE ACTIVO CON EXITO") || ESTATUSP=$(echo -e "\e[1;91m      >>>  FALLO DE INSTALACION EN APACHE <<<")
  echo ""
  echo -e "$ESTATUSP"
  echo ""
  echo -e "\e[1;97m        REMOVIENDO PAQUETES OBSOLETOS - \e[1;32m OK"
  apt autoremove -y &>/dev/null
  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections 2>/dev/null
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections 2>/dev/null
  msgi -bar2
  read -t 30 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
}

post_reboot(){
  echo 'wget -O /root/install.sh "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh"; clear; sleep 2; chmod +x /root/install.sh; /root/install.sh --continue' >> /root/.bashrc
  title "INSTALADOR VPS-SN"
  print_center -ama "La instalacion continuara\ndespues del reinicio!!!"
  msg -bar
}

install_vps_sn(){
  clear && clear
  msgi -bar2
  echo -ne "\033[1;97m Digite su slogan: \033[1;32m" && read slogan
  tput cuu1 && tput dl1
  echo -e "$slogan"
  msgi -bar2
  clear && clear
  
  mkdir /etc/VPS-SN >/dev/null 2>&1
  mkdir /etc/VPS-SN/tmp >/dev/null 2>&1
  
  cd /etc
  wget https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz >/dev/null 2>&1
  
  if [[ ! -e VPS-SN.tar.xz ]]; then
    echo -e "\033[1;31mError descargando VPS-SN.tar.xz, usando fallback\033[0m"
    mkdir -p /etc/VPS-SN/install
  else
    tar -xf VPS-SN.tar.xz >/dev/null 2>&1
    chmod +x VPS-SN.tar.xz >/dev/null 2>&1
    rm -rf VPS-SN.tar.xz
  fi
  
  cd
  chmod -R 755 /etc/VPS-SN
  VPS_SN="/etc/VPS-SN" && [[ ! -d ${VPS_SN} ]] && mkdir ${VPS_SN}
  VPS_inst="${VPS_SN}/install" && [[ ! -d ${VPS_inst} ]] && mkdir ${VPS_inst}
  SCPinstal="$HOME/install"
  
  rm -rf /usr/bin/menu
  rm -rf /usr/bin/adm
  rm -rf /usr/bin/VPS-SN
  
  echo "$slogan" >/etc/VPS-SN/tmp/message.txt
  echo "${VPS_SN}/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "${VPS_SN}/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "${VPS_SN}/menu" >/usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  
  sed -i '/VPS-SN/d' /root/.bashrc
  [[ -z $(echo $PATH | grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >>/etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >>/etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion 2>/dev/null || echo "1.0")' >>/etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >>/etc/bash.bashrc
  echo -e "[[ \$(date '+%s' -d \$up 2>/dev/null) -gt \$(date '+%s' -d \$(cat /etc/VPS-SN/vercion) 2>/dev/null) ]] && v2=\"Nueva Vercion disponible: \$v >>> \$up\" || v2=\"Script Vercion: \$v\"" >>/etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(less /etc/VPS-SN/tmp/message.txt)"' >>/etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >>/etc/bash.bashrc
  echo 'clear && echo -e "\n$(figlet -f big.flf "  VPS-SN")\n        RESELLER : $mess1 \n\n   Para iniciar VPS-SN escriba:  menu \n\n   $v2\n\n" | lolcat' >>/etc/bash.bashrc
  
  update-locale LANG=en_US.UTF-8 LANGUAGE=en
  service ssh restart &>/dev/null
  clear && clear
  msgi -bar2
  echo -e "\e[1;92m             >> INSTALACION COMPLETADA <<" && msgi -bar2
  echo -e "      COMANDO PRINCIPAL PARA ENTRAR AL PANEL "
  echo -e "                      \033[1;41m  menu  \033[0;37m" && msgi -bar2
}

# SELECTOR DE INSTALACION
while :; do
  case $1 in
  -s | --start)
    install_inicial && install_paquetes && post_reboot && time_reboot "15"
    break
    ;;
  -c | --continue)
    install_paquetes
    install_vps_sn
    mv -f ${colores} /etc/VPS-SN/module
    time_reboot "10"
    break
    ;;
  -m | --menu)
    break
    ;;
  *) exit ;;
  esac
done
