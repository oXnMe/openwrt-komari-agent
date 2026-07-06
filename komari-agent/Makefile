#
# Copyright (C) 2026 openwrt-komari-agent <https://github.com/oXnMe/openwrt-komari-agent>
#
# This is free software, licensed under the MIT License.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=komari-agent
PKG_VERSION:=1.1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=openwrt-komari-agent
PKG_LICENSE:=MIT

# Version override — must be BEFORE include package.mk so that
# PKG_BUILD_DIR and stamps use the correct version.
KOMARI_VERSION?=latest
KOMARI_PKG_VERSION?=

ifneq ($(KOMARI_PKG_VERSION),)
  PKG_VERSION:=$(KOMARI_PKG_VERSION)
endif

ifeq ($(KOMARI_VERSION),latest)
  KOMARI_RELEASE_PATH:=latest/download
else
  KOMARI_RELEASE_PATH:=download/$(KOMARI_VERSION)
endif

PKG_BUILD_DEPENDS:=

include $(INCLUDE_DIR)/package.mk

# Variant: zig (default) or go
ifeq ($(CONFIG_KOMARI_AGENT_VARIANT_GO),y)
  KOMARI_REPO:=komari-monitor/komari-agent
  KOMARI_VARIANT:=go
  KOMARI_VARIANT_DESC:=Go (upstream)
else
  KOMARI_REPO:=luodaoyi/komari-zig-agent
  KOMARI_VARIANT:=zig
  KOMARI_VARIANT_DESC:=Zig (lightweight)
endif

# Architecture mapping
ifeq ($(ARCH),x86_64)
  KOMARI_ARCH:=amd64
else ifeq ($(ARCH),aarch64)
  KOMARI_ARCH:=arm64
else ifeq ($(ARCH),arm)
  KOMARI_ARCH:=arm
else ifeq ($(ARCH),armeb)
  KOMARI_ARCH:=arm
else ifeq ($(ARCH),i386)
  KOMARI_ARCH:=386
else ifeq ($(ARCH),i486)
  KOMARI_ARCH:=386
else ifeq ($(ARCH),i586)
  KOMARI_ARCH:=386
else ifeq ($(ARCH),i686)
  KOMARI_ARCH:=386
else ifeq ($(ARCH),mips)
  KOMARI_ARCH:=mips
else ifeq ($(ARCH),mipsel)
  KOMARI_ARCH:=mipsel
else ifeq ($(ARCH),mips64)
  KOMARI_ARCH:=mips64
else ifeq ($(ARCH),mips64el)
  KOMARI_ARCH:=mips64el
else ifeq ($(ARCH),riscv64)
  KOMARI_ARCH:=riscv64
else ifeq ($(ARCH),s390x)
  KOMARI_ARCH:=s390x
else ifeq ($(ARCH),loongarch64)
  KOMARI_ARCH:=loong64
else
  KOMARI_ARCH:=
endif

# Go variant: no MIPS/RISC-V/s390x/LoongArch binaries
ifeq ($(KOMARI_VARIANT),go)
  ifneq ($(filter mips mipsel mips64 mips64el riscv64 s390x loong64,$(KOMARI_ARCH)),)
    KOMARI_ARCH_UNSUPPORTED:=1
  endif
endif

# GitHub proxy (optional): make ... GHPROXY=https://gh-proxy.org
GHPROXY?=

# Build download URLs as Make variables (not shell variables) to avoid
# OpenWrt build system stripping $ signs in define blocks.
KOMARI_GH_BASE := $(if $(GHPROXY),$(GHPROXY)/https://github.com,https://github.com)
KOMARI_DOWNLOAD_URL := $(KOMARI_GH_BASE)/$(KOMARI_REPO)/releases/$(KOMARI_RELEASE_PATH)/komari-agent-linux-$(KOMARI_ARCH)
KOMARI_SHA256_URL := $(KOMARI_GH_BASE)/$(KOMARI_REPO)/releases/$(KOMARI_RELEASE_PATH)/SHA256SUMS


define Package/komari-agent
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Monitoring
  TITLE:=Komari Monitoring Agent ($(KOMARI_VARIANT_DESC))
  URL:=https://github.com/$(KOMARI_REPO)
  DEPENDS:=ca-bundle
endef

define Package/komari-agent/description
  Komari monitoring agent for OpenWrt/LEDE.
  Pre-built binary downloaded from GitHub releases at build time.
  Configure via LuCI or UCI after installation.
endef

define Package/komari-agent/config
choice
	prompt "Agent implementation"
	default KOMARI_AGENT_VARIANT_ZIG

config KOMARI_AGENT_VARIANT_ZIG
	bool "Zig implementation (lightweight, recommended)"
	help
	  Zig implementation from https://github.com/luodaoyi/komari-zig-agent
	  Smaller binary, supports x86 / ARM / MIPS / RISC-V / s390x / LoongArch.

config KOMARI_AGENT_VARIANT_GO
	bool "Go implementation (upstream original)"
	help
	  Original Go implementation from https://github.com/komari-monitor/komari-agent
	  Supports x86 and ARM only.

endchoice
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp ./files/komari-build.sh $(PKG_BUILD_DIR)/
endef

define Build/Compile
	@if [ -z "$(KOMARI_ARCH)" ]; then \
		echo "ERROR: Unsupported architecture: $(ARCH)" >&2; exit 1; \
	fi
	@if [ -n "$(KOMARI_ARCH_UNSUPPORTED)" ]; then \
		echo "ERROR: Go variant has no binary for $(ARCH). Use Zig variant." >&2; exit 1; \
	fi
	@echo "=== $(KOMARI_VARIANT_DESC) / $(ARCH) -> $(KOMARI_ARCH) ==="
ifeq ($(KOMARI_VARIANT),zig)
	@sh $(PKG_BUILD_DIR)/komari-build.sh "$(PKG_BUILD_DIR)" "$(KOMARI_ARCH)" "$(KOMARI_DOWNLOAD_URL)" "$(KOMARI_SHA256_URL)" "$(GHPROXY)"
else
	@sh $(PKG_BUILD_DIR)/komari-build.sh "$(PKG_BUILD_DIR)" "$(KOMARI_ARCH)" "$(KOMARI_DOWNLOAD_URL)" "none" "$(GHPROXY)"
endif
endef

define Package/komari-agent/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/komari-agent $(1)/usr/bin/komari-agent

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/komari-agent.init $(1)/etc/init.d/komari-agent

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/komari-agent.conf $(1)/etc/config/komari-agent

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/komari-agent.uci-defaults $(1)/etc/uci-defaults/komari-agent
endef

define Package/komari-agent/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0
echo "Komari Agent installed ($(KOMARI_VARIANT_DESC)). Configure via LuCI or UCI."
exit 0
endef

$(eval $(call BuildPackage,komari-agent))
