include $(SOURCE_DIR)/packages/ksrepo/yum_ks_repos.mk
$(SOURCE_DIR)/packages/ksrepo/build.done: $(BUILD_DIR)/ksrepos.cfg

$(BUILD_DIR)/ksrepos.cfg: $(call depv,yum_ks_repos)
$(BUILD_DIR)/ksrepos.cfg: export contents:=$(yum_ks_repos)
$(BUILD_DIR)/ksrepos.cfg:
	mkdir -p $(@D)
	echo -e "$${contents}" > $@

