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
export DD_LOG_LEVEL=debug

bashio::log.info "Starting Datadog Agent (v0.8.5)..."

# Create datadog.yaml
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: debug
EOF

# Configure journald log collection
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: /var/log/journal
EOF

# Start the agent in background to capture status
/opt/datadog-agent/bin/agent/agent run &
AGENT_PID=$!

bashio::log.info "Waiting for agent to initialize..."
sleep 15

bashio::log.info "Running agent status..."
/opt/datadog-agent/bin/agent/agent status || bashio::log.error "Failed to get agent status"

bashio::log.info "Running agent check journald..."
/opt/datadog-agent/bin/agent/agent check journald || bashio::log.warn "Journald check failed (normal if not a check)"

# Keep running
wait $AGENT_PID
