rcToolChange = {}

local inst, tcContinue, tData, pData

inst = mc.mcGetInstance( "rcToolChange" )
tcContinue = mc.MC_FALSE

local function ReadIni()
	
end
ReadIni()

local function Confirm( state )
	
	local response, states, levels	
	response = wx.wxNO
	levels = {
		[CONFIRM_DISABLE] = function( state ) response = wx.wxYES end,
		[CONFIRM_MANUAL] = function( state )
			states = {
				[UNLOAD] = function()
					return string.format( "Manual toolchange:\nTool: %i Desc: %s\nIs tool unloaded?",
						tData.tIndex, tData.desc )
				end,
				[LOAD] = function()
					return string.format( "Manual toolchange:\nTool: %i\nDesc: %s\nIs tool loaded?",
						tData.tIndex, tData.desc )
				end,
			}			
			return rcCommon.ShowMessage( TYPE_MESSAGEBOX, LEVEL_USER_INPUT, states[ state ]() )
		end,
		[CONFIRM_USER] = function( state )
			states = {
				[UNLOAD] = function()
					return string.format( "Is tool unloaded from pocket %i in magazine %i?", pData.pIndex, pData.mIndex )
				end,
				[LOAD] = function()
					return string.format( "Is tool loaded to pocket %i in magazine %i?", pData.pIndex, pData.mIndex )
				end,
			}
			return rcCommon.ShowMessage( TYPE_MESSAGEBOX, LEVEL_USER_INPUT, states[ state ]() )
		end,
	}
	response = levels[ pData.mConf ]( state )
	
end

function rcToolChange.LoadTool()	
	
	if tcContinue ~= mc.MC_TRUE then return end	
	tcContinue = mc.MC_FALSE
	local tool, response		
	tool, rcDebug.rc = mc.mcToolGetSelected( inst )
	if tool == 0 then -- tool zero
		--LoadTool() is repsponsible for getting to safe z
		rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
			.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) )
		 )
		tcContinue = mc.MC_TRUE 
		return
	end
	--ensure latest data
	ReadIni()
	tData =  rcTool.GetData( tool )
	pData = rcPocket.GetData( tool )
	--  we have a bare spindle
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) ) -- rapid to desired z		
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( pData.p.x ), y( pData.p.y ) )	-- rapid to pocket xy position
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( pData.p.z + pData.lOffset.z ) ) -- rapid to spindle start position
	 )
	--load tool, loop if necessary
	response = wx.wxNO
	while response == wx.wxNO do
		if ( pData.spindle.loadRPM > 0 ) then
			-- start spindle and dwell
			local gCode = "" .. rcGCode.Line( SPIN_CW, s( pData.spindle.loadRPM ) )								
			gCode = gCode .. rcGCode.Line( DWELL, p( pData.spindle.dwell ) )
			-- plunge and retract thrice
			for _ = 1, 2 do
				gCode = gCode .. rcGCode.Line( INCREMENTAL_POSITION_MODE )															
				gCode = gCode .. rcGCode.Line( LINEAR_FEED_MOVE, f( pData.spindle.zFeedRate ), z( -pData.lOffset.z ) )
				gCode = gCode .. rcGCode.Line( LINEAR_FEED_MOVE, f( pData.spindle.zFeedRate ), z( pData.lOffset.z ) )
				gCode = gCode .. rcGCode.Line( ABSOLUTE_POSITION_MODE )																
			end
			-- stop spindle
			gCode = gCode .. rcGCode.Line( SPIN_STOP )
			rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
		end
		-- confirm tool loaded
		response = Confirm( LOAD )		
	end
	if response == wx.wxCANCEL then
		--assuming that the tool did not load and we have a bare spindle
		rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
			.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) ) -- rapid to desired z
		 )
		-- terminate with e-stop
		response = rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_ESTOP, "Tool load aborted!" )	
		return
	end
	-- we have a tool loaded
	rcDebug.rc = mc.mcToolSetCurrent( inst, tool )
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( pData.p.x + pData.lOffset.x ), y( pData.p.y + pData.lOffset.y ) ) -- rapid to safe xy position
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) ) -- rapid to desired z
	 )
	tcContinue = mc.MC_TRUE
	
end

function rcToolChange.UnloadTool()
	
	if tcContinue ~= mc.MC_TRUE then return end
	tcContinue = mc.MC_FALSE
	local tool, response
	tool, rcDebug.rc = mc.mcToolGetCurrent( inst )
	if tool == 0 then 
		-- do nothing for tool zero
		tcContinue = mc.MC_TRUE
		return 
	end 
	-- ensure latest data
	ReadIni()
	tData = rcTool.GetData( tool )
	pData = rcPocket.GetData( tool )
	--we have a tool onboard
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) ) -- rapid to desired z
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( pData.p.x + pData.lOffset.x ), y( pData.p.y + pData.lOffset.y ) ) -- rapid to safe xy position 
		-- rapid to spindle start position
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( pData.p.z + pData.lOffset.z ) )
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( pData.p.x ), y( pData.p.y ) )
	 )
	-- unload tool and confirm, loop if necessary
	response = wx.wxNO
	while response == wx.wxNO  do
		if ( pData.spindle.unloadRPM > 0 ) then
			rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
				-- start spindle in reverse and dwell
				.. rcGCode.Line( SPIN_CCW, s( pData.spindle.unloadRPM ) )								
				.. rcGCode.Line( DWELL, p( pData.spindle.dwell ) )
				-- plunge and retract
				.. rcGCode.Line( INCREMENTAL_POSITION_MODE )
				.. rcGCode.Line( LINEAR_FEED_MOVE, f( pData.spindle.zFeedRate ), z( -pData.lOffset.z ) )
				.. rcGCode.Line( LINEAR_FEED_MOVE, f( pData.spindle.zFeedRate ), z( pData.lOffset.z ) )
				.. rcGCode.Line( ABSOLUTE_POSITION_MODE )
				.. rcGCode.Line( SPIN_STOP )	-- stop spindle							
			)
		end
		-- confirm tool unloaded, loop if necessary
		response = Confirm( UNLOAD )	
	end
	if response == wx.wxCANCEL then
		-- terminate with e-stop
		response = rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_ESTOP, "Tool unload aborted!" )
		return
	end
	-- set tool to 0 for bare spindle
	rcDebug.rc = mc.mcToolSetCurrent( inst, 0 )		
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( CUTTER_COMPENSATION_CANCEL )
	)
	tcContinue = mc.MC_TRUE
	
end

function rcToolChange.PreToolChange()
	
	tcContinue = mc.MC_FALSE
	-- is selected tool same as current tool?
	if mc.mcToolGetSelected( inst ) == mc.mcToolGetCurrent( inst ) then
		rcCommon.ShowMessage( TYPE_LOG, LEVEL_INFORMATION, "M6: Selected tool = Current tool. No change required." )
		return
	end
	-- is machine homed and enabled?
	if rcCommon.GetHomedEnabled() ~= mc.MC_TRUE then return end
	-- record state
	--rcDebug.rc = mc.mcCntlMachineStatePush( inst )
	m114() -- dust cover open
	rcGCode.StartState()
	tcContinue = mc.MC_TRUE
	
end

function rcToolChange.PostToolChange()
	
	if tcContinue ~= mc.MC_TRUE then
		rcCommon.ShowMessage( TYPE_LOG, LEVEL_INFORMATION, string.format("rcToolChange: %s.", "operation aborted" ) )
		-- restore state
		--rcDebug.rc = mc.mcCntlMachineStatePop( inst )
		return
	else
		rcCommon.ShowMessage( TYPE_LOG, LEVEL_INFORMATION, string.format( "rcToolChange: %s.", "operation complete" ) )
		rcGCode.EndState()
		-- restore state
		--rcDebug.rc = mc.mcCntlMachineStatePop( inst )
		-- set current tool to selected
		rcDebug.rc = mc.mcToolSetCurrent( inst, mc.mcToolGetSelected( inst ) ) 
		rcCommon.ShowMessage( TYPE_LOG, LEVEL_INFORMATION, "M6: Toolchange complete." )
		m1005() -- tool length
		m115() -- dust cover close
		tcContinue = mc.MC_FALSE
	end
	
end

function rcToolChange.GetContinue()
	
	return tcContinue

end

return rcToolChange
