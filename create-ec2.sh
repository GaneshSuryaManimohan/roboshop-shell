#!/bin/bash

instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "web")
domain_name="surya-devops.online"
hosted_zone_id="Z0198617Y0ILC4355WO7"

for name in ${instances[@]}; do
    if [ $name == "shipping" ] || [ $name == "mysql" ]
    then
        instance_type="t3.medium"   
    else
        instance_type="t3.micro"
    fi
    echo "creating instance for: $name with instance type: $instance_type"

    instance_id=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type $instance_type --security-group-ids sg-0bbdd2b154434fbfd --subnet-id subnet-0272da41f92b04b12 --query 'Instances[0].InstanceId' --output text)
    echo "Instance Created for: $name with instance id: $instance_id"

    aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$name

    if [ $name == "web" ]
    then
        aws ec2 wait instance-running --instance-ids $instance_id
        public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PublicIpAddress]' --output text)
        ip_to_use=$public_ip
    else
    aws ec2 wait instance-running --instance-ids $instance_id
        private_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PrivateIpAddress]' --output text)
        ip_to_use=$private_ip
    fi

    echo "Creating R53 record for $name with ip: $ip_to_use"
    
    aws route53 change-resource-record-sets --hosted-zone-id "$hosted_zone_id" --change-batch "$(cat <<EOF
{
    "Comment": "Creating record for $name",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$name.$domain_name",
                "Type": "A",
                "TTL": 60,
                "ResourceRecords": [
                    {
                        "Value": "${ip_to_use}"
                    }
                ]
            }
        }
    ]
}
EOF
)"

done



