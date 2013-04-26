#!/bin/bash
#Must run on CentOS or RHEL
issue=$(head -1 /etc/issue)
#Check livecd-tools
if [[ "$(rpm --qf '%{name}-%{version}-%{release}' -q livecd-tools)" < "livecd-tools-13.4-3.el6" || "$(rpm --qf '%{name}-%{version}-%{release}' -q livecd-tools)" > "livecd-tools-13.5.el6" ]];then
  echo "Warning: livecd-tools-13.4-3 not installed. Results may be unstable."
fi

if [[ ! "$issue" =~ "CentOS" && ! "$issue" =~ "Red Hat" ]];then
  echo "Must be run on CentOS or Red Hat 6.3 or greater."
  exit 1
fi
sudo rm -rf bootstrap
mkdir -p bootstrap
cd bootstrap
cp ../bootstrap.cfg bootstrap.cfg
#Must use gzip for 2.6.32 kernel
sudo livecd-creator -c bootstrap.cfg -d -v --compression-type=gzip
mkdir tweak
mkdir iso
sudo mount -o loop livecd*.iso iso
if [ $? -ne 0 ]; then
  sudo umount iso
  sudo mount -o loop livecd*.iso iso
  if [ $? -ne 0 ] ;then
    echo "Can't unmount /iso"
    exit 1
  fi
fi
sudo rm -rf tweak/isolinux
sudo rsync -vaz iso/* tweak/.
cd tweak
sudo sed -i -e 's/rhgb //g' -e 's/quiet //g' -e 's/timeout 100/timeout 30/g' isolinux/isolinux.cfg
sudo sed -i -e 's/bootstrap-x86_64-............/fuel-bootstrap/g' isolinux/isolinux.cfg
sudo /usr/bin/mkisofs -J -r -hide-rr-moved -hide-joliet-trans-tbl -V fuel-bootstrap -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-info-table -o ../bootstrap.iso .
sudo umount ../iso
sudo /bin/cp -f ../bootstrap.iso /var/www/html/isos/bootstrap.iso

