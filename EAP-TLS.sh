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

jenkins_generate_pfx() { # using jenkins to generate our certificate !

    curl -k -X POST --silent -u "$USERNAME:$PASSWORD" --data-urlencode "$PARAMETERS" "$JENKINS_URL/job/$JOB_NAME/buildWithParameters" 
    echo "Generating the certificate in PFX format"
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

    # Rename the temporary file as the mobileconfig file
    mv -f "$tempFile" "${NomOrdinateur/.domain.intra/} - $SSID.mobileconfig"

    # Move the mobileconfig file to the specified directory
    mv -f "${NomOrdinateur/.domain.intra/} - $SSID.mobileconfig" ".profile/${NomOrdinateur/.domain.intra/} - $SSID.mobileconfig"

    # Clean up temporary files
    rm -f "$inputFile"

    
    echo "Operation completed."

    if profiles -P | grep -q "$NomOrdinateur";
    then
        echo "The profile is already installed!"
    else
        echo "The profile is not installed. Installing the profile..."
        sudo open "/System/Library/PreferencePanes/Profiles.prefPane" "/Users/$USER/.802.1x/.profile/${NomOrdinateur/.domain.intra/ - $SSID.mobileconfig}"
    fi
}

jenkins_generate_pfx
create_profile
