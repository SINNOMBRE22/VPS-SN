#!/bin/bash

# VPS-SN - Instalador Unificado COMPLETO
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 04:38:52 UTC
# Corrección: Sin dependencia del módulo al inicio

# Funciones de colores INDEPENDIENTES (NO dependen del módulo)
msg(){
  COLOR[0]='\033[1;37m'
  COLOR[1]='\e[31m'
  COLOR[2]='\e[32m'
  COLOR[3]='\e[33m'
  COLOR[4]='\e[34m'
  COLOR[5]='\e[91m'
  COLOR[6]='\033[1;97m'
  COLOR[7]='\e[36m'
  COLOR[8]='\e[30m'
  COLOR[9]='\033[34m'

  NEGRITO='\e[1m'
  SEMCOR='\e[0m'

  case $1 in
    -ne)   cor="${COLOR[1]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -nazu) cor="${COLOR[6]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -nverd)cor="${COLOR[2]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -nama) cor="${COLOR[3]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -ama)  cor="${COLOR[3]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -verm) cor="${COLOR[3]}${NEGRITO}[!] ${COLOR[1]}" && echo -e "${cor}${2}${SEMCOR}";;
    -verm2)cor="${COLOR[1]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -verm3)cor="${COLOR[1]}" && echo -e "${cor}${2}${SEMCOR}";;
    -teal) cor="${COLOR[7]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -teal2)cor="${COLOR[7]}" && echo -e "${cor}${2}${SEMCOR}";;
    -blak) cor="${COLOR[8]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -blak2)cor="${COLOR[8]}" && echo -e "${cor}${2}${SEMCOR}";;
    -azu)  cor="${COLOR[6]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -blu)  cor="${COLOR[9]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -blu1) cor="${COLOR[9]}" && echo -e "${cor}${2}${SEMCOR}";;
    -verd) cor="${COLOR[2]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -bra)  cor="${COLOR[0]}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
    -bar)  cor="${COLOR[1]}════════════════════════════════════════════════════" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
    -bar2) cor="${COLOR[7]}════════════════════════════════════════════════════" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
    -bar3) cor="${COLOR[1]}-----------------------------------------------------" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
    -bar4) cor="${COLOR[7]}-----------------------------------------------------" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
  esac
}

# Centrado de texto
print_center(){
  if [[ -z $2 ]]; then
    text="$1"
  else
    col="$1"
    text="$2"
  fi

  while read line; do
    unset space
    x=$(( ( 54 - ${#line}) / 2))
    for (( i = 0; i < $x; i++ )); do
      space+=' '
    done
    space+="$line"
    if [[ -z $2 ]]; then
      msg -azu "$space"
    else
      msg "$col" "$space"
    fi
  done <<< $(echo -e "$text")
}

# Titulos
title(){
    clear
    msg -bar
    if [[ -z $2 ]]; then
      print_center -azu "$1"
    else
      print_center "$1" "$2"
    fi
    msg -bar
}

# Pausa
enter(){
  msg -bar
  text="►► Presione enter para continuar ◄◄"
  if [[ -z $1 ]]; then
    print_center -ama "$text"
  else
    print_center "$1" "$text"
  fi
  read
}

# Exportar funciones
export -f msg
export -f print_center
export -f title
export -f enter

# Ahora sí cargar el módulo
module="$(pwd)/module"
rm -rf ${module} 2>/dev/null

msg -azu "Descargando módulo..."
if wget -q -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module" 2>/dev/null; then
  if [[ -e ${module} ]] && [[ -s ${module} ]]; then
    chmod +x ${module} 2>/dev/null
    source ${module}
    msg -verd "Módulo cargado"
  else
    msg -verm2 "Módulo vacío, continuando con funciones locales"
  fi
else
  msg -verm2 "No se pudo descargar módulo, usando funciones locales"
fi

CTRL_C(){
  echo ""
  msg -verm2 "Instalación cancelada"
  rm -rf ${module} 2>/dev/null
  exit 1
}

trap "CTRL_C" INT TERM EXIT

# Verificar si es root
if [[ $(whoami) != 'root' ]]; then
  msg -verm2 "Este script debe ejecutarse como root"
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
msg -verd "Zona horaria: Mexico_City"

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
  print_center -ama "REINICIANDO VPS EN $REBOOT_TIMEOUT SEGUNDOS"
  
  while [[ $REBOOT_TIMEOUT -gt 0 ]]; do
    echo -ne "\r-$REBOOT_TIMEOUT- segundos"
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
    
    leng="${#paquete}"
    puntos=$(( 21 - $leng))
    pts="."
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    msg -nazu "       instalando $paquete$(msg -ama "$pts")"
    
    if apt-get install -y $paquete >/dev/null 2>&1; then
      msg -verd "INSTALL"
    else
      msg -verm2 "FAIL"
      sleep 1
      tput cuu1 && tput dl1
      dpkg --configure -a >/dev/null 2>&1
      sleep 1
      tput cuu1 && tput dl1
      
      msg -nazu "       reintentando $paquete$(msg -ama "$pts")"
      if apt-get install -y $paquete >/dev/null 2>&1; then
        msg -verd "INSTALL"
      else
        msg -verm2 "SKIP"
      fi
    fi
  done
  
  msg -bar
  msg -verd "Dependencias instaladas"
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
  
  msg -azu "Creando directorios..."
  mkdir -p ${VPS_SN}/tmp >/dev/null 2>&1
  msg -verd "OK"
  
  msg -azu "Descargando VPS-SN.tar.xz..."
  cd /etc
  
  if wget -q https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz -O VPS-SN.tar.xz 2>/dev/null; then
    msg -verd "OK"
    
    msg -azu "Extrayendo archivos..."
    if tar -xf VPS-SN.tar.xz >/dev/null 2>&1; then
      msg -verd "OK"
      rm -rf VPS-SN.tar.xz
    else
      msg -verm2 "Error extrayendo"
      mkdir -p ${VPS_SN}/install
    fi
  else
    msg -verm2 "Error descargando"
    mkdir -p ${VPS_SN}/install
  fi
  
  cd ~
  chmod -R 755 ${VPS_SN}
  
  msg -azu "Limpiando comandos antiguos..."
  rm -rf /usr/bin/menu /usr/bin/adm /usr/bin/VPS-SN 2>/dev/null
  msg -verd "OK"
  
  msg -azu "Guardando slogan..."
  echo "$slogan" > ${VPS_SN}/tmp/message.txt
  msg -verd "OK"
  
  msg -azu "Creando comandos de usuario..."
  echo "${VPS_SN}/menu" > /usr/bin/menu && chmod +x /usr/bin/menu
  echo "${VPS_SN}/menu" > /usr/bin/adm && chmod +x /usr/bin/adm
  echo "${VPS_SN}/menu" > /usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  msg -verd "OK"
  
  msg -azu "Configurando .bashrc..."
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
  msg -verd "OK"
  
  msg -azu "Estableciendo locale..."
  update-locale LANG=en_US.UTF-8 LANGUAGE=en 2>/dev/null
  msg -verd "OK"
  
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
  print_center -ama "A continuacion se actualizaran los paquetes del sistema.\nEsto podria tomar tiempo."
  msg -bar3
  
  echo -ne "\033[1;37m Desea continuar? [S/N]: "
  read -r opcion
  
  if [[ "$opcion" != @(s|S) ]]; then
    title "INSTALACION CANCELADA"
    exit 1
  fi
  
  title "INSTALADOR VPS-SN By @Sin_Nombre22"
  os_system
  
  msg -azu "Sistema detectado: $distro $vercion"
  
  msg -azu "Ejecutando: apt-get update -y"
  apt-get update -y >/dev/null 2>&1
  msg -verd "OK"
  
  msg -azu "Ejecutando: apt-get upgrade -y"
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1
  msg -verd "OK"
  
  msg -bar
  post_reboot
}

# FLUJO PRINCIPAL
case "${1:-}" in
  -s|--start)
    msg -azu "Iniciando instalación..."
    install_start
    time_reboot "15"
    ;;
    
  -c|--continue)
    msg -azu "Continuando instalación..."
    rm -f /root/install.sh 2>/dev/null
    sed -i '/VPS-SN/d' /root/.bashrc 2>/dev/null
    os_system
    dependencias
    install_VPS_SN
    msg -bar
    msg -verd "VPS-SN instalado exitosamente"
    time_reboot "10"
    ;;
    
  -u|--update)
    msg -azu "Actualizando VPS-SN..."
    install_start
    dependencias
    install_VPS_SN
    msg -bar
    msg -verd "VPS-SN actualizado exitosamente"
    time_reboot "10"
    ;;
    
  *)
    msg -azu "Ejecutando instalación directa..."
    install_start
    post_reboot
    time_reboot "15"
    ;;
esac

# Limpiar
rm -f $(pwd)/$0 2>/dev/null
mv -f ${module} /etc/VPS-SN/module 2>/dev/null

exit 0
