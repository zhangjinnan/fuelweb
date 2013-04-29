.PHONY: iso img
all: iso img

ISOROOT:=$(BUILD_DIR)/iso/isoroot
ISOBASENAME:=nailgun-centos-6.3
ISONAME:=$(BUILD_DIR)/iso/$(ISOBASENAME).iso
IMGNAME:=$(BUILD_DIR)/iso/$(ISOBASENAME).img
BUILDKS:=$(SOURCE_DIR)/iso/ks-build.cfg
INSTALLKS:=$(SOURCE_DIR)/iso/ks.cfg
BUILDINSTALL:=-B

#yiso: $(BUILD_DIR)/iso/firstpass.done $(BUILD_DIR)/iso/iso.done
iso: $(BUILD_DIR)/iso/iso.done


#$(BUILD_DIR)/iso/isoroot-centos.done:
$(BUILD_DIR)/iso/isoroot.done:
	sudo pungi -c $(BUILDKS) --nosource --name="$(ISOBASENAME)" -G -C $(BUILDINSTALLOPT) -I --force 
	mkdir -p mountiso isoroot-mkisofs
	sudo mount -o loop,ro $(ISOBASENAME).iso mountiso
	rsync -vaz mountiso/. isoroot-mkisofs/.
	sudo umount mountiso
	rm -rf mountiso
	$(ACTION.COPY)

$(BUILD_DIR)/iso/isoroot-files.done: \
                $(BUILD_DIR)/iso/isoroot-dotfiles.done \
                $(ISOROOT)/isolinux/isolinux.cfg \
                $(ISOROOT)/ks.cfg \
                $(ISOROOT)/bootstrap_admin_node.sh \
                $(ISOROOT)/bootstrap_admin_node.conf \
                $(ISOROOT)/version.yaml \
                $(ISOROOT)/puppet-nailgun.tgz \
                $(ISOROOT)/puppet-slave.tgz
	$(ACTION.TOUCH)

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
# Building CD and USB stick images
########################

# keep in mind that mkisofs touches some files inside directory
# from which it builds iso image
# that is why we need to make isoroot.done dependent on some files
# and then copy these files into another directory
$(BUILD_DIR)/iso/iso.done: $(BUILD_DIR)/iso/isoroot.done
	rm -f $(ISONAME)
	mkdir -p $(BUILD_DIR)/iso/isoroot-mkisofs
	rsync -a --delete $(ISOROOT)/ $(BUILD_DIR)/iso/isoroot-mkisofs
	mkisofs -r -V "Mirantis FuelWeb" -p "Mirantis Inc." \
                -J -T -R -b isolinux/isolinux.bin \
                -no-emul-boot \
                -boot-load-size 4 -boot-info-table \
                -x "lost+found" -o $(ISONAME) $(BUILD_DIR)/iso/isoroot-mkisofs
	implantisomd5 $(ISONAME)
	$(ACTION.TOUCH)

