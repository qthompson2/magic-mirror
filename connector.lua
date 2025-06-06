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

return MonitorConnector