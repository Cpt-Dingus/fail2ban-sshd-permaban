# Made by Cpt-Dingus
# v1.2.1 - 30.11.2022


# -- Config --

# Amount of bans before a permaban [Default = 3]
ban_trigger = 3


# -- Imports --

import os
import json
import datetime

# -- Vars --

work_dir = os.path.dirname(os.path.realpath(__file__))  
ip_dict = {}



# -- Startup --

print('PY: Script started at {datetime.now.strftime("%m/%d/%Y, %H:%M:%S")}')


# Pulls IPs via a bash script, as python cannot directly run sudo commands
print("PY: Calling load")
os.system(f'sudo {os.path.join(work_dir, "main.sh")} -m load')


# Loading JSON
ips_json = json.load(open("/tmp/ips.json", "r"))
ip_list = ips_json['Fail2ban-ips'].split()
banned_ips = ips_json['Permabanned-ips'].split()



# -- Main --

# Add IPs to dictionary
for ip in ip_list:
    if not ip in ip_dict:
        ip_dict[f'{ip}'] = 1

    else:
        ip_dict[f'{ip}'] += 1


# Add IP to hosts.deny if the file isn't there already
for ip in ip_dict:

    if ip_dict[f'{ip}'] > ban_trigger and ip not in banned_ips:
        print(f"PY: Calling append of {ip}")
        os.system(f'sudo {os.path.join(work_dir, "main.sh")} -m append -i {ip}')


# -- Cleanup --

print("PY: Calling cleanup")
os.system(f'sudo {os.path.join(work_dir, "main.sh")} -m cleanup')
