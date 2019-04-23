provider "vsphere" {
  user           = "Administrator@vsphere.local"
  password       = "4!0XkF!n"
  vsphere_server = "10.134.214.130"
  allow_unverified_ssl = true
}

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
cd /tmp && wget http://utility/export/Liberty/daytrader8Server.zip > /dev/null 2>&1
echo "*INFO* downloaded Websphere Liberty RC $?"
echo "*INFO* extracted Websphere Liberty ....."
cd / && unzip /tmp/daytrader8Server.zip > /dev/null 2>&1
echo "*INFO* extracted Websphere Liberty RC $?"
echo "*INFO* starting Websphere Liberty ....."
/wlp/bin/server start daytrader8Server 
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
cp /etc/network/interfaces /etc/network/interfaces.tmp
grep -iv route /etc/network/interfaces.tmp > /etc/network/interfaces
echo up route add -net ${var.network_route1} netmask ${var.network_netmask1} gw ${var.network_gateway1} >> /etc/network/interfaces
echo up route add -net ${var.network_route2} netmask ${var.network_netmask2} gw ${var.network_gateway2} >> /etc/network/interfaces
systemctl restart networking
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
echo 10.134.214.138  utility >> /etc/hosts
cp /etc/network/interfaces /etc/network/interfaces.tmp
grep -iv route /etc/network/interfaces.tmp > /etc/network/interfaces
echo up route add -net ${var.network_route1} netmask ${var.network_netmask1} gw ${var.network_gateway1} >> /etc/network/interfaces
echo up route add -net ${var.network_route2} netmask ${var.network_netmask2} gw ${var.network_gateway2} >> /etc/network/interfaces
systemctl restart networking
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
/tmp/server_dec/db2setup -r /tmp/db2server.rsp > /dev/null 2>&1
echo "*INFO* DB2 install completed RC $?"
rm -fr /tmp/v11.1_linuxx64_dec.tar /tmp/server_dec
echo "*INFO* Downloading backup of TradeDB database"
su - db2inst1 -c 'wget http://utility/export/DB2/TRADEDB.0.db2inst1.DBPART000.20190423141353.001 > /dev/null 2>&1'
echo "*INFO* Restoring backup of TradeDB database"
su - db2inst1 -c 'db2 restore db tradedb replace existing redirect; db2 restore db tradedb continue; db2 activate db tradedb'
echo "*INFO* restore replace of TradeDB database completed RC $?"
echo "*INFO* execution of /tmp/install_software.sh completed"
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

