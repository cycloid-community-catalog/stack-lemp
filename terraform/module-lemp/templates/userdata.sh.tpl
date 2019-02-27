#!/bin/bash -v

export ENV=${env}
export CUSTOMER=${customer}
export PROJECT=${project}
export ROLE=${role}
export CUSTOMER_VAULT_PASSWORD=${vault_password}
export RDS_ADDRESS=${rds_address}
export RDS_PORT=${rds_port}
export RDS_DATABASE=${rds_database}
export RDS_USERNAME=${rds_username}
export S3_MEDIAS=${s3_medias}
export ELASTICACHE_ADDRESS=${elasticache_address}

LOG_FILE="/var/log/user-data.log"

AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
AWS_UNIQUE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

#TMP fix for https://github.com/boto/boto/issues/3783
echo '[Boto]
use_endpoint_heuristics = True' > /etc/boto.cfg

bash /home/admin/user-data.sh

if [ $? -eq 0 ]; then
    echo "cloudformation signal-resource SUCCESS" >> $LOG_FILE
    /usr/local/bin/aws cloudformation signal-resource --stack-name ${signal_stack_name} --logical-resource-id ${signal_resource_id} --unique-id $${AWS_UNIQUE_ID} --region $${AWS_REGION} --status SUCCESS  >> $LOG_FILE
else
    echo "cloudformation signal-resource FAILURE" >> $LOG_FILE
    /usr/local/bin/aws cloudformation signal-resource --stack-name ${signal_stack_name} --logical-resource-id ${signal_resource_id} --unique-id $${AWS_UNIQUE_ID} --region $${AWS_REGION} --status FAILURE  >> $LOG_FILE
fi
