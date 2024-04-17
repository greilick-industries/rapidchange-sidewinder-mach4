local inst = mc.mcGetInstance("rcCommon")

local rc = mc.MERROR_NOERROR

local rcCommon = {}

	rcCommon.TYPE_MESSAGEBOX = 1
	rcCommon.TYPE_LAST_ERROR = 2
	
	rcCommon.LEVEL_INFORMATION = 1
	rcCommon.LEVEL_USER_INPUT = 2
	rcCommon.LEVEL_ESTOP = 3
	
	function rcCommon.GetMachIsHomed()
		
		local homed = mc.MC_FALSE
		local axisEnabled, axisHomed, rc
		
		for i = 0, mc.MC_MAX_AXES, 1 do 
			
			axisEnabled, rc = mc.mcAxisIsEnabled(inst, i)
			if axisEnabled and rc == mc.MERROR_NOERROR then
			
				axisHomed, rc = mc.mcAxisIsHomed(inst, i)
				if not axisHomed  or rc ~= mc.MERROR_NOERROR then
					do return homed, rc end
				end
			
			end
			
		end
		
		homed = mc.MC_TRUE
		rc = mc.MERROR_NOERROR
		return homed, rc
	end
	
	function rcCommon.ShowMessage(messageType, messageLevel, message)
		
		rc = mc.MERROR_NOERROR
		
		messageTypes = {
			[rcCommon.TYPE_MESSAGEBOX] = function ( messageLevel, message )
					return messageBoxLevels[ messageLevel ] ( message )
				end,
			[rcCommon.TYPE_LAST_ERROR] = function ( messageLevel, message )
				return messageLastErrorLevels[ messageLevel ] ( message )
			end
		}
	
		messageBoxLevels = {
			[rcCommon.LEVEL_INFORMATION] = function ( message )
				local ok = wx.wxMessageBox(message, "Information", wx.wxOK + wx.wxICON_INFORMATION)
				return ok,  rc
			end, 
			[rcCommon.LEVEL_USER_INPUT] = function ( message )
				local yesNoCancel = wx.wxMessageBox(message, "Ïnput Required", wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION)
				return yesNoCancel, rc
			end,
			[rcCommon.LEVEL_ESTOP] = function ( message )
				rc = mc.mcCntlEStop(inst)
				local ok = wx.wxMessageBox(message, "Emergency!", wx.wxOK + wx.wxICON_STOP)
				return ok, rc
			end
			--wxMessageBox Return Values
			--wx.wxYES = 2
			--wx.wxOK = 4
			--wx.wxNO = 8
			--wx.wxCANCEL = 16
		}

		messageLastErrorLevels = {
			[rcCommon.LEVEL_INFORMATION] = function ( message )
				rc = mc.mcCntlSetLastError(inst, message)
				return wx.wxOK, rc
			end, 
			[rcCommon.LEVEL_USER_INPUT] = function ( message )
				local yesNoCancel = wx.wxMessageBox(message, "Ïnput Required", wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_QUESTION)
				return yesNoCancel, rc
			end,
			[rcCommon.LEVEL_ESTOP] = function ( message )
				rc = mc.mcCntlEStop(inst)
				if rc ~= mc.MERROR_NOERROR then
					-- do error handling
					do return rc end
				end
				rc = mc.mcCntlSetLastError(inst, message)
				return wx.wxOK, rc
			end
		}
		
		return messageTypes[ messageType ] ( messageLevel, message )

	end

return rcCommon, rc
