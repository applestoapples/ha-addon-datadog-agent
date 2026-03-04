ARG BUILD_FROM=gcr.io/datadoghq/agent:7
FROM ${BUILD_FROM}

RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
