#!/bin/bash
# VPS-SN - Instalador Unificado
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 01:24:22 UTC
# Configuración de módulos
module="$(pwd)/module"
rm -rf ${module}
wget -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module" &>/dev/null
[[ ! -e ${module} ]] && exit
chmod +x ${module} &>/dev/null
source ${module}

# Función para finalizar correctamente
CTRL_C() {
  rm -rf ${module}
  rm -rf /root/VPS-SN
  exit
}
trap "CTRL_C" INT TERM EXIT
rm $(pwd)/$0 &>/dev/null

# Verificar si es root
if [ $(whoami) != 'root' ]; then
  echo ""
  echo -e "\e[1;31m NECESITAS SER USER ROOT PARA EJECUTAR EL SCRIPT \n\n\e[97m                DIGITE: \e[1;32m sudo su\n"
  exit
fi

# Configuración de directorios VPS-SN
VPS_SN="/etc/VPS-SN" && [[ ! -d ${VPS_SN} ]] && mkdir ${VPS_SN}
VPS_inst="${VPS_SN}/install" && [[ ! -d ${VPS_inst} ]] && mkdir ${VPS_inst}
SCPinstal="$HOME/install"

# Zona horaria por defecto
rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Argentina/Tucuman /etc/localtime &>/dev/null
rm $(pwd)/$0 &> /dev/null

# Función para detener instalación
stop_install(){
  title "INSTALACION CANCELADA"
  exit
}

# Función de reinicio
time_reboot(){
  print_center -ama "REINICIANDO VPS EN $1 SEGUNDOS"
  REBOOT_TIMEOUT="$1"
  
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    print_center -ne "-$REBOOT_TIMEOUT-\r"
    sleep 1
    : $((REBOOT_TIMEOUT--))
  done
  reboot
}

# Detectar sistema operativo
os_system(){
  system=$(cat -n /etc/issue |grep 1 |cut -d ' ' -f6,7,8 |sed 's/1//' |sed 's/      //')
  distro=$(echo "$system"|awk '{print $1}')

  case $distro in
    Debian)vercion=$(echo $system|awk '{print $3}'|cut -d '.' -f1);;
    Ubuntu)vercion=$(echo $system|awk '{print $2}'|cut -d '.' -f1,2);;
  esac
}

# Configurar repositorios
repo(){
  link="https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Repositorios/$1.list"
  case $1 in
    8|9|10|11|16.04|18.04|20.04|20.10|21.04|21.10|22.04)wget -O /etc/apt/sources.list ${link} &>/dev/null;;
  esac
}

# Instalar dependencias
dependencias(){
  soft="sudo bsdmainutils zip unzip ufw curl python python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat"

  for i in $soft; do
    leng="${#i}"
    puntos=$(( 21 - $leng))
    pts="."
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    msg -nazu "       instalando $i$(msg -ama "$pts")"
    if apt install $i -y &>/dev/null ; then
      msg -verd "INSTALL"
    else
      msg -verm2 "FAIL"
      sleep 2
      tput cuu1 && tput dl1
      print_center -ama "aplicando fix a $i"
      dpkg --configure -a &>/dev/null
      sleep 2
      tput cuu1 && tput dl1

      msg -nazu "       instalando $i$(msg -ama "$pts")"
      if apt install $i -y &>/dev/null ; then
        msg -verd "INSTALL"
      else
        msg -verm2 "FAIL"
      fi
    fi
  done
}

# Instalar VPS-SN sin validación de KEY
install_VPS_SN() {
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
  
  [[ -z $(echo $PATH | grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >>/etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >>/etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion)' >>/etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >>/etc/bash.bashrc
  echo -e "[[ \$(date '+%s' -d \$up) -gt \$(date '+%s' -d \$(cat /etc/VPS-SN/vercion)) ]] && v2=\"Nueva Vercion disponible: \$v >>> \$up\" || v2=\"Script Vercion: \$v\"" >>/etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(less /etc/VPS-SN/tmp/message.txt)"' >>/etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >>/etc/bash.bashrc
  echo 'clear && echo -e "\n$(figlet -f big.flf "  VPS-SN")\n        RESELLER : $mess1 \n\n   Para iniciar VPS-SN escriba:  menu \n\n   $v2\n\n"|lolcat' >>/etc/bash.bashrc
  
  update-locale LANG=en_US.UTF-8 LANGUAGE=en
  clear && clear
  msgi -bar2
  echo -e "\e[1;92m             >> INSTALACION COMPLETADA <<" && msgi -bar2
  echo -e "      COMANDO PRINCIPAL PARA ENTRAR AL PANEL "
  echo -e "                      \033[1;41m  menu  \033[0;37m" && msgi -bar2
}

# Configurar reinicio con continuación
post_reboot(){
  echo 'wget -O /root/install.sh "https://raw.githubusercontent.com/rudi9999/VPS-SN/main/install.sh"; clear; sleep 2; chmod +x /root/install.sh; /root/install.sh --continue' >> /root/.bashrc
  title "INSTALADOR VPS-SN"
  print_center -ama "La instalacion continuara\ndespues del reinicio!!!"
  msg -bar
}

# Iniciar instalación
install_start(){
  title "INSTALADOR VPS-SN"
  print_center -ama "A continuacion se actualizaran los paquetes\ndel systema. Esto podria tomar tiempo,\ny requerir algunas preguntas\npropias de las actualizaciones."
  msg -bar3
  msg -ne " Desea continuar? [S/N]: "
  read opcion
  [[ "$opcion" != @(s|S) ]] && stop_install
  title "INSTALADOR VPS-SN"
  os_system
  repo "${vercion}"
  apt update -y; apt upgrade -y  
}

# Continuar instalación
install_continue(){
  os_system
  title "INSTALADOR VPS-SN"
  print_center -ama "$distro $vercion"
  print_center -verd "INSTALANDO DEPENDENCIAS"
  msg -bar3
  dependencias
  msg -bar3
  print_center -azu "Removiendo paquetes obsoletos"
  apt autoremove -y &>/dev/null
  sleep 2
  tput cuu1 && tput dl1
  print_center -ama "si algunas de las dependencias falla!!!\nal terminar, puede intentar instalar\nla misma manualmente usando el siguiente comando\napt install nom_del_paquete"
  enter
}

# Menú de opciones
while :
do
  case $1 in
    -s|--start)install_start && post_reboot && time_reboot "15";;
    -c|--continue)rm /root/install.sh &> /dev/null
                  sed -i '/VPS-SN/d' /root/.bashrc
                  install_continue
                  install_VPS_SN
                  break;;
    -u|--update)install_start
                install_continue
                install_VPS_SN
                break;;
    *)install_VPS_SN;;
  esac
done

# Fin del instalador
title "VPS-SN INSTALADO"
print_center -verd "Instalacion completada exitosamente"
msg -bar
time_reboot "10" 
