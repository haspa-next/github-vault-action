FROM vault:1.9.2

RUN apk -v --update add bash curl gettext jq python3 py3-pip && python3 -m pip install awscli --upgrade --use-deprecated=legacy-resolver

COPY scripts /scripts
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
