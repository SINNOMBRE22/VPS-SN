#!/bin/bash

# VPS-SN - Instalador con Funciones del Instalador LATAM
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-26 13:16:33 UTC
# Adaptado con funciones de NetVPS/LATAM

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
  8 | 9 | 10 | 11 | 16.04 | 18.04 | 20.04 | 20.10 | 21.04 | 21.10 | 22.04)
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

# 4. CAMBIAR CONTRASEÑA ROOT (sin cambios, pero mantenido)
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

# 5. REBOOT CON COUNTDOWN (mensaje modificado)
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

# 6. INSTALAR DEPENDENCIAS (mejorado con verificaciones)
dependencias() {
  rm -rf /root/paknoinstall.log >/dev/null 2>&1
  dpkg --configure -a >/dev/null 2>&1
  apt -f install -y >/dev/null 2>&1
  
  soft="sudo bsdmainutils zip screen unzip curl python3 python3-pip openssl cron iptables lsof pv at mlocate gawk bc jq npm nodejs socat netcat net-tools cowsay figlet lolcat apache2"

  for i in $soft; do
    echo -e "\e[1;97m        INSTALANDO PAQUETE \e[93m ------ \e[36m $i"
    barra_intall "apt-get install $i -y"
    if [ $? -ne 0 ]; then
      echo -e "\e[1;31m        ERROR INSTALANDO $i. INTENTANDO NUEVAMENTE..."
      apt-get install $i -y --fix-missing
    fi
  done
}

# 7. INSTALACIÓN INICIAL (sin confirmación de IP)
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
  
  # Actualizar sistema (mejorado)
  msg -bar
  echo -e "\e[1;93m\a\a\a      SE PROCEDERA A INSTALAR LAS ACTUALIZACIONES"
  msg -bar
  read -t 60 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
  clear && clear
  
  os_system
  repo "${vercion}"
  
  msg -bar
  echo -e " \e[5m\e[1;100m   =====>> ►►     VPS-SN     ◄◄ <<=====    \e[1;37m"
  msg -bar
  
  apt update -y && apt upgrade -y
  if [ $? -ne 0 ]; then
    echo -e "\e[1;31m        ERROR EN ACTUALIZACION. INTENTANDO NUEVAMENTE..."
    apt update -y --fix-missing && apt upgrade -y
  fi
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
  msg -bar
}

# 9. INSTALAR VPS-SN (reseller por defecto: Sin_Nombre22)
install_VPS_SN() {
  clear && clear
  
  mkdir -p /etc/VPS-SN >/dev/null 2>&1
  mkdir -p /etc/VPS-SN/tmp >/dev/null 2>&1
  
  cd /etc
  wget https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz >/dev/null 2>&1
  tar -xf VPS-SN.tar.xz >/dev/null 2>&1
  rm -rf VPS-SN.tar.xz
  cd
  chmod -R 755 /etc/VPS-SN
  
  rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/VPS-SN 2>/dev/null
  
  echo "Sin_Nombre22" >/etc/VPS-SN/tmp/message.txt
  
  echo "/etc/VPS-SN/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "/etc/VPS-SN/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "/etc/VPS-SN/menu" >/usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  
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

# ==================== MENÚ PRINCIPAL ====================

# Verificar ROOT
if [ $(whoami) != 'root' ]; then
  echo ""
  echo -e "\e[1;31m NECESITAS SER USER ROOT PARA EJECUTAR EL SCRIPT \n\n\e[97m                DIGITE: \e[1;32m sudo su\n"
  exit
fi

# Selector de instalación
while :; do
  case $1 in
  -s | --start)
    install_inicial && install_paquetes && install_VPS_SN && time_reboot "10"
    break
    ;;
  -c | --continue)
    install_paquetes && install_VPS_SN && time_reboot "10"
    break
    ;;
  *)
    install_inicial && install_paquetes && install_VPS_SN && time_reboot "10"
    break
    ;;
  esac
done
