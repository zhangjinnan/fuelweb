require 'rakelib/helper'

BUILD_DIR = "_build"
CENTOS_RELEASE = "6.3"
CENTOS_ARCH = "x86_64"
ISOLINUX_FILES = FileList['boot.msg', 'grub.conf', 'initrd.img', 'isolinux.bin',
                          'isolinux.cfg', 'memtest', 'splash.jpg', 'vesamenu.c32', 'vmlinuz']

desc "Build CentOS#{CENTOS_RELEASE} #{CENTOS_ARCH} ISO"
task :iso => [:isolinux_files, :repodata] do
  cp 'os/centos/ks.cfg', BUILD_DIR
  sh "mkisofs -r -N -L -d -J -T -b isolinux/isolinux.bin \
      -c isolinux/boot.cat -no-emul-boot -V IsoLabel \
      -boot-load-size 4 -boot-info-table -o built.iso #{BUILD_DIR}/"
end

ISOLINUX_FILES.each do |src|
  download_from_url("http://mirror.yandex.ru/centos/#{CENTOS_RELEASE}/os/#{CENTOS_ARCH}/isolinux/#{src}",
                    "#{BUILD_DIR}/isolinux/#{src}", :isolinux_files)
end

task :repodata => [:yum_configs, "#{BUILD_DIR}/Packages/comps.xml"]

directory "#{BUILD_DIR}/Packages"
file "#{BUILD_DIR}/Packages/comps.xml" => "#{BUILD_DIR}/Packages" do
  # Requirement from man page: Note that the groups file should be  in  the  same
  # directory as the rpm packages (i.e. /path/to/rpms/comps.xml)
  cp "os/centos/comps.xml", "#{BUILD_DIR}/Packages"
  xml = File.open('os/centos/comps.xml', 'r').readlines()
  packages = xml.grep(/<packagereq type='mandatory'>/).map {|line| line.gsub(/.*datory'>/, '').gsub(/<\/packagereq>$/, '')}
  puts "repotrack'ing packages..."
  packages.each do |pkg|
    sh "repotrack -c #{BUILD_DIR}/etc/yum.conf -p #{BUILD_DIR}/Packages -a x86_64 #{pkg}"
  end
  sh "yum -c #{BUILD_DIR}/etc/yum.conf clean all"
  yum_tmp = Dir.glob("/var/tmp/yum-#{ENV['USER']}-*")
  yum_tmp.each do |tmp|
    rm_r tmp
  end
  sh "createrepo -g comps.xml -o #{BUILD_DIR} #{BUILD_DIR}/Packages"
end


directory "#{BUILD_DIR}/etc/yum.repos.d"
task :yum_configs => "#{BUILD_DIR}/etc/yum.repos.d" do
  File.open("#{BUILD_DIR}/etc/yum.conf", 'w') { |f| f.write <<CONF }
[main]
cachedir=#{BUILD_DIR}/cache
keepcache=0
debuglevel=6
logfile=#{BUILD_DIR}/yum.log
exactarch=1
obsoletes=1
gpgcheck=0
plugins=0
reposdir=#{BUILD_DIR}/etc/yum.repos.d
CONF

  File.open("#{BUILD_DIR}/etc/yum.repos.d/base.repo", 'w') { |f| f.write <<CONF }
[base]
name=CentOS-#{CENTOS_RELEASE} - Base
baseurl=http://mirror.yandex.ru/centos/#{CENTOS_RELEASE}/os/#{CENTOS_ARCH}/
gpgcheck=0
enabled=1
CONF
end
