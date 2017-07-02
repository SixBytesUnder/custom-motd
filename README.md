Custom MOTD
====

### Be aware this is a very early version! ###

#### Highly customizable Message of the Day script for Raspberry Pi ####

Written in Bash. No dependancies. Tested with Raspbian only.

The following steps may vary depending on the OS. So far tested only on Raspbian Jessie.

- Download and save the `motd.sh` bash script onto your Raspberry Pi. Remember to add execution permissions and change the owner:
  
  ```bash
  $ sudo chown root:root /etc/profile.d/motd.sh
  $ sudo chmod +x /etc/profile.d/motd.sh
  ```
  
  After above remember you can just run the script to test if it works
  
  ```bash
  ./etc/profile.d/motd.sh
  ```
  
- You can remove default MOTD, but it's not necessary since the script will clean the screen anyway.
  
  ```bash
  $ sudo rm /etc/motd
  ```
  
- For the same reason as above, not necessary but you may want to remove the "last login" message. Disable the `PrintLastLog` option from the `sshd` service. 
  
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


Weather region codes: https://pastebin.com/dbtemx5F