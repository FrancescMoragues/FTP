#!/bin/bash

# ==========================================
# 1. VARIABLES (Ajustadas a IP 192.168.3.82)
# ==========================================
IP_SERVIDOR="192.168.3.82"
DIR_ANON="/srv/ftp/anonim"
USERS_ENGABIATS=("user_en1" "user_en2" "user_en3")
USERS_NO_ENGABIATS=("user_no1" "user_no2" "user_no3")
ALL_USERS=("${USERS_ENGABIATS[@]}" "${USERS_NO_ENGABIATS[@]}")
PASS="1234"

# ==========================================
# 2. INSTALACIÓN Y LIMPIEZA
# ==========================================
sudo apt update && sudo apt install vsftpd -y
sudo systemctl stop vsftpd

# ==========================================
# 3. USUARIOS Y GRUPOS (Pas 3 i 4 de la Guia)
# ==========================================
sudo groupadd -f ftp_no_engabieds

for user in "${ALL_USERS[@]}"; do
    # Borrar si ya existía para evitar errores de IP vieja
    sudo deluser --remove-home "$user" 2>/dev/null
    sudo useradd -m -s /bin/bash "$user"
    echo "$user:$PASS" | sudo chpasswd
done

# Asignar los no engabiados al grupo con permisos especiales
for user in "${USERS_NO_ENGABIATS[@]}"; do
    sudo usermod -aG ftp_no_engabieds "$user"
done

# ==========================================
# 4. DIRECTORIO ANÓNIMO Y COMPARTIDO (Pas 2 i 4)
# ==========================================
sudo mkdir -p $DIR_ANON
sudo chown root:root $DIR_ANON
sudo chmod 755 $DIR_ANON # Lectura para anónimos

# Permisos para que los NO engabiados escriban aquí
sudo chgrp ftp_no_engabieds $DIR_ANON
sudo chmod 775 $DIR_ANON 

# ==========================================
# 5. CONFIGURACIÓN VSFTPD.CONF
# ==========================================
sudo mv /etc/vsftpd.conf /etc/vsftpd.conf.old

sudo bash -c "cat <<EOF > /etc/vsftpd.conf
# Configuración Servidor $IP_SERVIDOR
listen=YES
local_enable=YES
write_enable=YES
local_umask=022

# Acceso Anónimo (Pas 2)
anonymous_enable=YES
anon_root=$DIR_ANON
no_anon_password=YES

# Gestión de Engabieds (Pas 4)
chroot_local_user=YES
allow_writeable_chroot=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot_list

# Mensajes (Pas 1 i 5)
ftpd_banner=Benvingut al servidor FTP de Kuy G8 (IP: $IP_SERVIDOR)
dirmessage_enable=YES

# Puertos Pasivos para el Cliente .76
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
EOF"

# Crear lista de excepciones (No engabiados)
printf "%s\n" "${USERS_NO_ENGABIATS[@]}" | sudo tee /etc/vsftpd.chroot_list

# ==========================================
# 6. MENSAJES POR USUARIO (Pas 5)
# ==========================================
for user in "${ALL_USERS[@]}"; do
    echo "Sessió iniciada correctament per a $user en el servidor $IP_SERVIDOR" | sudo tee /home/$user/.message
done

# ==========================================
# 7. REINICIO Y FIREWALL
# ==========================================
sudo ufw allow 21/tcp
sudo ufw allow 10000:10100/tcp
sudo systemctl restart vsftpd

echo "✅ FTP configurat a la nova IP $IP_SERVIDOR"
