if not fs.exists("/git-over-here.lua") then
	print("git-over-here not found, preparing installation...")
	shell.run("pastebin get h8np44GM /git-over-here.lua")
end
if not fs.exists("/bin/cc-output") then
	print("cc-output not found, preparing installation...")
	shell.run("git-over-here qthompson2/cc-output /bin/cc-output")
end

MonitorController = require("controller")
MonitorConnector = require("connector")

return {
	runRemoteMonitor = function(monitor_name, modem_side)
		local controller = MonitorController:new(monitor_name)
		controller:run(modem_side)
	end,
	connectRemoteMonitor = function(monitor_name, modem_side)
		return MonitorConnector:new(monitor_name, modem_side)
	end
}