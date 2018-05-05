Custom MOTD
====

#### Highly customizable Message of the Day script for Raspberry Pi ####

![](motd.png?raw=true "Custom MOTD")

Written in Bash. No other dependancies. So far tested with Raspbian Jessie only, but should work with most other Linux distributions.

The following steps may vary depending on the OS.

- Download and save the `motd.sh` bash script onto your machine. Remember to add execute permissions and change the owner:
  
  ```bash
  $ sudo cp motd.sh /etc/profile.d/motd.sh
  $ sudo chown root:root /etc/profile.d/motd.sh
  $ sudo chmod +x /etc/profile.d/motd.sh
  ```
    
  Just run the script to test if it works
  
  ```bash
  ./etc/profile.d/motd.sh
  ```
  
- You can remove default MOTD, but it's not necessary since the script will clean the screen anyway.
  
  ```bash
  $ sudo rm /etc/motd
  ```
  
- For the same reason as above, not necessary, but you may want to remove the "last login" message. Disable the `PrintLastLog` option from the `sshd` service.
  
  ```bash
  $ sudo vim.tiny /etc/ssh/sshd_config
  ```
  
  You should see:
  
  ```text
  PrintLastLog yes
  ```
  
  Change it to:
  
  ```text
  PrintLastLog no
  ```
  
  Restart the `sshd` service:
  
  ```bash
  $ sudo systemctl restart sshd
  ```

### Options ###

At the top of the file are variables allowing customization of the messages:

- `settings` array contains all possible messages to be displayed.
  Comment lines with a `#` for messages you don't want to see.
  Change order of items in array to change order of displayed messages.

- `weatherCode` set region code for the weather message.
  Full list of available [Accuweather location codes](accuweather_location_codes.txt)

- `colour` array, lets you set your own clours. List of colour codes:

  | Colour | Value |
  |--------|:-----:|
  | black  |   0   |
  | red    |   1   |
  | green  |   2   |
  | yellow |   3   |
  | blue   |   4   |
  | magenta|   5   |
  | cyan   |   6   |
  | white  |   7   |

## License

[MIT](https://github.com/SixBytesUnder/custom-motd/blob/master/LICENSE)
