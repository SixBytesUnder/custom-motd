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

## Code Structure

1.  **Configuration Section**: All user-configurable settings are consolidated at the top of the script. This includes:
    - An array `settings` that defines which information modules are displayed and in what order.
    - Variables for location (`weatherCode`) and temperature units (`degrees`).
    - An associative array `colour` for defining terminal color codes using `tput`.
2.  **Core Logic**:
    - A helper function `displayMessage` handles the formatted and colored output.
    - A central function `metrics` contains a `case` statement that holds the logic for each individual information module (e.g., `UPTIME`, `DISKS`, `WEATHER`).
3.  **Execution Flow**:
    - The script begins by checking for Bash version compatibility (specifically for array support).
    - It then iterates through the user-defined `settings` array.
    - For each setting, it calls the `metrics` function to display the corresponding information panel.
    - Finally, it resets the terminal colors.

## Tool Preferences

The script relies on a set of standard and powerful command-line tools to gather and process information:

-   **System & Hardware Info**:
    -   `uname`, `date`, `df`, `ps`, `who`, `last`
    -   Direct reads from `/proc` filesystem (`/proc/uptime`, `/proc/meminfo`, `/proc/loadavg`).
    -   Direct reads from `/sys` filesystem for CPU temperature.
    -   `vcgencmd` (Raspberry Pi specific) for GPU temperature.
-   **Text Processing**:
    -   `awk`: Used extensively for parsing and extracting data from command outputs.
    -   `grep`: For filtering lines based on patterns.
    -   `sed`: For stream editing, particularly for parsing the weather RSS feed.
    -   `cut`: For extracting specific fields from lines.
    -   `tr`: For character translation.
-   **Networking**:
    -   `ip`: To get the local IP address.
    -   `curl` / `wget`: To fetch the external IP address and weather data from online sources.
-   **Terminal Formatting**:
    -   `tput`: To apply colors to the output for better readability.
