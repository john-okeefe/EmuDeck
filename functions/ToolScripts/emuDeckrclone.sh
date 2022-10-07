#!/bin/bash

rclone_path="$toolsPath/rclone"
rclone_bin="$rclone_path/rclone"
rclone_config="$rclone_path/rclone.conf"

rclone_install(){	

    mkdir -p "$rclone_path"/tmp
    curl -L "$(getReleaseURLGH "rclone/rclone" "linux-amd64.zip")" --output "$rclone_path/tmp/rclone.temp" && mv "$rclone_path/tmp/rclone.temp" "$rclone_path/tmp/rclone.zip"

    unzip -o "$rclone_path/tmp/rclone.zip" -d "$rclone_path/tmp/" && rm "$rclone_path/tmp/rclone.zip"
    mv "$rclone_path"/tmp/* "$rclone_path/tmp/rclone" #don't quote the *
    mv  "$rclone_path/tmp/rclone/rclone" "$rclone_bin"
    rm -rf "$rclone_path/tmp"
    chmod +x "$rclone_bin"

    cp "$EMUDECKGIT/configs/rclone/rclone.conf" "$rclone_config"

}

rclone_pickProvider(){

    cloudProviders=()
    cloudProviders+=(1 "Emudeck-GDrive")
    cloudProviders+=(2 "Emudeck-DropBox")
    cloudProviders+=(3 "Emudeck-OneDrive")
    cloudProviders+=(4 "Emudeck-Box")
    cloudProviders+=(5 "Emudeck-NextCloud")

    rclone_provider=$(zenity --list \
        --title="EmuDeck SaveSync Host" \
        --height=500 \
        --width=500 \
        --ok-label="OK" \
        --cancel-label="Exit" \
        --text="Choose the service you would like to use to host your cloud saves.\n\nKeep in mind they can take a fair amount of space.\n\nThis will open a browser window for you to sign into your chosen cloud provider." \
        --radiolist \
        --column="Select" \
        --column="Provider" \
        "${cloudProviders[@]}" 2>/dev/null)
    if [[ -n "$rclone_provider" ]]; then
        setSetting rclone_provider "$rclone_provider"
        return 0
    else
        return 1
    fi
}

rclone_updateProvider(){
    $rclone_bin config update "$rclone_provider"
}

rclone_setup(){

    while true; do
        if [ ! -e "$rclone_bin" ]; then
            ans=$(zenity --info --title 'Rclone Setup!' \
                        --text 'Backup to cloud' \
                        --width=50 \
                        --ok-label Exit \
                        --extra-button "Install rclone" 2>/dev/null  )
        elif [ -n "$rclone_provider" ]; then
            ans=$(zenity --info --title 'Rclone Setup!' \
                        --text 'Backup to cloud' \
                        --width=50 \
                        --ok-label Exit \
                        --extra-button "Reinstall rclone" \
                        --extra-button "Pick Provider" 2>/dev/null  )
        else
            ans=$(zenity --info --title 'Rclone Setup!' \
                --text 'Backup to cloud' \
                --width=50 \
                --ok-label Exit \
                --extra-button "Reinstall rclone" \
                --extra-button "Pick Provider" \
                --extra-button "Login" \
                --extra-button "Run Backup" 2>/dev/null ) 
        fi
        rc=$?
        if [ "$rc" == 0 ]; then
            break
        elif [ "$ans" == "" ]; then
            break
        elif [ "$ans" == "Install rclone" ] || [ "$ans" == "Reinstall rclone" ]; then
            rclone_install
        elif [ "$ans" == "Pick Provider" ]; then
            rclone_pickProvider
        elif [ "$ans" == "Login" ]; then
            rclone_updateProvider
        elif [ "$ans" == "Run Backup" ]; then
            rclone_runcopy
        fi
    done

}

rclone_runcopy(){
    $rclone_bin copy -L "$savesPath" "$rclone_provider":Emudeck/saves -P
}