#!/bin/bash

# Made by Cpt-Dingus
# v1.2.1 - 30.11.2022


# -- CLI args --
while getopts i:m: flag
do
    case "${flag}" in
        i) ip=${OPTARG};;
	m) mode=${OPTARG};;
    esac
done


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


# -- Vars --

# Get list of banned IPs
raw_list=$(sudo zgrep 'Ban' /var/log/fail2ban.log)

# Get already permabanned IPs
raw_banned_list=$(sudo zgrep 'sshd' /etc/hosts.deny)

prev_ban="False"
prev_sshd="False"

# Arrays of IPs
ip_list=()
banned_list=()


# -- Main --

# Separates fail2ban log by spaces, if an IP is banned pulls it
for item in $raw_list
do
	if [ "$prev_ban" = "True" ]; then
		ip_list+="${item/e/'\n'/} "
		prev_ban="False"
	fi


	if [ "$item" = "Ban" ]; then
		prev_ban="True"
	fi
done


# Separates hosts.deny, if an sshd IP is banned, pulls it
for item in $raw_banned_list
do
	if [ "$prev_sshd" = "True" ]; then
		banned_list+="${item} "
		prev_sshd="False"
	fi

	if [ "$item" = "sshd:" ]; then
		prev_sshd="True"
	fi
done


# -- Writing to temporary JSON --

rm -rf /tmp/ips.json  # Removes previous instance
echo "SH: Cleaned up old ips.json"

echo "{\"Fail2ban-ips\":\"$ip_list\",\"Permabanned-ips\":\"$banned_list\"}" > /tmp/ips.json
echo "SH: Made new ips.json in /tmp"
