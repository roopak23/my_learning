#!/bin/bash

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi

    if [ "$stat" == 1 ]; then
        echo "Invalid Private IP provided - $EMR_IP"
    fi

    return $stat
}

if [[ ! -z "$1" ]]; then
    EMR_IP="$1"
    if valid_ip "$EMR_IP"; then
        if grep isMaster /mnt/var/lib/info/instance.json | grep true;
        then
            echo "Master Node: Setting private IP - $EMR_IP"
            echo "Get instance ID"
            INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
            echo "Get interface ID for instance $INSTANCE_ID"
            INTERFACE_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq .Reservations[].Instances[].NetworkInterfaces[].NetworkInterfaceId | xargs)
            #Assign private IP to the master instance:
            echo "Assign private IP to interface $INTERFACE_ID"
            aws ec2 assign-private-ip-addresses --network-interface-id $INTERFACE_ID --private-ip-addresses $EMR_IP
            echo "Get subnet ID for $INSTANCE_ID"
            SUBNET_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq .Reservations[].Instances[].NetworkInterfaces[].SubnetId | xargs)
            echo "Get subnet CIDR for subnet $SUBNET_ID "
            SUBNET_CIDR=$(aws ec2 describe-subnets --subnet-ids $SUBNET_ID | jq .Subnets[].CidrBlock | xargs)
            echo "Get CIDR prefix for $SUBNET_CIDR"
            CIDR_PREFIX=$(cut -d '/' -f 2- <<< "$SUBNET_CIDR")
            #Add the private IP address to the default network interface:
            echo "Add private IP to the default network interface for IP $EMR_IP an prefix  $CIDR_PREFIX"
            sudo ip addr add dev eth0 "$EMR_IP/$CIDR_PREFIX"
            #Configure iptablles rules such that traffic is redirected from the secondary to the primary IP address:
            echo "Get primary IP"
            PRIMARY_IP=$(/sbin/ifconfig eth0 | grep 'inet' | cut -d: -f2 | awk '{ print $2}' | xargs)
            echo "Add route between private IP $EMR_IP and primary IP $PRIMARY_IP"
            sudo iptables -t nat -A PREROUTING -d $EMR_IP -j DNAT --to-destination $PRIMARY_IP
        else
            echo "Core Node: Not setting private IP"
        fi
        echo "Add environment variable MASTER_STATIC_IP=$EMR_IP for all sessions"
		    echo "export MASTER_STATIC_IP=$EMR_IP" >> ~/.bash_profile
		    source ~/.bash_profile
    else
        exit 0
    fi
else
    echo "No Private IP provided!"
    exit 1
fi

exit 0