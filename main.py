# Made by Cpt-Dingus
# v1.0 - 27.11.2022


# -- Config --

# Amount of bans before a permaban [Default = 3]
permaban = 3


# -- Imports --

import os
import json

# Pulls IPs via a bash script, as python cannot directly run sudo commands
os.system("sudo ./main.sh -m load")


# -- Vars --

# Loading JSON
ips_json = json.load(open("ips.json", "r"))
ip_list = ips_json['Fail2ban-ips'].split()
banned_ips = ips_json['Permabanned-ips'].split()

ip_dict = {}


# -- Main --

# Add IPs to dictionary
for ip in ip_list:
    if not ip in ip_dict:
        ip_dict[f'{ip}'] = 1

    else:
        ip_dict[f'{ip}'] += 1


# Add IP to hosts.deny if the file isn't there already
for ip in ip_dict:

    if ip_dict[f'{ip}'] > 3 and ip not in banned_ips:
        os.system(f"sudo ./main.sh -m append -i {ip}")


# Cleanup
os.system("sudo ./main.sh -m cleanup")
