#!/bin/bash

# VPS-SN - Instalador Mejorado v2
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 05:08:00 UTC

clear

# Verificar root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Este script debe ejecutarse como root"
   exit 1
fi

set -e

echo "[+] Inicializando VPS-SN..."

# Zona horaria
rm -rf /etc/localtime 2>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime 2>/dev/null
echo "[+] Zona horaria: Mexico_City"

# Detectar SO
echo "[+] Detectando sistema..."
. /etc/os-release

# Actualizar
echo "[+] Actualizando repositorios..."
apt-get update -y >/dev/null 2>&1
apt-get install -y gnupg wget software-properties-common lsb-release curl >/dev/null 2>&1

# Instalar por SO
if [[ "$ID" == "ubuntu" ]]; then
    echo "[+] Ubuntu $VERSION_ID detectado"
    add-apt-repository -y ppa:ubuntu-toolchain-r/test < /dev/null >/dev/null 2>&1
    apt-get update -y >/dev/null 2>&1
    apt-get install -y libstdc++6 >/dev/null 2>&1

elif [[ "$ID" == "debian" ]]; then
    echo "[+] Debian $VERSION_ID detectado"
    apt-get install -y libstdc++6 >/dev/null 2>&1

else
    echo "[!] Sistema no soportado"
    exit 1
fi

# libcurl
echo "[+] Instalando libcurl4-openssl-dev..."
apt-get install -y libcurl4-openssl-dev >/dev/null 2>&1

# Descargar módulo
echo "[+] Descargando módulo..."
module="/tmp/module"
rm -rf ${module} 2>/dev/null
wget -q -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module"

if [[ ! -e ${module} ]]; then
    echo "[!] Error descargando módulo"
    exit 1
fi

chmod +x ${module}
source ${module}
echo "[+] Módulo cargado"

# Variables
VPS_SN="/etc/VPS-SN"
VPS_inst="${VPS_SN}/install"

mkdir -p ${VPS_SN} ${VPS_inst} 2>/dev/null

# Cleanup
CTRL_C(){
  echo ""
  echo "[!] Cancelado"
  rm -rf ${module} 2>/dev/null
  exit 1
}

trap "CTRL_C" INT TERM EXIT

# Detectar SO
os_system(){
  if [[ -f /etc/issue ]]; then
    system=$(cat -n /etc/issue |grep 1 |cut -d ' ' -f6,7,8 |sed 's/1//' |sed 's/      //')
    distro=$(echo "$system"|awk '{print $1}')
    
    case $distro in
      Debian)vercion=$(echo $system|awk '{print $3}'|cut -d '.' -f1);;
      Ubuntu)vercion=$(echo $system|awk '{print $2}'|cut -d '.' -f1,2);;
      *)vercion="unknown";;
    esac
  fi
}

# Reboot
time_reboot(){
  local REBOOT_TIMEOUT=$1
  print_center -ama "REINICIANDO EN $REBOOT_TIMEOUT SEGUNDOS"
  
  while [[ $REBOOT_TIMEOUT -gt 0 ]]; do
    echo -ne "\r$REBOOT_TIMEOUT segundos..."
    sleep 1
    ((REBOOT_TIMEOUT--))
  done
  echo ""
  reboot
}

# Dependencias
dependencias(){
  title "INSTALANDO DEPENDENCIAS"
  
  soft="sudo bsdmainutils zip unzip curl python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq git htop vim tmux psmisc wget net-tools figlet lolcat"

  for paquete in $soft; do
    leng="${#paquete}"
    puntos=$(( 25 - $leng))
    pts=""
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    msg -nazu "       instalando $paquete$pts"
    
    if apt-get install -y $paquete >/dev/null 2>&1; then
      msg -verd "OK"
    else
      msg -verm2 "RETRY"
      dpkg --configure -a >/dev/null 2>&1
      
      if apt-get install -y $paquete >/dev/null 2>&1; then
        msg -verd "OK"
      else
        msg -verm2 "SKIP"
      fi
    fi
  done
  
  msg -bar
}

# Instalar VPS-SN
install_VPS_SN() {
  clear && clear
  msg -bar2
  echo -ne "\033[1;97m Digite su slogan: \033[1;32m"
  read -r slogan
  
  if [[ -z "$slogan" ]]; then
    slogan="@Sin_Nombre22"
  fi
  
  echo -e "\033[0m"
  msg -bar2
  clear && clear
  
  mkdir -p /etc/VPS-SN/tmp >/dev/null 2>&1
  
  echo "[+] Descargando VPS-SN..."
  cd /etc
  
  if wget -q https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz -O VPS-SN.tar.xz 2>/dev/null; then
    echo "[+] Extrayendo..."
    tar -xf VPS-SN.tar.xz >/dev/null 2>&1
    rm -rf VPS-SN.tar.xz
    echo "[+] Listo"
  else
    echo "[!] Error descargando, creando estructura..."
    mkdir -p /etc/VPS-SN/install
  fi
  
  cd ~
  chmod -R 755 /etc/VPS-SN
  
  rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/VPS-SN 2>/dev/null
  
  echo "$slogan" >/etc/VPS-SN/tmp/message.txt
  
  echo "${VPS_SN}/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "${VPS_SN}/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "${VPS_SN}/menu" >/usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  
  [[ -z $(echo $PATH | grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >>/etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >>/etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion 2>/dev/null || echo "1.0.0")' >>/etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >>/etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(cat /etc/VPS-SN/tmp/message.txt)"' >>/etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >>/etc/bash.bashrc
  echo 'clear && echo -e "\n$(figlet -f big.flf "  VPS-SN" 2>/dev/null || echo "VPS-SN")\n        RESELLER : $mess1 \n\n   Para iniciar VPS-SN escriba:  menu \n\n"' >>/etc/bash.bashrc

  update-locale LANG=en_US.UTF-8 LANGUAGE=en 2>/dev/null
  
  clear && clear
  msg -bar2
  echo -e "\e[1;92m             >> INSTALACION COMPLETADA <<"
  msg -bar2
  echo -e "      COMANDO PRINCIPAL PARA ENTRAR AL PANEL "
  echo -e "                      \033[1;41m  menu  \033[0;37m"
  echo -e "                   Reseller: $slogan"
  msg -bar2
}

# Post reboot
post_reboot(){
  echo 'wget -q -O /root/install.sh "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh" && chmod +x /root/install.sh && /root/install.sh --continue' >> /root/.bashrc
}

# Inicio instalación
install_start(){
  title "INSTALADOR VPS-SN By @Sin_Nombre22"
  print_center -ama "Se actualizarán paquetes del sistema"
  msg -bar3
  
  echo -ne "\033[1;37m ¿Continuar? [S/N]: "
  read -r opcion
  
  if [[ "$opcion" != @(s|S) ]]; then
    title "CANCELADO"
    exit 1
  fi
  
  os_system
  
  echo "[+] Sistema: $distro $vercion"
  echo "[+] Actualizando..."
  apt-get update -y >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1
  echo "[+] Listo"
  
  msg -bar
  post_reboot
}

# Continuar
install_continue(){
  os_system
  title "INSTALADOR VPS-SN By @Sin_Nombre22"
  print_center -ama "$distro $vercion"
  print_center -verd "INSTALANDO DEPENDENCIAS"
  msg -bar3
  dependencias
  install_VPS_SN
  msg -bar
}

# FLUJO
case "${1:-none}" in
  -s|--start)
    echo "[+] Iniciando..."
    install_start
    time_reboot "15"
    ;;
    
  -c|--continue)
    echo "[+] Continuando..."
    rm -f /root/install.sh 2>/dev/null
    sed -i '/VPS-SN/d' /root/.bashrc 2>/dev/null
    install_continue
    echo "[+] ¡Completado!"
    time_reboot "10"
    ;;
    
  -u|--update)
    echo "[+] Actualizando..."
    install_start
    install_continue
    echo "[+] ¡Completado!"
    time_reboot "10"
    ;;
    
  none|*)
    echo "[+] Iniciando instalación..."
    install_start
    post_reboot
    time_reboot "15"
    ;;
esac

# Limpiar
rm -f $(pwd)/$0 2>/dev/null
mv -f ${module} /etc/VPS-SN/module 2>/dev/null

exit 0
