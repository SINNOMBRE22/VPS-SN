#!/bin/bash
# VPS-SN - Instalador Unificado para Ubuntu 22.04
# Proyecto: VPS-SN By @Sin_Nombre22
# Fecha: 2025-10-24 03:45:22 UTC
# Sistema: Ubuntu 22.04 LTS

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

# Zona horaria por defecto a Ciudad de México
rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime &>/dev/null
rm $(pwd)/$0 &> /dev/null

# Función para detener instalación
stop_install(){
  print_center -verm2 "INSTALACION CANCELADA"
  exit
}

# Función para pausar y esperar Enter
enter(){
  echo -e "\033[1;97m Presione ENTER para continuar... \033[0m"
  read
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

# Actualizar repositorios
update_repos(){
  echo -e "\033[1;36m Actualizando repositorios de Ubuntu 22.04...\033[0m"
  apt update -y >/dev/null 2>&1
  apt upgrade -y >/dev/null 2>&1
  echo -e "\033[1;32m ✓ Repositorios actualizados\033[0m"
}

# Instalar dependencias específicas para Ubuntu 22.04
dependencias_ubuntu_22(){
  # Paquetes básicos que SÍ existen en Ubuntu 22.04
  soft="sudo bsdmainutils zip unzip curl python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk grep bc jq git htop vim tmux psmisc wget net-tools socat"

  echo -e "\033[1;36m Instalando paquetes base...\033[0m"
  
  for i in $soft; do
    leng="${#i}"
    puntos=$(( 25 - $leng))
    pts=""
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    echo -ne "\033[1;33m instalando \033[1;36m$i\033[1;33m$pts\033[0m"
    
    if apt install -y $i &>/dev/null ; then
      echo -e "\r\033[1;33m instalando \033[1;36m$i\033[1;33m$pts\033[1;32m[OK]\033[0m"
    else
      echo -e "\r\033[1;33m instalando \033[1;36m$i\033[1;33m$pts\033[1;31m[FAIL]\033[0m"
      echo -e "\033[1;33m Intentando solucionar...\033[0m"
      dpkg --configure -a &>/dev/null
      sleep 1
      
      echo -ne "\033[1;33m reintentando \033[1;36m$i\033[1;33m$pts\033[0m"
      if apt install -y $i &>/dev/null ; then
        echo -e "\r\033[1;33m reintentando \033[1;36m$i\033[1;33m$pts\033[1;32m[OK]\033[0m"
      else
        echo -e "\r\033[1;33m reintentando \033[1;36m$i\033[1;33m$pts\033[1;31m[SKIP]\033[0m"
      fi
    fi
  done
  
  # Paquetes opcionales que pueden no estar disponibles
  echo -e "\n\033[1;36m Instalando paquetes opcionales...\033[0m"
  
  paquetes_opcionales="figlet lolcat cowsay npm nodejs netcat-openbsd ufw"
  
  for paq in $paquetes_opcionales; do
    leng="${#paq}"
    puntos=$(( 25 - $leng))
    pts=""
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    
    echo -ne "\033[1;33m instalando \033[1;36m$paq\033[1;33m$pts\033[0m"
    
    if apt install -y $paq &>/dev/null ; then
      echo -e "\r\033[1;33m instalando \033[1;36m$paq\033[1;33m$pts\033[1;32m[OK]\033[0m"
    else
      echo -e "\r\033[1;33m instalando \033[1;36m$paq\033[1;33m$pts\033[1;31m[OPTIONAL]\033[0m"
    fi
  done
  
  echo ""
  echo -e "\033[1;32m ✓ Instalación de dependencias completada\033[0m"
}

# Instalar VPS-SN sin validación de KEY
install_VPS_SN() {
  clear && clear
  msgi -bar2 2>/dev/null || echo "===================================================="
  echo -ne "\033[1;97m Digite su slogan: \033[1;32m" && read slogan
  tput cuu1 && tput dl1 2>/dev/null
  echo -e "$slogan"
  msgi -bar2 2>/dev/null || echo "===================================================="
  clear && clear
  
  mkdir -p /etc/VPS-SN/tmp >/dev/null 2>&1
  
  echo -e "\033[1;36m Iniciando descarga de archivos VPS-SN...\033[0m"
  
  cd /etc
  echo -ne "\033[1;33m Descargando VPS-SN.tar.xz...\033[0m"
  
  # Intentar descargar desde GitHub
  if wget -q https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz -O VPS-SN.tar.xz; then
    echo -e "\r\033[1;32m ✓ Descarga exitosa\033[0m"
    
    echo -ne "\033[1;33m Extrayendo archivos...\033[0m"
    if tar -xf VPS-SN.tar.xz >/dev/null 2>&1; then
      echo -e "\r\033[1;32m ✓ Archivos extraidos\033[0m"
      rm -rf VPS-SN.tar.xz
    else
      echo -e "\r\033[1;31m ✗ Error extrayendo archivos\033[0m"
      mkdir -p /etc/VPS-SN/install
    fi
  else
    echo -e "\r\033[1;31m ✗ Error en descarga, usando fallback\033[0m"
    mkdir -p /etc/VPS-SN/install
  fi
  
  cd
  chmod -R 755 /etc/VPS-SN
  
  # Limpiar comandos antiguos
  rm -rf /usr/bin/menu 2>/dev/null
  rm -rf /usr/bin/adm 2>/dev/null
  rm -rf /usr/bin/VPS-SN 2>/dev/null
  
  # Guardar slogan
  echo "$slogan" >/etc/VPS-SN/tmp/message.txt
  
  # Crear comandos de usuario
  echo "#!/bin/bash" > /usr/bin/menu
  echo "exec ${VPS_SN}/menu \"\$@\"" >> /usr/bin/menu
  chmod +x /usr/bin/menu
  
  cp /usr/bin/menu /usr/bin/adm
  cp /usr/bin/menu /usr/bin/VPS-SN
  
  # Configurar .bashrc
  echo "" >> /etc/bash.bashrc
  echo '# VPS-SN Configuration' >> /etc/bash.bashrc
  echo 'export PATH=$PATH:/usr/games' >> /etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >> /etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion 2>/dev/null || echo "1.0.0")' >> /etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >> /etc/bash.bashrc
  echo -e "[[ \$(date '+%s' -d \$up) -gt \$(date '+%s' -d \$(cat /etc/VPS-SN/vercion 2>/dev/null)) ]] && v2=\"Nueva Vercion disponible: \$v >>> \$up\" || v2=\"Script Vercion: \$v\"" >> /etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(cat /etc/VPS-SN/tmp/message.txt)"' >> /etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >> /etc/bash.bashrc
  echo 'clear && echo -e "\n\033[1;36m╔════════════════════════════════════╗\033[0m\n\033[1;36m║\033[1;32m       VPS-SN Panel Control\033[1;36m        ║\033[0m\n\033[1;36m╚════════════════════════════════════╝\033[0m\n\033[1;32m  RESELLER: $mess1\033[0m\n\n\033[1;33m  Para iniciar VPS-SN escriba: \033[1;32mmenu\033[0m\n\n\033[1;36m  $v2\033[0m\n\n"' >> /etc/bash.bashrc
  
  # Establecer locale
  update-locale LANG=en_US.UTF-8 LANGUAGE=en 2>/dev/null
  
  clear && clear
  msgi -bar2 2>/dev/null || echo "===================================================="
  echo -e "\e[1;92m             >> INSTALACION COMPLETADA <<" 
  msgi -bar2 2>/dev/null || echo "===================================================="
  echo -e "\033[1;36m      COMANDO PRINCIPAL PARA ENTRAR AL PANEL\033[0m"
  echo -e "                 \033[1;41m  menu  \033[0;37m"
  echo -e "\033[1;36m            Reseller: $slogan\033[0m"
  msgi -bar2 2>/dev/null || echo "===================================================="
}

# Configurar reinicio con continuación
post_reboot(){
  echo 'wget -q -O /root/install.sh "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh"; clear; sleep 2; chmod +x /root/install.sh; /root/install.sh --continue' >> /root/.bashrc
  print_center -aza "INSTALADOR VPS-SN" 2>/dev/null || echo "INSTALADOR VPS-SN"
  print_center -ama "La instalacion continuara\ndespues del reinicio!!!" 2>/dev/null || echo "Continuando tras reboot..."
  msg -bar 2>/dev/null || echo "===================================================="
}

# Iniciar instalación
install_start(){
  print_center -aza "INSTALADOR VPS-SN" 2>/dev/null || echo "INSTALADOR VPS-SN"
  print_center -ama "Sistema detectado: Ubuntu 22.04 LTS\n\nA continuacion se actualizaran los paquetes\ndel sistema. Esto podria tomar tiempo." 2>/dev/null
  msg -bar3 2>/dev/null || echo "===================================================="
  msg -ne " ¿Desea continuar? [S/N]: " 2>/dev/null || echo -n "¿Continuar? [S/N]: "
  read opcion
  [[ "$opcion" != @(s|S) ]] && stop_install
  
  update_repos
}

# Continuar instalación
install_continue(){
  os_system
  print_center -aza "INSTALADOR VPS-SN" 2>/dev/null || echo "INSTALADOR VPS-SN"
  print_center -ama "Sistema: Ubuntu 22.04 LTS" 2>/dev/null || echo "Ubuntu 22.04 LTS"
  print_center -verd "INSTALANDO DEPENDENCIAS" 2>/dev/null || echo "INSTALANDO DEPENDENCIAS"
  msg -bar3 2>/dev/null || echo "===================================================="
  
  dependencias_ubuntu_22
  
  msg -bar3 2>/dev/null || echo "===================================================="
  echo -e "\033[1;36m Realizando limpieza de paquetes obsoletos...\033[0m"
  apt autoremove -y &>/dev/null
  apt autoclean -y &>/dev/null
  echo -e "\033[1;32m ✓ Limpieza completada\033[0m"
  
  echo ""
  print_center -ama "Si alguna dependencia fallo, puede instalarla\nmanualmente con: apt install nombre_paquete" 2>/dev/null
  enter
}

# Menú de opciones principal
while :
do
  case $1 in
    -s|--start)install_start && post_reboot && time_reboot "15";;
    -c|--continue)
      rm /root/install.sh &> /dev/null
      sed -i '/VPS-SN/d' /root/.bashrc 2>/dev/null
      install_continue
      install_VPS_SN
      break
      ;;
    -u|--update)
      install_start
      install_continue
      install_VPS_SN
      break
      ;;
    *)install_VPS_SN;;
  esac
done

# Fin del instalador
clear
echo -e "\033[1;32m════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m      VPS-SN INSTALADO EXITOSAMENTE\033[0m"
echo -e "\033[1;32m════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;33m\n Comando para iniciar: \033[1;32mmenu\033[0m"
echo -e "\033[1;33m Reseller: \033[1;32m$slogan\033[0m\n"
msg -bar 2>/dev/null || echo "════════════════════════════════════════════════════"
time_reboot "10"
