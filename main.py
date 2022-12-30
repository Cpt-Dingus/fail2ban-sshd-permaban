# Made by Cpt-Dingus
# v1.3.1 - 31.12.2022


# -- Config --

# Amount of bans before a permaban [Default = 3]
ban_trigger = 3

# Scanning depth, options:
#  > [0] -> Only scan for fail2ban banned IPs [DEFAULT]
#  > [1] -> Scan auth.log for IPs that sshd is unable to negotiate with (No matching MACs, later referred to as UNW)
#  > [2] -> Scan auth.log for IPSs that are attempting to access root
#  > [3] -> Scan auth.log for all invalid users
#  > [4] -> All of the above
# Note: You can select multiple options at once, eg: [13]
depth = "0"



# -- Imports --

import os
import json
import datetime



# -- Vars --

work_dir = os.path.dirname(os.path.realpath(__file__))  
dict_path = os.path.join(work_dir, "ip_dict_storage.json")

ip_dict = {}
permabanned_ips = []

print(f'PY: Script started at {datetime.datetime.now().strftime("%m/%d/%Y, %H:%M:%S")}')


# Pulls IPs via a bash script, as python cannot directly run sudo commands
print("PY: Calling load")
os.system(f'sudo {os.path.join(work_dir, "main.sh")} -m load -d {depth}')


# Loading JSON lists
ips_json = json.load(open("/tmp/ips.json", "r"))
banned_ip_list = ips_json['Fail2ban-ips'].split() # Pre-parsed
permabanned_ips = ips_json['Permabanned-ips'].replace('sshd_ ', '').split()
UNW_list = ips_json['UNW'].split()
root_list = ips_json['Root_list'].split()
invalid_user_list = ips_json['Invalid_user_list'].split()


# -- Defs --

def parse_list(usr_list, trigger_word):
    global ip_dict
    prev_dtc = False
    buffer = []
    
    # Parsing
    for word in usr_list:
        if prev_dtc is True:
            buffer.append(word)
            prev_dtc = False
        
        if word == trigger_word:
            prev_dtc = True

    # Appending to dict
    for ip in buffer:
        if not ip in ip_dict:
            ip_dict[ip] = 1
        else:
            ip_dict[ip] += 1
        


# -- List parsing --

# 0 - Banned check
if "0" in depth or depth == "4": parse_list(banned_ip_list, "Ban")

# 1 - UNW check
if "1" in depth or depth == "4": parse_list(UNW_list, "with")

# 2 - Root access check
if "2" in depth or depth == "4":  parse_list(root_list, "root")

# 3 - Invalid user check
if "3" in depth or depth == "4":  parse_list(invalid_user_list, "from")


# Add IP to hosts.deny if it isn't there already
for ip in ip_dict:
    if ip_dict[ip] > ban_trigger and ip not in permabanned_ips:
        print(f"PY: Calling append of {ip}")
        os.system(f'sudo {os.path.join(work_dir, "main.sh")} -m append -i {ip}')


if ip_dict == {}: print("PY: No new IPs to append")

# -- Cleanup --

print("PY: Calling cleanup")
os.system(f'sudo {os.path.join(work_dir, "main.sh")} -m cleanup')

