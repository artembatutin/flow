APP_NAME := Flow
PROJECT := Flow.xcodeproj
SCHEME := Flow
CONFIGURATION ?= Debug
BUILD_ROOT := $(CURDIR)/build
BUILD_DIR := $(BUILD_ROOT)/$(CONFIGURATION)
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
APPLICATIONS_DIR ?= /Applications

.PHONY: build install uninstall clean

build:
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination 'platform=macOS' \
		CONFIGURATION_BUILD_DIR="$(BUILD_DIR)" \
		build

install: build
	rm -rf "$(APPLICATIONS_DIR)/$(APP_NAME).app"
	ditto "$(APP_BUNDLE)" "$(APPLICATIONS_DIR)/$(APP_NAME).app"

uninstall:
	rm -rf "$(APPLICATIONS_DIR)/$(APP_NAME).app"

clean:
	rm -rf "$(BUILD_ROOT)"
