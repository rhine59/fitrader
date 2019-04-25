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
cd /tmp && wget http://utility/export/Liberty/daytrader8Server.zip > /dev/null 2>&1
echo "*INFO* downloaded Websphere Liberty RC $?"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Websphere Liberty downloaded"}' \
	https://hooks.slack.com/services/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
echo "*INFO* extracted Websphere Liberty ....."
cd / && unzip /tmp/daytrader8Server.zip > /dev/null 2>&1
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Websphere Liberty installed"}' \
	https://hooks.slack.com/services/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
echo "*INFO* extracted Websphere Liberty RC $?"
echo "*INFO* starting Websphere Liberty ....."
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Waiting 3 minutes to allow database restore to complete on fidb"}' \
	https://hooks.slack.com/services/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
sleep 10800
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Resuming ..."}' \
	https://hooks.slack.com/services/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
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Starting Websphere Liberty with daytrader8 application"}' \
	https://hooks.slack.com/services/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
/wlp/bin/server start daytrader8Server 
curl -X POST -H 'Content-type: application/json' --data '{"text":"fiweb - Websphere Liberty and daytrader8 started"}' \
	https://hooks.slack.com/services/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
echo "*INFO* Websphere Liberty started RC $?"
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
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - Starting network configuration"}' \
	https://hooks.slack.com/services/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
echo 10.134.214.138  utility >> /etc/hosts
cp /etc/network/interfaces /etc/network/interfaces.tmp
grep -iv route /etc/network/interfaces.tmp > /etc/network/interfaces
echo up route add -net ${var.network_route1} netmask ${var.network_netmask1} gw ${var.network_gateway1} >> /etc/network/interfaces
echo up route add -net ${var.network_route2} netmask ${var.network_netmask2} gw ${var.network_gateway2} >> /etc/network/interfaces
systemctl restart networking
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - Network configuration completed"}' \
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
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - Extra OS packages installed"}' \
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
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - Installing DB2 ......."}' \
	https://hooks.slack.com/services/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
/tmp/server_dec/db2setup -r /tmp/db2server.rsp > /dev/null 2>&1
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - DB2 install completed"}' \
	https://hooks.slack.com/services/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
echo "*INFO* DB2 install completed RC $?"
rm -fr /tmp/v11.1_linuxx64_dec.tar /tmp/server_dec
echo "*INFO* Downloading backup of TradeDB database"
su - db2inst1 -c 'wget http://utility/export/DB2/TRADEDB.0.db2inst1.DBPART000.20190423141353.001 > /dev/null 2>&1'
echo "*INFO* Restoring backup of TradeDB database"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - restoring TRADEDB database backup ......."}' \
	https://hooks.slack.com/services/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
su - db2inst1 -c 'db2 restore db tradedb replace existing redirect; db2 restore db tradedb continue; db2 activate db tradedb'
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - DB2 TRADEDB database restore completed"}' \
	https://hooks.slack.com/services/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
echo "*INFO* restore replace of TradeDB database completed RC $?"
echo "*INFO* execution of /tmp/install_software.sh completed"
curl -X POST -H 'Content-type: application/json' --data '{"text":"fidb - configuration complete"}' \
	https://hooks.slack.com/services/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
curl -X POST -H 'Content-type: application/json' --data '{"text":"SUCCESS - Please use http://10.134.214.161:9080/daytrader/ to connect to your new workload"}' \
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
