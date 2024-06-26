#!/bin/bash
set -euo pipefail

# ============================================================================================
# Source functions
source functions
# ============================================================================================


printf "\033c"
echo "==================================================================================="
echo "==================================================================================="
echo " _____  _      __ __         __ __  ____      ___ ___    ___  ___    ____   ____ "
echo "|     || |    |  |  |       |  |  ||    |    |   |   |  /  _]|   \  |    | /    |"
echo "|   __|| |    |  |  | _____ |  |  | |  |     | _   _ | /  [_ |    \  |  | |  o  |"
echo "|  |_  | |___ |  ~  ||     ||  _  | |  |     |  \_/  ||    _]|  D  | |  | |     |"
echo "|   _] |     ||___, ||_____||  |  | |  |     |   |   ||   [_ |     | |  | |  _  |"
echo "|  |   |     ||     |       |  |  | |  |     |   |   ||     ||     | |  | |  |  |"
echo "|__|   |_____||____/        |__|__||____|    |___|___||_____||_____||____||__|__|"
echo "===================================================="
echo "Welcome to Fly-Hi Media"
echo "Installation process should be really quick"
echo "We just need you to answer some questions"
echo "===================================================================================="
echo ""



# ============================================================================================
# Check all the prerequisites are installed before continuing
# ============================================================================================
echo "Checking prerequisites..."


check_dependencides "docker"
check_dependencides "docker-compose"

if docker-compose -v &> /dev/null; then
docker-compose -v

sleep 1
fi
if [[ "$EUID" = 0 ]]; then
    send_message_in_red "Fly-Hi has to run without sudo! Please, run it again with regular permissions"
fi

# ============================================================================================



# Setting the preferred media service
echo
echo
echo
echo "By default, Fly-Hi supports various self-hosted services:"
running_services_management
running_services_network
running_services_media
running_services_download
echo
send_message_in_orange "Unless you are sure your previous docker installation has properly setup"
send_message_in_orange "permissions for non-root users run permissions.sh script, otherwise continue!"
read -p "Would you like to continue? [Y/n]: " start
start=${start:-"y"}
if [[ "$start" =~ [nN] ]]; then
exit 0
fi
# ============================================================================================
# Gathering information
# ============================================================================================
send_message_in_blue "=============================================================================="
echo
send_message_in_green "First I will need some basic information about your system like the"
send_message_in_green "locations of your library folders, time-zone etc. that we will need"
send_message_in_green "to use throughout the installation process, so lets start!"
echo
send_message_in_blue "=============================================================================="
echo
read -p "Where Would you like to install the docker-compose and .env files? [/opt/fly-hi]: " install_location

# Checking if the install_location exists
install_location=${install_location:-/opt/fly-hi}
sudo mkdir -p $install_location # or whichever directory will be used as the root folder of you docker services
sudo chown -R $USER:$USER $install_location # or whichever directory will be used as the root folder of you docker services
[[ -f "$install_location" ]] || mkdir -p "$install_location" || send_message_in_red "There was an error with your install location! Make sure the directory exists and the user \"$USER\" has permissions on it"
[[ -f "$install_location/media" ]] || mkdir -p "$install_location/media" || send_message_in_red "There was an error with your install location! Make sure the directory exists and the user \"$USER\" has permissions on it"
[[ -f "$install_location/starrs" ]] || mkdir -p "$install_location/starrs" || send_message_in_red "There was an error with your install location! Make sure the directory exists and the user \"$USER\" has permissions on it"
[[ -f "$install_location/network" ]] || mkdir -p "$install_location/network" || send_message_in_red "There was an error with your install location! Make sure the directory exists and the user \"$USER\" has permissions on it"
[[ -f "$install_location/management" ]] || mkdir -p "$install_location/management" || send_message_in_red "There was an error with your install location! Make sure the directory exists and the user \"$USER\" has permissions on it"
[[ -f "$install_location/custom" ]] || mkdir -p "$install_location/custom" || send_message_in_red "There was an error with your install location! Make sure the directory exists and the user \"$USER\" has permissions on it"
install_location=$(realpath "$install_location")

compose_media="$install_location/media/docker-compose.yaml"
compose_starrs="$install_location/starrs/docker-compose.yaml"
compose_network="$install_location/network/docker-compose.yaml"
compose_management="$install_location/management/docker-compose.yaml"
compose_custom="$install_location/custom/docker-compose.yaml"
env_media="$install_location/media/.env"
env_starrs="$install_location/starrs/.env"
env_network="$install_location/network/.env"
env_management="$install_location/management/.env"

wireguard="$install_location/wireguard-install.sh"
openvpn="$install_location/openvpn-install.sh"

# Set fly-hi script
send_message_in_orange "I need your sudo password to install the fly-hi CLI and correct permissions on it"
sudo cp fly-hi /usr/local/bin/fly-hi && sudo chmod +x /usr/local/bin/fly-hi
sudo sed -i -e "s;<install_location>;$install_location;g" /usr/local/bin/fly-hi

# Checking that the user exists
username=${username:-$USER}

if id -u "$username" &>/dev/null; then
    puid=$(id -u "$username");
    pgid=$(id -g "$username");
else
    send_message_in_red "The user \"$username\" doesn't exist!"
fi
# Copy the docker-compose and .env.example file from the examples to the real one
echo
echo "Configuring the docker-compose file for the user \"$username\" on \"$install_location\"..."
echo "Copying docker-compose files..."
echo "Copying environment files..."
cp docker-compose.example.media.yaml "$compose_media" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp docker-compose.example.starrs.yaml "$compose_starrs" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp docker-compose.example.network.yaml "$compose_network" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp docker-compose.example.management.yaml "$compose_management" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp docker-compose.example.custom.yaml "$compose_custom" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp env.example.media "$env_media" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp env.example.starrs "$env_starrs" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp env.example.network "$env_network" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"
cp env.example.management "$env_management" || send_message_in_red "Your user ($USER) needs to have permissions on the installation folder!"

# Set config folder
sed -i -e "s;<install_location>;$install_location;g" "$env_media" "$env_starrs" "$env_network" "$env_management"



echo
read -p "What's the user that is going to own the media server files? [$USER]: " username
username=${username:-$USER}
# Set PUID
sed -i -e "s/<your_PUID>/$puid/g" "$env_media" "$env_starrs" "$env_network" "$env_management"
# Set PGID
sed -i -e "s/<your_PGID>/$pgid/g" "$env_media" "$env_starrs" "$env_network" "$env_management"


#Choose Time Zone
echo
read -p "Please, input your timezone in format Region/City or leave system default: " timezone
timezone=${timezone:-"$(timedatectl | grep zone | awk -F":" '{ print $2 }' | awk '{ print $1 }')"}
# Set timezone
sed -i -e "s;<timezone>;$timezone;g" "$env_media" "$env_starrs" "$env_network" "$env_management"
echo
read -p "Please, input your DATA ROOT folder [/media/data]: " data_root
data_root=${data_root:-"/media/data"}
data_root=$(realpath "$data_root")
# Set data_root
sed -i -e "s;<data_root>;$data_root;g" "$env_media" "$env_starrs" "$env_network"
echo
send_message_in_green "User: $username"
send_message_in_green "Timezone: $timezone"
send_message_in_green "Install location: $install_location"
send_message_in_green "Data root folder: $data_root"
send_message_in_orange "If something doesnt look right please start over!"
sleep 2


send_message_in_blue "=============================================================================="
#databases
echo "We will need to install Postgres and MariaDB databases in order for some containers to properly work. This can also be managed post installation in docker-compose and .env files."
echo "This password will be used across all of your databases, make sure its strong!"
password=$(get_password "database")

sed -i -e "s;<database_password>;$password;g" "$env_network" "$env_management" "$env_media" "$env_starrs"
echo




clear
running_services_management
echo
send_message_in_purple "=============================================================================="
echo
send_message_in_cyan "Time to choose your Management Services."
send_message_in_cyan "Management Services are supposed to make your Self-Hosting life easier!"
echo
send_message_in_purple "=============================================================================="
echo
send_message_in_orange "=============================================================================="
send_message_in_orange "ANY SKIPPED SERVICE CAN BE FOUND IN $install_location/custom/docker-compose.yaml!"
send_message_in_orange "=============================================================================="
echo
add_service "heimdall" "Keep your services organized on a nice Dashboard (https://github.com/linuxserver/Heimdall)"
add_service "homarr" "A sleek, modern dashboard that puts all of your apps and services at your fingertips (https://homarr.dev/)"
add_service "portainer" "Keep your docker containers in check! (https://www.portainer.io/)"
add_service "watchtower" "Keep your docker containers up to date! (https://github.com/containrrr/watchtower)"
add_service "netdata" "Distributed real-time, health monitoring platform for systems, hardware, containers & applications, collecting metrics (https://www.netdata.cloud/)"
add_service "uptimekuma" "Real time monitoring of your services (https://github.com/louislam/uptime-kuma)"
add_service "glances" "System Information (https://nicolargo.github.io/glances/)"
add_service "scrutiny" "HDD/SSD monitoring tool with a nice dashboard (https://github.com/AnalogJ/scrutiny)"
add_service "phpmyadmin" "WEBui for managing MySQL databases, tables, columns, relations, indexes, users, permissions, etc (https://hub.docker.com/r/phpmyadmin/phpmyadmin/)"
add_service "pgadmin" "WEBui for managing Postgres databases, tables, columns, relations, indexes, users, permissions, etc (https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html)"
add_service "whoami" "Gives you basic information about your Host - Used for testing and troubleshooting"
add_service "dozzle" "All docker logs in one place on a nice WEB-UI (https://dozzle.dev/)"
add_service "ntfy" "Beautiful push notification server for docker services, ssh, cronjobs etc. (https://docs.ntfy.sh/)"
add_service "vaultwarden" "Password Manager (https://hub.docker.com/r/vaultwarden/server)"
add_service "homeassistant" "Open source home automation that puts local control and privacy first (https://www.home-assistant.io/)"


add_service "graylog" "Log Aggregator with a WEB-UI (https://graylog.org/)"
if [[ $graylog =~ [yY] ]]; then
    send_message_in_orange "Graylog will use sha256sum of password you input here - make sure you remember it"
    password=$(get_password "graylog")
    sed -i -e "s;<graylog_password>;$(echo -n $password | sha256sum | awk '{ print $1 }');g" "$env_management"
fi
send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="
#COCKPIT PROJECT
echo "Would you like to add Cockpit Project? [y/N]: "
send_message_in_orange "Note: This will require your sudo password!"
read -p "" cockpit
cockpit=${cockpit:-"n"}
if [[ "$cockpit" =~ [yY] ]]; then
. /etc/os-release
sudo apt install -t ${VERSION_CODENAME}-backports cockpit
sudo systemctl enable --now cockpit.socket
fi
send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="
clear
running_services_network
echo
send_message_in_purple "=============================================================================="
echo
send_message_in_cyan "Time to choose your Network Services."
send_message_in_cyan "Network services are here to make your server safer, accessible from outside or simply easier to navigate!"
echo
send_message_in_purple "=============================================================================="
echo
echo "Would you like to install Traefik? "
echo "Traefik can serve as a reverse-proxy and make your running service easily reachable through hostnames instead of IPs and Port numbers!"
echo
echo "If you dont have a Static IP or any private Domain name it might be better to skip traefik installation!!!"
echo "At the momemnt, this script supports obtaining certificates either with"
echo
echo "- DNS challege over cloudflare which doesnt require opening your ports"
echo
echo "- Classic HTTP challenge which needs to have ports 80 and 443 open and forwarded to your Host (Dangerous)"
echo
send_message_in_orange "Security note:"
echo "Forwarding ports will expose all of your service behind traefik to the public due to"
echo "docker security flaws: docker automatically opens all ports required by cointainers through iptables"
echo "Check https://github.com/chaifeng/ufw-docker and https://github.com/shinebayar-g/ufw-docker-automated"
echo "These ports stay open until you close them on the router itself or manipulate IP tables on the host machine"
echo
echo
echo "If you choose to install traefik, note that this is a pretty basic setup just to make things "
echo "work, no extra tweaks which could make it more secure etc., use this at your own risk!"
echo
echo
read -p "Would you like to proceed with installation of Traefik? [y/N]:" traefik
traefik=${traefik:-"n"}
if [[ $traefik =~ [yY] ]]; then
    # Uncomment lines between #traefikstart and #traefikend
    sed -i '/^#traefikstart$/,/^#traefikend$/{/^\(#traefikstart\|#traefikend\)$/!s/^#//}' "$compose_network"
    # delete lines with #localhost#
    sed -i '/#localhost#/d' "$compose_media" "$env_media" # this is used only for joplin and linkwarden because of some APP_URL conflicts when running behind reverse-proxy
    echo "Would you prefer to use DNS (only cloudflare supported at the momemnt - you can manually switch the"
    echo "provider after the installation to any other you can find here: https://go-acme.github.io/lego/dns/) "
    echo "or would you prefer to use HTTP challenge (any provider)?"
    echo
    echo "Extra info can be found here https://doc.traefik.io/traefik/user-guides/docker-compose/acme-http/"
    echo "and here https://doc.traefik.io/traefik/user-guides/docker-compose/acme-dns/"
    echo
    read -rp "[DNS/http]:" -e -i dns traefik_tls
    if [[ "$traefik_tls" == "dns" ]]; then
        read -p "Please, input your let's encrypt email address: " letsencrypt_email
        read -p "Please, input your cloudflare email address [$letsencrypt_email]: " cloudflare_email
        cloudflare_email=${cloudflare_email:-"$letsencrypt_email"}
        read -p "Please, input your cloudflare API token: " cloudflare_api
        read -p "Please, input your your domain name: " my_domain
    else
        read -p "Please, input your let's encrypt email address: " letsencrypt_email
        read -p "Please, input your your domain name: " my_domain
    fi
    # Set Traefik config
    if [[ "$traefik_tls" == "dns" ]]; then
        sed -i -e "s;<letsencrypt_email>;$letsencrypt_email;g" "$env_network"
        sed -i -e "s;<cloudflare_email>;$cloudflare_email;g" "$env_network"
        sed -i -e "s;<cloudflare_api>;$cloudflare_api;g" "$env_network"
        sudo sed -i -e "s;<my_domain>;$my_domain;g" "$env_network" "$env_management" "$env_media" "$env_starrs" "/usr/local/bin/fly-hi"
        sed -i '/#dnschallenge#/s/^#//' "$compose_network" "$compose_starrs" "$compose_management" "$compose_media"

    else
        sed -i -e "s;<letsencrypt_email>;$letsencrypt_email;g" "$env_network"
        sudo sed -i -e "s;<my_domain>;$my_domain;g" "$env_media" "$env_starrs" "$env_network" "$env_management" "/usr/local/bin/fly-hi"
        sed -i '/#httpchallenge#/s/^#//' "$compose_network" "$compose_starrs" "$compose_management" "$compose_media"
        sudo sed -i -e "s;<traefik>;$traefik;g" "/usr/local/bin/fly-hi"
    fi
else
  sudo sed -i '/#traefik#/d' "$compose_network" "$compose_starrs" "$compose_management" "$compose_media" "$env_media" "/usr/local/bin/fly-hi"
  echo "Skipping Traefik configuration"
  localhostip=$(hostname -I | awk '{ print $1 }')
  sed -i -e "s;<localhostip>;$localhostip;g" "$env_media"
fi
send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="

add_service "wgeasy" "Connect to your home network from anywhere in the world! https://github.com/wg-easy/wg-easy"
if [[ $wgeasy =~ [yY] ]]; then
    password=$(get_password "wgeasy")
    sed -i -e "s;<wgeasy_password>;$password;g" "$env_network"
    echo
    read -rp "Please, input the port you forwarded from your router to your wg-easy VPN server: " -e -i 51820 portfwd_wgeasy
    sed -i -e "s;<forwarded_port_wgeasy>;$portfwd_wgeasy;g" "$env_network"
    sed -i '/#port_forwarding_wgeasy#/s/^#//' "$env_network"
    if [[ $traefik =~ [nN] ]]; then
        sudo apt install curl -y
        echo
        my_current_public_ip=$(curl -s ifconfig.me)
        echo "If you dont have a statis IP address please input the domain name that will be regularly updated with your Dynamis DNS Client!"
        read -rp "Your current public IP address is: " -e -i ${my_current_public_ip} my_public_ip
        my_domain=${my_public_ip}
        sudo sed -i -e "s;<wg_hostname>;$my_public_ip;g" "$env_network" "$env_management" "$env_media" "$env_starrs" "/usr/local/bin/fly-hi"
        sudo sed -i -e "s;<my_domain>;$my_domain;g" "$env_network" "$env_management" "$env_media" "$env_starrs" "/usr/local/bin/fly-hi"
    else
        sudo sed -i -e "s;<wg_hostname>;$my_domain;g" "$env_network" "$env_management" "$env_media" "$env_starrs" "/usr/local/bin/fly-hi"
    fi
fi


send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="
#VPN CLIENT
read -p "Would you like to configure a VPN Client (Used for qBittorrent but with a few tweaks it can be used for any of your services)? [Y/n]: " gluetun
gluetun=${gluetun:-"y"}
if [[ $gluetun =~ [yY] ]]; then
    # Uncomment lines between #gluetunstart and #gluetunend
    sed -i '/^#gluetunstart$/,/^#gluetunend$/{/^\(#gluetunstart\|#gluetunend\)$/!s/^#//}' "$compose_network"
    # Comment lines with #yes_gluetun#
    sed -i '/#yes_gluetun#/s/^/#/' "$compose_starrs"
    send_message_in_cyan "You can check the supported VPN list here: https://yams.media/advanced/vpn."
    read -rp "What's your VPN service? (with spaces): " -e -i "mullvad" vpn_service
    echo
    echo "You should read $vpn_service's documentation in case it has different configurations for username and password."
    send_message_in_cyan "The documentation for $vpn_service is here: https://github.com/qdm12/gluetun/wiki/${vpn_service// /-}"
    echo
    read -p "What's your VPN username? (without spaces)(if you are using mullvad your mullvad password is your username): " vpn_user

    get_password "$vpn_service VPN"
    echo
    echo "What country Would you like to use? "
    send_message_in_cyan "You can check more info and the countries/regions list for your VPN here: https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers"
    send_message_in_cyan "and here: https://github.com/qdm12/gluetun-wiki/blob/main/setup/servers.md"
    read -rp "If you are using: NordVPN, Perfect Privacy, Private Internet Access, VyprVPN, WeVPN or Windscribe, then input a region: " -e -i USA vpn_country
    #vpn_country=${vpn_country:-"USA"}
    read -rp "What city Would you like to use (If it is two words put it in double quotes and check the github page for detailed lists)?: " -e -i '"Chicago IL"' vpn_city
    #vpn_city=${vpn_city:-"london"}
    echo
    echo "Recently popular services such as Mullvad removed their option to use port forwarding, if you have a service which provides such a"
    read -p "feature and you would like to use it, answer yes [N/y]: " portfwd_y_n
    portfwd_y_n=${portfwd_y_n:-"n"}
    if [[ $portfwd_y_n =~ [yY] ]]; then
    read -rp "Please, input your forwarded port for seeding: " -e -i 57778 portfwd
    sed -i -e "s;<forwarded_port>;$portfwd;g" "$env_network" "$env_starrs" "$env_media"
    sed -i '/#port_forwarding#/s/^#//' "$env_network" "$env_starrs" "$env_media" "$compose_network" "$compose_starrs" "$compose_media"
    fi
    #Set docker-compose file
    sed -i -e "s;<vpn_service>;$vpn_service;g" "$env_network"
    sed -i -e "s;<vpn_user>;$vpn_user;g" "$env_network"
    sed -i -e "s;<vpn_country>;$vpn_country;g" "$env_network"
    sed -i -e "s;<vpn_city>;$vpn_city;g" "$env_network"
    sed -i -e "s;<vpn_password>;$password;g" "$env_network"
    if echo "nordvpn perfect privacy private internet access vyprvpn wevpn windscribe" | grep -qw "$vpn_service"; then
        sed -i -e "s;SERVER_COUNTRIES;SERVER_REGIONS;g" "$env_network"
    fi
else
  # Comment lines with #no_gluetun#
  sed -i '/#no_gluetun#/s/^/#/' "$compose_starrs"
  echo "Skipping Gluetun configuration"
  portfwd_y_n=no
fi
send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="

#TAILSCALE
echo "Would you like to install Tailscale (Not open source)? [y/N]: "
read -p "" tailscale
tailscale=${tailscale:-"n"}
#INSTALL TAILSCALE
if [[ "$tailscale" =~ [yY] ]]; then
sudo -s <<EOF
curl -fsSL https://tailscale.com/install.sh | sh
EOF
else
    sudo sed -i '/#tailscale#/d' "/usr/local/bin/fly-hi"
fi


add_service "flaresolverr" "Proxy server to bypass Cloudflare protection in Prowlarr https://github.com/FlareSolverr/FlareSolverr"
add_service "ddclient" "Keep your Domain updated at all times (Unnecessary if you are NOT exposing any of your service to public!) https://github.com/ddclient/ddclient"
add_service "speedtest" "Monitor your internet speed on a scheduled basis https://github.com/alexjustesen/speedtest-tracker"



send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="
sleep 1

clear
running_services_media
echo
echo
send_message_in_purple "=============================================================================="
echo
send_message_in_cyan "Time to choose your media services."
send_message_in_cyan "Your media service is the one responsible for serving your files to your network."
echo
send_message_in_purple "=============================================================================="

add_service "jellyfin" "Media Streaming Service (open-source, fork of Emby, recommended) (https://jellyfin.org/)"
add_service "emby" "Media Streaming Service (closed-source) (https://emby.media/)"
add_service "plex" "Media Streaming Service (closed-source) (https://www.plex.tv/)"
add_service "airsonic" "Music Server (https://airsonic.github.io/)"
add_service "navidrome" "Music Server (https://www.navidrome.org/)"
add_service "ombi" "Jellyfin/Plex/Emby Media Requests (https://github.com/Ombi-app/Ombi)"
add_service "calibre_library" "Manage all your books in famous Calibre Library (https://hub.docker.com/r/linuxserver/calibre)"
add_service "calibre_web" "Web based Front End for Calibre-Library (https://github.com/janeczku/calibre-web)"
add_service "audiobookshelf" "Listen to your favorite Audiobooks (https://www.audiobookshelf.org/)"
add_service "readeck" "Nice Open Source alternative to Pocket (https://readeck.org/en/)"
add_service "linkding" "Simple bookmarks managers with support for tags (https://github.com/sissbruecker/linkding)"
add_service "linkwarden" "Fancy modern bookmarks manager with support for tags (https://github.com/linkwarden/linkwarden)"
add_service "stirlingpdf" "Your locally hosted one-stop-shop for all your PDF needs (https://github.com/Frooodle/Stirling-PDF)"
add_service "nextcloud" "Popular Open Source Google Cloud alternative (https://nextcloud.com/)"
add_service "filebrowser" "Nice WebUI for accessing and managing your files (https://filebrowser.org/)"
add_service "joplin" "Nice and very popular Notes-taking app - This is only a Server (https://joplinapp.org/)"
add_service "freshrss" "Nice RSS agregator (https://github.com/FreshRSS/FreshRSS/tree/edge/Docker#docker-compose)"
add_service "mealie" "A self-hosted recipe manager and meal planner (https://docs.mealie.io/)"
add_service "privatebin" "A pastebin allows users to share plain text through the web for a certain period of time(https://github.com/gabrielesh/PrivateBin)"
add_service "pingvinshare" "Pingvin Share is self-hosted file sharing platform and an alternative for WeTransfer (https://github.com/stonith404/pingvin-share)"
add_service "immich" "Self-hosted backup solution for photos and videos on mobile device (https://immich.app/)"
add_service "photoprism" "Self-hosted backup solution for photos and videos"
# keep photoprism last due to password prompt
if [[ "$photoprism" =~ [yY] ]]; then
    send_message_in_orange "Note that photoprism could create a huge amount of cached thumbnails which can fill up your OS drive if there is not enough space"
    read -rp "What will be your admin username?:" -e -i admin admin_username
    password=$(get_password "photoprism")
    echo
    # Set photoprism passwords
    sed -i -e "s;<admin_username>;$admin_username;g" "$env_media"
    sed -i -e "s;<admin_password>;$password;g" "$env_media"
fi
send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="

#SAMBA SERVER
echo "Would you like to install Samba server? "
read -p "Samba can be use as a Network Attached Storage which can be mounted on your other devices like KODI, PC, Phones etc.s [n/Y]:" samba
samba=${samba:-"y"}
if [[ $samba =~ [yY] ]]; then
    sudo apt update
    sudo apt install samba cifs-utils -y
        send_message_in_green "Adding Samba configuration..."
    # Check if the configuration already exists in smb.conf
    if ! grep -q "\[data\]" /etc/samba/smb.conf; then
        send_message_in_green "This is your Samba share config which you can modify at /etc/samba/smb.conf"
        send_message_in_green "=============================================================================="
        echo "[data]" | sudo tee -a /etc/samba/smb.conf
        echo "    path = $data_root" | sudo tee -a /etc/samba/smb.conf
        echo "    browsable = yes" | sudo tee -a /etc/samba/smb.conf
        echo "    read only = no" | sudo tee -a /etc/samba/smb.conf
        echo "    guest ok = no" | sudo tee -a /etc/samba/smb.conf
        echo "    force user = $username" | sudo tee -a /etc/samba/smb.conf
        echo "    force group = $username" | sudo tee -a /etc/samba/smb.conf
        echo "    create mask = 0776" | sudo tee -a /etc/samba/smb.conf
        echo "    directory mask = 0775" | sudo tee -a /etc/samba/smb.conf
        echo "    unix extensions = yes" | sudo tee -a /etc/samba/smb.conf
        echo "    follow symlinks=yes" | sudo tee -a /etc/samba/smb.conf
        echo "    wide links=yes" | sudo tee -a /etc/samba/smb.conf
        echo "    allow insecure wide links=yes" | sudo tee -a /etc/samba/smb.conf
        echo "    server multi channel support = yes" | sudo tee -a /etc/samba/smb.conf
        echo "    aio read size = 1" | sudo tee -a /etc/samba/smb.conf
        echo "    aio write size = 1" | sudo tee -a /etc/samba/smb.conf
        echo "    inherit permissions = yes" | sudo tee -a /etc/samba/smb.conf
        send_message_in_green "=============================================================================="
    else
        send_message_in_green "Configuration already exists in /etc/samba/smb.conf file. Skipping..."
    fi
    sudo service smbd restart
    sudo ufw allow samba
    sudo smbpasswd -a $username
else
    echo "Skipping Samba configuration"
fi

send_message_in_blue "=============================================================================="
send_message_in_blue "=============================================================================="
clear


running_services_download
echo
send_message_in_purple "=============================================================================="
echo
send_message_in_cyan "Time to choose your Starrs and Download Services!"
echo
send_message_in_purple "=============================================================================="

add_service "radarr" "Manage your Movies https://radarr.video/"
add_service "sonarr" "Manage your TV Shows https://sonarr.tv/"
add_service "readarr" "Manage your Books https://readarr.com/"
add_service "lidarr" "Manage your Music https://lidarr.audio/"
add_service "bazarr" "Manage Subtitles for you Media Collection https://www.bazarr.media/"
add_service "prowlarr" "Indexer aggregator for Sonarr and Radarr https://github.com/Prowlarr/Prowlarr"
add_service "qbittorrent" "Does the actual download...https://www.qbittorrent.org/"
add_service "qbittorrentpub" "This is just a second instance of qbittorrent that can be used to separate public from private torrent!"
add_service "tubesync" "Manage your favorite Youtube Channels (https://github.com/meeb/tubesync)"


# ============================================================================================
# Cleaning up...
# ============================================================================================

send_message_in_green "Setting up docker network to ${DOCKER_SUBNET:-172.22.0.0/24}"
# setting up docker network
docker network create --subnet=${DOCKER_SUBNET:-172.22.0.0/24} fly-hi || true

send_message_in_green "Fixing firewall rules..."
sleep 1
# Tweaks that should be done for some apps to work properly
#allow forwarded ports on router for wgeasy and vpn client
if [[ "$wgeasy" =~ [yY] ]]; then
    sudo /usr/sbin/ufw allow $portfwd_wgeasy
fi
if [[ $portfwd_y_n =~ [yY] ]]; then
    sudo /usr/sbin/ufw allow $portfwd
fi
# this is used so docker containers can easily access each other
sudo /usr/sbin/ufw allow from ${DOCKER_SUBNET:-172.22.0.0/24}
# Sometimes starrs have difficulty discovering qBittorrent if the webui port is not open
sudo /usr/sbin/ufw allow 8833
sudo /usr/sbin/ufw allow 8822
# Sometimes jellyseer has difficulty discovering jellyfin if the webui port is not open
sudo /usr/sbin/ufw allow 443
# BOTH OF THESE should be replaced with ufw allow from "docker.network.ip.address" to any port 443,8080
send_message_in_green "Done!✅"


send_message_in_green "Adding cronjobs..."
sleep 1
# Add photoprism indexing crontab as user
if [[ "$nextcloud" =~ [yY] ]]; then
    # Define the cron job command for Nextcloud
     nextcloud_cron_command="50 11 * * * sudo docker exec nextcloud sudo -u abc php /config/www/nextcloud/occ files:scan --all >> $install_location/cron-logs/nextcloud-scan.log 2>&1"
    # Check if the cron job already exists
     existing_nextcloud_cron_job=$(sudo crontab -l -u root 2>/dev/null | grep "files:scan --all") || true

    if [[ -z "$existing_nextcloud_cron_job" ]]; then
        send_message_in_green "Adding cronjob to user root"
        # If the cron job doesn't exist, add it
        (sudo crontab -u root -l 2>/dev/null; echo "$nextcloud_cron_command") | sudo crontab -u root - || true
    else
        # If the cron job already exists, notify or handle accordingly
        send_message_in_green "Nextcloud cron job already exists in user root crontab."
    fi
fi
if [[ $photoprism =~ [yY] ]]; then
    # Define the cron job command for Photoprism
    photoprism_cron_command="30 11 * * * docker exec -t photoprism photoprism index --cleanup > /home/$USER/photoprism.log 2>&1 && date >> $install_location/cron-logs/photoprism-scan.log 2>&1"

    # Check if the cron job already exists
    existing_photoprism_cron_job=$(sudo crontab -l -u $USER 2>/dev/null | grep "docker exec -t photoprism photoprism index --cleanup") || true


    if [[ -z "$existing_photoprism_cron_job" ]]; then
        # If the cron job doesn't exist, add it using crontab
        send_message_in_green "Adding cronjob to user $USER"
        (sudo crontab -u $USER -l 2>/dev/null; echo "$photoprism_cron_command") | sudo crontab -u $USER - || true
    else
        # If the cron job already exists, notify or handle accordingly
        send_message_in_green "Photoprism cron job already exists in user $USER crontab."
    fi
fi
send_message_in_green "Done!✅"


send_message_in_green "🎉🎉🎉🎉🎉 Everything installed correctly! 🎉🎉🎉🎉🎉"


send_message_in_green "If we need your sudo password to correct permissions you will be prompted for it..."
send_message_in_orange "If you have a large library this might take a long time, but it WILL finish so hang in there!! "
[[ -f "$data_root" ]] || sudo mkdir -p "$data_root" || send_message_in_red "There was an error with your install location!"
if sudo chown -R "$puid":"$pgid" "$data_root"; then
    send_message_in_green "Media directory ownership and permissions set successfully ✅"
else
    send_message_in_red "Failed to set ownership and permissions for the media directory. Check permissions ❌"
fi




echo "Running the server..."
echo "This is going to take a while...grab a coffee"
send_message_in_orange "If containers fail to start up due to port conflicts on your system"
send_message_in_orange "or some other reason, correct the yaml and env files and run 'fly-hi start'"
sleep 5
docker-compose -f "$compose_network" up -d
docker-compose -f "$compose_management" up -d
docker-compose -f "$compose_media" up -d
docker-compose -f "$compose_starrs" up -d
#media # Not sure if this is actually needed, would love some thoughts on this
# sudo chown -R "$puid":"$pgid" "$install_location/media/jellyfin" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/emby" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/plex" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/overseerr" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/ombi" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/jellyseerr" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/airsonic" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/audiobookshelf" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/calibre_web" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/calibre" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/tubesync" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/linkding" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/linkwarden" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/joplin" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/freshrss" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/stirling_pdf" || true
# sudo chown -R "$puid":"$pgid" "$install_location/media/filebrowser" || true
sleep 5
running_services_location > ~/fly-hi-links.txt
echo "Speedtest tracker: username: admin@example.com   password: password" >> ~/fly-hi-links.txt
echo "Qbittorrrent:      username: admin               password: The password can be obtained from docker logs"  >> ~/fly-hi-links.txt
echo "FileBrowser:       username: admin               password: admin"  >> ~/fly-hi-links.txt
echo "Calibre web:       username: admin               password: admin123"  >> ~/fly-hi-links.txt
echo "Linkding           username: admin               password: adminadmin"  >> ~/fly-hi-links.txt
echo "Airsonic:          username: admin               password: admin"  >> ~/fly-hi-links.txt
echo "Mealie:            username: changeme@email.com  password: MyPassword"  >> ~/fly-hi-links.txt
if [[ $traefik =~ [yY] ]]; then
        # If traefik is enabled accessing nextcloud over https wont be easy unless an override rule is added to the config
    #  * When generating URLs, Nextcloud attempts to detect whether the server is
    #  * accessed via ``https`` or ``http``. However, if Nextcloud is behind a proxy
    #  * and the proxy handles the ``https`` calls, Nextcloud would not know that
    #  * ``ssl`` is in use, which would result in incorrect URLs being generated.
    #  * Valid values are ``http`` and ``https``.
    #  */
    # Nextcloud image
    #sudo sed -i -e "s|'overwriteprotocol' => '',|'overwriteprotocol' => 'https',|g" "$install_location/media/nextcloud/config.php"
    # Nextcloud linuxserver image
    # this command works only after the nextcloud container is already up and running.
    #sudo sed -i -e "s|'overwriteprotocol' => '',|'overwriteprotocol' => 'https',|g" "$install_location/media/nextcloud/config/www/nextcloud/config/config.php"
    echo "" >> ~/fly-hi-links.txt
    echo " # Nextcloud " >> ~/fly-hi-links.txt
    echo "For nextcloud behind a reverse-proxy the overwrite protocol needs to be edited in nextcloud config. " >> ~/fly-hi-links.txt
    echo "Something like this:" >> ~/fly-hi-links.txt
    echo "'overwrite.cli.url' => 'http://nextcloud.${my_domain}', " >> ~/fly-hi-links.txt
    echo "'overwriteprotocol' => 'https'," >> ~/fly-hi-links.txt
    echo "'overwritehost' => 'nextcloud.${my_domain}'," >> ~/fly-hi-links.txt
fi



printf "\033c"

echo "==================================================================================="
echo " _____  _      __ __         __ __  ____      ___ ___    ___  ___    ____   ____ "
echo "|     || |    |  |  |       |  |  ||    |    |   |   |  /  _]|   \  |    | /    |"
echo "|   __|| |    |  |  | _____ |  |  | |  |     | _   _ | /  [_ |    \  |  | |  o  |"
echo "|  |_  | |___ |  ~  ||     ||  _  | |  |     |  \_/  ||    _]|  D  | |  | |     |"
echo "|   _] |     ||___, ||_____||  |  | |  |     |   |   ||   [_ |     | |  | |  _  |"
echo "|  |   |     ||     |       |  |  | |  |     |   |   ||     ||     | |  | |  |  |"
echo "|__|   |_____||____/        |__|__||____|    |___|___||_____||_____||____||__|__|"
echo "==================================================================================="
send_message_in_green "All done!✅  Enjoy Fly-Hi!"
echo "You can check the installation on $install_location"
echo "==================================================================================="
echo "Everything should be running now! To check everything running run 'fly-hi links'"
echo
fly-hi links
echo "==================================================================================="
echo "All the services location, some DEFAULT PASSWORDS and some useful notes to save you time  properly setting up your server are also saved in ~/fly-hi_media.txt"
echo "==================================================================================="
echo "To configure some of the service you can check the guides at"
echo "https://yams.media/config and https://trash-guides.info/"
echo "==================================================================================="
exit 0
