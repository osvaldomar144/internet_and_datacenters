#!/bin/bash
echo "\n"==================================================="\n"
echo "         Creazione laboratorio KATHARA                " 
echo "\n"==================================================="\n"

# global variables
header="LAB_AUTHOR=\"Osvaldo Alexis Hidalgo Martinez\""
PATH_DAEMON_RIP="../../../../frr/rip/daemons"
PATH_DAEMON_OSPF="../../../../frr/ospf/daemons"
PATH_FRR_RIP="../../../../frr/rip/frr.conf"
PATH_FRR_OSPF="../../../../frr/ospf/frr.conf"
PATH_VTYSH_CONF="../../../../frr/vtysh.conf"
LINE_OSPF_COST=8
prefix_protocol="0.0.0.0"
area="0.0.0.0"

read -p '=> Folder Name: ' name_folder
mkdir $name_folder && cd $name_folder

# Create lab.conf file
echo "${header}\n" > "lab.conf"

# Insert protocol type
echo "\n=> Select routing protocol ... insert 'rip' or 'ospf' \n" 
read -p '   Protocol: ' protocol

if [ $protocol == 'rip' ] 
then 
    echo "\n=> [OK] Selected RIP option"
    read -p '=> Insert network prefix for frr.conf: ' prefix_protocol
    PATH_DAEMON=$PATH_DAEMON_RIP
    PATH_FRR=$PATH_FRR_RIP
elif [ $protocol == 'ospf' ] 
then
    echo "\n=> [OK] Selected OSPF option"
    read -p '=> Insert network prefix for frr.conf: ' prefix_protocol
    read -p '=> Insert area for frr.conf: ' area
    PATH_DAEMON=$PATH_DAEMON_OSPF
    PATH_FRR=$PATH_FRR_OSPF
else 
    echo "\n=> [ERROR]: Invalid Option" && cd ..
    echo "=> CLEAN FILES" && rm -rf $name_folder
    echo "=> [OK] - Finished" && exit 1
fi

# Insert Data
echo "\n"
read -p "=> Insert devices: " -a devices

for device in ${devices[@]}
do
    echo "\n_________ Insert for ${device}: _________\n"
    read -p " => NETWORKS for ${device}: " -a networks
    index=0
    for network in ${networks[@]}
    do
        string="${device}[${index}]=\"${network}\""
        echo $string >> "lab.conf"
        index=$((index+1))
    done
    echo "${device}[image]=\"kathara/frr\"\n" >> "lab.conf"
    file="${device}.startup"
    touch $file
    read -p " => IPs interfaces for device ${device}: " -a ips
    index=0
    for ip in ${ips[@]}
    do
        command="ip address add ${ip} dev eth${index}"
        echo $command >> $file
        index=$((index+1))
    done
    read -p ' => Exclude device from protocol? (y, n): ' exclude
    if [ $exclude == 'n' ]
    then
        echo "systemctl start frr" >> $file
        mkdir $device && cd $device
        mkdir etc && cd etc
        mkdir frr && cd frr
        cp $PATH_DAEMON daemons && cp $PATH_VTYSH_CONF vtysh.conf
        cp $PATH_DAEMON daemons && cp $PATH_VTYSH_CONF vtysh.conf && cp $PATH_FRR frr.conf
        if [ $protocol == 'ospf' ] 
        then
            read -p " => Interface costs for device ${device}: " -a costs
            index=0
            line=$LINE_OSPF_COST
            for cost in ${costs[@]}
            do
                command="\ninterface eth${index}\nospf cost ${cost}"
                sed -i -e "${line}s/$/ ${command}/" frr.conf
                line=$((line+2))
                index=$((index+1))
            done
            sed -i -e "s/TO_FIX_AREA/${area}/" frr.conf && rm frr.conf-e
        fi
        carattere_prima="/"
        char_index=$(echo "$prefix_protocol" | awk -F"${carattere_prima}" '{print length($1) + 1}')
        prefix_modified="${prefix_protocol:0:char_index-1}\\${prefix_protocol:char_index-1}/"
        sed -i -e "s/TO_FIX_PREFIX/${prefix_modified}" frr.conf && rm frr.conf-e
        cd ../../../
    fi
    echo "\n_________ End insert for ${device}: _________"
done