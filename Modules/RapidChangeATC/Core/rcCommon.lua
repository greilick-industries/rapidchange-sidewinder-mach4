rcCommon = {}

local inst

inst = mc.mcGetInstance("rcCommon")

function rcCommon.GetAxesHomed(axes)
	
	local enabled, homed
	axes = axes or {mc.X_AXIS, mc.Y_AXIS, mc.Z_AXIS}
	homed = mc.MC_TRUE
	for i,v in ipairs(axes) do
		enabled, rcDebug.rc = mc.mcAxisIsEnabled(inst, v)
		if enabled == mc.MC_TRUE then
			homed, rcDebug.rc = mc.mcAxisIsHomed(inst, v)
			if homed == mc.MC_FALSE then break end
		end
	end
	if homed ~= mc.MC_TRUE then
		rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_INFORMATION, "RapidChangeATC: Not all axes enabled! Operation aborted." )
	end
	return homed
	
end

function rcCommon.GetMachEnabled()
	
	local enabled, hSig
	
	hSig, rcDebug.rc = mc.mcSignalGetHandle(inst, mc.OSIG_MACHINE_ENABLED)
	enabled, rcDebug.rc = mc.mcSignalGetState(hSig)
	if enabled ~= mc.MC_TRUE then
		rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_INFORMATION, "RapidChangeATC: Mach4 not enabled! Operation aborted." )
	end
	return enabled
	
end

function rcCommon.GetHomedEnabled()
	
	return rcCommon.GetMachEnabled() and rcCommon.GetAxesHomed()
	
end

function rcCommon.ShowMessage(messageType, messageLevel, message)
	
	local messageTypes, messageBoxLevels, messageLastErrorLevels
	
	messageTypes = {
		[TYPE_MESSAGEBOX] = function ( messageLevel, message )
				return messageBoxLevels[ messageLevel ] ( message )
			end,
		[TYPE_LAST_ERROR] = function ( messageLevel, message )
			return messageLastErrorLevels[ messageLevel ] ( message )
		end,
		[TYPE_LOG] = function ( messageLevel, message )
			return messageLogLevels[ messageLevel ] ( message )
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
			mc.mcCntlEnable( inst, 0 )
			local ok = wx.wxMessageBox(message, "Stop!", wx.wxOK + wx.wxICON_STOP)
			return ok
		end,
		[LEVEL_ESTOP] = function ( message )
			rcDebug.rc = mc.mcCntlEStop(inst)
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
			rcDebug.rc = mc.mcCntlSetLastError(inst, message)
			return wx.wxOK
		end, 
		[LEVEL_USER_INPUT] = function ( message )
			local yesNoCancel = wx.wxMessageBox(message, "Ïnput Required", wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION)
			return yesNoCancel
		end,
		[LEVEL_STOP] = function ( message )
			mc.mcCntlEnable( inst, 0 )
			rcDebug.rc = mc.mcCntlSetLastError(inst, message)
			return wx.wxOK
		end,
		[LEVEL_ESTOP] = function ( message )
			rcDebug.rc = mc.mcCntlEStop(inst)
			rcDebug.rc = mc.mcCntlSetLastError(inst, message)
			return wx.wxOK
		end
	}
	
	messageLogLevels = {
		[LEVEL_INFORMATION] = function ( message )
			mc.mcCntlLog(inst, message, "RapidChangeATC", 0)
			return wx.wxOK
		end, 
		[LEVEL_USER_INPUT] = function ( message )
			local yesNoCancel = wx.wxMessageBox(message, "Ïnput Required", wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION)
			mc.mcCntlLog(inst, message, "RapidChangeATC", 0)
			return yesNoCancel
		end,
		[LEVEL_STOP] = function ( message )
			mc.mcCntlEnable( inst, 0 )
			mc.mcCntlLog( inst, message, "RapidChangeATC", 0 )
			return wx.wxOK
		end,
		[LEVEL_ESTOP] = function ( message )
			rcDebug.rc = mc.mcCntlEStop(inst)
			rcDebug.rc = mc.mcCntlSetLastError(inst, message)
			return wx.wxOK
		end
	}
	
	return messageTypes[ messageType ] ( messageLevel, message )

end

return rcCommon
