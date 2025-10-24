#!/bin/bash

# V2RAY Manager - Corregido y Verificado
# By @Sin_Nombre22

restart(){
	title "REINICIANDO V2RAY"
	if command -v v2ray &> /dev/null; then
		if v2ray restart 2>/dev/null | grep -q "success"; then
			print_center -verd "v2ray restart success !"
		else
			print_center -verm2 "v2ray restart fail !"
		fi
	else
		print_center -verm2 "v2ray no instalado"
	fi
	msg -bar
	sleep 3
}

ins_v2r(){
	title "INSTALANDO V2RAY"
	print_center -ama "La instalacion puede tener fallas!\nObserve atentamente el log de instalacion.\nPodría contener información sobre errores!"
	enter
	
	if source <(curl -sSL https://raw.githubusercontent.com/SINNOMBRE22/VPS-SN/main/utilidades/v2ray/v2ray.sh) 2>/dev/null; then
		msg -verd "V2RAY Instalado correctamente"
	else
		msg -verm2 "Error instalando V2RAY"
	fi
	enter
}

v2ray_tls(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		print_center -ama "Instale v2ray primero"
		msg -bar
		enter
		return
	fi

	title "CERTIFICADO TLS V2RAY"
	if v2ray tls 2>/dev/null; then
		msg -verd "Certificado configurado"
	else
		msg -verm2 "Error configurando certificado"
	fi
	enter
}

removeV2Ray(){
	title "DESINSTALANDO V2RAY"
	print_center -ama "Esto puede tomar un tiempo..."
	
	bash <(curl -L -s https://multi.netlify.app/go.sh) --remove >/dev/null 2>&1
	rm -rf /etc/v2ray >/dev/null 2>&1
	rm -rf /var/log/v2ray >/dev/null 2>&1
	
	bash <(curl -L -s https://multi.netlify.app/go.sh) --remove -x >/dev/null 2>&1
	rm -rf /etc/xray >/dev/null 2>&1
	rm -rf /var/log/xray >/dev/null 2>&1
	
	pip uninstall v2ray_util -y >/dev/null 2>&1
	
	clear
	msg -bar
	print_center -verd "V2RAY REMOVIDO!"
	enter
	return 1
}

v2ray_stream(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "PROTOCOLOS V2RAY"
	v2ray stream
	msg -bar
	read foo
}

port(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "CONFIGURAR PUERTO V2RAY"
	print_center -azu "Puerto actual: $(jq -r '.inbounds[].port' /etc/v2ray/config.json 2>/dev/null || echo 'desconocido')"
	msg -bar
	msg -ne " Nuevo puerto: "
	read puerto
	
	if [[ $puerto =~ ^[0-9]+$ ]] && [ $puerto -gt 0 ] && [ $puerto -lt 65535 ]; then
		jq --argjson p $puerto '.inbounds[].port = $p' /etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /etc/v2ray/config.json
		restart
		msg -verd "Puerto actualizado a $puerto"
	else
		msg -verm2 "Puerto inválido"
	fi
	enter
}

alterid(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "CONFIGURAR ALTERID V2RAY"
	print_center -azu "AlterId actual: $(jq -r '.inbounds[].settings.clients[0].alterId' /etc/v2ray/config.json 2>/dev/null || echo 'desconocido')"
	msg -bar
	msg -ne " Nuevo alterId: "
	read alterid
	
	if [[ $alterid =~ ^[0-9]+$ ]]; then
		jq --argjson a $alterid '.inbounds[].settings.clients[].alterId = $a' /etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /etc/v2ray/config.json
		restart
		msg -verd "AlterId actualizado a $alterid"
	else
		msg -verm2 "AlterId inválido"
	fi
	enter
}

n_v2ray(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "CONFIGURACION NATIVA V2RAY"
	v2ray
	enter
}

address(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "CONFIGURAR ADDRESS V2RAY"
	current=$(jq -r '.inbounds[].domain' /etc/v2ray/config.json 2>/dev/null || echo $(wget -qO- ipv4.icanhazip.com))
	print_center -azu "Address actual: $current"
	msg -bar
	msg -ne " Nuevo address: "
	read addr
	
	if [[ ! -z "$addr" ]]; then
		jq --arg a "$addr" '.inbounds[].domain = $a' /etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /etc/v2ray/config.json
		restart
		msg -verd "Address actualizado a $addr"
	else
		msg -verm2 "Address vacío"
	fi
	enter
}

host(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "CONFIGURAR HOST V2RAY"
	current=$(jq -r '.inbounds[].streamSettings.wsSettings.headers.Host' /etc/v2ray/config.json 2>/dev/null || echo "desconocido")
	print_center -azu "Host actual: $current"
	msg -bar
	msg -ne " Nuevo host: "
	read host
	
	if [[ ! -z "$host" ]]; then
		jq --arg h "$host" '.inbounds[].streamSettings.wsSettings.headers.Host = $h' /etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /etc/v2ray/config.json
		restart
		msg -verd "Host actualizado a $host"
	else
		msg -verm2 "Host vacío"
	fi
	enter
}

path(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "CONFIGURAR PATH V2RAY"
	current=$(jq -r '.inbounds[].streamSettings.wsSettings.path' /etc/v2ray/config.json 2>/dev/null || echo "/")
	print_center -azu "Path actual: $current"
	msg -bar
	msg -ne " Nuevo path: "
	read path
	
	if [[ ! -z "$path" ]]; then
		jq --arg p "$path" '.inbounds[].streamSettings.wsSettings.path = $p' /etc/v2ray/config.json > /tmp/config.json && mv /tmp/config.json /etc/v2ray/config.json
		restart
		msg -verd "Path actualizado a $path"
	else
		msg -verm2 "Path vacío"
	fi
	enter
}

reset(){
	if ! command -v v2ray &> /dev/null; then
		title "ERROR"
		print_center -verm2 "v2ray no está instalado"
		msg -bar
		enter
		return
	fi

	title "RESTAURAR AJUSTES V2RAY"
	print_center -ama "¿Está seguro de restaurar ajustes por defecto? [S/N]"
	read confirm
	
	if [[ "$confirm" = @(s|S) ]]; then
		v2ray new
		msg -verd "Ajustes restaurados"
		restart
	else
		msg -ama "Operación cancelada"
	fi
	enter
}

while :
do
	clear
	msg -bar
	print_center -verd "v2ray manager by @Sin_Nombre22"
	msg -bar
	msg -ama "INSTALACION"
	msg -bar3
	menu_func "$(msg -verd "INSTALL/RE-INSTALL V2RAY")" \
	"$(msg -verm2 "DESINSTALAR V2RAY")\n$(msg -bar3)\n$(msg -ama "CONFIGURACION")\n$(msg -bar3)" \
	"Certificado SSL/TLS" \
	"Protocolos" \
	"Puerto" \
	"AlterId" \
	"Configuración nativa\n$(msg -bar3)\n$(msg -ama "CLIENTES")\n$(msg -bar3)" \
	"Address" \
	"Host" \
	"Path\n$(msg -bar3)\n$(msg -ama "EXTRAS")\n$(msg -bar3)" \
	"Restablecer ajustes"
	back
	opcion=$(selection_fun 12)
	case $opcion in
		1)ins_v2r;;
		2)removeV2Ray;;
		3)v2ray_tls;;
		4)v2ray_stream;;
		5)port;;
		6)alterid;;
		7)n_v2ray;;
		8)address;;
		9)host;;
		10)path;;
		11)reset;;
		0)break;;
	esac
	[[ "$?" = "1" ]] && break
done
return 1
