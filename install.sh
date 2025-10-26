#!/bin/bash

# VPS-SN - Instalador con Funciones del Instalador LATAM
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-26 15:32:34 UTC
# Adaptado con funciones de NetVPS/Multi-Script

clear && clear

# COLORES Y FUNCIONES BÁSICAS
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

# ==================== FUNCIONES ====================

# 1. DETECTAR SISTEMA OPERATIVO
os_system() {
  system=$(cat -n /etc/issue | grep 1 | cut -d ' ' -f6,7,8 | sed 's/1//' | sed 's/      //')
  distro=$(echo "$system" | awk '{print $1}')

  case $distro in
  Debian) vercion=$(echo $system | awk '{print $3}' | cut -d '.' -f1) ;;
  Ubuntu) vercion=$(echo $system | awk '{print $2}' | cut -d '.' -f1,2) ;;
  esac
}

# 2. CONFIGURAR REPOSITORIOS
repo() {
  link="https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Repositorios/$1.list"
  case $1 in
  8|9|10|11|16.04|18.04|20.04|20.10|21.04|21.10|22.04)
    wget -O /etc/apt/sources.list ${link} &>/dev/null
    ;;
  esac
}

# 3. BARRA DE INSTALACIÓN
barra_intall() {
  comando="$1"
  txt="Instalando"
  _=$($comando > /dev/null 2>&1) & > /dev/null
  pid=$!
  while [[ -d /proc/$pid ]]; do
    echo -ne " \033[1;33m$txt[\033[1;31m"
    for ((i = 0; i < 10; i++)); do
      echo -ne "##"
      sleep 0.1
    done
    echo -ne "\033[1;33m]\r"
  done
  echo -e " \033[1;32m[OK]\033[0m"
}

# 4. CAMBIAR CONTRASEÑA ROOT
pass_root() {
  wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/utilidades/sshd_config >/dev/null 2>&1
  chmod +rwx /etc/ssh/sshd_config
  service ssh restart >/dev/null 2>&1
  msg -bar
  echo -ne "\e[1;97m DIGITE NUEVA CONTRASEÑA:  \e[1;31m" && read pass
  (
    echo $pass
    echo $pass
  ) | passwd root 2>/dev/null
  sleep 1s
  msg -bar
  echo -e "\e[1;94m     CONTRASEÑA AGREGADA CORRECTAMENTE"
  echo -e "\e[1;97m TU CONTRASEÑA ROOT AHORA ES: \e[41m $pass \e[0;37m"
}

# 5. REBOOT CON COUNTDOWN
time_reboot() {
  clear && clear
  msg -bar
  echo -e "\e[1;93m     EL MENU ESTARA INSTALADO DESPUES DE LA INSTALACION"
  msg -bar
  REBOOT_TIMEOUT="$1"
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    print_center -ne "-$REBOOT_TIMEOUT-\r"
    sleep 1
    : $((REBOOT_TIMEOUT--))
  done
  reboot
}

# 6. INSTALAR DEPENDENCIAS - VERSIÓN MEJORADA
dependencias() {
  rm -rf /root/paknoinstall.log >/dev/null 2>&1
  rm -rf /root/packinstall.log >/dev/null 2>&1
  
  # Reparar sistema primero
  echo -e "\e[1;97m REPARANDO SISTEMA..."
  dpkg --configure -a >/dev/null 2>&1
  apt -f install -y >/dev/null 2>&1
  apt --fix-broken install -y >/dev/null 2>&1
  
  # Actualizar lista de paquetes
  echo -e "\e[1;97m ACTUALIZANDO LISTA DE PAQUETES..."
  apt update >/dev/null 2>&1
  
  # Lista completa de dependencias
  soft=(
    sudo bsdmainutils zip screen unzip ufw 
    curl python3 python3-pip openssl cron 
    iptables lsof pv boxes at mlocate gawk 
    bc jq npm nodejs socat netcat 
    netcat-traditional net-tools cowsay 
    figlet lolcat apache2 python2
  )
  
  echo -e "\e[1;97m INSTALANDO DEPENDENCIAS ESENCIALES..."
  echo -e "\e[1;90m (Esto puede tomar varios minutos...)\e[0m"
  msg -bar
  
  # Instalar paquetes uno por uno para mejor control
  for paquete in "${soft[@]}"; do
    echo -ne "\e[1;97m Instalando: \e[1;93m$paquete"
    if apt install "$paquete" -y >/dev/null 2>&1; then
      echo -e "\r\e[1;97m Instalando: \e[1;92m$paquete ✅\e[0m"
    else
      echo -e "\r\e[1;97m Instalando: \e[1;91m$paquete ❌\e[0m"
      echo "$paquete" >> /root/paknoinstall.log
    fi
    sleep 1
  done
  
  # Verificar si hay paquetes fallidos
  if [[ -f /root/paknoinstall.log ]]; then
    echo -e "\n\e[1;91m ALGUNOS PAQUETES NO SE PUDIERON INSTALAR:\e[0m"
    cat /root/paknoinstall.log
    echo -e "\e[1;93m Reintentando instalación de paquetes fallidos...\e[0m"
    
    while read -r paquete_fallido; do
      apt install "$paquete_fallido" -y --fix-missing >/dev/null 2>&1 && \
        echo -e "\e[1;92m ✅ $paquete_fallido instalado en segundo intento\e[0m" || \
        echo -e "\e[1;91m ❌ $paquete_fallido sigue fallando\e[0m"
    done < /root/paknoinstall.log
  fi
  
  echo -e "\e[1;92m DEPENDENCIAS INSTALADAS CORRECTAMENTE.\e[0m"
  msg -bar
}

# 7. INSTALACIÓN INICIAL
install_inicial() {
  clear && clear
  
  # Cambiar pass ROOT
  msg -bar
  echo -e "\e[1;93m             AGREGAR Y EDITAR PASS ROOT\e[1;97m"
  msg -bar
  echo -e "\e[1;97m CAMBIAR PASS ROOT? \e[32m"
  msg -bar
  echo -ne "\e[1;97m Seleccione  \e[1;31m[\e[1;93m S \e[1;31m/\e[1;93m N \e[1;31m]\e[1;97m: \e[1;93m" && read pass_root_option
  [[ "$pass_root_option" = "s" || "$pass_root_option" = "S" ]] && pass_root
  
  # Actualizar sistema
  msg -bar
  echo -e "\e[1;93m\a\a\a      ACTUALIZANDO SISTEMA..."
  msg -bar
  read -t 60 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
  clear && clear
  
  os_system
  repo "${vercion}"
  
  msg -bar
  echo -e " \e[5m\e[1;100m   =====>> ►►     VPS-SN     ◄◄ <<=====    \e[1;37m"
  msg -bar
  
  echo -e "\e[1;97m ACTUALIZANDO SISTEMA...\e[0m"
  apt update && apt upgrade -y
  if [ $? -ne 0 ]; then
    echo -e "\e[1;31m ERROR EN ACTUALIZACION. INTENTANDO REPARAR...\e[0m"
    apt update --fix-missing && apt upgrade -y
  fi
  echo -e "\e[1;32m SISTEMA ACTUALIZADO CORRECTAMENTE.\e[0m"
}

# 8. INSTALAR PAQUETES
install_paquetes() {
  clear && clear
  msg -bar
  echo -e " \e[5m\e[1;100m   =====>> ►►     VPS-SN     ◄◄ <<=====    \e[1;37m"
  msg -bar
  echo -e "   \e[1;41m    -- INSTALACION PAQUETES FALTANTES --    \e[49m"
  msg -bar
  dependencias
}

# 9. INSTALAR VPS-SN
install_VPS_SN() {
  clear && clear
  
  mkdir -p /etc/VPS-SN >/dev/null 2>&1
  mkdir -p /etc/VPS-SN/tmp >/dev/null 2>&1
  
  cd /etc
  echo -e "\e[1;97m DESCARGANDO VPS-SN...\e[0m"
  wget https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz >/dev/null 2>&1
  echo -e "\e[1;97m EXRAYENDO ARCHIVOS...\e[0m"
  tar -xf VPS-SN.tar.xz >/dev/null 2>&1
  rm -rf VPS-SN.tar.xz
  cd
  chmod -R 755 /etc/VPS-SN
  
  # Crear comandos del sistema
  rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/VPS-SN 2>/dev/null
  echo "Sin_Nombre22" >/etc/VPS-SN/tmp/message.txt
  
  echo "/etc/VPS-SN/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "/etc/VPS-SN/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "/etc/VPS-SN/menu" >/usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  
  # Configurar bashrc
  [[ -z $(echo $PATH | grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >>/etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >>/etc/bash.bashrc
  echo 'echo ""' >>/etc/bash.bashrc
  echo 'figlet "VPS-SN" |lolcat' >>/etc/bash.bashrc
  echo 'mess1="$(cat /etc/VPS-SN/tmp/message.txt)"' >>/etc/bash.bashrc
  echo 'echo ""' >>/etc/bash.bashrc
  echo 'echo -e "\t\033[92mRESELLER : $mess1 "' >>/etc/bash.bashrc
  echo 'echo ""' >>/etc/bash.bashrc
  echo 'echo -e "\t\033[1;100mPARA MOSTAR PANEL BASH ESCRIBA:\e[0m\e[1;41m menu \e[0m"' >>/etc/bash.bashrc
  echo 'echo ""' >>/etc/bash.bashrc
  
  update-locale LANG=en_US.UTF-8 LANGUAGE=en
  clear && clear
  msg -bar
  echo -e "\e[1;92m             >> INSTALACION COMPLETADA <<" && msg -bar
  echo -e "      COMANDO PRINCIPAL PARA ENTRAR AL PANEL "
  echo -e "                      \033[1;41m  menu  \033[0;37m" && msg -bar
  
  rm $(pwd)/$0 &> /dev/null
}

# ==================== EJECUCIÓN PRINCIPAL ====================

# Verificar ROOT
if [ $(whoami) != 'root' ]; then
  echo ""
  echo -e "\e[1;31m NECESITAS SER USER ROOT PARA EJECUTAR EL SCRIPT \n\n\e[97m                DIGITE: \e[1;32m sudo su\n"
  exit 1
fi

# Ejecutar instalación completa
install_inicial
install_paquetes  
install_VPS_SN
time_reboot "10"
