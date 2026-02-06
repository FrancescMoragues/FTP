#!/bin/bash

# ==========================================
# 1. VARIABLES Y DEFINICIONES (Pas 1)
# ==========================================
# IP Servidor: 192.168.3.78 (ejemplo)
# Red: 192.168.3.0/24
DOMINIO="ftp.intranet.kuy.com"

# Usuarios (3 engabiats, 3 no engabiats)
USERS_ENGABIATS=("user_en1" "user_en2" "user_en3")
USERS_NO_ENGABIATS=("user_no1" "user_no2" "user_no3")
ALL_USERS=("${USERS_ENGABIATS[@]}" "${USERS_NO_ENGABIATS[@]}")

DIR_ANON="/srv/ftp/anonim" # Directorio compartido (Pas 1 y 4)
PASS="1234"

# ==========================================
# 2. INSTALACIÓN (Pas 1)
# ==========================================
sudo apt update && sudo apt install vsftpd -y

# ==========================================
# 3. CREACIÓN DE USUARIOS (Pas 3)
# ==========================================
# Crear grupo para usuarios no engabiados
sudo groupadd ftp_no_engabieds

for user in "${ALL_USERS[@]}"; do
    sudo useradd -m -s /bin/bash "$user"
    echo "$user:$PASS" | sudo chpasswd
done

# Añadir los no engabiados al grupo especial
for user in "${USERS_NO_ENGABIATS[@]}"; do
    sudo usermod -aG ftp_no_engabieds "$user"
done

# ==========================================
# 4. DIRECTORIOS Y PERMISOS (Pas 2 y 4)
# ==========================================
sudo mkdir -p $DIR_ANON

# Permisos Anónimos: lectura para todos
sudo chown root:root $DIR_ANON
sudo chmod 755 $DIR_ANON

# Permisos Escritura: Solo para el grupo de no engabiados
sudo chgrp ftp_no_engabieds $DIR_ANON
sudo chmod 775 $DIR_ANON

# ==========================================
# 5. CONFIGURACIÓN VSFTPD (Pas 4 y 5)
# ==========================================
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

sudo bash -c "cat <<EOF > /etc/vsftpd.conf
# Configuración Básica
listen=YES
local_enable=YES
write_enable=YES
local_umask=022

# Configuración Anónima (Pas 2)
anonymous_enable=YES
anon_root=$DIR_ANON
no_anon_password=YES

# Configuración de Engabieds (Pas 4)
chroot_local_user=YES
allow_writeable_chroot=YES
chroot_list_enable=YES
# Los usuarios en esta lista NO serán engabiados
chroot_list_file=/etc/vsftpd.chroot_list

# Mensajes (Pas 1 y 5)
ftpd_banner=Benvingut al servei FTP de Kuy G8 - Intranet.
dirmessage_enable=YES
EOF"

# Crear la lista de usuarios NO engabiados
for user in "${USERS_NO_ENGABIATS[@]}"; do
    echo "$user" | sudo tee -a /etc/vsftpd.chroot_list
done

# ==========================================
# 6. MENSAJES PERSONALIZADOS (Pas 5)
# ==========================================
for user in "${ALL_USERS[@]}"; do
    echo "Hola $user, benvingut al teu espai personal." | sudo tee /home/$user/.message
done

# ==========================================
# 7. REINICIO Y COMPROBACIÓN (Pas 6)
# ==========================================
sudo systemctl restart vsftpd
echo "✅ Servidor FTP de Intranet configurado según la guía."
