FROM vault:0.10.3

RUN apk -v --update add bash curl gettext jq python3 py3-pip && python3 -m pip install awscli --upgrade 

COPY scripts /scripts
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
