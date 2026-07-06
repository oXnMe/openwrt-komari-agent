-- LuCI CBI Model for Komari Agent
-- Provides a web interface for all komari-agent runtime parameters

local sys = require "luci.sys"
local fs = require "nixio.fs"
local m = Map("komari-agent", translate("Komari Agent"),
	translate("Komari is a lightweight self-hosted server monitoring tool. The agent collects system metrics "
		.. "and reports to the panel. The service will NOT start until you configure "
		.. "the Panel URL and Token, and set Enabled to checked."))
local s = m:section(TypedSection, "komari-agent", translate("Settings"))
s.anonymous = true
s.addremove = false

-- ============================================================
-- Required Parameters
-- ============================================================

local enabled = s:option(Flag, "enabled", translate("Enabled"),
	translate("Master switch. The service only starts when this is checked "
		.. "AND both Panel URL and Token are configured."))
enabled.default = 0
enabled.rmempty = false

local endpoint = s:option(Value, "endpoint", translate("Panel URL"),
	translate("Komari panel address, e.g., https://panel.example.com"))
endpoint.placeholder = "https://panel.example.com"
endpoint.datatype = "string"

local token = s:option(Value, "token", translate("Token"),
	translate("Authentication token obtained from the panel"))
token.password = true
token.datatype = "string"

-- ============================================================
-- Collection Settings
-- ============================================================

local interval = s:option(Value, "interval", translate("Collection Interval"),
	translate("Data collection interval in seconds. Leave empty to use the "
		.. "agent's built-in default (1s)."))
interval.placeholder = "1"
interval.datatype = "min(1)"
interval.rmempty = true

local month_rotate = s:option(Value, "month_rotate", translate("Monthly Reset Day"),
	translate("Day of month to reset network traffic statistics (1-31). "
		.. "Leave empty to disable traffic statistics."))
month_rotate.placeholder = "留空不统计流量"
month_rotate.datatype = "range(1, 31)"
month_rotate.rmempty = true

-- ============================================================
-- Feature Flags
-- ============================================================

local disable_web_ssh = s:option(Flag, "disable_web_ssh", translate("Disable Web SSH"),
	translate("Disable remote SSH access through the web panel"))
disable_web_ssh.default = 0

local ignore_unsafe_cert = s:option(Flag, "ignore_unsafe_cert", translate("Ignore Unsafe Certificate"),
	translate("Skip TLS certificate verification (use with self-signed certs)"))
ignore_unsafe_cert.default = 0

local get_ip_from_nic = s:option(Flag, "get_ip_from_nic", translate("Get IP from NIC"),
	translate("Get the public IP address from network interface instead of external service"))
get_ip_from_nic.default = 0

local disable_auto_update = s:option(Flag, "disable_auto_update", translate("Disable Auto Update"),
	translate("Disable automatic agent binary updates"))
disable_auto_update.default = 0

local memory_include_cache = s:option(Flag, "memory_include_cache", translate("Include Cache Memory"),
	translate("Report used memory + buffer/cache memory (default: used memory only)"))
memory_include_cache.default = 0

local gpu = s:option(Flag, "gpu", translate("GPU Monitoring"),
	translate("Enable detailed GPU monitoring"))
gpu.default = 0

-- ============================================================
-- Network Interface Filters
-- ============================================================

-- Collect available network interfaces for dropdown selection
local function get_network_interfaces()
	local interfaces = {}
	local ifaces = sys.net.devices()
	for _, iface in ipairs(ifaces) do
		if iface ~= "lo" then
			interfaces[#interfaces + 1] = iface
		end
	end
	table.sort(interfaces)
	return interfaces
end

local interfaces = get_network_interfaces()

local include_nics = s:option(MultiValue, "include_nics", translate("Include NICs"),
	translate("Only monitor these network interfaces. Leave empty to monitor all. "
		.. "Multiple interfaces can be selected."))
include_nics.delimiter = ","
for _, iface in ipairs(interfaces) do
	include_nics:value(iface, iface)
end

local exclude_nics = s:option(MultiValue, "exclude_nics", translate("Exclude NICs"),
	translate("Exclude these network interfaces from monitoring. "
		.. "Leave empty to exclude none."))
exclude_nics.delimiter = ","
for _, iface in ipairs(interfaces) do
	exclude_nics:value(iface, iface)
end

-- ============================================================
-- Mount Point Filters
-- ============================================================

-- Collect available mount points for suggestions
local function get_mount_points()
	local mounts = {}
	local f = io.open("/proc/mounts", "r")
	if f then
		for line in f:lines() do
			local mp = line:match("^%S+%s+(%S+)%s+%S+%s+%S+%s+%d+%s+%d+")
			if mp and mp ~= "/" and not mp:match("^/proc") and not mp:match("^/sys")
			   and not mp:match("^/dev") and not mp:match("^/run") then
				-- Unescape octal sequences in mount point paths
				mp = mp:gsub("\\(%d%d%d)", function(o)
					return string.char(tonumber(o, 8))
				end)
				mounts[#mounts + 1] = mp
			end
		end
		f:close()
	end
	table.sort(mounts)
	return mounts
end

local mount_points = get_mount_points()

local include_mountpoint = s:option(DynamicList, "include_mountpoint",
	translate("Include Mount Points"),
	translate("Only monitor these mount points. Leave empty to monitor all. "
		.. "Separate multiple entries. You can type custom paths or select from the list."))
for _, mp in ipairs(mount_points) do
	include_mountpoint:value(mp, mp)
end

return m
