#!/bin/bash
# MULTI-SCRIPT - Instalador Unificado
# ACTUALIZADO EL 24-10-2025 -- By @Kalix1

clear && clear
module="$(pwd)/module"
rm -rf ${module}
wget -O ${module} "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/module" &>/dev/null
[[ ! -e ${module} ]] && exit
chmod +x ${module} &>/dev/null
source ${module}

CTRL_C() {
  rm -rf ${module}
  rm -rf /root/LATAM
  exit
}
trap "CTRL_C" INT TERM EXIT
rm $(pwd)/$0 &>/dev/null

#-- VERIFICAR ROOT
if [ $(whoami) != 'root' ]; then
  echo ""
  echo -e "\e[1;31m NECESITAS SER USER ROOT PARA EJECUTAR EL SCRIPT \n\n\e[97m                DIGITE: \e[1;32m sudo su\n"
  exit
fi

# ========== CONFIGURACIÓN DE PATHS ==========
VPS_SN="/etc/VPS-SN" && [[ ! -d ${VPS_SN} ]] && mkdir ${VPS_SN}
VPS_inst="${VPS_SN}/install" && [[ ! -d ${VPS_inst} ]] && mkdir ${VPS_inst}
SCPinstal="$HOME/install"

# ========== CONFIGURACIÓN DE ZONA HORARIA ==========
rm -rf /etc/localtime &>/dev/null
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime &>/dev/null

# ========== SISTEMA MEJORADO DE INSTALACIÓN DE DEPENDENCIAS ==========
install_package() {
    local package="$1"
    local max_attempts=2
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if apt-get install -y "$package" &>/dev/null; then
            echo -e "\e[1;92m ✅"
            return 0
        else
            if [ $attempt -eq $max_attempts ]; then
                echo -e "\e[1;91m ❌"
                return 1
            else
                echo -ne "\e[1;93m 🔄"
                sleep 2
                apt-get update &>/dev/null
            fi
        fi
        attempt=$((attempt + 1))
    done
}

dependencias() {
    clear
    title "=====>> ►►     VPS-SN SCRIPT     ◄◄ <<====="
    print_center -ama "-- INSTALACIÓN DE DEPENDENCIAS --"
    echo ""
    
    # Actualizar lista de paquetes
    print_center -azu "ACTUALIZANDO LISTA DE PAQUETES..."
    apt-get update &>/dev/null
    
    # Lista de paquetes a instalar
    local packages=(
        "sudo" "bsdmainutils" "zip" "screen" "unzip" "ufw" "curl" 
        "python3" "python3-pip" "openssl" "cron" "iptables" "lsof" 
        "pv" "boxes" "at" "mlocate" "gawk" "bc" "jq" "npm" "nodejs" 
        "socat" "netcat" "netcat-traditional" "net-tools" "cowsay" 
        "figlet" "lolcat" "apache2"
    )
    
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        echo -ne "\e[1;97m Instalando: \e[1;96m$package\e[0m"
        if ! install_package "$package"; then
            failed_packages+=("$package")
        fi
    done
    
    # Mostrar resumen
    echo ""
    if [ ${#failed_packages[@]} -eq 0 ]; then
        print_center -verd "TODAS LAS DEPENDENCIAS SE INSTALARON CORRECTAMENTE"
    else
        print_center -verm "ALGUNOS PAQUETES NO SE PUDIERON INSTALAR:"
        for failed in "${failed_packages[@]}"; do
            echo -e "\e[1;91m   $failed"
        done
        echo ""
        print_center -ama "Se reintentarán los paquetes fallidos..."
        
        # Reintentar paquetes fallidos
        local retry_failed=()
        for package in "${failed_packages[@]}"; do
            echo -ne "\e[1;97m Reintentando: \e[1;96m$package\e[0m"
            if install_package "$package"; then
                echo -e "\e[1;92m ✅ (Reintento exitoso)"
            else
                retry_failed+=("$package")
            fi
        done
        
        if [ ${#retry_failed[@]} -gt 0 ]; then
            echo ""
            print_center -verm "PAQUETES QUE NO SE PUDIERON INSTALAR:"
            for failed in "${retry_failed[@]}"; do
                echo -e "\e[1;91m   $failed"
            done
        fi
    fi
    
    echo ""
    print_center -azu "FINALIZANDO INSTALACIÓN DE DEPENDENCIAS"
    sleep 2
}

# ========== FUNCIONES PRINCIPALES ==========
os_system() {
  system=$(cat -n /etc/issue | grep 1 | cut -d ' ' -f6,7,8 | sed 's/1//' | sed 's/      //')
  distro=$(echo "$system" | awk '{print $1}')

  case $distro in
  Debian) vercion=$(echo $system | awk '{print $3}' | cut -d '.' -f1) ;;
  Ubuntu) vercion=$(echo $system | awk '{print $2}' | cut -d '.' -f1,2) ;;
  esac
}

## PRIMER PASO DE INSTALACION
install_inicial() {
  clear && clear
  #--VERIFICAR IP MANUAL
  tu_ip() {
    echo ""
    echo -ne "\e[1;96m #Digite tu IP Publica (IPV4): \e[32m" && read IP
    val_ip() {
      local ip=$IP
      local stat=1
      if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
      fi
      return $stat
    }
    if val_ip $IP; then
      echo "$IP" >/root/.ssh/authrized_key.reg
    else
      echo ""
      echo -e "\e[31mLa IP Digitada no es valida, Verifiquela"
      echo ""
      sleep 5s
      tu_ip
    fi
  }
  
  #CONFIGURAR SSH-ROOT PRINCIPAL
  pass_root() {
    wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Herramientas-main/module/sshd_config >/dev/null 2>&1
    chmod +rwx /etc/ssh/sshd_config
    service ssh restart
    title "CONFIGURACIÓN DE CONTRASEÑA ROOT"
    echo -ne "\e[1;97m DIGITE NUEVA CONTRASEÑA:  \e[1;31m" && read pass
    (
      echo $pass
      echo $pass
    ) | passwd root 2>/dev/null
    sleep 1s
    print_center -verd "CONTRASEÑA AGREGADA O EDITADA CORRECTAMENTE"
    echo -e "\e[1;97m TU CONTRASEÑA ROOT AHORA ES: \e[41m $pass \e[0;37m"
  }
  
  #-- VERIFICAR VERSION
  v1=$(curl -sSL "https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/Vercion")
  echo "$v1" >/etc/version_instalacion
  v22=$(cat /etc/version_instalacion)
  
  #-- CONFIGURACION BASICA
  os_system
  title "=====>> ►►     VPS-SN SCRIPT     ◄◄ <<====="
  print_center -ama "   PREPARANDO INSTALACIÓN | VERSION: $v22"
  
  ## PAQUETES PRINCIPALES
  echo ""
  print_center -azu "🔎 IDENTIFICANDO SISTEMA OPERATIVO"
  print_center -verd "| $distro $vercion |"
  echo ""
  print_center -azu "◽️ DESACTIVANDO PASS ALFANUMERICO"
  
  [[ $(dpkg --get-selections | grep -w "libpam-cracklib" | head -1) ]] || apt-get install libpam-cracklib -y &>/dev/null
  echo -e '# Modulo Pass Simple
password [success=1 default=ignore] pam_unix.so obscure sha512
password requisite pam_deny.so
password required pam_permit.so' >/etc/pam.d/common-password && chmod +x /etc/pam.d/common-password
  service ssh restart >/dev/null 2>&1
  echo ""
  
  fun_ip() {
    TUIP=$(curl -s ifconfig.me)
    echo "$TUIP" >/root/.ssh/authrized_key.reg
    print_center -ama "¿ESTA ES TU IP PÚBLICA? $TUIP"
    echo ""
    print_center -ama "Seleccione [S/N]: "
    read -n 1 tu_ip
    [[ "$tu_ip" = "n" || "$tu_ip" = "N" ]] && tu_ip
  }
  fun_ip
  
  title "AGREGAR Y EDITAR PASS ROOT"
  print_center -ama "¿CAMBIAR PASS ROOT?"
  echo ""
    print_center -ama "Seleccione [S/N]: "
    read -n 1 pass_root_input
  [[ "$pass_root_input" = "s" || "$pass_root_input" = "S" ]] && pass_root
  
  print_center -ama "SE PROCEDERA A INSTALAR LAS ACTUALIZACIONES"
  print_center -ama "ESTE PROCESO PUEDE TARDAR VARIOS MINUTOS"
  print_center -ama "Y PUEDE PEDIR ALGUNAS CONFIRMACIONES"
  echo ""
  read -t 120 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
  clear && clear
  apt update
  apt upgrade -y
  wget -O /usr/bin/install https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/install.sh &>/dev/null
  chmod +rwx /usr/bin/install
}

time_reboot() {
  clear && clear
  title "REINICIO DEL SISTEMA"
  print_center -ama "CONTINUARÁ INSTALACIÓN DESPUÉS DEL REBOOT"
  print_center -verd "O EJECUTE EL COMANDO: VPS-SN --continue"
  
  print_center -ama "REINICIANDO VPS EN $1 SEGUNDOS"
  REBOOT_TIMEOUT="$1"
  
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    print_center -ne "-$REBOOT_TIMEOUT-\r"
    sleep 1
    : $((REBOOT_TIMEOUT--))
  done
  reboot
}

install_paquetes() {
  clear && clear
  /bin/cp /etc/skel/.bashrc ~/
  title "=====>> ►►     VPS-SN SCRIPT     ◄◄ <<====="
  print_center -ama "-- INSTALACIÓN PAQUETES FALTANTES --"
  dependencias
  sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf >/dev/null 2>&1
  service apache2 restart >/dev/null 2>&1
  [[ $(sudo lsof -i :81) ]] || print_center -verm ">>> FALLO DE INSTALACIÓN EN APACHE <<<"
  [[ $(sudo lsof -i :81) ]] && print_center -verd "PUERTO APACHE ACTIVO CON EXITO"
  echo ""
  print_center -verd "REMOVIENDO PAQUETES OBSOLETOS - OK"
  apt autoremove -y &>/dev/null
  echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
  echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
  read -t 30 -n 1 -rsp $'\e[1;97m           Presiona Enter Para continuar\n'
}

# ========== INSTALACIÓN VPS-SN ==========
install_VPS_SN() {
  clear && clear
  title "INSTALACIÓN VPS-SN"
  print_center -ama "Digite su slogan: "
  read slogan
  tput cuu1 && tput dl1
  echo -e "$slogan"
  
  mkdir /etc/VPS-SN >/dev/null 2>&1
  mkdir /etc/VPS-SN/tmp >/dev/null 2>&1
  
  cd /etc
  print_center -azu "DESCARGANDO VPS-SN..."
  wget https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/VPS-SN.tar.xz >/dev/null 2>&1
  
  if [[ -e VPS-SN.tar.xz ]]; then
    tar -xf VPS-SN.tar.xz >/dev/null 2>&1
    rm -rf VPS-SN.tar.xz
  else
    mkdir -p /etc/VPS-SN/install
  fi
  
  cd
  chmod -R 755 /etc/VPS-SN
  
  rm -rf /usr/bin/menu
  rm -rf /usr/bin/adm
  rm -rf /usr/bin/VPS-SN
  
  echo "$slogan" >/etc/VPS-SN/tmp/message.txt
  echo "${VPS_SN}/menu" >/usr/bin/menu && chmod +x /usr/bin/menu
  echo "${VPS_SN}/menu" >/usr/bin/adm && chmod +x /usr/bin/adm
  echo "${VPS_SN}/menu" >/usr/bin/VPS-SN && chmod +x /usr/bin/VPS-SN
  
  [[ -z $(echo $PATH|grep "/usr/games") ]] && echo 'if [[ $(echo $PATH|grep "/usr/games") = "" ]]; then PATH=$PATH:/usr/games; fi' >> /etc/bash.bashrc
  echo '[[ $UID = 0 ]] && screen -dmS up /etc/VPS-SN/chekup.sh' >> /etc/bash.bashrc
  echo 'v=$(cat /etc/VPS-SN/vercion)' >> /etc/bash.bashrc
  echo '[[ -e /etc/VPS-SN/new_vercion ]] && up=$(cat /etc/VPS-SN/new_vercion) || up=$v' >> /etc/bash.bashrc
  echo -e "[[ \$(date '+%s' -d \$up) -gt \$(date '+%s' -d \$(cat /etc/VPS-SN/vercion)) ]] && v2=\"Nueva Vercion disponible: \$v >>> \$up\" || v2=\"Script Vercion: \$v\"" >> /etc/bash.bashrc
  echo '[[ -e "/etc/VPS-SN/tmp/message.txt" ]] && mess1="$(less /etc/VPS-SN/tmp/message.txt)"' >> /etc/bash.bashrc
  echo '[[ -z "$mess1" ]] && mess1="@Sin_Nombre22"' >> /etc/bash.bashrc
  echo 'clear && echo -e "\n$(figlet -f big.flf "  VPS-SN")\n        RESELLER : $mess1 \n\n   Para iniciar VPS-SN escriba:  menu \n\n   $v2\n\n"|lolcat' >> /etc/bash.bashrc

  update-locale LANG=en_US.UTF-8 LANGUAGE=en
  clear
  title "INSTALACIÓN COMPLETADA"
  print_center -verd ">> VPS-SN INSTALADO BY @Sin_Nombre22 <<"
  print_center -ama "COMANDO PRINCIPAL PARA ENTRAR AL PANEL"
  print_center -verd "menu"
}

# ========== SELECTOR DE INSTALACION ==========
while :; do
  case $1 in
  -s | --start)
    install_inicial && install_paquetes
    break
    ;;
  -c | --continue)
    install_paquetes
    break
    ;;
  -m | --menu)
    break
    ;;
  *) 
    # Si no hay argumentos, mostrar opciones
    title "VPS-SN INSTALADOR"
    print_center -ama "Opciones disponibles:"
    echo -e "\e[1;92m  -s, --start    \e[1;97m- Instalación inicial completa"
    echo -e "\e[1;92m  -c, --continue \e[1;97m- Continuar instalación después de reboot"
    echo -e "\e[1;92m  -m, --menu     \e[1;97m- Entrar al menu principal"
    exit ;;
  esac
done

# ========== INSTALAR VPS-SN AL FINAL ==========
install_VPS_SN

mv -f ${module} /etc/VPS-SN/module
time_reboot "5"
