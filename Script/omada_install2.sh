#!/bin/bash
#title           :install-omada-controller.sh
#description     :Installer for TP-Link Omada Software Controller
#supported       :Ubuntu 20.04, Ubuntu 22.04
#author          :monsn0
#contributors    :YameteNekoSan
#date            :2021-07-29
#updated         :2025-02-10

VERBOSE=0

# Function to print verbose messages
verbose() {
  if [ $VERBOSE -eq 1 ]; then
    echo -e "$1"
  fi
}

# Parse command line options
while getopts "v" option; do
  case $option in
    v)
      VERBOSE=1
      ;;
    *)
      echo "Usage: $0 [-v]"
      exit 1
      ;;
  esac
done

echo "---------------------------------------------"
echo "TP-Link Omada Software Controller - Installer"
echo "---------------------------------------------"

echo "[+] Verifying running as root"
if [ `id -u` -ne 0 ]; then
  echo -e "\e[1;31m[!] Script requires to be ran as root. Please rerun using sudo. \e[0m"
  exit 1
fi

echo "[+] Verifying supported CPU"
if ! lscpu | grep -iq avx; then
    echo -e "\e[1;31m[!] Your CPU does not support AVX. MongoDB 5.0+ requires an AVX supported CPU. \e[0m"
    exit 1
fi

echo "[+] Verifying supported OS"
OS=$(hostnamectl status | grep "Operating System" | sed 's/^[ \t]*//')
echo "[~] $OS"

if [[ $OS = *"Ubuntu 20.04"* ]]; then
    OsVer=focal
elif [[ $OS = *"Ubuntu 22.04"* ]]; then
    OsVer=jammy
else
    echo -e "\e[1;31m[!] Script currently only supports Ubuntu 20.04 or 22.04! \e[0m"
    exit 1
fi

echo "[+] Installing script prerequisites"
verbose "[~] Running apt-get update"
apt-get -qq update
verbose "[~] Installing gnupg, curl, and wget"
apt-get -qq install gnupg curl wget &> /dev/null

echo "[+] Importing the MongoDB 7.0 PGP key and creating the APT repository"
verbose "[~] Downloading MongoDB PGP key"
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
verbose "[~] Adding MongoDB repository to sources list"
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $OsVer/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list
verbose "[~] Running apt-get update"
apt-get -qq update

# Package dependencies
echo "[+] Installing MongoDB 7.0"
verbose "[~] Installing MongoDB package"
apt-get -qq install mongodb-org &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "\e[1;31m[!] Failed to install MongoDB. \e[0m"
  exit 1
fi

echo "[+] Installing OpenJDK 8 JRE (headless)"
verbose "[~] Installing OpenJDK 8 JRE package"
apt-get -qq install openjdk-8-jre-headless &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "\e[1;31m[!] Failed to install OpenJDK 8 JRE. \e[0m"
  exit 1
fi

echo "[+] Installing JSVC"
verbose "[~] Installing JSVC package"
apt-get -qq install jsvc &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "\e[1;31m[!] Failed to install JSVC. \e[0m"
  exit 1
fi

echo "[+] Downloading the latest Omada Software Controller package"
OmadaPackageUrl=$(curl -fsSL https://support.omadanetworks.com/us/product/omada-software-controller/?resourceType=download | grep -oPi '<a[^>]*href="\K[^"]*Linux_x64.deb[^"]*' | head -n 1)
verbose "[~] Downloading Omada package from $OmadaPackageUrl"
wget -qP /tmp/ $OmadaPackageUrl
if [ $? -ne 0 ]; then
  echo -e "\e[1;31m[!] Failed to download Omada package. \e[0m"
  exit 1
fi

echo "[+] Installing Omada Software Controller $(echo $(basename $OmadaPackageUrl) | tr "_" "\n" | sed -n '4p')"
verbose "[~] Installing Omada package"
dpkg -i /tmp/$(basename $OmadaPackageUrl) &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "\e[1;31m[!] Failed to install Omada Software Controller. \e[0m"
  exit 1
fi

# Clean up
verbose "[~] Cleaning up temporary files"
rm /tmp/$(basename $OmadaPackageUrl)

hostIP=$(hostname -I | cut -f1 -d' ')
echo -e "\e[0;32m[~] Omada Software Controller has been successfully installed! :)\e[0m"
echo -e "\e[0;32m[~] Please visit https://${hostIP}:8043 to complete the initial setup wizard.\e[0m\n"