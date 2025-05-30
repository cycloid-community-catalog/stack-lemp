#!/bin/bash -v

set -e

# Wait for apt to be available
apt_wait () {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    sleep 1
  done
}

# Wait for apt to be available
apt_wait

# Debug tools
apt-get update -y
apt-get install net-tools jq netcat-traditional rsync vim git bind9-dnsutils -y

# To install SSM Agent on Debian Server
# https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-deb.html

mkdir /tmp/ssm
cd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
systemctl status amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

function finish {
    if [ $rc != 0 ]; then
      export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      echo "cloudformation signal-resource FAILURE" >> $LOG_FILE
      aws cloudformation signal-resource --stack-name ${signal_stack_name} --logical-resource-id ${signal_resource_id} --unique-id $${AWS_UNIQUE_ID} --region $${AWS_REGION} --status FAILURE  2>&1 >> $LOG_FILE

      echo "[halt] 3 min before shutdown" >> $LOG_FILE
      echo "[debug] keep up by creating /var/tmp/keeprunning" >> $LOG_FILE
      sleep 60

      if [ ! -f "/var/tmp/keeprunning" ]; then
        echo "[halt] halt" >> $LOG_FILE
        halt -f
      fi
      echo "[halt] keeprunning" >> $LOG_FILE
    else
      echo "cloudformation signal-resource SUCCESS" >> $LOG_FILE
      aws cloudformation signal-resource --stack-name ${signal_stack_name} --logical-resource-id ${signal_resource_id} --unique-id $${AWS_UNIQUE_ID} --region $${AWS_REGION} --status SUCCESS  2>&1 >> $LOG_FILE

      # ensure last return code is 0
      echo "End" >> $LOG_FILE
    fi
}

trap 'rc=$?; set +e; finish' EXIT

export ENV=${env}
export ORGANIZATION=${organization}
export PROJECT=${project}
export ROLE=${role}
export RDS_ADDRESS=${rds_address}
export RDS_PORT=${rds_port}
export RDS_DATABASE=${rds_database}
export RDS_USERNAME=${rds_username}
export S3_MEDIAS=${s3_medias}
export ELASTICACHE_ADDRESS=${elasticache_address}

LOG_FILE="/var/log/user-data.log"

export AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
export AWS_UNIQUE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

#TMP fix for https://github.com/boto/boto/issues/3783
echo '[Boto]
use_endpoint_heuristics = True' > /etc/boto.cfg

bash /home/admin/user-data.sh


