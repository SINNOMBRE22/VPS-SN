#!/bin/bash

# VPS-SN - Instalador Independiente
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 04:06:31 UTC

# Colores
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'
PURPLE='\033[1;35m'
RESET='\033[0m'

# Funciones de colores
title(){
  echo -e "\n${BLUE}════════════════════════════════════════${RESET}"
  echo -e "${PURPLE}$1${RESET}"
  echo -e "${BLUE}════════════════════════════════════════${RESET}\n"
}

msg_info(){
  echo -e "${BLUE}[INFO]${RESET} $1"
}

msg_ok(){
  echo -e "${GREEN}[OK]${RESET} $1"
}

msg_error(){
  echo -e "${RED}[ERROR]${RESET} $1"
}

msg_warning(){
  echo -e "${YELLOW}[WARNING]${RESET} $1"
}

print_bar(){
  echo -e "${BLUE}════════════════════════════════════════${RESET}"
}

# Control+C
CTRL_C(){
  echo ""
  msg_error "Instalación cancelada"
  exit 1
}

trap "CTRL_C" INT TERM EXIT

# Verificar si es root
if [ $(whoami) != 'root' ]; then
  msg_error "NECESITAS SER USER ROOT PARA EJECUTAR EL SCRIPT"
  echo -e "${YELLOW}DIGITE: ${GREEN}sudo su${RESET}\n"
  exit 1
fi

# Variables globales
VPS_SN="/etc/VPS-SN"
VPS_inst="${VPS_SN}/install"
SCPinstal="$HOME/install"

# Crear directorios
mkdir -p ${VPS_SN} ${VPS_inst} ${SCPinstal} 2>/dev/null

# Zona horaria
rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime &>/dev/null

# Limpiar script
rm $(pwd)/$0 &> /dev/null

# Detectar sistema operativo
os_system(){
  system=$(cat -n /etc/issue |grep 1 |cut -d ' ' -f6,7,8 |sed 's/1//' |sed 's/      //')
  distro=$(echo "$system"|awk '{print $1}')

  case $distro in
    Debian)vercion=$(echo $system|awk '{print $3}'|cut -d '.' -f1);;
    Ubuntu)vercion=$(echo $system|awk '{print $2}'|cut -d '.' -f1,2);;
  esac
}

# Función de reinicio
time_reboot(){
  local REBOOT_TIMEOUT=$1
  msg_info "REINICIANDO VPS EN $REBOOT_TIMEOUT SEGUNDOS"
  
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    echo -ne "\r${YELLOW}Reiniciando en: -$REBOOT_TIMEOUT- segundos${RESET}"
    sleep 1
    : $((REBOOT_TIMEOUT--))
  done
  echo ""
  reboot
}

# Actualizar repositorios
update_system(){
  title "ACTUALIZANDO SISTEMA"
  msg_info "Actualizando lista de paquetes..."
  apt update -y >/dev/null 2>&1
  msg_ok "Lista de paquetes actualizada"
  
  msg_info "Actualizando paquetes del sistema..."
  apt upgrade -y >/dev/null 2>&1
  msg_ok "Paquetes actualizados"
}

# Instalar dependencias
install_deps(){
  title "INSTALANDO DEPENDENCIAS"
  
  soft="sudo bsdmainutils zip unzip curl python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq git htop vim tmux psmisc wget net-tools figlet lolcat"

  total=$(echo $soft | wc -w)
  count=0
  
  for i in $soft; do
    count=$((count + 1))
    pct=$((count * 100 / total))
    
    printf "\r${BLUE}[${pct}%%]${RESET} Instalando ${YELLOW}$i${RESET}..."
    
    if apt install -y $i >/dev/null 2>&1; then
      printf "\r${BLUE}[${pct}%%]${RESET} Instalando ${GREEN}$i${RESET} ${GREEN}[OK]${RESET}\n"
    else
      printf "\r${BLUE}[${pct}%%]${RESET} Instalando ${RED}$i${RESET} ${YELLOW}[RETRY]${RESET}"
      dpkg --configure -a >/dev/null 2>&1
      sleep 1
      
      if apt install -y $i >/dev/null 2>&1; then
        printf "\r${BLUE}[${pct}%%]${RESET} Instalando ${GREEN}$i${RESET} ${GREEN}[OK]${RESET}\n"
      else
        printf "\r${BLUE}[${pct}%%]${RESET} Instalando ${YELLOW}$i${RESET} ${YELLOW}[SKIP]${RESET}\n"
      fi
    fi
  done
  
  print_bar
  msg_ok "Instalación de dependencias completada"
}

# Instalador VPS-SN
install_VPS_SN(){
  title "INSTALANDO VPS-SN"
  
  echo -ne "${YELLOW}Digite su slogan: ${GREEN}"
  read slogan
  echo -e "${RESET}"
  
  if [[ -z "$slogan" ]]; then
    slogan="@Sin_Nombre22"
  fi
  
  msg_info "Slogan configurado: $slogan"
  
  # Crear directorios
  mkdir -p ${VPS_SN}/tmp >/dev/null 2>&1
  
  # Descargar VPS-SN
  cd /etc
  msg_info "Descargando VPS-SN.tar.xz..."
  
  if wget -q https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz -O VPS-SN.tar.xz 2>/dev/null; then
    msg_ok "Descarga exitosa"
    
    msg_info "Extrayendo archivos..."
    if tar -xf VPS-SN.tar.xz >/dev/null 2>&1; then
      msg_ok "Archivos extraidos"
      rm -rf VPS-SN.tar.xz
    else
      msg_error "Error extrayendo archivos"
      mkdir -p ${VPS_SN}/install
    fi
  else
    msg_warning "No se pudo descargar VPS-SN.tar.xz, creando estructura vacía"
    mkdir -p ${VPS_SN}/install
  fi
  
  cd
  chmod -R 755 ${VPS_SN}
  
  # Limpiar comandos antiguos
  rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/VPS-SN 2>/dev/null
  
  # Guardar slogan
  echo "$slogan" > ${VPS_SN}/tmp/message.txt
  
  # Crear comandos de usuario
  echo "#!/bin/bash" > /usr/bin/menu
  echo "exec ${VPS_SN}/menu \"\$@\"" >> /usr/bin/menu
  chmod +x /usr/bin/menu
  
  cp /usr/bin/menu /usr/bin/adm
  cp /usr/bin/menu /usr/bin/VPS-SN
  
  msg_ok "Comandos de usuario creados"
  
  # Configurar .bashrc
  echo "" >> /etc/bash.bashrc
  echo '# VPS-SN Configuration' >> /etc/bash.bashrc
  echo 'export PATH=$PATH:/usr/games' >> /etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >> /etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion 2>/dev/null || echo "1.0.0")' >> /etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >> /etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(cat /etc/VPS-SN/tmp/message.txt)"' >> /etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >> /etc/bash.bashrc
  echo 'clear && echo -e "\n\033[1;36m╔════════════════════════════════════╗\033[0m\n\033[1;36m║\033[1;32m       VPS-SN Panel Control\033[1;36m        ║\033[0m\n\033[1;36m╚════════════════════════════════════╝\033[0m\n\033[1;32m  RESELLER: $mess1\033[0m\n\n\033[1;33m  Para iniciar VPS-SN escriba: \033[1;32mmenu\033[0m\n\n"' >> /etc/bash.bashrc
  
  msg_ok "Configuración de bash completada"
  
  # Locale
  update-locale LANG=en_US.UTF-8 LANGUAGE=en 2>/dev/null
  
  print_bar
}

# Función post reboot
post_reboot(){
  echo 'wget -q -O /root/install.sh "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh" && chmod +x /root/install.sh && /root/install.sh --continue' >> /root/.bashrc
  title "CONTINUACIÓN DESPUÉS DEL REBOOT"
  msg_info "La instalación continuará después del reinicio"
  print_bar
}

# Menú principal
case $1 in
  -s|--start)
    title "INSTALADOR VPS-SN By @Sin_Nombre22"
    msg_info "Sistema detectado: $distro"
    echo ""
    echo -ne "${YELLOW}¿Desea continuar con la instalación? [S/N]: ${GREEN}"
    read opcion
    echo -e "${RESET}"
    
    if [[ "$opcion" = @(s|S|y|Y) ]]; then
      os_system
      update_system
      post_reboot
      time_reboot "15"
    else
      msg_error "Instalación cancelada"
      exit 1
    fi
    ;;
    
  -c|--continue)
    title "CONTINUANDO INSTALACIÓN VPS-SN"
    rm /root/install.sh &> /dev/null
    sed -i '/VPS-SN/d' /root/.bashrc 2>/dev/null
    os_system
    install_deps
    install_VPS_SN
    print_bar
    msg_ok "VPS-SN instalado exitosamente"
    print_bar
    time_reboot "10"
    ;;
    
  -u|--update)
    title "ACTUALIZANDO VPS-SN"
    os_system
    update_system
    install_deps
    install_VPS_SN
    print_bar
    msg_ok "VPS-SN actualizado exitosamente"
    print_bar
    time_reboot "10"
    ;;
    
  *)
    title "INSTALADOR VPS-SN By @Sin_Nombre22"
    msg_info "Iniciando instalación directa..."
    os_system
    install_deps
    install_VPS_SN
    print_bar
    msg_ok "VPS-SN instalado exitosamente"
    print_bar
    echo -ne "${YELLOW}¿Reiniciar ahora? [S/N]: ${GREEN}"
    read reboot_now
    echo -e "${RESET}"
    
    if [[ "$reboot_now" = @(s|S|y|Y) ]]; then
      time_reboot "10"
    else
      msg_warning "Recuerde reiniciar el sistema para completar la instalación"
      exit 0
    fi
    ;;
esac
