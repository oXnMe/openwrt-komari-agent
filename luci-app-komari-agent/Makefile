#
# Copyright (C) 2026 openwrt-komari-agent <https://github.com/oXnMe/openwrt-komari-agent>
#
# This is free software, licensed under the MIT License.
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Komari Agent - LuCI Configuration Interface
LUCI_DESCRIPTION:=Web interface for configuring the Komari monitoring agent.
LUCI_DEPENDS:=+komari-agent +luci-compat
LUCI_LANG.zh_Hans:=简体中文
LUCI_LANG.zh-cn:=简体中文

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,luci-app-komari-agent))
