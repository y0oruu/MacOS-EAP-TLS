#!/bin/bash

USER=$(who | grep tty | awk  '{print $1}' | head -n 1)
mkdir -p /Users/$USER/.802.1x/.profile
mv -f TEMPLATE.mobileconfig /Users/$USER/.802.1x/TEMPLATE.mobileconfig
cd /Users/$USER/.802.1x/

hostname=$(hostname)
NomOrdinateur=${hostname/.local/}.domain.intra
NomSansSuffixe=${NomOrdinateur/.domain.intra/}$

JENKINS_URL="url"
JOB_NAME="JOBNAME"
USERNAME="USER"
PASSWORD="PASS"
PARAMETERS="HOSTNAME=$NomOrdinateur"

jenkins_generate_pfx() {

    curl -k -X POST --silent -u "$USERNAME:$PASSWORD" --data-urlencode "$PARAMETERS" "$JENKINS_URL/job/$JOB_NAME/buildWithParameters" 
    echo "Genération du certificat en format PFX"
    sleep 40
    curl -k -O -J --silent -u "$USERNAME:$PASSWORD" "$JENKINS_URL/job/$JOB_NAME/lastSuccessfulBuild/artifact/$NomOrdinateur.pfx"
}

create_profile() {

    openssl base64 -in "${NomOrdinateur}.pfx" -out "${NomOrdinateur}.txt"

    autreFichier="TEMPLATE.mobileconfig"
    tempFile="temp.txt"

    inputFile="$NomOrdinateur.txt"
    while IFS= read -r line; do
        texteRemplacement="$texteRemplacement$line"
    done < "$inputFile"

    sed -e "s|%data%|${texteRemplacement}|g; s|%User%|${NomSansSuffixe}|g; s|%SSID%|${SSID}|g; s|%NomPC%|${NomOrdinateur}|g" "$autreFichier" > "$tempFile"

    # Renomme le fichier temporaire en tant que fichier mobileconfig
    mv -f "$tempFile" "${NomOrdinateur/.domain.intra/} - $SSID.mobileconfig"

    # Déplace le fichier mobileconfig dans le répertoire spécifié
    mv -f "${NomOrdinateur/.domain.intra/} - $SSID.mobileconfig" ".profile/${NomOrdinateur/.domain.intra/} - $SSID.mobileconfig"

    # Nettoie les fichiers temporaires
    rm -f "$inputFile"

    
    echo "Opération terminée."

    if profiles -P | grep -q "$NomOrdinateur";
    then
        echo "Le profil est déjà installé !"
    else
        echo "Le profil n'est pas installé. Installation du profil..."
        sudo open "/System/Library/PreferencePanes/Profiles.prefPane" "/Users/$USER/.802.1x/.profile/${NomOrdinateur/.domain.intra/ - $SSID.mobileconfig}"
    fi
}

renouvellement_certificat() {
    echo "Renouvellement du certificat !"
    jenkins_generate_pfx

    echo "Génération du nouveau certificat !"

    sudo security delete-certificate -c $NomOrdinateur
    echo "Suppression de l'ancien certificat !"

    sudo security import $NomOrdinateur.pfx -k /Users/$USER/Library/Keychains/login.keychain-db -P "passkey of the PFX file"
    echo "Importation du nouveau certificat !"
}

jenkins_generate_pfx
create_profile

