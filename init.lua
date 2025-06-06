if not fs.exists("/git-over-here.lua") then
	print("git-over-here not found, preparing installation...")
	shell.run("pastebin get h8np44GM /git-over-here.lua")
end
if not fs.exists("/bin/cc-output") then
	print("cc-output not found, preparing installation...")
	shell.run("git-over-here qthompson2/cc-output /bin/cc-output")
end

Output = require("bin.cc-output")

MonitorController = {}

function MonitorController:new(monitor_name)
	local obj = {}

	obj.monitor = peripheral.wrap(monitor_name or "") or peripheral.find("monitor")
	obj.monitor_name = monitor_name or peripheral.getName(obj.monitor)
	self.running = false

	if not obj.monitor then
		error("MonitorController.new: No monitors connected to this device.")
	end

	Output.redirect(obj.monitor_name)

	setmetatable(obj, self)
	self.__index = self

	return obj
end

function MonitorController:run(modem_side)
	local modem = peripheral.wrap(modem_side or "") or peripheral.find("modem")
	modem_side = modem_side or peripheral.getName(modem)

	rednet.open(modem_side)
	rednet.host("wmp", self.monitor_name)

	self.running = true

	while self.running do
		local event_data = {os.pullEvent()}
		local event = event_data[1]

		if event == "rednet_message" then
			local sender_id = event_data[2]
			local message = event_data[3]
			local protocol = event_data[4]

			if protocol == "wmp" then
				if type(message) == "table" then
					if message.command == "getTextColor" then
						message.command = "getTextColour"
						message.colour = message.color or message.colour
					elseif message.command == "getBackgroundColor" then
						message.command = "getBackgroundColour"
						message.colour = message.color or message.colour
					elseif message.command == "setTextColor" then
						message.command = "setTextColour"
						message.colour = message.color or message.colour
					elseif message.command == "setBackgroundColor" then
						message.command = "setBackgroundColour"
						message.colour = message.color or message.colour
					elseif message.command == "isColor" then
						message.command = "isColour"
					end

					if message.command == "clear" then
						Output.clear()
						rednet.send(sender_id, {success = true}, "wmp")

					elseif message.command == "clearLine" then
						Output.clearLine()
						rednet.send(sender_id, {success = true}, "wmp")

					elseif message.command == "update" then
						Output.update()
						rednet.send(sender_id, {success = true}, "wmp")

					elseif message.command == "setTextScale" then
						if type(message.scale) == "number" then
							Output.setTextScale(message.scale)
							rednet.send(sender_id, {success = true}, "wmp")
						
						else
							rednet.send(sender_id, {success = false, msg = "Invalid Argument: type of message.scale cannot be " .. type(message.scale) .. "."}, "wmp")
						end

					elseif message.command == "setCursorPos" then
						if type(message.x) == "number" and type(message.y) == "number" then
							Output.setCursorPos(message.x, message.y)
							rednet.send(sender_id, {success = true}, "wmp")

						elseif type(message.x) ~= "number" then
							rednet.send(sender_id, {success = false, msg = "Invalid Argument: type of message.x cannot be " .. type(message.x) .. "."}, "wmp")
						elseif type(message.y) ~= "number" then
							rednet.send(sender_id, {success = false, msg = "Invalid Argument: type of message.y cannot be " .. type(message.y) .. "."}, "wmp")
						end

					elseif message.command == "write" then
						if type(message.text) == "string" then
							Output.write(message.text)
							rednet.send(sender_id, {success = true}, "wmp")

						else
							rednet.send(sender_id, {success = false, msg = "Invalid Argument: type of message.text cannot be " .. type(message.text) .. "."}, "wmp")
						end

					elseif message.command == "blit" then
						if message.text and message.fg_colours and message.bg_colours then
							if #message.text == #message.fg_colours and #message.text == #message.bg_colours then
								Output.blit(message.text, message.fg_colours, message.bg_colours)
								rednet.send(sender_id, {success = true}, "wmp")

							else
								rednet.send(sender_id, {success = false, msg = "Invalid Argument: Lengths of text, fg_colours, and bg_colours must be equal."}, "wmp")
							end
						end

					elseif message.command == "setTextColour" then
						if type(message.colour) == "number" then
							if message.colour >= 0 and message.colour <= 65535 then
								Output.setTextColour(message.colour)
								rednet.send(sender_id, {success = true}, "wmp")
							else
								rednet.send(sender_id, {success = false, msg = "Invalid Argument: message.colour must be between 0 and 65535."}, "wmp")
							end

						else
							rednet.send(sender_id, {success = false, msg = "Invalid Argument: message.colour cannot be " .. type(message.colour) .. "."}, "wmp")
						end

					elseif message.command == "setBackgroundColour" then
						if type(message.colour) == "number" then
							if message.colour >= 0 and message.colour <= 65535 then
								Output.setBackgroundColour(message.colour)
								rednet.send(sender_id, {success = true}, "wmp")
							else
								rednet.send(sender_id, {success = false, msg = "Invalid Argument: message.colour must be between 0 and 65535."}, "wmp")
							end

						else
							rednet.send(sender_id, {success = false, msg = "Invalid Argument: message.colour cannot be " .. type(message.colour) .. "."}, "wmp")
						end

					elseif message.command == "setCursorBlink" then
						if type(message.blink) == "boolean" then
							Output.setCursorBlink(message.blink)
							rednet.send(sender_id, {success = true}, "wmp")
						else

							rednet.send(sender_id, {success = false, msg = "Invalid Argument: type of message.blink cannot be " .. type(message.blink) .. "."}, "wmp")
						end

					elseif message.command == "getSize" then
						local rows, cols = Output.getSize()
						rednet.send(sender_id, {rows = rows, cols = cols, success = true}, "wmp")

					elseif message.command == "getCursorPos" then
						local x, y = Output.getCursorPos()
						rednet.send(sender_id, {x = x, y = y, success = true}, "wmp")

					elseif message.command == "getTextColour" then
						local colour = Output.getTextColour()
						rednet.send(sender_id, {colour = colour, success = true}, "wmp")

					elseif message.command == "getBackgroundColour" then
						local colour = Output.getBackgroundColour()
						rednet.send(sender_id, {colour = colour, success = true}, "wmp")

					elseif message.command == "getTextScale" then
						local scale = Output.getTextScale()
						rednet.send(sender_id, {scale = scale, success = true}, "wmp")

					elseif message.command == "getCursorBlink" then
						local blink = Output.getCursorBlink()
						rednet.send(sender_id, {blink = blink, success = true}, "wmp")

					elseif message.command == "isColour" then
						local is_colour = Output.isColour()
						rednet.send(sender_id, {is_colour = is_colour, success = true}, "wmp")

					elseif message.command == "scroll" then
						if type(message.lines) == "number" then
							Output.scroll(message.lines)
							rednet.send(sender_id, {success = true}, "wmp")
						else
							rednet.send(sender_id, {success = false, msg = "Invalid Argument: type of message.lines cannot be " .. type(message.lines) .. "."}, "wmp")
						end

					elseif message.command == "isColour" then
						local is_colour = Output.isColour()
						rednet.send(sender_id, {is_colour = is_colour, success = true}, "wmp")

					else
						rednet.send(sender_id, {success = false, msg = "Command Not Found: \"" .. tostring(message.command) .. "\""}, "wmp")
					end
				else
					Output.write(message)
				end
			end
		elseif event == "monitor_touch" then
			--TODO: broadcast touch events
		end
	end
end

MonitorConnector = {}

function MonitorConnector:new(monitor_name, modem_side)
	local obj = {}

	if not monitor_name then
		error("MonitorConnector.new: monitor_name is required.")
	end

	local modem = peripheral.wrap(modem_side or "") or peripheral.find("modem")
	if not modem then
		error("MonitorConnector.new: No modem found.")
	end
	obj.modem_side = peripheral.getName(modem)

	rednet.open(obj.modem_side)
	obj.controller_id = rednet.lookup("wmp", monitor_name)
	if not obj.controller_id then
		error("MonitorConnector.new: No monitor controller found with name '" .. monitor_name .. "'.")
	end
	rednet.close(obj.modem_side)

	local sendCommand = function(body)
		rednet.open(obj.modem_side)
		rednet.send(obj.controller_id, body, "wmp")
		while true do
			local id, message = rednet.receive("wmp", 1)
			if id == obj.controller_id and message and message.success then
				rednet.close(obj.modem_side)
				return message
			elseif id == obj.controller_id and message and not message.success then
				error("MonitorConnector." .. body.command .. ": " .. (message.msg or "Unknown error occurred."))
			elseif not id then
				error("MonitorConnector." .. body.command .. ": timed out.")
			end
		end
	end

	obj.update = function()
		sendCommand({command = "update"})
	end

	obj.write = function(text)
		sendCommand({command = "write", text = text})
	end

	obj.clear = function()
		sendCommand({command = "clear"})
	end

	obj.clearLine = function()
		sendCommand({command = "clearLine"})
	end

	obj.setCursorPos = function(x, y)
		sendCommand({command = "setCursorPos", x = x, y = y})
	end

	obj.getCursorPos = function()
		local response = sendCommand({command = "getCursorPos"})
		return response.x, response.y
	end

	obj.blit = function(text, fg_colours, bg_colours)
		sendCommand({
			command = "blit",
			text = text,
			fg_colours = fg_colours,
			bg_colours = bg_colours
		})
	end

	obj.setTextColour = function(colour)
		sendCommand({command = "setTextColour", colour = colour})
	end
	obj.setTextColor = obj.setTextColour -- Alias for compatibility

	obj.setBackgroundColour = function(colour)
		sendCommand({command = "setBackgroundColour", colour = colour})
	end
	obj.setBackgroundColor = obj.setTextColour -- Alias for compatibility

	obj.setTextScale = function(scale)
		sendCommand({command = "setTextScale", scale = scale})
	end

	obj.getTextColour = function()
		local response = sendCommand({command = "getTextColour"})
		return response.colour
	end
	obj.getTextColor = obj.getTextColour -- Alias for compatibility

	obj.getBackgroundColour = function()
		local response = sendCommand({command = "getBackgroundColour"})
		return response.colour
	end
	obj.getBackgroundColor = obj.getTextColour -- Alias for compatibility

	obj.getTextScale = function()
		local response = sendCommand({command = "getTextScale"})
		return response.scale
	end

	obj.getSize = function()
		local response = sendCommand({command = "getSize"})
		return response.rows, response.cols
	end

	obj.getCursorBlink = function()
		local response = sendCommand({command = "getCursorBlink"})
		return response.blink
	end

	obj.setCursorBlink = function(blink)
		sendCommand({command = "setCursorBlink", blink = blink})
	end

	obj.isColour = function()
		local response = sendCommand({command = "isColour"})
		return response.is_colour
	end
	obj.isColor = obj.isColour -- Alias for compatibility

	obj.scroll = function(lines)
		sendCommand({command = "scroll", lines = lines})
	end

	setmetatable(obj, {
		__name = "peripheral",
		name = "RemoteMonitor:" .. monitor_name,
		types = {"monitor", "RemoteMonitor"}
	})

	return obj
end

return {
	runRemoteMonitor = function(monitor_name, modem_side)
		local controller = MonitorController:new(monitor_name)
		controller:run(modem_side)
	end,
	connectRemoteMonitor = function(monitor_name, modem_side)
		return MonitorConnector:new(monitor_name, modem_side)
	end
}