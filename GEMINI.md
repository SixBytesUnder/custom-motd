# Project: Raspberry Pi MOTD

## Description

This project consists of a highly customizable Bash script (`motd.sh`) designed to display a "Message of the Day" (MOTD) upon logging into a Raspberry Pi or other Linux system. It provides a colorful and informative overview of various system metrics.

The script is modular, allowing users to easily enable, disable, and reorder the information panels by editing a configuration array. It fetches data from system files (`/proc`, `/sys`), standard Linux commands, and external services (for weather and IP information).

## Coding Style

- **Indentation**: 4 spaces are used for indentation within blocks and control structures.
- **Variable Naming**: A mix of `camelCase` (e.g., `weatherCode`) and `lowercase` (e.g., `logo`) is used for variables. Module names in the configuration section are `UPPERCASE` (e.g., `SYSTEM`, `MEMORY`).
- **Functions**: Function names are written in `camelCase` (e.g., `displayMessage`).
- **Comments**: The script is well-commented, with clear sections for user settings and explanations for specific commands.
- **Quoting**: Both single (`'`) and double (`"`) quotes are used for strings.
- **Shebang**: The script explicitly uses `#!/bin/bash`.

## Workflow & Git Rules

- **Auto-Commit on Task/Feature Completion**: Always stage and commit changes to Git (`git add` and `git commit` with a clear, descriptive message) whenever a given feature, fix, or task is completed.

## Code Structure

1. **Configuration Section**: All user-configurable settings are consolidated at the top of the script. This includes:
  - An array `settings` that defines which information modules are displayed and in what order (`LOGOSMALL`, `LOGOBIG`, `MODEL`, `SYSTEM`, `DATE`, `UPTIME`, `MEMORY`, `DISKS`, `LOADAVERAGE`, `PROCESSES`, `IP`, `UPDATES`, `WEATHER`, `CPUTEMP`, `GPUTEMP`, `THROTTLED`, `SERVICES`, `DOCKER`, `SSHLOGINS`, `LASTLOGIN`, `MESSAGES`).
  - Variables for screen-clearing behavior (`clearScreen`), location (`weatherCode`), temperature units (`degrees`), cache TTL (`cacheTTL`), and warning thresholds (`tempWarnC`, `memWarnPct`, `diskWarnPct`).
  - An associative array `colour` for defining terminal ANSI color codes.
2. **Core Logic**:
  - A helper function `displayMessage` handles the formatted and colored output.
  - A helper function `getCached` caches the output of slow commands (`IP`, `UPDATES`, `WEATHER`) in `/tmp` for `cacheTTL` seconds.
  - A central function `metrics` contains a `case` statement that holds the logic for each individual information module.
3. **Execution Flow**:
  - The script begins by checking for Bash 4+ version compatibility (for associative array support).
  - It optionally clears the screen according to `clearScreen` (`"interactive"`, `"always"`, or `"never"`).
  - It then iterates through the user-defined `settings` array.
  - For each setting, it calls the `metrics` function to display the corresponding information panel.
  - Finally, it resets the terminal colors.

## Tool Preferences

The script relies on a set of standard and powerful command-line tools to gather and process information:

- **System & Hardware Info**:
  - `uname`, `date`, `df`, `ps`, `who`, `last`, `hostname`, `systemctl`, `docker`, `journalctl`
  - Direct reads from `/proc` filesystem (`/proc/uptime`, `/proc/meminfo`, `/proc/loadavg`, `/proc/device-tree/model`).
  - Direct reads from `/sys` filesystem for CPU temperature (`/sys/class/thermal/thermal_zone0/temp`).
  - `vcgencmd` (Raspberry Pi specific) for GPU temperature and throttling/under-voltage status (`get_throttled`).
- **Text Processing**:
  - `awk`: Used extensively for parsing, formatting, and threshold checking on command outputs.
  - `grep`: For filtering lines based on patterns.
  - `cut`: For extracting specific fields from lines.
  - `tr`: For character translation.
- **Networking**:
  - `hostname -I`: To get the local IP address.
  - `curl`: To fetch the external IP address (`https://icanhazip.com/`) and weather data (`https://wttr.in/`) with timeouts.
- **Terminal Formatting**:
  - ANSI escape sequences (`$'\e[...m'`) for fast, subshell-free terminal coloring.
