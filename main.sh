#!/bin/bash

# Made by Cpt-Dingus
# v1.3 - 10.12.2022



# -- CLI args --

while getopts m:i:d: flag
do
    case "${flag}" in
	m) mode=${OPTARG};;
	i) ip=${OPTARG};;
	d) depth=${OPTARG};;
    esac
done

# Mode - Options:
#	  > load    -> Load selected files, send contents to ips.json in /tmp
#	  > append  -> Append Ip parameter to /etc/hosts.deny
# 	  > cleanup -> Remove ips.json from /tmp

# Ip - Passed ip to append if Mode is [append]

# Depth - Options:
#         > [0] -> Only scan for fail2ban banned IPs [DEFAULT]
#         > [1] -> Scan auth.log for IPs that sshd is unable to negotiate with (No matching MACs)
#         > [2] -> Scan auth.log for IPSs that are attempting to access root 
#         > [3] -> Scan auth.log for all invalid users
# 	  > [4] -> All of the above
# Note: You can select multiple options at once, eg: [13]



# -- Processing 'mode' flag --

# Cleans up temp file
if [ "$mode" = "cleanup" ]; then
	sudo rm -rf /tmp/ips.json
	echo "SH: Removed ips.json"
	exit 0
fi

# Appends IP to hosts.deny if script is done already
if [ "$mode" = "append" ]; then
	sudo echo "sshd: $ip" >> /etc/hosts.deny
	echo "SH: Appended $ip to hosts.deny"
	exit 0
fi

# Makes sure proper mode is selected
if [ "$mode" != "load" ]; then
	echo "SH: Wrong/no mode flag detected! Please run this script with -m load to push IPs to a JSON, -m append to append an -i ip to hosts.deny, or -m cleanup to clean up the temporary JSON"
	exit 1
fi


# TODO: If block borked
#if [ "$(grep -vo 01234 <<< "$depth")" ]; then
#	echo "SH: Wrong/no depth flag detected! Refer to the config, fix the -d flag accordingly."
#	exit 1
#fi




# -- Vars --


# Get already permabanned IPs
raw_permabanned_list=$(sudo zgrep 'sshd' /etc/hosts.deny)

prev_sshd="False"
prev_ban="False"
ip_list=()
permabanned_list=()



# -- Optional vars --

raw_ban_list="Skipping"

if [[ $depth =~ 0 || $depth = "4" ]]; then
	# Raw list of IPs banned by fail2ban (Will get parsed by SH)
	raw_ban_list=$(sudo zgrep 'Ban' /var/log/fail2ban.log)
fi


# All of these are outputted raw, they will get parsed by the python script (PY).

raw_UNW_list="Skipping"

if [[ $depth =~ 1 || $depth = "4" ]]; then 
	# Raw list of unable to negotiate with IPs
	raw_UNW_list=$(sudo zgrep 'Unable to negotiate with' /var/log/auth.log | sudo zgrep 'sshd' | tr : _ | tr -d '\n')
fi


raw_root_list="Skipping"

if [[ $depth =~ 2 || $depth = "4" ]]; then
	# Raw list of IPs that tried to auth as root
	raw_root_list=$(sudo zgrep 'Connection closed by authenticating user root' /var/log/auth.log | sudo zgrep 'sshd' | tr : _ | tr -d '\n')
fi



raw_invalid_user_list="Skipping"

if [[ $depth =~ 3 || $depth = "4" ]]; then
	# Raw list of IPs that tried to auth as an invalid user
	raw_invalid_user_list=$(sudo zgrep 'Failed password for invalid user' /var/log/auth.log | sudo zgrep 'sshd' | sed "s/invalid user user/invalid user/" | tr : _ | tr -d '\n')

fi



# -- Parsing list --

# Separates fail2ban log by spaces, if an IP is banned pulls it
for item in $raw_ban_list
do
	if [ "$prev_ban" = "True" ]; then
		ip_list+=( "${item/e/'\n'/} " )
		prev_ban="False"
	fi


	if [ "$item" = "Ban" ]; then
		prev_ban="True"
	fi
done


# Separates hosts.deny, if an sshd IP is banned, pulls it
for item in $raw_permabanned_list
do
	if [ "$prev_sshd" = "True" ]; then
		permabanned_list+=( "${item} " )
		prev_sshd="False"
	fi

	if [ "$item" = "sshd:" ]; then
		prev_sshd="True"
	fi
done



# -- Writing to temporary JSON --

echo "{\"Fail2ban-ips\":\"${ip_list[*]}\",\"Permabanned-ips\":\"${permabanned_list[*]}\",\"UNW\":\"$raw_UNW_list\",\"Root_list\":\"$raw_root_list\",\"Invalid_user_list\":\"$raw_invalid_user_list\"}" > /tmp/ips.json
echo "SH: Made new ips.json in /tmp"

