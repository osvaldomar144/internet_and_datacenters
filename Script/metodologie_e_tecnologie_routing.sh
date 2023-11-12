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
LINE_OSPF_AREAS=11

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
    read -p '   multi-area? (y, n): ' multiarea
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
            read -p ' => Exclude cost for this device? (y, n): ' exclude_cost
            if [ $exclude_cost == 'n' ]
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
                line=$((LINE_OSPF_AREAS+(line-LINE_OSPF_COST)))
            else
                line=$LINE_OSPF_AREAS
            fi
            if [ $multiarea == 'y' ]
            then
                read -p " => Device is in backbone area? (y, n): " backbone_device
                if [ $backbone_device == 'y' ] 
                then
                    read -p ' => Insert prefix for BACKBONE area: ' backbone
                    read -p ' => Insert area for BACKBONE: ' area_backbone
                    command="network ${backbone} area ${area_backbone}"
                    i=$(echo "$command" | awk -F"/" '{print length($1) + 1}')
                    command_modified="\n${command:0:i-1}\\${command:i-1}"
                    sed -i -e "${line}s/$/ ${command_modified}/" frr.conf && rm frr.conf-e
                    line=$((line+1))
                fi
                read -p " => Insert stub info? (y, n): " stub_info
                if [ $stub_info == 'y' ] 
                then
                    read -p " => Insert stub prefixes: " -a stubs
                    read -p " => Insert stub areas: " -a areas_stub
                    areas_to_write=()
                    k=0
                    for stub in ${stubs[@]}
                    do
                        command="network ${stub} area ${areas_stub[k]}"
                        i=$(echo "$command" | awk -F"/" '{print length($1) + 1}')
                        command_modified="\n${command:0:i[0]-1}\\${command:i[0]-1}"
                        sed -i -e "${line}s/$/ ${command_modified}/" frr.conf && rm frr.conf-e
                        line=$((line+1))
                        if ! [[ " ${areas_to_write[@]} " =~ " ${areas_stub[k]} " ]]; then
                            areas_to_write+=(${areas_stub[k]})
                        fi
                        k=$((k+1))
                    done
                    for area in ${areas_to_write[@]}
                    do
                        command="\narea ${area} stub"
                        sed -i -e "${line}s/$/ ${command}/" frr.conf && rm frr.conf-e
                        line=$((line+1))
                    done
                fi
            else
                read -p ' => Insert network prefix for frr.conf: ' prefix_single_area
                read -p ' => Insert area for frr.conf: ' single_area
                command="network ${prefix_single_area} area ${single_area}"
                i=$(echo "$command" | awk -F"/" '{print length($1) + 1}')
                command_modified="\n${command:0:i-1}\\${command:i-1}"
                sed -i -e "${line}s/$/ ${command_modified}/" frr.conf && rm frr.conf-e
            fi
        fi
        if [ $protocol == 'rip' ]
        then
            char_index=$(echo "$prefix_protocol" | awk -F"/" '{print length($1) + 1}')
            prefix_modified="${prefix_protocol:0:char_index-1}\\${prefix_protocol:char_index-1}/"
            sed -i -e "s/TO_FIX_PREFIX/${prefix_modified}" frr.conf && rm frr.conf-e
        fi
        cd ../../../
    fi
    echo "\n_________ End insert for ${device}: _________"
done