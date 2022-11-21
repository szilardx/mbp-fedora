### Add rpm repo hosted on heroku https://github.com/mikeeq/mbp-fedora-kernel/releases
repo --name=fedora-mbp --baseurl=https://fedora-mbp-repo.herokuapp.com/

### Selinux in permissive mode
bootloader --append="intel_iommu=on iommu=pt pcie_ports=compat"

### Accepting EULA
eula --agreed

### Install kernel from hosted rpm repo
# https://pykickstart.readthedocs.io/en/latest/kickstart-docs.html#chapter-9-package-selection
%packages

## Install mbp-fedora-kernel, mbp-fedora-t2-config, mbp-fedora-t2-repo
curl
-kernel-5.*.fc37.x86_64
kernel-*.*[0-9].mbp.fc37.x86_64
mbp-fedora-t2-config
mbp-fedora-t2-repo

%end

%post
### Add dns server configuration
echo "===]> Info: Printing PWD"
pwd
echo "===]> Info: Printing /etc/resolv.conf"
cat /etc/resolv.conf
echo "===]> Info: Listing /etc/resolv.conf"
ls -la /etc/resolv.conf
echo "===]> Info: Renaming default /etc/resolv.conf"
mv /etc/resolv.conf /etc/resolv.conf_backup
echo "===]> Info: Add Google DNS to /etc/resolv.conf"
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
echo "===]> Info: Print /etc/resolv.conf"
cat /etc/resolv.conf

KERNEL_VERSION=6.0.9-300.mbp.fc37.x86_64
UPDATE_SCRIPT_BRANCH=v6.0-f37

### Add update_kernel_mbp script
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/${UPDATE_SCRIPT_BRANCH}/update_kernel_mbp.sh -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp

### Remove temporary files
mv /etc/resolv.conf_backup /etc/resolv.conf

### Remove not compatible kernels
rpm -e $(rpm -qa | grep kernel | grep -v headers | grep -v oops | grep -v wifi | grep -v mbp)

### Add kernel RPM packages to YUM/DNF exclusions
sed -i '/^type=rpm.*/a exclude=kernel,kernel-core,kernel-devel,kernel-devel-matched,kernel-modules,kernel-modules-extra,kernel-modules-internal' /etc/yum.repos.d/fedora*.repo

%end

%post --nochroot
### Copy grub config without finding macos partition to fix failure reading sector error
cp -rfv /tmp/kickstart_files/grub/30_os-prober ${INSTALL_ROOT}/etc/grub.d/30_os-prober
chmod 755 ${INSTALL_ROOT}/etc/grub.d/30_os-prober

### Post install anaconda scripts - Reformatting HFS+ EFI partition to FAT32 and rebuilding grub config
cp -rfv /tmp/kickstart_files/post-install-kickstart/*.ks ${INSTALL_ROOT}/usr/share/anaconda/post-scripts/

%end
