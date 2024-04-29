rcToolChange = {}
--[[
NOTES
1. All functions are responsible for getting themselves into a safe g53 position AT THE BEGINNING!
2. rcToolChange.LoadTool() is responsible for raising spindle at it's end
]]
local inst, tcContinue, rc, tData, pData

inst = mc.mcGetInstance( "rcToolChange" )
tcContinue = mc.MC_FALSE

local function ReadIni()
	
end
ReadIni()


function rcToolChange.LoadTool()
	
	if tcContinue ~= mc.MC_TRUE then return end
	
	local tool, response
		
	tool, rcDebug.rc = mc.mcToolGetSelected( inst )
		
	if tool == 0 then -- tool zero
		--LoadTool() is repsponsible for getting to safe z
		rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
			.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) )
		 )
		return
		
	end
	
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
		response = rcCommon.ShowMessage( TYPE_MESSAGEBOX, LEVEL_USER_INPUT, string.format( "Is tool loaded from pocket %i in magazine %i?", pData.pIndex, pData.mIndex ) )
		
	end
	
	if response == wx.wxCANCEL then
		--assuming that the tool did not load and we have a bare spindle
		rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
			.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) ) -- rapid to desired z
		 )
		-- terminate with e-stop
		response = rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_ESTOP, "Tool load aborted due to user cancellation!" )	
		tcContinue = mc.mc_FALSE
		return
		
	end
	-- we have a tool loaded
	rcDebug.rc = mc.mcToolSetCurrent( inst, tool )
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( pData.p.x + pData.lOffset.x ), y( pData.p.y + pData.lOffset.y ) ) -- rapid to safe xy position
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) ) -- rapid to desired z
	 )
		
end

function rcToolChange.UnloadTool()
	
	if tcContinue ~= mc.MC_TRUE then return end
	
	local tool, response
	
	tool, rcDebug.rc = mc.mcToolGetCurrent( inst )
	if tool == 0 then return end -- do nothing for tool zero
	
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
		response = rcCommon.ShowMessage( TYPE_MESSAGEBOX, LEVEL_USER_INPUT, string.format( "Is tool unloaded to pocket %i in magazine %i?", pData.pIndex, pData.mIndex ) )
	
	end
	
	if response == wx.wxCANCEL then
		-- terminate with e-stop
		response = rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_ESTOP, "Tool unload aborted due to user cancellation!" )
		tcContinue = mc.mc_FALSE
		return
		
	end
	-- set tool to 0 for bare spindle
	rcDebug.rc = mc.mcToolSetCurrent( inst, 0 )														
	
end

function rcToolChange.PreToolChange()
	
	local mach4Enabled, machineHomed
	
	tcContinue = mc.MC_TRUE
	-- is selected tool same as current tool?
	if ( mc.mcToolGetSelected( inst ) == mc.mcToolGetCurrent( inst ) ) then
			rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_INFORMATION, "M6: Selected tool = Current tool. No change required." )
			tcContinue = mc.MC_FALSE
		return
	end
	-- is Mach4 enabled?
	mach4Enabled = rcCommon.GetMachEnabled()
	if mach4Enabled ~= mc.MC_TRUE then
		rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_INFORMATION, "M6: Mach4 not enabled! Toolchange operation aborted." )
		tcContinue = mc.MC_FALSE
		return
	end
	-- is machine homed?
	machineHomed  = rcCommon.GetAxesHomed()
	if machineHomed ~= mc.MC_TRUE then
		rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_INFORMATION, "M6: Machine not homed! Toolchange operation aborted." )
		tcContinue = mc.MC_FALSE
		return
	end
	
	-- record state
	rcDebug.rc = mc.mcCntlMachineStatePush( inst )
	
	--[[TODO:
		- record and save flood coolant signal status
		- record and save mist coolant signal status
		- record and save dust collection signal status
	]]
	m111() -- dust collector stop
	m114() -- dust cover open
	
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( SPIN_STOP )		-- stop spindle
		.. rcGCode.Line( COOLANT_STOP )	-- stop coolant
		.. rcGCode.Line( DISABLE_OVERRIDES )	-- disable feed/speed rate overrides
		.. rcGCode.Line( SAFE_START )	-- set safe gCode
	)
	
end

function rcToolChange.PostToolChange()
	
	if tcContinue ~= mc.MC_TRUE then return end
	
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( ENABLE_OVERRIDES )	-- enable feed/speed rate overrides
	 ) 
	
	m115() -- dust cover close
	m110() -- dust collector start
	
	--[[TODO:
		- restore flood coolant to previous signal status
		- restore mist coolant to previous signal status
		- restore dust collection to previous signal status
	]]	
	
	-- restore state
	rcDebug.rc = mc.mcCntlMachineStatePop( inst )
	-- set current tool to selected
	rcDebug.rc = mc.mcToolSetCurrent( inst, mc.mcToolGetSelected( inst ) ) 
	
	rcCommon.ShowMessage( TYPE_LAST_ERROR, LEVEL_INFORMATION, "M6: Toolchange complete." )
	
end

function rcToolChange.GetContinue()
	
	return tcContinue

end

return rcToolChange
