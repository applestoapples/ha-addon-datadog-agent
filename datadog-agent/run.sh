#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

# Read add-on options
DD_API_KEY=$(bashio::config 'dd_api_key')
DD_SITE=$(bashio::config 'dd_site')
DD_HOSTNAME=$(bashio::config 'dd_hostname')

if [ -z "$DD_API_KEY" ]; then
  bashio::log.error "dd_api_key is required"
  exit 1
fi

export DD_API_KEY
export DD_SITE
export DD_HOSTNAME
export DD_LOGS_ENABLED=true
export DD_LOG_LEVEL=debug
export DD_JOURNALD_PATH=/var/log/journal

bashio::log.info "STARTUP: Diagnostic check (v0.7.8)..."
bashio::log.info "STARTUP: Current user: $(id)"

# Create a minimal datadog.yaml
bashio::log.info "STARTUP: Generating datadog.yaml..."
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: debug
EOF

# Configure journald log collection
bashio::log.info "STARTUP: Configuring journald integration..."
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: /var/log/journal
EOF

# Ensure the agent can read everything
chmod -R 777 /etc/datadog-agent

bashio::log.info "STARTUP: Checking /var/log/journal contents..."
if [ -d "/var/log/journal" ]; then
  bashio::log.info "Found /var/log/journal"
  ls -F /var/log/journal || bashio::log.warn "Could not list /var/log/journal"
else
  bashio::log.warn "/var/log/journal not found!"
fi

bashio::log.info "STARTUP: Starting Datadog Agent..."
exec /opt/datadog-agent/bin/agent/agent run
