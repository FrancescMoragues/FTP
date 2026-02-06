#!/bin/bash

echo "Creant directori /var/erebor/anonim..."
mkdir -p /var/erebor/anonim
chown ftp:ftp /var/erebor/anonim
chmod 775 /var/erebor/anonim

USUARIS=("guimli" "eomer" "faramir" "sauron")
PASS_GENERICA="Erebor2024*"

echo "Creant usuaris i assignant permisos..."

for USUARI in "${USUARIS[@]}"; do
    
    if id "$USUARI" &>/dev/null; then
        echo "L'usuari $USUARI ja existeix."
    else
        useradd -m -s /bin/bash "$USUARI"
        echo "$USUARI:$PASS_GENERICA" | chpasswd
        echo "Usuari $USUARI creat correctament."
    fi

    if [[ "$USUARI" == "guimli" || "$USUARI" == "eomer" ]]; then
        usermod -aG ftp "$USUARI"

        chmod g+w /var/erebor/anonim
        echo "Permisos d'escriptura assignats a $USUARI per a /var/erebor/anonim"
    fi
done

echo "Configuració finalitzada."
echo "Contrasenya temporal per a tots: $PASS_GENERICA"
