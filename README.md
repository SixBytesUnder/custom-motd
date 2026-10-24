# Custom MOTD

### Highly customizable Message of the Day script for Raspberry Pi

![](motd.png?raw=true "Custom MOTD")

Written in Bash (requires Bash 4.0+). Compatible with modern **Raspberry Pi OS** (Bookworm, Bullseye, Trixie, and legacy Raspbian releases) as well as Debian, Ubuntu, and most other Linux distributions.

---

## Installation

1. Download and install the `motd.sh` script into `/etc/profile.d/` with execute permissions:

```bash
wget https://raw.githubusercontent.com/SixBytesUnder/custom-motd/master/motd.sh
sudo cp motd.sh /etc/profile.d/motd.sh
sudo chown root:root /etc/profile.d/motd.sh
sudo chmod +x /etc/profile.d/motd.sh
```

2. Execute the script directly to test it:

```bash
/etc/profile.d/motd.sh
```

That's it! Every time you log in via SSH or open a login shell on your Raspberry Pi, you will see the custom Message of the Day.

### Optional System Tweaks

- **Remove the static default MOTD**:
  _(Not strictly required if `clearScreen` is set to `"interactive"` or `"always"`, as the screen is cleared first.)_

  ```bash
  sudo rm -f /etc/motd
  ```

- **Disable default dynamic MOTD scripts** (if `clearScreen="never"` and you don't want duplicate system banners):

  ```bash
  sudo chmod -x /etc/update-motd.d/*
  ```

- **Disable SSH's built-in "Last login" line** (since the `LASTLOGIN` module already displays it):
  Edit `/etc/ssh/sshd_config`:

  ```bash
  sudo vim /etc/ssh/sshd_config
  ```

  Set `PrintLastLog` to `no`:

  ```text
  PrintLastLog no
  ```

  Restart the SSH service:

  ```bash
  sudo systemctl restart ssh || sudo systemctl restart sshd
  ```

---

## Available Modules

You can enable, disable (by commenting out with `#`), or reorder any of the following modules in the `settings` array at the top of `motd.sh`:

| Module        | Description                                                                            |
| :------------ | :------------------------------------------------------------------------------------- |
| `LOGOSMALL`   | Compact Raspberry Pi ASCII/Unicode logo                                                |
| `LOGOBIG`     | Full-size Raspberry Pi ASCII art logo with banner text                                 |
| `MODEL`       | Raspberry Pi board model and hardware revision (`/proc/device-tree/model`)             |
| `SYSTEM`      | Kernel name, hostname, kernel release/version, and architecture (`uname`)              |
| `DATE`        | Current system day, date, and time                                                     |
| `UPTIME`      | System uptime formatted in days, hours, minutes, and seconds                           |
| `MEMORY`      | Available and total RAM in `MiB` with usage percentage                                 |
| `DISKS`       | Mounted physical filesystems with free space, total size, and usage percentage         |
| `LOADAVERAGE` | 1, 5, and 15-minute CPU load averages                                                  |
| `PROCESSES`   | Total number of running processes                                                      |
| `IP`          | Local IP address (`hostname -I`) and external public IP (`icanhazip.com`)              |
| `UPDATES`     | Number of `apt` packages available for upgrade                                         |
| `WEATHER`     | Current temperature and weather conditions via `wttr.in`                               |
| `CPUTEMP`     | CPU thermal zone temperature                                                           |
| `GPUTEMP`     | Raspberry Pi VideoCore GPU temperature (`vcgencmd measure_temp`)                       |
| `THROTTLED`   | Power supply under-voltage and thermal throttling status (`vcgencmd get_throttled`)    |
| `SERVICES`    | Health summary of `systemd` units (lists any failed services)                          |
| `DOCKER`      | Running vs. total Docker container count (automatically hidden if no containers exist) |
| `SSHLOGINS`   | Number of currently logged-in user sessions                                            |
| `LASTLOGIN`   | Details and source IP/host of the previous login session                               |
| `MESSAGES`    | Last 3 system log entries from `/var/log/messages` or `journalctl`                     |

---

## Configuration Options

All user-configurable variables are located in the `SETTINGS` section at the top of `motd.sh`:

- **`settings`**: Array defining which modules are displayed and in what order. Comment out lines with `#` to hide modules.
- **`clearScreen`**: Controls whether the terminal screen is cleared before printing the MOTD:
  - `"interactive"` _(default)_ — Clears only when running in an interactive terminal (`[[ -t 1 && -n "$TERM" ]]`), keeping `scp`, `sftp`, and `update-motd.d` safe.
  - `"always"` — Always runs `clear`.
  - `"never"` — Never clears the screen (preserves pre-login SSH/PAM messages).
- **`weatherCode`**: Location for the `WEATHER` module powered by [wttr.in](https://wttr.in).
  - Examples: `"London"`, `"New+York"`, `"Warsaw"`, or `""` (empty) for automatic IP-based location detection.
- **`degrees`**: Temperature unit for `WEATHER`, `CPUTEMP`, and `GPUTEMP`:
  - `"C"` _(default)_ for Celsius or `"F"` for Fahrenheit.
- **`cacheTTL`**: Cache time-to-live in seconds (default: `3600` = 1 hour) for slow checks (`IP` external lookup, `UPDATES`, and `WEATHER`).
  - Cached values are stored per-user in `/tmp/motd_cache_<UID>_*` so SSH logins remain instantaneous.
  - Set `cacheTTL=0` to disable caching and fetch live data on every login.
- **Warning Thresholds**: Metrics automatically highlight in **red** (`${colour[warning]}`) when they reach or exceed these values:
  - `tempWarnC=70` — CPU or GPU temperature warning threshold in `°C` (applies regardless of whether display is set to `C` or `F`).
  - `memWarnPct=85` — RAM usage percentage warning threshold.
  - `diskWarnPct=85` — Disk usage percentage warning threshold.
- **`colour`**: Associative array mapping semantic roles (`header`, `neutral`, `info`, `warning`, `reset`) to ANSI escape codes:

  | Colour  |  ANSI Code  |
  | :------ | :---------: |
  | Black   | `$'\e[30m'` |
  | Red     | `$'\e[31m'` |
  | Green   | `$'\e[32m'` |
  | Yellow  | `$'\e[33m'` |
  | Blue    | `$'\e[34m'` |
  | Magenta | `$'\e[35m'` |
  | Cyan    | `$'\e[36m'` |
  | White   | `$'\e[37m'` |
  | Reset   | `$'\e[0m'`  |

---

## License

[MIT](https://github.com/SixBytesUnder/custom-motd/blob/master/LICENSE)
