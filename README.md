# MacOS-EAP-TLS
Bash script to automatically create 802.1x connexion in MacOS

The script calls a jenkins job to generate a certificate in PFX format. Next, the script get the certificate and put the data in a .MOBILECONFIG file called the "Template". 
When all the informations are entered in the Template.MOBILECONFIG file such as the data of the certificate, the SSID.. The template is no longer a template but the config file of the EAP-TLS connexion for this computer.
When all this is finished, the profile is installed.

All of this process is entirely automatic, the only part which is manual is to install the profile because Apple retired the feature to do it automatically.

You can modify this script as you wish, for example to not call the Jenkins job or anything else.
