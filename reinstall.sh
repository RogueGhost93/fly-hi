#!/bin/bash -x
# ============================================================================================
# Source functions
source functions
# ============================================================================================

echo "Running the server..."
echo "This is going to take a while...grab a coffee"
send_warning_message "If containers fail to start up due to port conflicts on your system"
send_warning_message "or some other reason, correct the yaml and env files and run reinstall.sh script"
source env.reinstall
docker network create --subnet=${DOCKER_SUBNET:-172.22.0.0/24} fly-hi || true
docker-compose -f "$compose_network" up -d
docker-compose -f "$compose_management" up -d
docker-compose -f "$compose_media" up -d
docker-compose -f "$compose_starrs" up -d





send_success_message "If we need your sudo password to install the fly-hi CLI and correct permissions you will be prompted for it..."
send_warning_message "If you have a large library this might take a long time, but it WILL finish so hang in there!! "
[[ -f "$data_root" ]] || sudo mkdir -p "$data_root" || send_error_message "There was an error with your install location!"
if sudo chown -R "$puid":"$pgid" "$data_root"; then
    send_success_message "Media directory ownership and permissions set successfully ✅"
else
    send_error_message "Failed to set ownership and permissions for the media directory. Check permissions ❌"
fi

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


# ============================================================================================
# Cleaning up...
# ============================================================================================

send_success_message "Fixing firewall rules..."
sleep 1
# Tweaks that should be done for some apps to work properly
#allow forwarded ports on router for wgeasy and vpn client
if [ "$wgeasy" == "y" ]; then
    sudo /usr/sbin/ufw allow $portfwd_wgeasy
fi
if [[ $portfwd_y_n == "y" ]]; then
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
send_success_message "Done!✅"


send_success_message "Adding cronjobs..."
sleep 1
# Add photoprism indexing crontab as user
if [ "$nextcloud" == "y" ]; then
    # Define the cron job command for Nextcloud
     nextcloud_cron_command="50 11 * * * sudo docker exec nextcloud sudo -u abc php /config/www/nextcloud/occ files:scan --all >> $install_location/cron-logs/nextcloud-scan.log 2>&1"
    # Check if the cron job already exists
     existing_nextcloud_cron_job=$(sudo crontab -l -u root 2>/dev/null | grep "files:scan --all")

    if [ -z "$existing_nextcloud_cron_job" ]; then
        send_success_message "Adding cronjob to user root"
        # If the cron job doesn't exist, add it
        (sudo crontab -u root -l 2>/dev/null; echo "$nextcloud_cron_command") | sudo crontab -u root -
    else
        # If the cron job already exists, notify or handle accordingly
        send_success_message "Nextcloud cron job already exists in user root crontab."
    fi
        # If traefik is enabled accessing nextcloud over https wont be easy unless an override rule is added to the config
    #  * When generating URLs, Nextcloud attempts to detect whether the server is
    #  * accessed via ``https`` or ``http``. However, if Nextcloud is behind a proxy
    #  * and the proxy handles the ``https`` calls, Nextcloud would not know that
    #  * ``ssl`` is in use, which would result in incorrect URLs being generated.
    #  * Valid values are ``http`` and ``https``.
    #  */
    if [[ $traefik == "y" ]]; then
        # Nextcloud image
        #sudo sed -i -e "s|'overwriteprotocol' => '',|'overwriteprotocol' => 'https',|g" "$install_location/media/nextcloud/config.php"
        # Nextcloud linuxserver image
        sudo sed -i -e "s|'overwriteprotocol' => '',|'overwriteprotocol' => 'https',|g" "$install_location/media/nextcloud/config/www/nextcloud/config/config.php"
    fi
fi
if [[ $photoprism == "y" ]]; then
    # Define the cron job command for Photoprism
    photoprism_cron_command="30 11 * * * docker exec -t photoprism photoprism index --cleanup > /home/$USER/photoprism.log 2>&1 && date >> test/cron-logs/photoprism-scan.log 2>&1"

    # Check if the cron job already exists
    existing_photoprism_cron_job=$(sudo crontab -l -u $USER 2>/dev/null | grep "docker exec -t photoprism photoprism index --cleanup")


    if [ -z "$existing_photoprism_cron_job" ]; then
        # If the cron job doesn't exist, add it using crontab
        send_success_message "Adding cronjob to user $USER"
        (sudo crontab -u $USER -l 2>/dev/null; echo "$photoprism_cron_command") | sudo crontab -u $USER -
    else
        # If the cron job already exists, notify or handle accordingly
        send_success_message "Photoprism cron job already exists in user $USER crontab."
    fi
fi
send_success_message "Done!✅"


sleep 3
#printf "\033c"

echo "==================================================================================="
echo " _____  _      __ __         __ __  ____      ___ ___    ___  ___    ____   ____ "
echo "|     || |    |  |  |       |  |  ||    |    |   |   |  /  _]|   \  |    | /    |"
echo "|   __|| |    |  |  | _____ |  |  | |  |     | _   _ | /  [_ |    \  |  | |  o  |"
echo "|  |_  | |___ |  ~  ||     ||  _  | |  |     |  \_/  ||    _]|  D  | |  | |     |"
echo "|   _] |     ||___, ||_____||  |  | |  |     |   |   ||   [_ |     | |  | |  _  |"
echo "|  |   |     ||     |       |  |  | |  |     |   |   ||     ||     | |  | |  |  |"
echo "|__|   |_____||____/        |__|__||____|    |___|___||_____||_____||____||__|__|"
echo "==================================================================================="
send_success_message "All done!✅  Enjoy Fly-Hi!"
echo "You can check the installation on $install_location"
echo "==================================================================================="
echo "Everything should be running now! To check everything running, go to:"
echo
running_services_location
echo "==================================================================================="
send_warning_message "You might need to wait for a couple of minutes while everything gets up and running"
echo "All the services location and some DEFAULT PASSWORDS to save you time are also saved in ~/fly-hi_media.txt"
running_services_location > ~/fly-hi-links.txt
echo "Speedtest tracker: username: admin@example.com   password: password" >> ~/fly-hi-links.txt
echo "Qbittorrrent:      username: admin               password: The password can be obtained from docker logs"  >> ~/fly-hi-links.txt
echo "FileBrowser:       username: admin               password: admin"  >> ~/fly-hi-links.txt
echo "Calibre web:       username: admin               password: admin123"  >> ~/fly-hi-links.txt
echo "Linkding           username: admin               password: adminadmin"  >> ~/fly-hi-links.txt
echo "Airsonic:          username: admin               password: admin"  >> ~/fly-hi-links.txt
echo "Mealie:            username: changeme@email.com  password: MyPassword"  >> ~/fly-hi-links.txt
echo "==================================================================================="
echo "To configure Fly-Hi, check the documentation at"
echo "https://yams.media/config"
echo "==================================================================================="
exit 0
