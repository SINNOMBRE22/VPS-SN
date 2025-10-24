#!/bin/bash
# VPS-SN - Instalador Simplificado
# Basado en ADMRufu structure
# By @Sin_Nombre22
# Fecha: 2025-10-24 10:25:26 UTC

clear && clear
colores="$(pwd)/colores"
rm -rf ${colores}
wget -O ${colores} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module" &>/dev/null
[[ ! -e ${colores} ]] && exit
chmod +x ${colores} &>/dev/null
source ${colores}

CTRL_C() {
  rm -rf ${colores}
  exit
}

trap "CTRL_C" INT TERM EXIT

# VERIFICAR ROOT
if [ $(whoami) != 'root' ]; then
  echo ""
  echo -e "\e[1;31m NECESITAS SER USER ROOT PARA EJECUTAR EL SCRIPT \n\n\e[97m                DIGITE: \e[1;32m sudo su\n"
  exit
fi

# DETECTAR SISTEMA OPERATIVO
os_system() {
  system=$(cat -n /etc/issue | grep 1 | cut -d ' ' -f6,7,8 | sed 's/1//' | sed 's/      //')
  distro=$(echo "$system" | awk '{print $1}')

  case $distro in
  Debian) vercion=$(echo $system | awk '{print $3}' | cut -d '.' -f1) ;;
  Ubuntu) vercion=$(echo $system | awk '{print $2}' | cut -d '.' -f1,2) ;;
  esac
}

# CONFIGURAR REPOSITORIOS
repo() {
  link="https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Repositorios/$1.list"
  case $1 in
  8 | 9 | 10 | 11 | 16.04 | 18.04 | 20.04 | 20.10 | 21.04 | 21.10 | 22.04) 
    wget -O /etc/apt/sources.list ${link} &>/dev/null 
    ;;
  esac
}

# PASO 1: INSTALACION INICIAL
install_inicial() {
  clear && clear
  
  # DESACTIVAR PASS ALFANUMERICO
  os_system
  repo "${vercion}"
  
  msg -bar2
  echo -e " \e[5m\e[1;100m   =====>> ►►     VPS-SN     ◄◄ <<=====    \e[1;37m"
  msg -bar2
  msg -ama "   PREPARANDO INSTALACION DEL SISTEMA"
  echo ""
  echo -e "\e[1;97m         🔎 IDENTIFICANDO SISTEMA OPERATIVO"
  echo -e "\e[1;32m                 | $distro $vercion |"
  echo ""
  echo -e "\e[1;97m        ◽️ DESACTIVANDO PASS ALFANUMERICO "
  [[ $(dpkg --get-selections | grep -w "libpam-cracklib" | head -1) ]] || apt-get install libpam-cracklib -y &>/dev/null
  echo -e '# Modulo Pass Simple
password [success=1 default=ignore] pam_unix.so obscure sha512
password requisite pam_deny.so
password required pam_permit.so' >/etc/pam.d/common-password && chmod +x /etc/pam.d/common-password
  [[ $(dpkg --get-selections | grep -w "libpam-cracklib" | head -1) ]] && echo -e "\e[1;32m OK"
  service ssh restart >/dev/null 2>&1
  
  msg -bar2
  echo -e "\e[1;93m\a\a\a      SE PROCEDERA A INSTALAR LAS ACTUALIZACIONES"
  echo -e "\e[1;93m      PERTINENTES DEL SISTEMA, ESTE PROCESO PUEDE TARDAR"
  echo -e "\e[1;93m      VARIOS MINUTOS Y PUEDE PEDIR ALGUNAS CONFIRMACIONES \e[0;37m"
  msg -bar
  read -t 120 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
  
  clear && clear
  apt update
  apt upgrade -y
}

# PASO 2: INSTALAR DEPENDENCIAS
dependencias() {
  clear && clear
  msg -bar2
  echo -e " \e[5m\e[1;100m   =====>> ►►     VPS-SN     ◄◄ <<=====    \e[1;37m"
  msg -bar
  echo -e "   \e[1;41m    -- INSTALACION PAQUETES NECESARIOS --    \e[49m"
  msg -bar
  
  dpkg --configure -a >/dev/null 2>&1
  apt -f install -y >/dev/null 2>&1
  
  soft="sudo bsdmainutils zip screen unzip ufw curl python python3 python3-pip openssl cron iptables lsof pv boxes at mlocate gawk bc jq npm nodejs socat netcat netcat-traditional net-tools figlet lolcat"

  for i in $soft; do
    echo -e "\e[1;97m        INSTALANDO PAQUETE \e[93m ------ \e[36m $i"
    apt-get install $i -y >/dev/null 2>&1
  done
  
  echo ""
  echo -e "\e[1;97m        REMOVIENDO PAQUETES OBSOLETOS - \e[1;32m OK"
  apt autoremove -y &>/dev/null
  
  msg -bar2
  read -t 30 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
}

# PASO 3: INSTALAR VPS-SN
install_VPS_SN() {
  clear && clear
  msg -bar2
  echo -ne "\033[1;97m Digite su slogan: \033[1;32m" && read slogan
  tput cuu1 && tput dl1
  echo -e "$slogan"
  msg -bar2
  clear && clear
  
  mkdir /etc/VPS-SN >/dev/null 2>&1
  mkdir -p /etc/VPS-SN/{install,source,tmp} >/dev/null 2>&1
  
  cd /etc
  echo -e "\e[1;97m        DESCARGANDO VPS-SN..."
  wget https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz >/dev/null 2>&1
  
  echo -e "\e[1;97m        EXTRAYENDO ARCHIVOS..."
  tar -xf VPS-SN.tar.xz >/dev/null 2>&1
  rm -rf VPS-SN.tar.xz
  
  cd
  chmod -R 755 /etc/VPS-SN
  
  rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/VPS-SN
  
  echo "$slogan" >/etc/VPS-SN/tmp/message.txt
  
  echo "${VPS_SN}/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "${VPS_SN}/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "${VPS_SN}/menu" >/usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  
  [[ -z $(echo $PATH | grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >>/etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >>/etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion 2>/dev/null)' >>/etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >>/etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(cat /etc/VPS-SN/tmp/message.txt)"' >>/etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >>/etc/bash.bashrc
  echo 'clear && echo -e "\n$(figlet -f big.flf "  VPS-SN")\n        RESELLER : $mess1 \n\n   Para iniciar VPS-SN escriba:  menu \n\n"|lolcat' >>/etc/bash.bashrc

  update-locale LANG=en_US.UTF-8 LANGUAGE=en
  
  clear && clear
  msg -bar2
  echo -e "\e[1;92m             >> INSTALACION COMPLETADA <<" && msg -bar2
  echo -e "      COMANDO PRINCIPAL PARA ENTRAR AL PANEL "
  echo -e "                      \033[1;41m  menu  \033[0;37m" && msg -bar2
}

# REINICIO
time_reboot() {
  clear && clear
  msg -bar
  echo -e "\e[1;93m              VPS-SN INSTALADO EXITOSAMENTE"
  echo -e "\e[1;93m                 REINICIANDO EN 10 SEGUNDOS"
  msg -bar
  REBOOT_TIMEOUT=10
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    echo -ne "                         -$REBOOT_TIMEOUT-\r"
    sleep 1
    : $((REBOOT_TIMEOUT--))
  done
  reboot
}

# FLUJO PRINCIPAL
clear && clear
msg -bar2
echo -e " \e[5m\e[1;100m   =====>> ►►  INSTALADOR VPS-SN  ◄◄ <<=====   \e[1;37m"
msg -bar2
echo ""
echo -e "\e[1;97m           ¿ESTA SEGURO DE INSTALAR VPS-SN?"
echo -e "\e[1;97m        Esta operacion actualizará el sistema"
echo -e "\e[1;97m     e instalará todas las dependencias necesarias"
msg -bar2
echo -ne "\e[1;97m Seleccione  \e[1;31m[\e[1;93m S \e[1;31m/\e[1;93m N \e[1;31m]\e[1;97m: \e[1;93m" && read confirmacion

if [[ "$confirmacion" = "s" || "$confirmacion" = "S" ]]; then
  install_inicial
  dependencias
  install_VPS_SN
  time_reboot
else
  clear && clear
  msg -bar2
  echo -e "\e[1;97m          ---- INSTALACION CANCELADA -----"
  msg -bar2
  exit 1
fi
