# Hoop Config Manager

A command-line utility to easily manage and switch between multiple Hoop configurations.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/hoophq/utilities/main/config-mgr/install.sh | bash
```

Or download and install manually:

```bash
curl -fsSL https://raw.githubusercontent.com/hoophq/utilities/main/config-mgr/hoop-config-manager.sh -o /usr/local/bin/hoop-config
chmod +x /usr/local/bin/hoop-config
```

## Usage

### View Current Config and List All

```bash
hoop-config
```

Output:
```
Currently loaded: demo

Saved configurations:

  • demo
    API: https://demo.hoop.dev
  • sandbox
    API: https://sandbox.hoop.dev
```

### Create a New Config

```bash
hoop-config add staging
```

You'll be prompted for:
- **API URL** (required): e.g., `https://staging.hoop.dev`
- **gRPC URL** (optional): Defaults to `grpcs://<hostname>:8443` from API URL
- **TLS CA path** (optional): Path to CA certificate
- **Skip TLS verification** (optional): `true` or `false` (default: `false`)

### Save Current Config

```bash
hoop-config save production
```

Saves your currently active config with a name for later use.

### Switch Configs

```bash
hoop-config load staging
```

Switches to a saved configuration. Your previous config is automatically backed up.

### List All Configs

```bash
hoop-config list
```

Shows all saved configurations with their API URLs.

### Show Current Config Details

```bash
hoop-config current
```

Displays detailed information about the currently active configuration.

### Delete a Config

```bash
hoop-config delete old-config
```

Removes a saved configuration.

### Get Help

```bash
hoop-config help
```

## Examples

### Setting Up Multiple Environments

```bash
# Create and configure development environment
hoop-config add dev
# Enter: https://dev.hoop.dev
# Press Enter to accept default gRPC URL
# Skip TLS CA
# Enter: false

# Create staging environment
hoop-config add staging
# Enter: https://staging.hoop.dev
# Press Enter to accept defaults

# Create production environment
hoop-config add production
# Enter: https://prod.hoop.dev
# Enter custom gRPC: grpcs://prod.hoop.dev:9443
# Skip TLS CA
# Enter: false
```

### Switching Between Environments

```bash
# Switch to development
hoop-config load dev

# Do some work...

# Switch to staging for testing
hoop-config load staging

# Check what's currently loaded
hoop-config
```

### Saving Changes

```bash
# Make manual changes to ~/.hoop/config.toml
# Then save them
hoop-config save custom-setup
```

## How It Works

- Configs are stored in: `~/.hoop/configs/`
- Active config is at: `~/.hoop/config.toml`
- The tool compares your active config against saved configs to show which one is loaded
- If you've modified the active config, it shows as "custom (unsaved)"

## Optional: Shorter Alias

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias hc='hoop-config'
```

Then use:
```bash
hc              # View status
hc load dev     # Load dev config
hc add staging  # Add staging config
```

## Troubleshooting

### Permission Denied
If you get permission errors during installation:
```bash
curl -fsSL https://raw.githubusercontent.com/hoophq/utilities/main/config-mgr/install.sh | sudo bash
```

### Config Not Found
Make sure you've saved configs before trying to load them:
```bash
hoop-config list  # See all saved configs
```

### Custom Config Shows Instead of Named Config
If you see "custom (unsaved)" but expect a named config, your active config has been modified. Either:
- Save it as a new config: `hoop-config save new-name`
- Reload the original: `hoop-config load original-name`

## Requirements

- Bash 4.0+
- Standard Unix tools: `sed`, `grep`, `diff`

## License

Internal tool for Hoop team use.
