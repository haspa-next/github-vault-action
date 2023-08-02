FROM vault:0.10.4

RUN apk -v --update add bash curl gettext jq python3 py3-pip && python3 -m pip install --upgrade pip && python3 -m pip install awscli --upgrade 

COPY scripts /scripts
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
