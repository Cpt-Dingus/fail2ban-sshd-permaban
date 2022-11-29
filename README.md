# Fail2ban-sshd-permaban
- Permabans an IP from accesing your SSH server after X bans from [Fail2Ban](https://github.com/fail2ban/fail2ban) by adding it to /etc/hosts.deny
- Uses Python and a bash script
- Can be automated using CRON

## Setup
1. Clone repo and cd into it

> `git clone https://github.com/Cpt-Dingus/fail2ban-sshd-permaban && cd fail2ban-sshd-permaban`

2. Optional config

Open main.py with nano (or another editor), set the `permaban` value to the amount of bans that should trigger a permaban [Default is 3]

3. Set up a CRON schedule for main.py

Example: Hourly check

> `crontab –e`

> `0 * * * * python /path/to/script/main.py`
