include $(SOURCE_DIR)/mirror/rhel/yum_repos.mk

.PHONY: show-yum-urls

$(BUILD_DIR)/mirror/rhel/etc/yum.conf: $(call depv,rhel_yum_conf)
$(BUILD_DIR)/mirror/rhel/etc/yum.conf: export contents:=$(rhel_yum_conf)
$(BUILD_DIR)/mirror/rhel/etc/yum.conf:
	mkdir -p $(@D)
	echo "$${contents}" > $@

$(BUILD_DIR)/mirror/rhel/etc/yum-plugins/priorities.py: \
		$(SOURCE_DIR)/mirror/rhel/yum-priorities-plugin.py
	mkdir -p $(@D)
	cp $(SOURCE_DIR)/mirror/rhel/yum-priorities-plugin.py $@

$(BUILD_DIR)/mirror/rhel/etc/yum/pluginconf.d/priorities.conf:
	mkdir -p $(@D)
	echo "[main]\nenabled=1\ncheck_obsoletes=1\nfull_match=1" > $@

$(BUILD_DIR)/mirror/rhel/etc/yum.repos.d/base.repo: $(call depv,YUM_REPOS)
$(BUILD_DIR)/mirror/rhel/etc/yum.repos.d/base.repo: \
		export contents:=$(foreach repo,$(YUM_REPOS),\n$(rhel_yum_repo_$(repo))\n)
$(BUILD_DIR)/mirror/rhel/etc/yum.repos.d/base.repo:
	@mkdir -p $(@D)
	echo "$${contents}" > $@

$(BUILD_DIR)/mirror/rhel/yum-config.done: \
		$(BUILD_DIR)/mirror/rhel/etc/yum.conf \
		$(BUILD_DIR)/mirror/rhel/etc/yum.repos.d/base.repo \
		$(BUILD_DIR)/mirror/rhel/etc/yum-plugins/priorities.py \
		$(BUILD_DIR)/mirror/rhel/etc/yum/pluginconf.d/priorities.conf
	$(ACTION.TOUCH)

$(BUILD_DIR)/mirror/rhel/yum.done: $(call depv,REQUIRED_RHEL_RPMS)
$(BUILD_DIR)/mirror/rhel/yum.done: \
		$(BUILD_DIR)/mirror/rhel/yum-config.done
	yum -c $(BUILD_DIR)/mirror/rhel/etc/yum.conf clean all
	rm -rf /var/tmp/yum-$$USER-*/
	yumdownloader -q --resolve --archlist=$(CENTOS_ARCH) \
		-c $(BUILD_DIR)/mirror/rhel/etc/yum.conf \
		--destdir=$(LOCAL_MIRROR_RHEL)/Packages \
		`echo $(REQUIRED_RHEL_RPMS) | /bin/sed 's/-[0-9][0-9\.a-zA-Z_-]\+//g'`
	$(ACTION.TOUCH)

show-yum-urls-rhel: $(call depv,REQUIRED_RHEL_RPMS)
show-yum-urls-rhel: \
		$(BUILD_DIR)/mirror/rhel/yum-config.done
	yum -c $(BUILD_DIR)/mirror/rhel/etc/yum.conf clean all
	rm -rf /var/tmp/yum-$$USER-*/
	yumdownloader --urls -q --resolve --archlist=$(CENTOS_ARCH) \
		-c $(BUILD_DIR)/mirror/rhel/etc/yum.conf \
		--destdir=$(LOCAL_MIRROR_RHEL)/Packages \
		`echo $(REQUIRED_RHEL_RPMS) | /bin/sed 's/-[0-9][0-9\.a-zA-Z_-]\+//g'`

$(LOCAL_MIRROR_RHEL)/repodata/comps.xml: \
		export COMPSXML=$(shell wget -qO- $(MIRROR_RHEL)/repodata/repomd.xml | grep -m 1 '$(@F)' | awk -F'"' '{ print $$2 }')
$(LOCAL_MIRROR_RHEL)/repodata/comps.xml:
	@mkdir -p $(@D)
	if ( echo $${COMPSXML} | grep -q '\.gz$$' ); then \
		wget -O $@.gz $(MIRROR_RHEL)/$${COMPSXML}; \
		gunzip $@.gz; \
	else \
		wget -O $@ $(MIRROR_RHEL)/$${COMPSXML}; \
	fi

$(BUILD_DIR)/mirror/rhel/fuel.done:
	mkdir -p $(LOCAL_MIRROR)/mirror/rhel/fuel/Packages
	-wget -c -i $(SOURCE_DIR)/req-fuel-rhel.txt -B http://download.mirantis.com/epel-fuel-grizzly/x86_64/ -P $(LOCAL_MIRROR)/rhel/fuel/Packages
	-wget -c -i $(SOURCE_DIR)/req-fuel-rhel.txt -B http://download.mirantis.com/epel-fuel-grizzly/noarch/ -P $(LOCAL_MIRROR)/rhel/fuel/Packages
	-wget -c -i $(SOURCE_DIR)/req-fuel-rhel.txt -B http://srv11-msk.msk.mirantis.net/rhel6/fuel-rpms/x86_64/ -P $(LOCAL_MIRROR)/rhel/fuel/Packages
	$(ACTION.TOUCH)

$(BUILD_DIR)/mirror/rhel/repo.done: \
		$(BUILD_DIR)/mirror/rhel/yum.done \
		$(BUILD_DIR)/mirror/rhel/fuel.done \
		| $(LOCAL_MIRROR_RHEL)/repodata/comps.xml
	createrepo -g $(LOCAL_MIRROR_RHEL)/repodata/comps.xml \
		-o $(LOCAL_MIRROR_RHEL)/ $(LOCAL_MIRROR_RHEL)/
	$(ACTION.TOUCH)
