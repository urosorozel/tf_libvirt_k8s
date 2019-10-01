# Terraform template for deploying VM's via libvirt

## Terraform Libvirt provide

`sudo apt install libvirt-dev mkisofs`

Compile Libvirt provider

```
$ go get https://github.com/dmacvicar/terraform-provider-libvirt
$ cd $GOPATH/src/github.com/dmacvicar/terraform-provider-libvirt
$ make
$ cp  $GOPATH/bin/terraform-provider-libvirt ~/.terraform.d/plugins/
```

## Ansible Terraform provider

To be able to connect to provisioned VM's

```
$ go get github.com/nbering/terraform-provider-ansible
$ cd $GOPATH/src/github.com/nbering/terraform-provider-ansible
$ make
$ cp $GOPATH/bin/terraform-provider-ansible ~/.terraform.d/plugins/
```

##  Kubespray

Modify ansible.cfg add `inventory = ../inventory/` to default section.

Export ANSIBLE_TF_DIR for Ansible Terraform

```
export ANSIBLE_TF_DIR=/home/uros/git/tf_libvirt_k8s
```


## Define pool
```
virsh pool-define-as libvirt_pool dir - - - - "/libvirt_pool"
```
` <domain name='local.net' localOnly='yes'/>`
