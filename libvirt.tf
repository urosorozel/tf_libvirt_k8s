provider "libvirt" {
  uri = "qemu:///system"
}

#provider "libvirt" {
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#}

data "template_file" "master_user_data" {
  template = "${file("${path.module}/cloud_init.yml")}"

  vars = {
    user_name          = "ubuntu"
    ssh_authorized_key = "${var.ssh_authorized_key}"
  }
}

data "template_file" "master_meta_data" {
  count    = "${var.master_node_count}"
  template = "${file("${path.module}/meta_data.yml")}"

  vars = {
    hostname = "${format("${var.master_node_prefix}-%02d", count.index + 1)}"
  }
}

data "template_file" "master_network_config" {
  template = "${file("${path.module}/network_config.yml")}"
}

resource "libvirt_cloudinit_disk" "master_commoninit" {
  count          = "${var.master_node_count}"
  name           = "${format("${var.master_node_prefix}-seed-%01d.iso", count.index + 1)}"
  pool           = "guest_images"
  user_data      = "${data.template_file.master_user_data.rendered}"
  meta_data      = "${data.template_file.master_meta_data.*.rendered[count.index]}"
  network_config = "${data.template_file.master_network_config.rendered}"
}

resource "libvirt_volume" "ubuntu-cosmic" {
  name = "ubuntu-cosmic.qcow2"
  pool = "guest_images"
  source = "/root/cosmic-server-26022019-cloud-init-latest" 
  format = "qcow2"
}

resource "libvirt_volume" "master-deploy-image" {
  name = "${var.master_node_prefix}-${count.index}.qcow2"
  base_volume_id = libvirt_volume.ubuntu-cosmic.id
  pool = "guest_images"
  size = "${var.master_node_disk}" 
  format = "qcow2"
  count = "${var.master_node_count}"
}


# Define KVM domain to create
resource "libvirt_domain" "master_nodes" {
  name   = "${var.master_node_prefix}-${count.index}"
  memory = "${var.master_node_memory}"
  vcpu   = "${var.master_node_cpu}"

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = "${element(libvirt_volume.master-deploy-image,count.index).id}"
  }

  cloudinit = "${element(libvirt_cloudinit_disk.master_commoninit,count.index).id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
  count = "${var.master_node_count}"
}

# END MASTER
resource "libvirt_volume" "worker-deploy-image" {
  name = "${var.worker_node_prefix}-${count.index}.qcow2"
  base_volume_id = libvirt_volume.ubuntu-cosmic.id
  pool = "guest_images"
  size = "${var.worker_node_disk}"
  format = "qcow2"
  count = "${var.worker_node_count}"
}

data "template_file" "worker_user_data" {
  template = "${file("${path.module}/cloud_init.yml")}"

  vars = {
    user_name          = "ubuntu"
    ssh_authorized_key = "${var.ssh_authorized_key}"
  }
}

data "template_file" "worker_meta_data" {
  count    = "${var.worker_node_count}"
  template = "${file("${path.module}/meta_data.yml")}"

  vars = {
    hostname = "${format("${var.worker_node_prefix}-%02d", count.index + 1)}"
  }
}

data "template_file" "worker_network_config" {
  template = "${file("${path.module}/network_config.yml")}"
}

resource "libvirt_cloudinit_disk" "worker_commoninit" {
  count          = "${var.worker_node_count}"
  name           = "${format("${var.worker_node_prefix}-seed-%01d.iso", count.index + 1)}"
  pool           = "guest_images"
  user_data      = "${data.template_file.worker_user_data.rendered}"
  meta_data      = "${data.template_file.worker_meta_data.*.rendered[count.index]}"
  network_config = "${data.template_file.worker_network_config.rendered}"
}

# Define KVM domain to create
resource "libvirt_domain" "worker_nodes" {
  name   = "${var.worker_node_prefix}-${count.index}"
  memory = "${var.worker_node_memory}"
  vcpu   = "${var.worker_node_cpu}"

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = "${element(libvirt_volume.worker-deploy-image,count.index).id}"
  }

  cloudinit = "${element(libvirt_cloudinit_disk.worker_commoninit,count.index).id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
  count = "${var.worker_node_count}"
}

# Output Server IP
#output "ip" {
#  value = "${libvirt_domain.db1.network_interface.0.addresses.0}"
#}
