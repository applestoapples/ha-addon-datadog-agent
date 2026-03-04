ARG BUILD_FROM=gcr.io/datadoghq/agent:7
FROM ${BUILD_FROM}

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
