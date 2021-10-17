ARG PWSH_TAG=latest
FROM mcr.microsoft.com/powershell:$PWSH_TAG

COPY modules /usr/local/share/powershell/Modules/VoiceActorRadioDownloader

RUN apt update && \
    apt --yes install ffmpeg && \
    apt-get clean && \
    mkdir /vard

ENTRYPOINT ["pwsh", "-Command"]
