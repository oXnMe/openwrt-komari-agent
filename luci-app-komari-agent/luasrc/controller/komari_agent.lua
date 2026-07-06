-- LuCI Controller for Komari Agent
-- Registers the configuration page under Services -> Komari Agent

module("luci.controller.komari_agent", package.seeall)

function index()
	-- Only show menu if config file exists
	if not nixio.fs.access("/etc/config/komari-agent") then
		return
	end

	entry({"admin", "services", "komari-agent"},
		cbi("komari_agent"), _("Komari Agent"), 60).dependent = true
end
