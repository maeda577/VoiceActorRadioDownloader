#!/bin/sh
apt update
apt --yes install git curl libicu-dev

# https://docs.microsoft.com/ja-jp/powershell/scripting/install/install-other-linux?view=powershell-7.2#binary-archives
# Download the powershell '.tar.gz' archive
curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.2.1/powershell-7.2.1-linux-arm64.tar.gz

# Create the target folder where powershell will be placed
mkdir -p /opt/microsoft/powershell/7

# Expand powershell to the target folder
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

# Set execute permissions
chmod +x /opt/microsoft/powershell/7/pwsh

# Create the symbolic link that points to pwsh
ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

apt --yes install ffmpeg
