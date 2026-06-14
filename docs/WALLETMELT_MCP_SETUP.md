# WalletMelt V2: Flutter & Dart MCP Server Setup

This document records the installation and configuration of the first-party Flutter/Dart Model Context Protocol (MCP) server for this repository.

---

## 1. What was Installed/Configured
We configured the **built-in** stdio-based Dart and Flutter MCP server (`dart mcp-server`) that comes pre-packaged with the Dart SDK (version `3.12.2` or later).

Exposed capabilities include:
- `analyze_files`: Direct codebase syntax and warning linting.
- `dart_fix` / `dart_format`: Idiomatic, style-compliant refactoring.
- `pub` / `pub_dev_search`: Package/dependency constraint awareness.
- `hot_reload` / `hot_restart`: VM integration for agentic hot reloading.
- `list_devices` / `list_running_apps`: Emulator/device status queries.
- `widget_inspector` / `lsp`: Structural UI tree and LSP code inspection.

---

## 2. Configuration Details
- **Configuration File Path:** `C:\Users\Hp\.gemini\antigravity-cli\mcp_config.json`
- **Config File Contents:**
  ```json
  {
    "mcpServers": {
      "dart-flutter": {
        "command": "dart",
        "args": [
          "mcp-server"
        ]
      }
    }
  }
  ```

---

## 3. How to Verify
To verify that the MCP server is available and functional in the local shell environment:
1. Run the help command to check usage parameters:
   ```powershell
   dart help mcp-server
   ```
2. Run the version command:
   ```powershell
   dart mcp-server --version
   ```
   *(Exits with code 0 and prints the current MCP version, e.g. `0.1.4`)*.

---

## 4. How Antigravity CLI Activates the Server
Antigravity automatically loads definitions from `%USERPROFILE%\.gemini\antigravity-cli\mcp_config.json` on startup. 

**Required Action:** If Antigravity CLI was already running, a simple restart/reload of the CLI agent session is required to initialize the new `dart-flutter` MCP server host instance.

---

## 5. Production Code Integrity
- **Production Source Code (`lib/`):** **UNTOUCHED** (No files modified).
- **App Screens / DB / Repositories:** **UNTOUCHED**.
- **Tests (`test/`):** **UNTOUCHED** (All 44 unit and widget tests remain intact and green).
