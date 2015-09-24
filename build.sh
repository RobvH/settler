#!/usr/bin/env bash

# install required vagrant plugin to handle reloads during provisioning
vagrant plugin install vagrant-reload

# start with no machines
vagrant destroy -f
rm -rf .vagrant

time vagrant up --provider virtualbox 2>&1 | tee virtualbox-build-output.log
vagrant halt
vagrant package --base `ls ~/VirtualBox\ VMs | grep settler` --output virtualbox.box

ls -lh virtualbox.box
vagrant destroy -f
rm -rf .vagrant

time vagrant up --provider vmware_fusion 2>&1 | tee vmware-build-output.log
vagrant halt
# defrag disk (assumes running on osx)
/Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -d .vagrant/machines/default/vmware_fusion/*-*-*-*-*/disk.vmdk
# shrink disk (assumes running on osx)
/Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -k .vagrant/machines/default/vmware_fusion/*-*-*-*-*/disk.vmdk
# 'vagrant package' does not work with vmware boxes (http://docs.vagrantup.com/v2/vmware/boxes.html)
cd .vagrant/machines/default/vmware_fusion/*-*-*-*-*/
rm -f vmware*.log
tar cvzf ../../../../../vmware_fusion.box *
cd ../../../../../

ls -lh vmware_fusion.box
vagrant destroy -f
rm -rf .vagrant

time vagrant up --provider parallels 2>&1 | tee parallels-build-output.log
vagrant halt
# setup some nice vars 
SETTLER_PVM=`ls ~/Documents/Parallels | grep settler`
PARALLELS=~/Documents/Parallels
SETTLER=$PARALLELS/$SETTLER_PVM
# shrink disk
prl_disk_tool compact --hdd $SETTLER/harddisk1.hdd
# vagrant package does not support Parallels, either
cp Vagrantfile $PARALLELS
pushd .
cd $PARALLELS
rm -f $SETTLER_PVM/*.log
tar -czvf parallels.box ./$SETTLER_PVM ./Vagrantfile
popd
mv $PARALLELS/parallels.box .
rm $PARALLELS/Vagrantfile

ls -lh parallels.box
vagrant destroy -f
rm -rf .vagrant
