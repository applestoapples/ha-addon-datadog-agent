ARG BUILD_FROM
FROM gcr.io/datadoghq/agent:7 AS agent

FROM ${BUILD_FROM}

# Install dependencies for journald and logs support
RUN apt-get update && apt-get install -y --no-install-recommends 
    jq 
    libsystemd0 
    systemd 
    && rm -rf /var/lib/apt/lists/*

# Copy the agent from the official image
COPY --from=agent /opt/datadog-agent /opt/datadog-agent
COPY --from=agent /etc/datadog-agent /etc/datadog-agent

# Set up environment
ENV PATH="/opt/datadog-agent/bin/agent/:${PATH}"

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
