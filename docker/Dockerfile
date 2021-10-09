ARG PWSH_TAG=latest
FROM mcr.microsoft.com/powershell:$PWSH_TAG
ARG REFS_TARGET=heads
ARG VARD_VERSION=main

LABEL Description="VoiceActorRadioDownloader" Version="$VARD_VERSION"

# スクリプトをダウンロードし$PSHOME/Modulesに入れる
RUN pwsh -Command "\
    Set-Variable -Name tmpDir -Value (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath vard) ;\
    New-Item -Path \$tmpDir -ItemType Directory ;\
    Set-Variable -Name tmpZip -Value (Join-Path -Path \$tmpDir -ChildPath vard.zip) ;\
    Invoke-WebRequest -OutFile \$tmpZip -Uri https://github.com/maeda577/VoiceActorRadioDownloader/archive/refs/$REFS_TARGET/$VARD_VERSION.zip ;\
    Expand-Archive -Path \$tmpZip -DestinationPath \$tmpDir ;\
    Move-Item -Path ((Join-Path -Path \$tmpDir -ChildPath VoiceActorRadioDownloader-$VARD_VERSION) | Join-Path -ChildPath modules) -Destination ((Join-Path -Path \$PSHOME -ChildPath Modules) | Join-Path -ChildPath VoiceActorRadioDownloader) ;\
    Remove-Item -Path \$tmpDir -Recurse -Force ;\
"

ENTRYPOINT pwsh
