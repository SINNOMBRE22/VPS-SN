#!/bin/bash

clear

# VPS-SN - Instalador Mejorado
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 05:02:36 UTC

set -e

# Detectar si es root
if [[ $EUID -ne 0 ]]; then
   echo "[!] Este script debe ejecutarse como root"
   exit 1
fi

# Configurar linger para root
if ! loginctl show-user root | grep -q '^Linger=yes'; then
    echo "[+] Configurando linger para root..."
    loginctl enable-linger root
fi

# Crear directorio runtime
if [ ! -d /run/user/0 ]; then
    echo "[+] Creando directorio /run/user/0..."
    mkdir -p /run/user/0
    chmod 700 /run/user/0
    chown root:root /run/user/0
fi

# Configurar XDG_RUNTIME_DIR
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/0
fi

echo "[+] Detectando sistema operativo..."
. /etc/os-release

# Actualizar repositorios
echo "[+] Actualizando repositorios..."
apt-get update -y >/dev/null 2>&1
apt-get install -y gnupg wget software-properties-common lsb-release >/dev/null 2>&1

# Detectar distro e instalar dependencias
if [[ "$ID" == "ubuntu" ]]; then
    echo "[+] Ubuntu detectado: $VERSION_ID"
    echo "[+] Configurando PPA ubuntu-toolchain-r/test..."
    add-apt-repository -y ppa:ubuntu-toolchain-r/test < /dev/null >/dev/null 2>&1
    apt-get update -y >/dev/null 2>&1

    echo "[+] Instalando libstdc++6..."
    apt-get install -y libstdc++6 >/dev/null 2>&1

elif [[ "$ID" == "debian" ]]; then
    echo "[+] Debian detectado: $VERSION_ID"

    if ! dpkg-query -W -f='${Status}' libstdc++6 > /dev/null 2>&1; then
        echo "[+] Instalando libstdc++6..."
        apt-get install -y libstdc++6 >/dev/null 2>&1
    else
        echo "[+] libstdc++6 ya está instalado"
    fi

    if [[ $? -ne 0 ]]; then
        echo "[+] Instalando libstdc++6 manualmente..."
        ARCH=$(dpkg --print-architecture)
        VERSION_ID_NUM=$(echo "$VERSION_ID" | cut -d'.' -f1)
        
        LIBSTDCPP_DEB_URL="https://ftp.debian.org/debian/pool/main/g/gcc-11/libstdc++6-11-dbg_11.5.0-2_${ARCH}.deb"
        
        echo "[+] Descargando desde: $LIBSTDCPP_DEB_URL"
        wget -q -O /tmp/libstdc++6.deb "$LIBSTDCPP_DEB_URL"
        
        echo "[+] Instalando .deb..."
        dpkg -i /tmp/libstdc++6.deb || apt-get install -f -y >/dev/null 2>&1
    fi

else
    echo "[!] Sistema no soportado automáticamente"
    exit 1
fi

# Instalar libcurl4-openssl-dev
echo "[+] Detectando libcurl4-openssl-dev..."
if ! dpkg -l | grep -q libcurl4-openssl-dev; then
    echo "[+] Instalando libcurl4-openssl-dev..."
    apt-get update -y >/dev/null 2>&1
    apt-get install -y libcurl4-openssl-dev >/dev/null 2>&1
else
    echo "[+] libcurl4-openssl-dev ya está instalado"
fi

# Cargar módulo
echo "[+] Descargando módulo de funciones..."
module="$(pwd)/module"
rm -rf ${module} 2>/dev/null
wget -q -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module"

if [[ ! -e ${module} ]]; then
    echo "[!] Error descargando módulo"
    exit 1
fi

chmod +x ${module}
source ${module}

# Cleanup
CTRL_C(){
  echo ""
  msg -verm2 "Instalación cancelada"
  rm -rf ${module} 2>/dev/null
  exit 1
}

trap "CTRL_C" INT TERM EXIT

# Variables
VPS_SN="/etc/VPS-SN"
VPS_inst="${VPS_SN}/install"
SCPinstal="$HOME/install"

mkdir -p ${VPS_SN} ${VPS_inst} ${SCPinstal} 2>/dev/null

# Zona horaria
rm -rf /etc/localtime 2>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime 2>/dev/null

echo "[+] Zona horaria: Mexico_City"

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

time_reboot(){
  local REBOOT_TIMEOUT=$1
  print_center -ama "REINICIANDO EN $REBOOT_TIMEOUT SEGUNDOS"
  
  while [[ $REBOOT_TIMEOUT -gt 0 ]]; do
    echo -ne "\r-$REBOOT_TIMEOUT-"
    sleep 1
    ((REBOOT_TIMEOUT--))
  done
  reboot
}

dependencias(){
  title "INSTALANDO DEPENDENCIAS"
  
  soft="sudo bsdmainutils zip unzip curl python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq git htop vim tmux psmisc wget net-tools figlet lolcat"

  total=$(echo $soft | wc -w)
  count=0
  
  for paquete in $soft; do
    count=$((count + 1))
    pct=$((count * 100 / total))
    
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
      msg -verm2 "FAIL"
      sleep 1
      tput cuu1 && tput dl1 2>/dev/null
      dpkg --configure -a >/dev/null 2>&1
      sleep 1
      tput cuu1 && tput dl1 2>/dev/null
      
      msg -nazu "       reintentando $paquete$pts"
      if apt-get install -y $paquete >/dev/null 2>&1; then
        msg -verd "OK"
      else
        msg -verm2 "SKIP"
      fi
    fi
  done
  
  msg -bar
}

install_VPS_SN() {
  clear && clear
  msg -bar2
  echo -ne "\033[1;97m Digite su slogan: \033[1;32m" && read slogan
  tput cuu1 && tput dl1 2>/dev/null
  echo -e "$slogan"
  msg -bar2
  clear && clear
  
  mkdir -p /etc/VPS-SN/tmp >/dev/null 2>&1
  
  cd /etc
  echo "[+] Descargando VPS-SN.tar.xz..."
  wget -q https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz -O VPS-SN.tar.xz
  
  if [[ -e VPS-SN.tar.xz ]]; then
    echo "[+] Extrayendo archivos..."
    tar -xf VPS-SN.tar.xz >/dev/null 2>&1
    rm -rf VPS-SN.tar.xz
    echo "[+] Archivos extraidos"
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

post_reboot(){
  echo 'wget -q -O /root/install.sh "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh" && chmod +x /root/install.sh && /root/install.sh --continue' >> /root/.bashrc
  title "CONTINUACIÓN TRAS REBOOT"
  print_center -ama "La instalación continuará después del reinicio"
}

install_start(){
  title "INSTALADOR VPS-SN By @Sin_Nombre22"
  print_center -ama "Se actualizarán los paquetes del sistema.\nEsto puede tomar tiempo..."
  msg -bar3
  
  echo -ne "\033[1;37m ¿Desea continuar? [S/N]: "
  read -r opcion
  
  if [[ "$opcion" != @(s|S) ]]; then
    title "INSTALACION CANCELADA"
    exit 1
  fi
  
  title "INSTALADOR VPS-SN By @Sin_Nombre22"
  os_system
  
  echo "[+] Sistema: $distro $vercion"
  echo "[+] Ejecutando: apt-get update"
  apt-get update -y >/dev/null 2>&1
  
  echo "[+] Ejecutando: apt-get upgrade"
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1
  
  msg -bar
  post_reboot
}

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

# FLUJO PRINCIPAL
case "${1:-}" in
  -s|--start)
    echo "[+] Iniciando instalación..."
    install_start
    time_reboot "15"
    ;;
    
  -c|--continue)
    echo "[+] Continuando instalación..."
    rm -f /root/install.sh 2>/dev/null
    sed -i '/VPS-SN/d' /root/.bashrc 2>/dev/null
    install_continue
    echo "[+] VPS-SN instalado exitosamente"
    time_reboot "10"
    ;;
    
  -u|--update)
    echo "[+] Actualizando VPS-SN..."
    install_start
    install_continue
    echo "[+] VPS-SN actualizado"
    time_reboot "10"
    ;;
    
  *)
    echo "[+] Instalación directa..."
    install_start
    post_reboot
    time_reboot "15"
    ;;
esac

# Limpiar
rm -f $(pwd)/$0 2>/dev/null
mv -f ${module} /etc/VPS-SN/module 2>/dev/null

exit 0
