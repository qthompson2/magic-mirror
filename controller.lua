Output = require("bin.cc-output")

MonitorController = {}

function MonitorController:new(identifier, monitor_name)
	local obj = {}

	obj.identifier = identifier or error("MonitorController.new: identifier cannot be nil.")

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
	rednet.host("wmp", self.identifier)

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

return MonitorController