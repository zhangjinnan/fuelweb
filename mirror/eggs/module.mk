.PHONY: clean clean-mirror-eggs mirror-eggs

mirror-eggs: $(BUILD_DIR)/mirror/eggs/build.done

clean: clean-mirror-eggs

clean-mirror-eggs:
	-sudo umount $(BUILD_DIR)/mirror/eggs/SANDBOX/proc
	-sudo umount $(BUILD_DIR)/mirror/eggs/SANDBOX/dev
	sudo rm -rf $(BUILD_DIR)/mirror/eggs

CHROOT_EGGS:=$(filter-out git+ssh%,$(REQUIRED_EGGS))
NO_CHROOT_EGGS:=$(filter git+ssh%,$(REQUIRED_EGGS))

$(BUILD_DIR)/mirror/eggs/build.done: $(call depv,LOCAL_MIRROR_EGGS)
$(BUILD_DIR)/mirror/eggs/build.done: $(call depv,REQUIRED_EGGS)
$(BUILD_DIR)/mirror/eggs/build.done: $(call depv,SANDBOX_PACKAGES)
$(BUILD_DIR)/mirror/eggs/build.done: SANDBOX:=$(BUILD_DIR)/mirror/eggs/SANDBOX
$(BUILD_DIR)/mirror/eggs/build.done: export SANDBOX_UP:=$(SANDBOX_UP)
$(BUILD_DIR)/mirror/eggs/build.done: export SANDBOX_DOWN:=$(SANDBOX_DOWN)
$(BUILD_DIR)/mirror/eggs/build.done: \
		$(BUILD_DIR)/mirror/centos/build.done
	mkdir -p $(@D)

	# Creating eggs mirror directory
	mkdir -p $(LOCAL_MIRROR_EGGS)

	# Clone git+ssh repos and set up list of requirements.
	# It's ok for public version to fail here, so we ignore errors
	rm -rf $(BUILD_DIR)/mirror/eggs/git-clone
	mkdir -p $(BUILD_DIR)/mirror/eggs/git-clone
	for repo in $(NO_CHROOT_EGGS); do \
	  (cd $(BUILD_DIR)/mirror/eggs/git-clone && git clone $$repo) || true; \
	done
	for repo in $(BUILD_DIR)/mirror/eggs/git-clone/*; do \
	  (cd $$repo && python setup.py sdist && cp dist/*.tar.gz $(LOCAL_MIRROR_EGGS) ) || true; \
	done
	find $(BUILD_DIR)/mirror/eggs/git-clone -wholename '*.egg-info/requires.txt' | xargs sort -u > $(BUILD_DIR)/mirror/eggs/chroot-req-pre.txt
	echo $(CHROOT_EGGS) >> $(BUILD_DIR)/mirror/eggs/chroot-req-pre.txt
	sed -e 's/\s\+/\n/g' $(BUILD_DIR)/mirror/eggs/chroot-req-pre.txt | sort -u > $(BUILD_DIR)/mirror/eggs/chroot-req.txt

	sudo sh -c "$${SANDBOX_UP}"

	# Avoiding eggs download duplication.
	sudo rsync -a --delete $(LOCAL_MIRROR_EGGS) $(SANDBOX)/tmp

	# Here we don't know if MIRROR_EGGS
	# is a list of links or a correct pip index.
	# That is why we use --index-url and --find-links options
	# for the same url.

	# Installing new version of pip.
	sudo chroot $(SANDBOX) pip --version 2>/dev/null | awk '{print $$2}' | grep -qE "^1.2.1$$" || \
		sudo chroot $(SANDBOX) pip-python install \
		--index-url $(MIRROR_EGGS) \
		--find-links $(MIRROR_EGGS) \
		pip==1.2.1

	# Downloading required pip packages.
	# pip cannot download two versions of the package at once,
	# so we do it in cycle.
	for dep in `cat $(BUILD_DIR)/mirror/eggs/chroot-req.txt`; do \
	  sudo chroot $(SANDBOX) pip install \
		--exists-action=i \
		--index-url $(MIRROR_EGGS) \
		--find-links $(MIRROR_EGGS) \
		--download /tmp/$(notdir $(LOCAL_MIRROR_EGGS)) \
		$$dep; \
	done

	# # Copying downloaded eggs into eggs mirror
	rsync -a $(SANDBOX)/tmp/$(notdir $(LOCAL_MIRROR_EGGS))/ $(LOCAL_MIRROR_EGGS)

	sudo sh -c "$${SANDBOX_DOWN}"
	$(ACTION.TOUCH)
