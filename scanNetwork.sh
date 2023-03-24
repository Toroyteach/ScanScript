#!/bin/bash
#Author: Toroyteach

# This is my first script running on a virtual machine
# letss gooo hehheh
#
#
# Ping Sweep Script
#


#Ensure the script is running in Admin mode
if [[ $(id -u) -ne 0 ]]; then
	echo "You need Super User priviledges to run this script"
	exit 1
fi

#Spinner to make the user not to stare on blank screen
spin() {
    spinner="/|\\-/|\\-"
    while :; do
        for i in $(seq 0 7); do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 1
        done
    done
}

# Request the user to enter the network range
echo -e "\nPlease enter the network range (e.g. 192.168.0.0/24): "
read -e network
echo -e "\nScanning network range..."
	## turn the cursor back on
	tput civis

	spin &
	SPIN_PID=$!

	trap "kill -9 $SPIN_PID" $(seq 0 15)

# Ping sweep the network
for ip in $(nmap -sn $network | grep "Nmap scan report" | awk '{print $5}'); do
    ping -c 1 -w 1 $ip > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$ip" >> active_ips.txt
    fi
done


	kill -9 $SPIN_PID

	## turn the cursor back on
	tput cvvis

# Inform the user that the scan is complete
echo -e "\nScan complete! Active IP addresses saved to active_ips.txt"

#Run nmap scan on all the found ips
echo -e "\nScanning IPS to get there information"

IP_FILE="active_ips.txt"
OUTPUT_FILE="results_info.txt"

	## turn the cursor back on
	tput civis

	spin &
	SPIN_PID_1=$!

	trap "kill -9 $SPIN_PID" $(seq 0 15)

for IP in $(cat $IP_FILE); do
  echo "*******************************************" >> $OUTPUT_FILE
  #Run nmap in stealth scan mode
  nmap -sS -P $IP >> $OUTPUT_FILE
  #Scan for OS
  nmap -sS -O $IP | grep "Aggressive OS guesses:" | awk '{print $4,$5,$6,$7,$8,$9,$10,$11 }' >> $OUTPUT_FILE
  echo -e "\n" >> $OUTPUT_FILE
  echo "*******************************************" >> $OUTPUT_FILE
done

	kill -9 $SPIN_PID_1

	## turn the cursor back on
	tput cvvis
