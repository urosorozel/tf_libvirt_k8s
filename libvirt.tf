provider "libvirt" {
  uri = "qemu:///system"
}

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
  pool           = "libvirt_pool"
  user_data      = "${data.template_file.master_user_data.rendered}"
  meta_data      = "${data.template_file.master_meta_data.*.rendered[count.index]}"
  network_config = "${data.template_file.master_network_config.rendered}"
}

resource "libvirt_volume" "ubuntu-image" {
  name = "${var.qcow_image_filename}"
  pool = "libvirt_pool"
  source = "${var.qcow_image_path}/${var.qcow_image_filename}"
  format = "qcow2"
}

resource "libvirt_volume" "master-deploy-image" {
  name = "${var.master_node_prefix}-${count.index}.qcow2"
  base_volume_id = libvirt_volume.ubuntu-image.id
  pool = "libvirt_pool"
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
    wait_for_lease = true
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
  base_volume_id = libvirt_volume.ubuntu-image.id
  pool = "libvirt_pool"
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
  pool           = "libvirt_pool"
  user_data      = "${data.template_file.worker_user_data.rendered}"
  meta_data      = "${data.template_file.worker_meta_data.*.rendered[count.index]}"
  network_config = "${data.template_file.worker_network_config.rendered}"
}

# Define KVM domain to create
resource "libvirt_domain" "worker_nodes" {
  name   = "${format("${var.worker_node_prefix}-%02d", count.index + 1)}"
  memory = "${var.worker_node_memory}"
  vcpu   = "${var.worker_node_cpu}"

  network_interface {
    network_name = "default"
    wait_for_lease = true
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


# END WORKER
resource "libvirt_volume" "etcd-deploy-image" {
  name = "${var.etcd_node_prefix}-${count.index}.qcow2"
  base_volume_id = libvirt_volume.ubuntu-image.id
  pool = "libvirt_pool"
  size = "${var.etcd_node_disk}"
  format = "qcow2"
  count = "${var.etcd_node_count}"
}

data "template_file" "etcd_user_data" {
  template = "${file("${path.module}/cloud_init.yml")}"

  vars = {
    user_name          = "ubuntu"
    ssh_authorized_key = "${var.ssh_authorized_key}"
  }
}

data "template_file" "etcd_meta_data" {
  count    = "${var.etcd_node_count}"
  template = "${file("${path.module}/meta_data.yml")}"

  vars = {
    hostname = "${format("${var.etcd_node_prefix}-%02d", count.index + 1)}"
  }
}

data "template_file" "etcd_network_config" {
  template = "${file("${path.module}/network_config.yml")}"
}

resource "libvirt_cloudinit_disk" "etcd_commoninit" {
  count          = "${var.etcd_node_count}"
  name           = "${format("${var.etcd_node_prefix}-seed-%01d.iso", count.index + 1)}"
  pool           = "libvirt_pool"
  user_data      = "${data.template_file.etcd_user_data.rendered}"
  meta_data      = "${data.template_file.etcd_meta_data.*.rendered[count.index]}"
  network_config = "${data.template_file.etcd_network_config.rendered}"
}

# Define KVM domain to create
resource "libvirt_domain" "etcd_nodes" {
  name   = "${format("${var.etcd_node_prefix}-%02d", count.index + 1)}"
  memory = "${var.etcd_node_memory}"
  vcpu   = "${var.etcd_node_cpu}"

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = "${element(libvirt_volume.etcd-deploy-image,count.index).id}"
  }

  cloudinit = "${element(libvirt_cloudinit_disk.etcd_commoninit,count.index).id}"

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
  count = "${var.etcd_node_count}"
}

resource "ansible_host" "master_nodes" {
    inventory_hostname = "${format("${var.master_node_prefix}-%02d", count.index + 1)}.local.net"
    groups = ["kube-master","k8s-cluster","master"]
    vars = {
        ansible_user = "ubuntu"
        ansible_host = "${element(libvirt_domain.master_nodes,count.index).network_interface.0.addresses.0}"
    }
    count = "${var.master_node_count}"
    depends_on = [libvirt_domain.master_nodes]
}

resource "ansible_host" "worker_nodes" {
    inventory_hostname = "${format("${var.worker_node_prefix}-%02d", count.index + 1)}.local.net"
    groups = ["kube-node","k8s-cluster","worker"]
    vars = {
        ansible_user = "ubuntu"
        ansible_host = "${element(libvirt_domain.worker_nodes,count.index).network_interface.0.addresses.0}"
    }
    count = "${var.worker_node_count}"
    depends_on = [libvirt_domain.worker_nodes]
}

resource "ansible_host" "etcd_nodes" {
    inventory_hostname = "${format("${var.etcd_node_prefix}-%02d", count.index + 1)}.local.net"
    groups = ["etcd","k8s-cluster"]
    vars = {
        ansible_user = "ubuntu"
        ansible_host = "${element(libvirt_domain.etcd_nodes,count.index).network_interface.0.addresses.0}"
    }
    count = "${var.etcd_node_count}"
    depends_on = [libvirt_domain.etcd_nodes]
}

output "master_ips" {
  value = libvirt_domain.master_nodes.*.network_interface.0.addresses
}

output "worker_ips" {
  value = libvirt_domain.worker_nodes.*.network_interface.0.addresses
}

output "etcd_ips" {
  value = libvirt_domain.etcd_nodes.*.network_interface.0.addresses
}
