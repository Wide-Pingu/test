 FROM ubuntu:latest


COPY exportGlobalRightsToNotion.sh exportSpecificRightsToNotion.sh script_chapeau.sh /

COPY keycloak_export_helpers/ /keycloak_export_helpers/


RUN apt-get update && apt-get install -y \
    curl \
    gh \
    git \
    jq \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

CMD ["bash","-c","keycloak_export_helpers/export-git-config.sh; /exportGlobalRightsToNotion.sh; /exportSpecificRightsToNotion.sh"]
