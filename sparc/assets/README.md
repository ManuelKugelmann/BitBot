# Assets

This directory contains visual assets and branding elements used in BitBot's development and documentation.

## Contents

### Logo
- **`bitbot-logo.sh`** - ASCII art logo generator script

## Logo Usage

The BitBot logo is displayed:
- In the CLI `bitbot help` command
- During first-run initialization
- In development documentation

### Generating the Logo

```bash
source sparc/assets/bitbot-logo.sh
print_bitbot_logo
```

### Production Integration

The logo script is integrated into production code:
- **Production location**: `/core/util/logo.sh`
- **Used by**: `/core/workspace/bitbot-help.sh`, `/core/global/bitbot-init.sh`

## Design Guidelines

### ASCII Art Logo
- **Width**: Designed for 80-character terminal width
- **Colors**: Uses ANSI color codes (blue for "Bit", cyan for "Bot")
- **Format**: Shell function for easy integration

### Future Assets

This directory is prepared to hold:
- Architecture diagrams (Phase 3)
- Sequence diagrams
- Flow charts
- Icon files
- Screenshots for documentation

## Not Included in Release

Logo scripts in `sparc/assets/` are development artifacts. The production logo is distributed via `/core/util/logo.sh`.

## See Also

- **Production Logo**: `/core/util/logo.sh`
- **Logo Integration**: `/core/workspace/bitbot-help.sh` (help command)
- **First Run**: `/core/global/bitbot-init.sh` (onboarding)
