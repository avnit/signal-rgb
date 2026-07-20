# signal-rgb — SignalRGB × Claude (MCP) tooling

Control [SignalRGB](https://signalrgb.com) from Claude Desktop, Claude Code, or any
[Model Context Protocol](https://modelcontextprotocol.io) client — plus a tiny CLI for
scripting it directly. "Set my RGB to a calm blue", "make the lights follow the screen",
"switch to an audio visualizer" — all natural-language, all local.

SignalRGB (v2.5.72+) ships its own MCP server (`SignalRgbMcp.exe`), a stdio JSON-RPC
server exposing ~60 tools: apply/install effects, tweak effect properties live,
per-LED overrides, device settings and layouts, and app/debug logs. This repo is the
glue that makes it easy to wire up and keep working across SignalRGB updates.

## The update problem this solves

SignalRGB installs into a **version-specific** folder:

```
%LOCALAPPDATA%\VortxEngine\app-<version>\Signal-x64\SignalRgbMcp.exe
```

Point your MCP config at that path and it silently breaks on the next SignalRGB
auto-update. [`signalrgb-mcp.cmd`](signalrgb-mcp.cmd) resolves the newest installed
version at launch time, so your config never goes stale.

## Setup

1. **Enable MCP in SignalRGB**: Settings → Application → AI Integration →
   toggle **Enable Model Context Protocol**, then **restart SignalRGB**
   (the toggle does nothing until restart — the server answers
   `"MCP is currently disabled"` otherwise).
2. Copy `signalrgb-mcp.cmd` somewhere stable, e.g. `%USERPROFILE%\.claude\mcp\`.

### Claude Code

```powershell
claude mcp add --scope user signalrgb -- cmd /c "%USERPROFILE%\.claude\mcp\signalrgb-mcp.cmd"
claude mcp list   # signalrgb: ... - √ Connected
```

### Claude Desktop

Add to `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "signalrgb": {
      "command": "cmd",
      "args": ["/c", "C:\\Users\\YOU\\.claude\\mcp\\signalrgb-mcp.cmd"]
    }
  }
}
```

Restart Claude Desktop afterwards.

## CLI helper — `srgb.ps1`

Script SignalRGB without an MCP client (handshake + one tool call + exit):

```powershell
# What's running right now?
.\srgb.ps1 -Tool read_status

# Sync lights to whatever is on screen (movies, YouTube, games)
.\srgb.ps1 -Tool effect_apply -ArgsJson '{"name":"Screen Ambience"}'
.\srgb.ps1 -Tool effect_setproperties -ArgsJson '{"picture_mode":"Vivid","saturation":40}'

# Beat-reactive instead (reacts to system audio — Spotify, YouTube Music, anything)
.\srgb.ps1 -Tool effect_apply -ArgsJson '{"name":"Rave Visualizer"}'
```

## Tool highlights

| Tool | What it does |
| :--- | :--- |
| `read_status` / `read_effects` / `read_devices` | Current effect, effect library, connected devices |
| `effect_apply` / `effect_install` | Switch or install effects by name |
| `effect_setproperties` | Live-tweak the active effect (colors, sensitivity, modes) |
| `read_effectsettings` | Discover the active effect's tunable properties |
| `device_ledoverrides` | Pin individual LEDs to a color |
| `debug_*` | App, effect, plugin, and canvas logs |

## Notes

- Windows only (SignalRGB is Windows-only).
- Audio-reactive effects listen to the system's default audio output — no per-app wiring.
- SignalRGB also integrates with **NVIDIA G-Assist** (Settings → AI Integration) once
  G-Assist is installed via the NVIDIA App (RTX GPU with 6 GB+ VRAM required).
