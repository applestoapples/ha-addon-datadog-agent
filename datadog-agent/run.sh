#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

# Read add-on options
DD_API_KEY=$(bashio::config 'dd_api_key')
DD_SITE=$(bashio::config 'dd_site')
DD_HOSTNAME=$(bashio::config 'dd_hostname')

export DD_API_KEY
export DD_SITE
export DD_HOSTNAME
export DD_LOGS_ENABLED=true
export DD_LOG_LEVEL=info

bashio::log.info "Starting Datadog Agent (v0.9.2)..."

# Find actual journal path
# HAOS uses /run/log/journal for volatile logs (current boot)
# and /var/log/journal for persistent logs.
JOURNAL_PATH="/var/log/journal"
if [ -d "/run/log/journal" ]; then
    JOURNAL_PATH="/run/log/journal"
    bashio::log.info "Using volatile journal path: $JOURNAL_PATH"
fi

# Create datadog.yaml
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: info
# Better metadata for containers
logs_config:
  container_collect_all: true
EOF

# Configure journald log collection
# We add source:haos to make it easy to find everything from this host
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: $JOURNAL_PATH
    source: haos
EOF

# Ensure permissions
chmod -R 755 /etc/datadog-agent

# Start the agent
exec /opt/datadog-agent/bin/agent/agent run
