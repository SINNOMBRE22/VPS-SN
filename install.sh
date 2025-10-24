#!/bin/bash

# VPS-SN - Instalador Unificado COMPLETO
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 04:36:18 UTC
# Correcciones: msgi → msg, apt → apt-get

set -e  # Salir si hay error

module="$(pwd)/module"
rm -rf ${module} 2>/dev/null

# Funciones básicas de mensajes (en caso de fallo del módulo)
msg_info() {
  echo -e "\033[1;36m[INFO]\033[0m $1"
}

msg_error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
}

msg_ok() {
  echo -e "\033[1;32m[OK]\033[0m $1"
}

msg_warning() {
  echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# Intentar descargar módulo
msg_info "Descargando módulo..."
if wget -q -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module" 2>/dev/null; then
  msg_ok "Módulo descargado"
  if [[ -e ${module} ]] && [[ -s ${module} ]]; then
    chmod +x ${module} 2>/dev/null
    source ${module}
    msg_ok "Módulo cargado exitosamente"
  else
    msg_error "Módulo descargado pero vacío"
    exit 1
  fi
else
  msg_error "No se pudo descargar el módulo"
  exit 1
fi

CTRL_C(){
  echo ""
  msg_error "Instalación cancelada por usuario"
  rm -rf ${module} 2>/dev/null
  exit 1
}

trap "CTRL_C" INT TERM EXIT

# Verificar si es root
if [[ $(whoami) != 'root' ]]; then
  msg_error "Este script debe ejecutarse como root"
  echo "Usa: sudo su"
  exit 1
fi

# Variables globales
VPS_SN="/etc/VPS-SN"
VPS_inst="${VPS_SN}/install"
SCPinstal="$HOME/install"

# Crear directorios
mkdir -p ${VPS_SN} ${VPS_inst} ${SCPinstal} 2>/dev/null

# Zona horaria
rm -rf /etc/localtime 2>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime 2>/dev/null
msg_ok "Zona horaria configurada a Mexico_City"

# Detectar sistema operativo
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
  msg_info "REINICIANDO VPS EN $REBOOT_TIMEOUT SEGUNDOS"
  
  while [[ $REBOOT_TIMEOUT -gt 0 ]]; do
    echo -ne "\r${REBOOT_TIMEOUT} segundos..."
    sleep 1
    ((REBOOT_TIMEOUT--))
  done
  echo ""
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
    
    printf "\r\033[1;36m[${pct}%%]\033[0m Instalando \033[1;33m$paquete\033[0m..."
    
    if apt-get install -y $paquete >/dev/null 2>&1; then
      printf "\r\033[1;32m[${pct}%%]\033[0m Instalando \033[1;33m$paquete\033[0m \033[1;32m[OK]\033[0m\n"
    else
      printf "\r\033[1;33m[${pct}%%]\033[0m Instalando \033[1;33m$paquete\033[0m \033[1;31m[RETRY]\033[0m"
      dpkg --configure -a >/dev/null 2>&1
      sleep 1
      
      if apt-get install -y $paquete >/dev/null 2>&1; then
        printf "\r\033[1;32m[${pct}%%]\033[0m Instalando \033[1;33m$paquete\033[0m \033[1;32m[OK]\033[0m\n"
      else
        printf "\r\033[1;33m[${pct}%%]\033[0m Instalando \033[1;33m$paquete\033[0m \033[1;33m[SKIP]\033[0m\n"
      fi
    fi
  done
  
  msg -bar
  msg_ok "Instalación de dependencias completada"
}

install_VPS_SN(){
  clear
  msg -bar2
  echo -ne "\033[1;97m Digite su slogan: \033[1;32m"
  read -r slogan
  
  if [[ -z "$slogan" ]]; then
    slogan="@Sin_Nombre22"
  fi
  
  echo -e "\033[0m"
  msg -bar2
  clear
  
  msg_info "Creando directorios..."
  mkdir -p ${VPS_SN}/tmp >/dev/null 2>&1
  msg_ok "Directorios creados"
  
  msg_info "Descargando VPS-SN.tar.xz..."
  cd /etc
  
  if wget -q https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz -O VPS-SN.tar.xz 2>/dev/null; then
    msg_ok "Descarga exitosa"
    
    msg_info "Extrayendo archivos..."
    if tar -xf VPS-SN.tar.xz >/dev/null 2>&1; then
      msg_ok "Archivos extraidos"
      rm -rf VPS-SN.tar.xz
    else
      msg_error "Error extrayendo, creando estructura vacía"
      mkdir -p ${VPS_SN}/install
    fi
  else
    msg_error "Fallo descarga, creando estructura vacía"
    mkdir -p ${VPS_SN}/install
  fi
  
  cd ~
  chmod -R 755 ${VPS_SN}
  
  msg_info "Limpiando comandos antiguos..."
  rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/VPS-SN 2>/dev/null
  
  msg_info "Guardando slogan..."
  echo "$slogan" > ${VPS_SN}/tmp/message.txt
  
  msg_info "Creando comandos de usuario..."
  echo "${VPS_SN}/menu" > /usr/bin/menu && chmod +x /usr/bin/menu
  echo "${VPS_SN}/menu" > /usr/bin/adm && chmod +x /usr/bin/adm
  echo "${VPS_SN}/menu" > /usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  msg_ok "Comandos creados"
  
  msg_info "Configurando .bashrc..."
  {
    echo ""
    echo '# VPS-SN Configuration'
    echo 'export PATH=$PATH:/usr/games'
    echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh'
    echo 'v=$(cat /etc/VPS-SN/vercion 2>/dev/null || echo "1.0.0")'
    echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v'
    echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(cat /etc/VPS-SN/tmp/message.txt)"'
    echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"'
    echo 'clear && echo -e "\n$(figlet -f big.flf "  VPS-SN" 2>/dev/null || echo "VPS-SN")\n        RESELLER : $mess1 \n\n   Para iniciar VPS-SN escriba:  menu \n\n"'
  } >> /etc/bash.bashrc
  
  msg_ok "Configuración de bash completada"
  
  msg_info "Estableciendo locale..."
  update-locale LANG=en_US.UTF-8 LANGUAGE=en 2>/dev/null
  msg_ok "Locale configurado"
  
  clear
  msg -bar2
  echo -e "\033[1;32m             >> INSTALACION COMPLETADA <<"
  msg -bar2
  echo -e "      COMANDO PRINCIPAL PARA ENTRAR AL PANEL "
  echo -e "                      \033[1;41m  menu  \033[0;37m"
  echo -e "                 Reseller: $slogan"
  msg -bar2
}

post_reboot(){
  echo 'wget -q -O /root/install.sh "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh" && chmod +x /root/install.sh && /root/install.sh --continue' >> /root/.bashrc
}

install_start(){
  title "INSTALADOR VPS-SN By @Sin_Nombre22"
  print_center -ama "A continuacion se actualizaran los paquetes del sistema.\nEsto podria tomar tiempo, y requerir algunas preguntas."
  msg -bar3
  
  echo -ne "\033[1;37m Desea continuar? [S/N]: "
  read -r opcion
  
  if [[ "$opcion" != @(s|S) ]]; then
    title "INSTALACION CANCELADA"
    exit 1
  fi
  
  title "INSTALADOR VPS-SN By @Sin_Nombre22"
  os_system
  
  msg_info "Sistema detectado: $distro $vercion"
  
  msg_info "Actualizando repositorios con apt-get update..."
  apt-get update -y >/dev/null 2>&1
  msg_ok "Repositorios actualizados"
  
  msg_info "Actualizando paquetes del sistema con apt-get upgrade..."
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1
  msg_ok "Paquetes actualizados"
  
  msg -bar
  post_reboot
}

# FLUJO PRINCIPAL
case "${1:-}" in
  -s|--start)
    msg_info "Iniciando instalación..."
    install_start
    time_reboot "15"
    ;;
    
  -c|--continue)
    msg_info "Continuando instalación..."
    rm -f /root/install.sh 2>/dev/null
    sed -i '/VPS-SN/d' /root/.bashrc 2>/dev/null
    os_system
    dependencias
    install_VPS_SN
    msg -bar
    msg_ok "VPS-SN instalado exitosamente"
    time_reboot "10"
    ;;
    
  -u|--update)
    msg_info "Actualizando VPS-SN..."
    install_start
    dependencias
    install_VPS_SN
    msg -bar
    msg_ok "VPS-SN actualizado exitosamente"
    time_reboot "10"
    ;;
    
  *)
    msg_info "Ejecutando instalación directa..."
    install_start
    post_reboot
    time_reboot "15"
    ;;
esac

# Limpiar script
rm -f $(pwd)/$0 2>/dev/null
mv -f ${module} /etc/VPS-SN/module 2>/dev/null

exit 0
