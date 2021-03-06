# Possible values for CM: (nocm | chef | chefdk | salt | puppet)
CM ?= nocm
# Possible values for CM_VERSION: (latest | x.y.z | x.y)
CM_VERSION ?=
ifndef CM_VERSION
	ifneq ($(CM),nocm)
		CM_VERSION = latest
	endif
endif
BOX_VERSION ?= $(shell cat VERSION)
ifeq ($(CM),nocm)
	BOX_SUFFIX := -$(CM)-$(BOX_VERSION).box
else
	BOX_SUFFIX := -$(CM)$(CM_VERSION)-$(BOX_VERSION).box
endif

TEMPLATE_FILENAMES := $(filter-out ubuntu.json,$(wildcard *.json))
BOX_NAMES := $(basename $(TEMPLATE_FILENAMES))
BOX_FILENAMES := $(TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
VMWARE_BOX_DIR ?= box/vmware
VMWARE_TEMPLATE_FILENAMES = $(TEMPLATE_FILENAMES)
VMWARE_BOX_FILENAMES := $(VMWARE_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
VMWARE_BOX_FILES := $(foreach box_filename, $(VMWARE_BOX_FILENAMES), $(VMWARE_BOX_DIR)/$(box_filename))
VIRTUALBOX_BOX_DIR ?= box/virtualbox
VIRTUALBOX_TEMPLATE_FILENAMES = $(TEMPLATE_FILENAMES)
VIRTUALBOX_BOX_FILENAMES := $(VIRTUALBOX_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
VIRTUALBOX_BOX_FILES := $(foreach box_filename, $(VIRTUALBOX_BOX_FILENAMES), $(VIRTUALBOX_BOX_DIR)/$(box_filename))
PARALLELS_BOX_DIR ?= box/parallels
PARALLELS_TEMPLATE_FILENAMES = $(TEMPLATE_FILENAMES)
PARALLELS_BOX_FILENAMES := $(PARALLELS_TEMPLATE_FILENAMES:.json=$(BOX_SUFFIX))
PARALLELS_BOX_FILES := $(foreach box_filename, $(PARALLELS_BOX_FILENAMES), $(PARALLELS_BOX_DIR)/$(box_filename))
BOX_FILES := $(VMWARE_BOX_FILES) $(VIRTUALBOX_BOX_FILES) $(PARALLELS_BOX_FILES)

box/vmware/%$(BOX_SUFFIX) box/virtualbox/%$(BOX_SUFFIX) box/parallels/%$(BOX_SUFFIX): %.json
	bin/box build $<

.PHONY: all clean assure deliver

all: build assure deliver

build: $(BOX_FILES)

assure: assure_vmware assure_virtualbox assure_parallels

assure_vmware: $(VMWARE_BOX_FILES)
	@for vmware_box_file in $(VMWARE_BOX_FILES) ; do \
		echo Checking $$vmware_box_file ; \
		bin/box test $$vmware_box_file vmware ; \
	done

assure_virtualbox: $(VIRTUALBOX_BOX_FILES)
	@for virtualbox_box_file in $(VIRTUALBOX_BOX_FILES) ; do \
		echo Checking $$virtualbox_box_file ; \
		bin/box test $$virtualb_box_file virtualbox ; \
	done

assure_parallels: $(PARALLELS_BOX_FILES)
	@for parallels_box_file in $(PARALLELS_BOX_FILES) ; do \
		echo Checking $$parallels_box_file ; \
		bin/box test $$parallels_box_file parallels ; \
	done

deliver:
	@for box_name in $(BOX_NAMES) ; do \
		echo Uploading $$box_name to Atlas ; \
		bin/register_atlas_box_cutter.sh $$box_name $(BOX_SUFFIX) $(BOX_VERSION) ; \
		bin/register_atlas.sh $$box_name $(BOX_SUFFIX) $(BOX_VERSION) ; \
	done

clean:
	rm -f $(BOX_FILES)
	echo Deleting output-*vmware-iso ; \
	echo rm -rf output-*vmware-iso ; \
	echo Deleting output-*virtualbox-iso ; \
	echo rm -rf output-*virtualbox-iso ; \
	echo Deleting output-*parallels-iso ; \
	echo rm -rf output-*parallels-iso ; \
