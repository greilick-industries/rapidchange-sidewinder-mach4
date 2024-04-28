rcCommon = {}

TYPE_MESSAGEBOX = 1
TYPE_LAST_ERROR = 2
LEVEL_INFORMATION = 1
LEVEL_USER_INPUT = 2
LEVEL_STOP = 3
LEVEL_ESTOP = 4

local inst

inst = mc.mcGetInstance("rcCommon")

function rcCommon.GetAxesHomed(axes)
	
	local enabled, homed, rc
	
	axes = axes or {mc.X_AXIS, mc.Y_AXIS, mc.Z_AXIS}
	homed = mc.MC_TRUE
	
	for i,v in ipairs(axes) do
		
		enabled, rc = mc.mcAxisIsEnabled(inst, v)
		
		if enabled == mc.MC_TRUE then
			
			homed, rc = mc.mcAxisIsHomed(inst, v)
			if homed == mc.MC_FALSE then break end
		
		end
	
	end

	return homed
	
end

function rcCommon.GetMachEnabled()
	
	local enabled, hSig, rc
	
	hSig, rc = mc.mcSignalGetHandle(inst, mc.OSIG_MACHINE_ENABLED)
	enabled, rc = mc.mcSignalGetState(hSig)

	return enabled
	
end

function rcCommon.ShowMessage(messageType, messageLevel, message)
	
	local rc, messageTypes, messageBoxLevels, messageLastErrorLevels
	
	messageTypes = {
		[TYPE_MESSAGEBOX] = function ( messageLevel, message )
				return messageBoxLevels[ messageLevel ] ( message )
			end,
		[TYPE_LAST_ERROR] = function ( messageLevel, message )
			return messageLastErrorLevels[ messageLevel ] ( message )
		end
	}

	messageBoxLevels = {
		[LEVEL_INFORMATION] = function ( message )
			local ok = wx.wxMessageBox(message, "Information", wx.wxOK + wx.wxICON_INFORMATION)
			return ok
		end, 
		[LEVEL_USER_INPUT] = function ( message )
			local yesNoCancel = wx.wxMessageBox(message, "Ïnput Required", wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION)
			return yesNoCancel
		end,
		[LEVEL_STOP] = function ( message )
			local ok = wx.wxMessageBox(message, "Stop!", wx.wxOK + wx.wxICON_STOP)
			return ok
		end,
		[LEVEL_ESTOP] = function ( message )
			rc = mc.mcCntlEStop(inst)
			local ok = wx.wxMessageBox(message, "Emergency!", wx.wxOK + wx.wxICON_STOP)
			return ok
		end
		--wxMessageBox Return Values
		--wx.wxYES = 2
		--wx.wxOK = 4
		--wx.wxNO = 8
		--wx.wxCANCEL = 16
	}

	messageLastErrorLevels = {
		[LEVEL_INFORMATION] = function ( message )
			rc = mc.mcCntlSetLastError(inst, message)
			return wx.wxOK
		end, 
		[LEVEL_USER_INPUT] = function ( message )
			local yesNoCancel = wx.wxMessageBox(message, "Ïnput Required", wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION)
			return yesNoCancel
		end,
		[LEVEL_STOP] = function ( message )
			rc = mc.mcCntlSetLastError(inst, message)
			return wx.wxOK
		end,
		[LEVEL_ESTOP] = function ( message )
			rc = mc.mcCntlEStop(inst)
			rc = mc.mcCntlSetLastError(inst, message)
			return wx.wxOK
		end
	}
	
	return messageTypes[ messageType ] ( messageLevel, message )

end

return rcCommon
