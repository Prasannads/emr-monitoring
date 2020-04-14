#!/bin/sh
echo "#!/bin/bash
echo \"Collecting Metrics...\"
instance_ip=ip-\"\$(/sbin/ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)\"

export IS_MASTER=\$(cat  /mnt/var/lib/info/instance.json | jq -r \".isMaster\") || exit 1

if [[ \$IS_MASTER == \"true\" ]]; then
export instance_type_prefix=\"master\"
else
export instance_type_prefix=\"slaves\"
fi

pushgateway=https://localhost:9091/metrics/job/\"\$1\"/instance/
mem=(\$(free -m | awk -v RS=\"\" '{print \$8} {print \$9} {print \$10}'))
cat << EOF | curl --data-binary @- \${pushgateway}\${instance_ip}/type/\${instance_type_prefix}
    memory_total \${mem[0]}
    memory_free \${mem[1]}
    memory_used \${mem[2]}
EOF
cpu=(\$(top -b -n1 | grep \"Cpu(s)\" | awk '{print \$2} {print \$3} {print \$5}' | sed 's/[^0-9.]*//g'))
cat << EOF | curl --data-binary @- \${pushgateway}\${instance_ip}/type/\${instance_type_prefix}
    cpu_user_load \${cpu[0]}
    cpu_sys_load \${cpu[1]}
    cpu_idle_load \${cpu[2]}
EOF
disk=(\$(df -hP /mnt | awk '{print \$2} {print \$3} {print \$4} {print \$5}' | tail -4 | sed 's/[^0-9.]*//g'))
cat << EOF | curl --data-binary @- \${pushgateway}\${instance_ip}/type/\${instance_type_prefix}
    disk_size \${disk[0]}
    disk_used_size \${disk[1]}
    disk_available_size \${disk[2]}
    disk_used_percentage \${disk[3]}
EOF" > /home/hadoop/emr-monitoring-metrics.sh
chmod 700 /home/hadoop/emr-montoring-metrics.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/hadoop/emr-montoring-metrics.sh $1") | crontab -