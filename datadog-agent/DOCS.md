# Datadog Agent Add-on

Ships Home Assistant OS logs to Datadog via the journald integration.

## Configuration

| Option       | Description                          | Default          |
|--------------|--------------------------------------|------------------|
| `dd_api_key` | Your Datadog API key (required)      | —                |
| `dd_site`    | Datadog intake site                  | `datadoghq.com`  |
| `dd_tags`    | List of tags to apply to all logs    | `[]`             |

## How it works

The add-on runs the official Datadog Agent container with `journald: true` in the
add-on manifest, which mounts `/var/log/journal` read-only. The agent reads system
journal entries and forwards them to Datadog over HTTPS.

No inbound ports are required — the agent pushes logs to the Datadog intake.

## Installation

1. Add this repository to Home Assistant: **Settings > Add-ons > Add-on Store > ⋮ > Repositories**
2. Install the **Datadog Agent** add-on
3. Set your `dd_api_key` in the add-on configuration
4. Start the add-on
