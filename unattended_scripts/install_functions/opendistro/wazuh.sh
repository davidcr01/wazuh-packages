# Copyright (C) 2015-2021, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

installWazuh() {
    
    logger "Installing the Wazuh manager."
    if [ ${sys_type} == "zypper" ]; then
        eval "zypper -n install wazuh-manager=${wazuh_version}-${wazuh_revision} ${debug}"
    else
        eval "${sys_type} install wazuh-manager${sep}${wazuh_version}-${wazuh_revision} -y ${debug}"
    fi
    if [  "$?" != 0  ]; then
        logger -e "Wazuh installation failed"
        rollBack
        exit 1;
    else
        wazuhinstalled="1"
        logger "Done"
    fi   
    startService "wazuh-manager"

}

configureWazuhCluster() {

    cluster_name=$wazuh_cluster_config_cluster_name
    if [[ $winame == $wazuh_cluster_config_master_node_name ]]; then
        node_type="master"
    else
        node_type="worker"
    fi
    master_address=$wazuh_cluster_config_cluster_master_address
    key=$(cat ${base_path}/certs/clusterkey)
    bind_address="0.0.0.0"
    port="1516"
    hidden="no"
    disabled="no"
    lstart=$(grep -n "<cluster>" /var/ossec/etc/ossec.conf | cut -d : -f 1)
    lend=$(grep -n "</cluster>" /var/ossec/etc/ossec.conf | cut -d : -f 1)

    eval 'sed -i -e "${lstart},${lend}s/<name>.*<\/name>/<name>${cluster_name}<\/name>/" \
        -e "${lstart},${lend}s/<node_name>.*<\/node_name>/<node_name>${iname}<\/node_name>/" \
        -e "${lstart},${lend}s/<node_type>.*<\/node_type>/<node_type>${node_type}<\/node_type>/" \
        -e "${lstart},${lend}s/<key>.*<\/key>/<key>${key}<\/key>/" \
        -e "${lstart},${lend}s/<port>.*<\/port>/<port>${port}<\/port>/" \
        -e "${lstart},${lend}s/<bind_addr>.*<\/bind_addr>/<bind_addr>${bind_address}<\/bind_addr>/" \
        -e "${lstart},${lend}s/<node>.*<\/node>/<node>${master_address}<\/node>/" \
        -e "${lstart},${lend}s/<hidden>.*<\/hidden>/<hidden>${hidden}<\/hidden>/" \
        -e "${lstart},${lend}s/<disabled>.*<\/disabled>/<disabled>${disabled}<\/disabled>/" \
        /var/ossec/etc/ossec.conf'

    startService "wazuh-manager"
}