#!/bin/bash

module="$(pwd)/module"
rm -rf ${module}
wget -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module" &>/dev/null
[[ ! -e ${module} ]] && exit
chmod +x ${module} &>/dev/null
source ${module}

CTRL_C(){
  rm -rf ${module}; exit
}

if [[ ! $(id -u) = 0 ]]; then
  clear
  msg -bar
  print_center -ama "ERROR DE EJECUCION"
  msg -bar
  print_center -ama "DEVE EJECUTAR DESDE EL USUARIO ROOT"
  msg -bar
  CTRL_C
fi

trap "CTRL_C" INT TERM EXIT

VPS_SN="/etc/VPS-SN" && [[ ! -d ${VPS_SN} ]] && mkdir ${VPS_SN}
VPS_inst="${VPS_SN}/install" && [[ ! -d ${VPS_inst} ]] && mkdir ${VPS_inst}
tmp="${VPS_SN}/tmp" && [[ ! -d ${tmp} ]] && mkdir ${tmp}
SCPinstal="$HOME/install"

cp -f $0 ${VPS_SN}/install.sh
rm $(pwd)/$0 &> /dev/null

stop_install(){
  title "INSTALACION CANCELADA"
  exit
}

time_reboot(){
  print_center -ama "EL MENU ESTARA INSTALADO DESPUES DE LA INSTALACION"
  REBOOT_TIMEOUT="$1"

  while [ $REBOOT_TIMEOUT -gt 0 ]; do
     print_center -ne "-$REBOOT_TIMEOUT-\r"
     sleep 1
     : $((REBOOT_TIMEOUT--))
  done
  reboot
}

repo_install(){
  link="https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Repositorios/$VERSION_ID.list"
  case $VERSION_ID in
    8*|9*|10*|11*|16.04*|18.04*|20.04*|20.10*|21.04*|21.10*|22.04*) [[ ! -e /etc/apt/sources.list.back ]] && cp /etc/apt/sources.list /etc/apt/sources.list.back
                                                                    wget -O /etc/apt/sources.list ${link} &>/dev/null;;
  esac
}

dependencias(){
  soft="sudo bsdmainutils zip unzip ufw curl python python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat sqlite3 libsqlite3-dev locales"

  msg -bar3
  print_center -verd "INSTALANDO TODAS LAS DEPENDENCIAS"
  msg -bar3
  
  if apt install $soft -y &>/dev/null ; then
    print_center -verd "TODAS LAS DEPENDENCIAS INSTALADAS CORRECTAMENTE"
  else
    print_center -verm "ALGUNAS DEPENDENCIAS FALLARON. INTENTANDO REPARAR..."
    dpkg --configure -a &>/dev/null
    apt -f install -y &>/dev/null
    if apt install $soft -y --fix-missing &>/dev/null ; then
      print_center -verd "DEPENDENCIAS INSTALADAS DESPUES DE REPARACION"
    else
      print_center -verm "ALGUNAS DEPENDENCIAS SIGUEN FALLANDO. PUEDES INSTALARLAS MANUALMENTE CON: apt install <paquete>"
    fi
  fi
}

verificar_arq(){
  unset ARQ
  case $1 in
    menu|chekup.sh|bashrc)ARQ="${VPS_SN}";;
    VPS-SN)ARQ="/usr/bin";;
    message.txt)ARQ="${tmp}";;
    *)ARQ="${VPS_inst}";;
  esac
  mv -f ${SCPinstal}/$1 ${ARQ}/$1
  chmod +x ${ARQ}/$1
}

error_fun(){
  msg -bar3
  print_center -verm "Falla al descargar $1"
  print_center -ama "Reportar con el administrador"
  msg -bar3
  [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
  exit
}

post_reboot(){
  echo 'clear; sleep 2; /etc/VPS-SN/install.sh --continue' >> /root/.bashrc
  title "INSTALADOR VPS-SN"
  print_center -ama "La instalacion continuara\ndespues del reinicio!!!"
  msg -bar
}

install_start(){
  title "INSTALADOR VPS-SN"
  print_center -ama "A continuacion se actualizaran los paquetes\ndel sistema. Esto podria tomar tiempo,\ny requerir algunas preguntas\npropias de las actualizaciones."
  msg -bar3
  read -rp "$(msg -verm2 " Desea continuar? [S/N]:") " -e -i S opcion
  [[ "$opcion" != @(s|S) ]] && stop_install
  title "INSTALADOR VPS-SN"
  repo_install
  apt update -y; apt upgrade -y
}

install_continue(){
  title "INSTALADOR VPS-SN"
  print_center -ama "$PRETTY_NAME"
  dependencias
  msg -bar3
  print_center -azu "Removiendo paquetes obsoletos"
  apt autoremove -y &>/dev/null
  sleep 2
}

source /etc/os-release; export PRETTY_NAME

while :
do
  case $1 in
    -s|--start)install_start; post_reboot; time_reboot "15";;
    -c|--continue)sed -i '/VPS-SN/d' /root/.bashrc
                  install_continue
                  break;;
    -u|--update)install_start
                rm -rf /etc/VPS-SN/tmp/style
                install_continue
                break;;
    -t|--test)break;;
    *)exit;;
  esac
done

title "INSTALADOR VPS-SN"

cd $HOME

arch='menu
chekup.sh
bashrc'

lisArq="https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main"

ver=$(curl -sSL "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/vercion")
echo "$ver" > ${VPS_SN}/vercion

title -ama '[Proyecto by @Sin_Nombre22]'
print_center -ama 'INSTALANDO SCRIPT VPS-SN'
sleep 2

[[ ! -d ${SCPinstal} ]] && mkdir ${SCPinstal}
print_center -ama 'Descarga de archivos.....'

for arqx in $(echo $arch); do
  wget -O ${SCPinstal}/${arqx} ${lisArq}/${arqx} > /dev/null 2>&1 && {
    verificar_arq "${arqx}"
  } || {
    print_center -verm2 'Instalacion fallida de $arqx'
    sleep 2s
    error_fun "${arqx}"
  }
done

print_center -verd 'Instalacion completa'
sleep 2s
rm $HOME/lista-arq
[[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
rm -rf /usr/bin/menu
rm -rf /usr/bin/adm
ln -s /usr/bin/VPS-SN /usr/bin/menu
ln -s /usr/bin/VPS-SN /usr/bin/adm
echo "Sin_Nombre22" > ${VPS_SN}/tmp/message.txt
sed -i '/VPS-SN/d' /etc/bash.bashrc
sed -i '/VPS-SN/d' /root/.bashrc
echo '[[ -e /etc/VPS-SN/bashrc ]] && source /etc/VPS-SN/bashrc' >> /etc/bash.bashrc
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LANGUAGE=en LC_ALL=en_US.UTF-8
echo -e "LANG=en_US.UTF-8\nLANGUAGE=en\nLC_ALL=en_US.UTF-8" > /etc/default/locale
[[ ! $(cat /etc/shells|grep "/bin/false") ]] && echo -e "/bin/false" >> /etc/shells
clear
title "-- VPS-SN INSTALADO --"

mv -f ${module} /etc/VPS-SN/module
time_reboot "5"
