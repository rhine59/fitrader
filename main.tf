data "vsphere_datacenter" "dc" {
  name = "datacenter1"
}

data "vsphere_resource_pool" "pool" {
  name          = "gold"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "cluster1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "SDDC-DPG-Mgmt"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "Templates/ubuntu"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "null_resource" "install-software-fiweb" {
  depends_on = ["vsphere_virtual_machine.fidb"]
  connection {
    type = "ssh"
    user = "root"
    password = "Passw0rd="
    host = "${var.virtual_machine_fiweb_ip}"
    }
  provisioner "file" {
    content = <<EOF
#!/bin/bash -x
echo "*INFO* executing /tmp/install_software.sh"
echo "*INFO* changing hosts file"
echo 10.134.214.138  utility >> /etc/hosts
apt install -y unzip
echo "*INFO* unzip install RC $?"
echo "*INFO* downloading Websphere Liberty ....."
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Downloading Websphere Liberty"}' \
	https://hooks.slack.com/services/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
cd /tmp && wget http://utility/export/Liberty/daytrader8.zip > /dev/null 2>&1
echo "*INFO* downloaded Websphere Liberty RC $?"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Websphere Liberty downloaded"}' \
	https://hooks.slack.com/services/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
echo "*INFO* extracted Websphere Liberty ....."
cd / && unzip /tmp/daytrader8.zip > /dev/null 2>&1
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Websphere Liberty installed"}' \
	https://hooks.slack.com/services/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
echo "*INFO* extracted Websphere Liberty RC $?"

curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Installing DB2 Java drivers"}' \
        https://hooks.slack.com/services/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
echo "*INFO* installing DB2 Java drivers ....."
cd /tmp && wget http://utility/export/DB2/db2drivers.tar > /dev/null 2>&1
mkdir /wlp/db2 && cd /wlp/db2 > /dev/null 2>&1
tar -xvf /tmp/db2drivers.tar > /dev/null 2>&1
echo "*INFO* DB2 Java driver installed RC $?"

curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Installing Java8"}' \
        https://hooks.slack.com/services/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
echo "*INFO* downloading Java"
cd /tmp && wget http://utility/export/Java/ibm-java-sdk-8.0-5.31-x86_64-archive.bin > /dev/null 2>&1
echo "*INFO* downloaded Java RC $?"
chmod 755 /tmp/ibm-java-sdk-8.0-5.31-x86_64-archive.bin
echo "*INFO* building Java installation response file"
echo INSTALLER_UI=silent > /tmp/installer.properties
echo LICENSE_ACCEPTED=TRUE >> /tmp/installer.properties
echo USER_INSTALL_DIR=/wlp/ibm-java-x86_64-80 >> /tmp/installer.properties
echo "*INFO* install Java8 ....."
/tmp/ibm-java-sdk-8.0-5.31-x86_64-archive.bin -i silent -f /tmp/installer.properties > /dev/null 2>&1
echo "*INFO* installed Java8 into /wlp/ibm-java-x86_64-80 RC $?"
echo "*INFO* setting JAVA_HOME to /wlp/ibm-java-x86_64-80 in /wlp/usr/servers/daytrader8/server.env"
echo JAVA_HOME=/wlp/ibm-java-x86_64-80/jre >> /wlp/usr/servers/daytrader8/server.env


echo "*INFO* starting Websphere Liberty ....."
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Waiting 3 minutes to allow database restore to complete on fidb"}' \
	https://hooks.slack.com/services/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
sleep 180
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Resuming ..."}' \
	https://hooks.slack.com/services/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
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Starting Websphere Liberty with daytrader8 application"}' \
	https://hooks.slack.com/services/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
/wlp/bin/server start daytrader8 --clean
sleep 60
/wlp/bin/server start daytrader8 --clean
echo "*INFO* Websphere Liberty started RC $?"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Websphere Liberty and daytrader8 started"}' \
	https://hooks.slack.com/services/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

curl -X POST -H 'Content-type: application/json' --data '{"text":"SUCCESS - Please use http://${vsphere_virtual_machine.fiweb.guest_ip_addresses.0}:9080/daytrader/ to connect to your new workload"}' \
	https://hooks.slack.com/services/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

echo "*INFO* execution of /tmp/install_software.sh complete"
exit 0
EOF
    destination = "/tmp/install_software.sh"
  }
# Execute the script remotely
  provisioner "remote-exec" {
    inline = [
	"chmod +x /tmp/install_software.sh; bash /tmp/install_software.sh" ]
  }
}

resource "null_resource" "config-static-route-fiweb" {
  depends_on = ["vsphere_virtual_machine.fiweb"]
  connection {
    type = "ssh"
    user = "root"
    password = "Passw0rd="
    host = "${var.virtual_machine_fiweb_ip}"
    }
 
  provisioner "file" {
    content = <<EOF
#!/bin/bash -x
echo "--- customise fiweb begin ---"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Starting network configuration"}' \
	https://hooks.slack.com/services/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
cp /etc/network/interfaces /etc/network/interfaces.tmp
grep -iv route /etc/network/interfaces.tmp > /etc/network/interfaces
echo up route add -net ${var.network_route1} netmask ${var.network_netmask1} gw ${var.network_gateway1} >> /etc/network/interfaces
echo up route add -net ${var.network_route2} netmask ${var.network_netmask2} gw ${var.network_gateway2} >> /etc/network/interfaces
systemctl restart networking
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Network configuration complete"}' \
	https://hooks.slack.com/services/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
echo "--- customise fiweb end ---"
exit 0
EOF
    destination = "/tmp/config-static-route.sh"
  }

# Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/config-static-route.sh; bash /tmp/config-static-route.sh"    ]
  }
} 

resource "vsphere_virtual_machine" "fiweb" {
  name = "${var.fiweb-name}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder = "${var.folder_name}"
  num_cpus = 2
  memory   = 4096
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }
  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    customize {
      linux_options {
        host_name = "${var.fiweb-name}"
        domain    = "${var.virtual_machine_domain}"
      }
      network_interface {
        ipv4_address = "${var.virtual_machine_fiweb_ip}"
        ipv4_netmask = "${var.virtual_machine_netmask}"
      }
      ipv4_gateway    = "${var.virtual_machine_gateway}"
      dns_suffix_list = ["${var.virtual_machine_domain}"]
      dns_server_list = ["${var.virtual_machine_dns_servers}"]
    }
  }
  connection {
    type = "ssh"
    user = "root"
    password = "Passw0rd="
  }
}

resource "null_resource" "config-static-route-fidb" {
  depends_on = ["vsphere_virtual_machine.fidb"]
  connection {
    type = "ssh"
    user = "root"
    password = "Passw0rd="
    host = "${var.virtual_machine_fidb_ip}"
    }

  provisioner "file" {
    content = <<EOF
#!/bin/bash -x
echo "--- customise fidb begin ---"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - Starting network configuration"}' \
	https://hooks.slack.com/services/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
echo 10.134.214.138  utility >> /etc/hosts
cp /etc/network/interfaces /etc/network/interfaces.tmp
grep -iv route /etc/network/interfaces.tmp > /etc/network/interfaces
echo up route add -net ${var.network_route1} netmask ${var.network_netmask1} gw ${var.network_gateway1} >> /etc/network/interfaces
echo up route add -net ${var.network_route2} netmask ${var.network_netmask2} gw ${var.network_gateway2} >> /etc/network/interfaces
systemctl restart networking
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - Network configuration completed"}' \
	https://hooks.slack.com/services/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
echo "--- customise fidb end ---"
exit 0
EOF
    destination = "/tmp/config-static-route.sh"
  }

# Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/config-static-route.sh; bash /tmp/config-static-route.sh"    ]
  }
}

resource "null_resource" "install-software-fidb" {
  depends_on = ["vsphere_virtual_machine.fidb"]
  connection {
    type = "ssh"
    user = "root"
    password = "Passw0rd="
    host = "${var.virtual_machine_fidb_ip}"
    }
  provisioner "file" {
    content = <<EOF
#!/bin/bash -x
echo "*INFO* executing /tmp/install_software.sh"
echo 10.134.214.138  utility >> /etc/hosts
echo "*INFO* installing extra packages ....."
apt install -y binutils apt-file lib32ncurses5 lib32z1 libaio1 lib32stdc++6 libpam0g:i386 > /dev/null 2>&1
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - Extra OS packages installed"}' \
	https://hooks.slack.com/services/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
echo "*INFO* install complete RC $?"
echo "*INFO* downloading DB2 ......"
cd /tmp && wget http://utility/export/DB2/v11.1_linuxx64_dec.tar > /dev/null 2>&1
echo "*INFO* download of DB2 completed RC $?"
echo "*INFO* extracting DB2 ......"
tar -xvf v11.1_linuxx64_dec.tar > /dev/null 2>&1
echo "*INFO* extract of DB2 complete RC $?"
echo "*INFO* downloading DB2 install response file"
wget http://utility/export/DB2/db2server.rsp > /dev/null 2>&1
echo "*INFO* downloading of DB2 install response file complete RC $?"
echo "*INFO* installing DB2 ..............."
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - Installing DB2 ......."}' \
	https://hooks.slack.com/services/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
/tmp/server_dec/db2setup -r /tmp/db2server.rsp > /dev/null 2>&1
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - DB2 install completed"}' \
	https://hooks.slack.com/services/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
echo "*INFO* DB2 install completed RC $?"
rm -fr /tmp/v11.1_linuxx64_dec.tar /tmp/server_dec
echo "*INFO* Downloading backup of TradeDB database"
su - db2inst1 -c 'wget http://utility/export/DB2/TRADEDB.0.db2inst1.DBPART000.20190423141353.001 > /dev/null 2>&1'
echo "*INFO* Restoring backup of TradeDB database"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - restoring TRADEDB database backup ......."}' \
	https://hooks.slack.com/services/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
su - db2inst1 -c 'db2 restore db tradedb replace existing redirect; db2 restore db tradedb continue; db2 activate db tradedb'
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - DB2 TRADEDB database restore completed"}' \
	https://hooks.slack.com/services/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
echo "*INFO* restore replace of TradeDB database completed RC $?"
echo "*INFO* execution of /tmp/install_software.sh completed"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb2 - configuration complete"}' \
	https://hooks.slack.com/services/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
exit 0
EOF
    destination = "/tmp/install_software.sh"
  }
# Execute the script remotely
  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/install_software.sh; bash /tmp/install_software.sh" ]
  }
}

resource "vsphere_virtual_machine" "fidb" {
  name = "${var.fidb-name}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder = "${var.folder_name}"
  num_cpus = 4
  memory   = 8192
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }
  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    customize {
      linux_options {
        host_name = "${var.fidb-name}"
        domain    = "${var.virtual_machine_domain}"
      }
      network_interface {
        ipv4_address = "${var.virtual_machine_fidb_ip}"
        ipv4_netmask = "${var.virtual_machine_netmask}"
      }
      ipv4_gateway    = "${var.virtual_machine_gateway}"
      dns_suffix_list = ["${var.virtual_machine_domain}"]
      dns_server_list = ["${var.virtual_machine_dns_servers}"]
    }
  }
  connection {
    type = "ssh"
    user = "root"
    password = "Passw0rd="
  }
}

output "fiweb ip address" {
  value = "${vsphere_virtual_machine.fiweb.guest_ip_addresses.0}"
}

output "fidb ip address" {
  value = "${vsphere_virtual_machine.fidb.guest_ip_addresses.0}"
}

output "daytrader8" {
  value = "http://${vsphere_virtual_machine.fiweb.guest_ip_addresses.0}:9080/daytrader/"
}
