#!/usr/bin/env bashio
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
export DD_LOG_LEVEL=info

bashio::log.info "Starting Datadog Agent (v0.9.1)..."

# Create datadog.yaml
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: info
EOF

# Find the active journal path
# HAOS uses /run/log/journal for volatile logs (current boot)
# and /var/log/journal for persistent logs.
JOURNAL_PATH="/var/log/journal"
if [ -d "/run/log/journal" ]; then
    JOURNAL_PATH="/run/log/journal"
    bashio::log.info "Using volatile journal path: $JOURNAL_PATH"
fi

# Configure journald log collection
# We remove unit filters to match ha-addon-syslog behavior (get everything)
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: $JOURNAL_PATH
EOF

# Ensure permissions
chmod -R 755 /etc/datadog-agent

# Start the agent
exec /opt/datadog-agent/bin/agent/agent run
