.PHONY: iso img
all: iso img

include $(SOURCE_DIR)/iso/ks-build.mk

ISOROOT:=$(BUILD_DIR)/iso/isoroot
ISOBASENAME:=nailgun
ISOVER:=6.3
ISONAME:=$(BUILD_DIR)/iso/$(ISOBASENAME).iso
IMGNAME:=$(BUILD_DIR)/iso/$(ISOBASENAME).img
BUILDKS:=$(BUILD_DIR)/iso/ks-build.cfg
INSTALLKS:=$(SOURCE_DIR)/iso/ks.cfg

#iso: $(BUILD_DIR)/iso/firstpass.done $(BUILD_DIR)/iso/iso.done
iso: $(BUILD_DIR)/iso/iso.done


$(BUILD_DIR)/iso/isoroot-pungi.done: $(BUILD_DIR)/iso/kickstart.done
	if [ -f 6.3/x86_64/os/images/install.img ];then \
	  echo "Reusing existing iso data (and saving time)...";\
	  sudo pungi -c $(BUILDKS) --nosplitmedia --name=$(ISOBASENAME) --ver=$(ISOVER) --nosource --nodebuginfo -G -C -I --force --destdir $$PWD; \
	else \
	  echo "No existing iso data. Building from scratch (~15 minutes)..."; \
	  sudo pungi -c $(BUILDKS) --nosplitmedia --name=$(ISOBASENAME) --ver=$(ISOVER) --nosource --nodebuginfo -G -C -I --force; \
	fi
	mkdir -p mountiso $(ISOROOT)
	sudo mount -o loop,ro $(ISOVER)/x86_64/iso/$(ISOBASENAME)-$(ISOVER)-x86_64-DVD.iso mountiso
	rsync -a --delete --exclude=isolinux/isolinux.cfg mountiso/. $(ISOROOT)/.
	sudo umount mountiso
	rm -rf mountiso
	#sudo rm -rf $(ISOVER)/x86_64/iso/*.iso

$(BUILD_DIR)/iso/isoroot-files.done: \
	        $(ISOROOT)/isolinux/isolinux.cfg \
	        $(ISOROOT)/ks.cfg \
	        $(ISOROOT)/bootstrap_admin_node.sh \
	        $(ISOROOT)/bootstrap_admin_node.conf \
	        $(ISOROOT)/version.yaml \
	        $(ISOROOT)/puppet-nailgun.tgz \
	        $(ISOROOT)/puppet-slave.tgz
	$(ACTION.TOUCH)


$(BUILD_DIR)/iso/kickstart.done: $(SOURCE_DIR)/packages/ksrepo/build.done $(BUILDKS)
$(BUILDKS): $(call depv,ks_build_cfg)
$(BUILDKS): export contents:=$(ks_build_cfg)
$(BUILDKS):
	mkdir -p $(@D)
	echo -e "$${contents}" > $@
	

$(BUILD_DIR)/iso/isoroot-centos.done: \
               $(BUILD_DIR)/mirror/build.done \
               $(BUILD_DIR)/packages/build.done \
               $(BUILD_DIR)/iso/isoroot-dotfiles.done
	mkdir -p $(ISOROOT)
	rsync -rp $(LOCAL_MIRROR_CENTOS_OS_BASEURL)/    $(ISOROOT)
	createrepo -g `readlink -f "$(ISOROOT)/repodata/comps.xml"` \
               -u media://`head -1 $(ISOROOT)/.discinfo` $(ISOROOT)
	$(ACTION.TOUCH)

$(BUILD_DIR)/iso/isoroot-eggs.done: \
               $(BUILD_DIR)/mirror/build.done \
               $(BUILD_DIR)/packages/build.done
	mkdir -p $(ISOROOT)/eggs
	rsync -a --delete $(LOCAL_MIRROR_EGGS)/ $(ISOROOT)/eggs
	$(ACTION.TOUCH)

$(BUILD_DIR)/iso/isoroot-gems.done: \
               $(BUILD_DIR)/mirror/build.done \
               $(BUILD_DIR)/packages/build.done
	mkdir -p $(ISOROOT)/gems
	rsync -a --delete $(LOCAL_MIRROR_GEMS)/ $(ISOROOT)/gems
	$(ACTION.TOUCH)


########################
# Extra files
# ########################
#
#

$(BUILD_DIR)/iso/isoroot-dotfiles.done: \
                $(ISOROOT)/.discinfo \
                $(ISOROOT)/.treeinfo
	$(ACTION.TOUCH)

$(ISOROOT)/.discinfo: $(SOURCE_DIR)/iso/.discinfo ; $(ACTION.COPY)
$(ISOROOT)/.treeinfo: $(SOURCE_DIR)/iso/.treeinfo ; $(ACTION.COPY)
$(ISOROOT)/isolinux/isolinux.cfg: $(SOURCE_DIR)/iso/isolinux/isolinux.cfg ; $(ACTION.COPY)
$(ISOROOT)/ks.cfg: $(SOURCE_DIR)/iso/ks.cfg ; $(ACTION.COPY)
$(ISOROOT)/bootstrap_admin_node.sh: $(SOURCE_DIR)/iso/bootstrap_admin_node.sh ; $(ACTION.COPY)
$(ISOROOT)/bootstrap_admin_node.conf: $(SOURCE_DIR)/iso/bootstrap_admin_node.conf ; $(ACTION.COPY)
$(ISOROOT)/version.yaml: $(call depv,COMMIT_SHA)
$(ISOROOT)/version.yaml: $(call depv,PRODUCT_VERSION)
$(ISOROOT)/version.yaml:
	echo "COMMIT_SHA: $(COMMIT_SHA)" > $@
	echo "PRODUCT_VERSION: $(PRODUCT_VERSION)" >> $@
$(ISOROOT)/puppet-nailgun.tgz: \
                $(call find-files,$(SOURCE_DIR)/puppet) \
                $(SOURCE_DIR)/bin/send2syslog.py
	(cd $(SOURCE_DIR)/puppet && tar chzf $@ *)
$(ISOROOT)/puppet-slave.tgz: \
                $(call find-files,$(SOURCE_DIR)/puppet/nailytest) \
                $(call find-files,$(SOURCE_DIR)/puppet/osnailyfacter) \
                $(call find-files,$(SOURCE_DIR)/fuel/deployment/puppet)
	(cd $(SOURCE_DIR)/puppet && tar cf $(ISOROOT)/puppet-slave.tar nailytest osnailyfacter)
	(cd $(SOURCE_DIR)/fuel/deployment/puppet && tar rf $(ISOROOT)/puppet-slave.tar ./*)
	gzip -c -9 $(ISOROOT)/puppet-slave.tar > $@ && \
                rm $(ISOROOT)/puppet-slave.tar
########################
# Iso image root file system.
########################

$(BUILD_DIR)/iso/isoroot.done: \
                $(BUILD_DIR)/mirror/build.done \
                $(BUILD_DIR)/packages/build.done \
                $(BUILD_DIR)/iso/isoroot-centos.done \
                $(BUILD_DIR)/iso/isoroot-eggs.done \
                $(BUILD_DIR)/iso/isoroot-gems.done \
                $(BUILD_DIR)/iso/isoroot-files.done \
                $(BUILD_DIR)/iso/isoroot-bootstrap.done
	$(ACTION.TOUCH)

########################
# Bootstrap image.
########################

BOOTSTRAP_FILES:=initramfs.img linux

$(BUILD_DIR)/iso/isoroot-bootstrap.done: \
	        $(ISOROOT)/bootstrap/bootstrap.rsa \
	        $(addprefix $(ISOROOT)/bootstrap/, $(BOOTSTRAP_FILES))
	$(ACTION.TOUCH)

$(addprefix $(ISOROOT)/bootstrap/, $(BOOTSTRAP_FILES)): \
                $(BUILD_DIR)/bootstrap/build.done
	@mkdir -p $(@D)
	cp $(BUILD_DIR)/bootstrap/$(@F) $@

$(ISOROOT)/bootstrap/bootstrap.rsa: $(SOURCE_DIR)/bootstrap/ssh/id_rsa ; $(ACTION.COPY)


########################
# Building CD and USB stick images
########################

# keep in mind that mkisofs touches some files inside directory
# from which it builds iso image
# that is why we need to make isoroot.done dependent on some files
# and then copy these files into another directory
ifeq "$(ISO_METHOD)" "pungi"
$(BUILD_DIR)/iso/iso.done: $(BUILD_DIR)/iso/isoroot-pungi.done \
		$(BUILD_DIR)/iso/isoroot-files.done 
else
$(BUILD_DIR)/iso/iso.done: $(BUILD_DIR)/iso/isoroot.done \
	        $(BUILD_DIR)/iso/isoroot-dotfiles.done
endif
	rm -f $(ISONAME)
	mkdir -p $(BUILD_DIR)/iso/isoroot-mkisofs
	rsync -a --delete $(ISOROOT)/ $(BUILD_DIR)/iso/isoroot-mkisofs
	sudo mkisofs -r -V "Mirantis FuelWeb" -p "Mirantis Inc." \
                -J -T -R -b isolinux/isolinux.bin \
                -no-emul-boot \
                -boot-load-size 4 -boot-info-table \
                -x "lost+found" -o $(ISONAME) $(BUILD_DIR)/iso/isoroot-mkisofs
	sudo implantisomd5 $(ISONAME)
	env user=$$USER sudo chown $$user:$$user $(ISONAME)
	$(ACTION.TOUCH)

