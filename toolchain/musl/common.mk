#
# Copyright (C) 2012-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(BUILD_DIR)/target.mk

PKG_NAME:=musl
PKG_VERSION:=$(call qstrip,$(CONFIG_MUSL_VERSION))
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=ea9525c8bcf6170df59364c4bcd616de1acf8703
PKG_MIRROR_HASH:=6975c45b9bfe586ac00dbfcd1b1a13ab110af0528028ab3dee03e23e2c0763e5
PKG_SOURCE_URL:=git://git.musl-libc.org/musl
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.xz

LIBC_SO_VERSION:=$(PKG_VERSION)
PATCH_DIR:=$(PATH_PREFIX)/patches

BUILD_DIR_HOST:=$(BUILD_DIR_TOOLCHAIN)
HOST_BUILD_PREFIX:=$(TOOLCHAIN_DIR)
HOST_BUILD_DIR:=$(COMPILE_DIR_TOOLCHAIN)/$(PKG_NAME)-$(PKG_VERSION)

include $(BUILD_DIR)/toolchain-build.mk
include $(BUILD_DIR)/hardening.mk

TARGET_CFLAGS:= $(filter-out -O%,$(TARGET_CFLAGS))
TARGET_CFLAGS+= $(if $(CONFIG_MUSL_DISABLE_CRYPT_SIZE_HACK),,-DCRYPT_SIZE_HACK)

MUSL_CONFIGURE:= \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	$(HOST_BUILD_DIR)/configure \
		--prefix=/ \
		--host=$(GNU_HOST_NAME) \
		--target=$(REAL_GNU_TARGET_NAME) \
		--disable-gcc-wrapper \
		--enable-debug \
		--enable-optimize

define Host/Prepare
	$(call Host/Prepare/Default)
	$(if $(strip $(QUILT)), \
		cd $(HOST_BUILD_DIR); \
		if $(QUILT_CMD) next >/dev/null 2>&1; then \
			$(QUILT_CMD) push -a; \
		fi
	)
	ln -snf $(PKG_NAME)-$(PKG_VERSION) $(COMPILE_DIR_TOOLCHAIN)/$(PKG_NAME)
endef

define Host/Configure
	( cd $(HOST_BUILD_DIR); rm -f config.cache; \
		$(MUSL_CONFIGURE) \
	);
endef

define Host/Clean
	rm -rf \
		$(HOST_BUILD_DIR) \
		$(COMPILE_DIR_TOOLCHAIN)/$(PKG_NAME) \
		$(COMPILE_DIR_TOOLCHAIN)/$(LIBC)-dev
endef
