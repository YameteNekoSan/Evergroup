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

# Function to handle errors
handle_error() {
  echo -e "\e[1;31m[!] $1 \e[0m"
  exit 1
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
  handle_error "Script requires to be ran as root. Please rerun using sudo."
fi

echo "[+] Verifying supported CPU"
if ! lscpu | grep -iq avx; then
  handle_error "Your CPU does not support AVX. MongoDB 5.0+ requires an AVX supported CPU."
fi

# Check if required commands are available
command -v curl >/dev/null 2>&1 || handle_error "curl is required but it's not installed."
command -v wget >/dev/null 2>&1 || handle_error "wget is required but it's not installed."
command -v dpkg >/dev/null 2>&1 || handle_error "dpkg is required but it's not installed."

# Install OpenJDK 8 JRE
echo "[+] Install of OpenJDK 8 JRE"
verbose "[~] Installing OpenJDK 8 JRE package"
apt-get -qq install openjdk-8-jre &> /dev/null
[ $? -ne 0 ] && handle_error "Failed to install OpenJDK 8 JRE."

# Install JSVC
echo "[+] Install of JSVC"
verbose "[~] Installing JSVC package"
apt-get -qq install jsvc &> /dev/null
[ $? -ne 0 ] && handle_error "Failed to install JSVC."

# Download the latest Omada Software Controller package
echo "[+] Download of the latest Omada Software Controller package"
OmadaPackageUrl=$(curl -fsSL https://support.omadanetworks.com/us/product/omada-software-controller/?resourceType=download | grep -oPi '<a[^>]*href="\K[^"]*Linux_x64.deb[^"]*' | head -n 1)
verbose "[~] Downloading Omada package from $OmadaPackageUrl"
wget -qP /tmp/ $OmadaPackageUrl
[ $? -ne 0 ] && handle_error "Failed to download Omada package."

# Install Omada Software Controller
OmadaPackageName=$(basename $OmadaPackageUrl)
echo "[+] Install of Omada Software Controller $(echo $OmadaPackageName | tr "_" "\n" | sed -n '4p')"
verbose "[~] Installing Omada package"
dpkg -i /tmp/$OmadaPackageName &> /dev/null
[ $? -ne 0 ] && handle_error "Failed to install Omada Software Controller."

# Clean up
verbose "[~] Cleaning up temporary files"
rm /tmp/$OmadaPackageName

# Display success message
hostIP=$(hostname -I | cut -f1 -d' ')
echo -e "\e[0;32m[~] Omada Software Controller has been successfully installed! :)\e[0m"
echo -e "\e[0;32m[~] Please visit https://${hostIP}:8043 to complete the initial setup wizard.\e[0m\n"