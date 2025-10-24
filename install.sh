#!/bin/bash

# VPS-SN - Instalador Unificado
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 04:03:32 UTC

module="$(pwd)/module"
rm -rf ${module}
wget -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/module/module" &>/dev/null

if [[ ! -e ${module} ]]; then
  echo -e "\033[1;31m[ERROR] No se pudo descargar el módulo\033[0m"
  echo -e "\033[1;33mVerifique la URL del módulo\033[0m"
  exit 1
fi

chmod +x ${module} &>/dev/null
source ${module}

CTRL_C(){
  rm -rf ${module}; exit
}

trap "CTRL_C" INT TERM EXIT

VPS_SN="/etc/VPS-SN" && [[ ! -d ${VPS_SN} ]] && mkdir ${VPS_SN}
VPS_inst="${VPS_SN}/install" && [[ ! -d ${VPS_inst} ]] && mkdir ${VPS_inst}
SCPinstal="$HOME/install"

rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime &>/dev/null
rm $(pwd)/$0 &> /dev/null

stop_install(){
 	[[ -z $1 ]] && title "INSTALACION CANCELADA" || echo -e "\033[1;31mINSTALACION CANCELADA\033[0m"
 	exit
}

time_reboot(){
  [[ -z $(command -v print_center) ]] && echo "REINICIANDO VPS EN $1 SEGUNDOS" || print_center -ama "REINICIANDO VPS EN $1 SEGUNDOS"
  REBOOT_TIMEOUT="$1"
  
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
     [[ -z $(command -v print_center) ]] && echo -ne "-$REBOOT_TIMEOUT-\r" || print_center -ne "-$REBOOT_TIMEOUT-\r"
     sleep 1
     : $((REBOOT_TIMEOUT--))
  done
  reboot
}

os_system(){
  system=$(cat -n /etc/issue |grep 1 |cut -d ' ' -f6,7,8 |sed 's/1//' |sed 's/      //')
  distro=$(echo "$system"|awk '{print $1}')

  case $distro in
    Debian)vercion=$(echo $system|awk '{print $3}'|cut -d '.' -f1);;
    Ubuntu)vercion=$(echo $system|awk '{print $2}'|cut -d '.' -f1,2);;
  esac
}

repo(){
  link="https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Repositorios/$1.list"
  case $1 in
    8|9|10|11|16.04|18.04|20.04|20.10|21.04|21.10|22.04)
      echo -e "\033[1;36m[INFO] Descargando repositorio para $distro $1\033[0m"
      wget -O /etc/apt/sources.list ${link} &>/dev/null
      ;;
  esac
}

dependencias(){
	soft="sudo bsdmainutils zip unzip curl python python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq npm nodejs socat net-tools figlet lolcat git htop vim tmux psmisc"

	for i in $soft; do
		leng="${#i}"
		puntos=$(( 25 - $leng))
		pts=""
		for (( a = 0; a < $puntos; a++ )); do
			pts+="."
		done
		
		if [[ ! -z $(command -v msg) ]]; then
			msg -nazu "       instalando $i$(msg -ama "$pts")"
			if apt install $i -y &>/dev/null ; then
				msg -verd "INSTALL"
			else
				msg -verm2 "FAIL"
				sleep 2
				tput cuu1 && tput dl1
				echo -e "\033[1;36m[INFO] Aplicando fix a $i\033[0m"
				dpkg --configure -a &>/dev/null
				sleep 2
				tput cuu1 && tput dl1

				echo -ne "\033[1;33m       instalando $i$pts\033[0m"
				if apt install $i -y &>/dev/null ; then
					echo -e "\r\033[1;32m       instalando $i$pts[OK]\033[0m"
				else
					echo -e "\r\033[1;31m       instalando $i$pts[FAIL]\033[0m"
				fi
			fi
		else
			echo -ne "\033[1;33m       instalando $i$pts\033[0m"
			if apt install $i -y &>/dev/null ; then
				echo -e "\r\033[1;32m       instalando $i$pts[OK]\033[0m"
			else
				echo -e "\r\033[1;31m       instalando $i$pts[FAIL]\033[0m"
				sleep 1
				dpkg --configure -a &>/dev/null
				sleep 1
				
				echo -ne "\033[1;33m       reintentando $i$pts\033[0m"
				if apt install $i -y &>/dev/null ; then
					echo -e "\r\033[1;32m       reintentando $i$pts[OK]\033[0m"
				else
					echo -e "\r\033[1;31m       reintentando $i$pts[SKIP]\033[0m"
				fi
			fi
		fi
	done
}

post_reboot(){
  echo 'wget -O /root/install.sh "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh"; clear; sleep 2; chmod +x /root/install.sh; /root/install.sh --continue' >> /root/.bashrc
  [[ ! -z $(command -v title) ]] && title "INSTALADOR VPS-SN By @Sin_Nombre22" || echo -e "\033[1;36mINSTALADOR VPS-SN By @Sin_Nombre22\033[0m"
  [[ ! -z $(command -v print_center) ]] && print_center -ama "La instalacion continuara\ndespues del reinicio!!!" || echo -e "\033[1;33mLa instalacion continuara despues del reinicio!!!\033[0m"
  [[ ! -z $(command -v msg) ]] && msg -bar || echo "===================================================="
}

install_start(){
  [[ ! -z $(command -v title) ]] && title "INSTALADOR VPS-SN By @Sin_Nombre22" || echo -e "\033[1;36mINSTALADOR VPS-SN By @Sin_Nombre22\033[0m"
  [[ ! -z $(command -v print_center) ]] && print_center -ama "A continuacion se actualizaran los paquetes\ndel systema. Esto podria tomar tiempo,\ny requerir algunas preguntas\npropias de las actualizaciones." || echo -e "\033[1;33mA continuacion se actualizaran los paquetes del sistema...\033[0m"
  [[ ! -z $(command -v msg) ]] && msg -bar3 || echo "===================================================="
  
  echo -ne "\033[1;37m Desea continuar? [S/N]: "
  read opcion
  [[ "$opcion" != @(s|S) ]] && stop_install
  
  [[ ! -z $(command -v title) ]] && title "INSTALADOR VPS-SN By @Sin_Nombre22" || echo -e "\033[1;36mINSTALADOR VPS-SN By @Sin_Nombre22\033[0m"
  os_system
  
  echo -e "\033[1;36m[INFO] Detectado: $distro $vercion\033[0m"
  repo "${vercion}"
  
  echo -e "\033[1;36m[INFO] Actualizando repositorios...\033[0m"
  apt update -y >/dev/null 2>&1
  
  echo -e "\033[1;36m[INFO] Actualizando paquetes...\033[0m"
  apt upgrade -y >/dev/null 2>&1
}

install_continue(){
  os_system
  [[ ! -z $(command -v title) ]] && title "INSTALADOR VPS-SN By @Sin_Nombre22" || echo -e "\033[1;36mINSTALADOR VPS-SN By @Sin_Nombre22\033[0m"
  [[ ! -z $(command -v print_center) ]] && print_center -ama "$distro $vercion" || echo -e "\033[1;33m$distro $vercion\033[0m"
  [[ ! -z $(command -v print_center) ]] && print_center -verd "INSTALANDO DEPENDENCIAS" || echo -e "\033[1;32mINSTALANDO DEPENDENCIAS\033[0m"
  [[ ! -z $(command -v msg) ]] && msg -bar3 || echo "===================================================="
  
  dependencias
  
  [[ ! -z $(command -v msg) ]] && msg -bar3 || echo "===================================================="
  [[ ! -z $(command -v print_center) ]] && print_center -azu "Removiendo paquetes obsoletos" || echo -e "\033[1;36mRemoviendo paquetes obsoletos\033[0m"
  apt autoremove -y &>/dev/null
  sleep 2
  tput cuu1 && tput dl1 2>/dev/null
  
  [[ ! -z $(command -v print_center) ]] && print_center -ama "si algunas de las dependencias falla!!!\nal terminar, puede intentar instalar\nla misma manualmente usando el siguiente comando\napt install nom_del_paquete" || echo -e "\033[1;33mInstale manualmente si es necesario\033[0m"
  
  echo -e "\033[1;97m Presione ENTER para continuar... \033[0m"
  read
}

install_VPS_SN(){
  clear && clear
  [[ ! -z $(command -v msgi) ]] && msgi -bar2 || echo "===================================================="
  
  echo -ne "\033[1;97m Digite su slogan: \033[1;32m" && read slogan
  tput cuu1 && tput dl1 2>/dev/null
  echo -e "$slogan"
  
  [[ ! -z $(command -v msgi) ]] && msgi -bar2 || echo "===================================================="
  clear && clear
  
  mkdir -p /etc/VPS-SN/tmp >/dev/null 2>&1
  
  cd /etc
  echo -e "\033[1;36m[INFO] Descargando VPS-SN.tar.xz...\033[0m"
  wget -q https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz -O VPS-SN.tar.xz
  
  if [[ -e VPS-SN.tar.xz ]]; then
    echo -e "\033[1;32m[OK] Descarga exitosa\033[0m"
    echo -e "\033[1;36m[INFO] Extrayendo archivos...\033[0m"
    tar -xf VPS-SN.tar.xz >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
      echo -e "\033[1;32m[OK] Archivos extraidos\033[0m"
      rm -rf VPS-SN.tar.xz
    else
      echo -e "\033[1;31m[ERROR] Error extrayendo archivos\033[0m"
      mkdir -p /etc/VPS-SN/install
    fi
  else
    echo -e "\033[1;31m[ERROR] Fallo descarga, usando fallback\033[0m"
    mkdir -p /etc/VPS-SN/install
  fi
  
  cd
  chmod -R 755 /etc/VPS-SN 2>/dev/null
  
  rm -rf /usr/bin/menu 2>/dev/null
  rm -rf /usr/bin/adm 2>/dev/null
  rm -rf /usr/bin/VPS-SN 2>/dev/null
  
  echo "$slogan" >/etc/VPS-SN/tmp/message.txt
  echo "${VPS_SN}/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "${VPS_SN}/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "${VPS_SN}/menu" >/usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  
  [[ -z $(echo $PATH|grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >> /etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >> /etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion 2>/dev/null || echo "1.0.0")' >> /etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >> /etc/bash.bashrc
  echo -e "[[ \$(date '+%s' -d \$up) -gt \$(date '+%s' -d \$(cat /etc/VPS-SN/vercion 2>/dev/null)) ]] && v2=\"Nueva Vercion disponible: \$v >>> \$up\" || v2=\"Script Vercion: \$v\"" >> /etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(cat /etc/VPS-SN/tmp/message.txt)"' >> /etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >> /etc/bash.bashrc
  echo 'clear && echo -e "\n$(figlet -f big.flf "  VPS-SN")\n        RESELLER : $mess1 \n\n   Para iniciar VPS-SN escriba:  menu \n\n   $v2\n\n"|lolcat' >> /etc/bash.bashrc

  update-locale LANG=en_US.UTF-8 LANGUAGE=en 2>/dev/null
  
  clear
  [[ ! -z $(command -v title) ]] && title "-- VPS-SN INSTALADO BY @Sin_Nombre22 --" || echo -e "\033[1;32m-- VPS-SN INSTALADO BY @Sin_Nombre22 --\033[0m"
}

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
    *)exit;;
  esac
done

[[ ! -z $(command -v title) ]] && title "INSTALADOR VPS-SN By @Sin_Nombre22" || echo -e "\033[1;36mINSTALADOR VPS-SN By @Sin_Nombre22\033[0m"
install_VPS_SN

mv -f ${module} /etc/VPS-SN/module 2>/dev/null
time_reboot "10"
