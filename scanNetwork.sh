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

# file to store the ip outputs
IP_FILE="Utils/active_ips.txt"
OUTPUT_FILE="Results/results_info.txt"

# Request the user to enter the network range
echo -e "\nPlease enter the network range (e.g. 192.168.0.0/24): "
read -e network
echo -e "\nScanning network range to get Active Hosts..."
## turn the cursor off
tput civis

spin &
SPIN_PID_0=$!

trap "kill -9 $SPIN_PID_0" $(seq 0 15)

# Ping sweep the network
for ip in $(nmap -sS -n $network | grep "Nmap scan report" | awk '{print $5}'); do
    ping -c 1 -w 1 $ip >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$ip" >> $IP_FILE
    fi
done

kill -9 $SPIN_PID_0

## turn the cursor back on
tput cvvis

# Inform the user that the scan is complete
echo -e "\nScan complete! Active Hosts and There IP addresses are saved to $IP_FILE"

#Run nmap scan on all the found ips
echo -e "\nScanning IPS to get there information"


## turn the cursor off
tput civis

spin &
SPIN_PID_1=$!

trap "kill -9 $SPIN_PID_1" $(seq 0 15)

TEMP_FILE="Utils/temp_file.txt"

echo -e "Netwok Scan Result on Range of IP's in the network $network on :$(date +"%c")" >> $OUTPUT_FILE

for IP in $(cat $IP_FILE); do

    #Empty new line
    echo -e "\n" >> $OUTPUT_FILE
    echo -e "**************************************************" >> $OUTPUT_FILE
    echo -e "\nScan results for Target Host: $IP \n" >> $OUTPUT_FILE

    # Run and Get the response and store to temp file.
    nmap -sSC -v -O $IP >> $TEMP_FILE

    # Get the first line and intro text of the scan
    awk 'NR==1 {print $0}' $TEMP_FILE >> $OUTPUT_FILE

    # get the time elapsed or taken
    echo -e "\nTime Taken: \n" >> $OUTPUT_FILE
    cat $TEMP_FILE | grep "Nmap done:" | awk '{print $11,$12}' >> $OUTPUT_FILE
    
    # get open and closed ports of Target Host
    echo -e "\nOpen and Closed Ports of the Target Host: \n" >> $OUTPUT_FILE
    OPEN_CLOSED_PORTS=$(awk '/PORT/; f; /^[0-9]+/ { print $0 }; END {if (f) print $0}' $TEMP_FILE)

    if [ -z "$OPEN_CLOSED_PORTS" ]; then
  	echo "null." >> $OUTPUT_FILE
    else
	awk '/PORT/; F; /^[0-9]+/ {print $0}; END {if (f) print $0}' $TEMP_FILE >> $OUTPUT_FILE
    fi

    # get Operating System of the Target host
    echo -e "\nOperating System of the Traget Host:\n" >> $OUTPUT_FILE

    OPERATING_SYSTEM=$(cat $TEMP_FILE | grep "Aggressive OS guesses:" | awk '{print $4,$5,$6,$7,$8,$9,$10,$11}')

    if [ -z "$OPERATING_SYSTEM" ]; then
  	    echo "could not identify Operating System." >> $OUTPUT_FILE
    else
	    cat $TEMP_FILE | grep "Aggressive OS guesses:" | awk '{print $4,$5,$6,$7,$8,$9,$10,$11}' >> $OUTPUT_FILE
    fi

    # Get Rogue services running in the target host
    echo -e "\nRogues Services running the Target Host:\n" >> $OUTPUT_FILE

    ROGUE_SERVICES=$(awk '/Host script results/{f=1}; f; /^$/{f=0}' $TEMP_FILE)

    if [ -z "$ROGUE_SERVICES" ]; then
  	    echo "null." >> $OUTPUT_FILE
    else
	    awk '/Host script results/{f=1}; f; /^$/{f=0}' $TEMP_FILE >> $OUTPUT_FILE
    fi

    # Delete the contents of the temp file
    truncate -s 0 $TEMP_FILE

done

kill -9 $SPIN_PID_1

echo -e "Finished Scanning Successfully"

## turn the cursor back on
tput cvvis
