--[[
NOTES
1. All functions are responsible for getting themselves into a safe g53 position AT THE BEGINNING!
2. rcToolChange.LoadTool( ) is responsible for raising spindle at it's end
]]

local inst = mc.mcGetInstance( "rcToolChange" )

local rcToolChange, rcDebug, rcCommon, rcGCode, rcTool, rcPocket, gCode, rc

rcToolChange = {}
rcDebug = require "rcDebug"
rcCommon = require "rcCommon"
rcGCode = require "rcGCode"
rcTool = require "rcTool"
rcPocket = require "rcPocket"

function rcToolChange.LoadTool( )
	
	local t, tData, pData, response
	rc = mc.MERROR_NOERROR
	
	t, rc = mc.mcToolGetSelected( inst )
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end
	
	if t == 0 then -- tool zero
		gCode = rcGCode.Clear( )
		gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.GetZSafeClearance( ) )
		rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
	end
		do return rc end
	end

	tData, rc =  rcTool.GetData( t )
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end
	
	pData, rc =  rcPocket.GetData( t )
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end
	
	gCode = rcGCode.Clear( )
	-- rapid to desired z, we have a bare spindle
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.GetZSafeClearance( ) )		
	-- rapid to pocket xy position
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.x( pData.p.x ), rcGCode.y( pData.p.y ) )	
	-- rapid to spindle start position, we have a bare spindle
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.z( pData.p.z + pData.lOffset.z ) )	
	rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
	end
	
	--load tool, loop if necessary
	response = wx.wxNO
	while response == wx.wxNO and rc == mc.MERROR_NOERROR do
		
		if (pData.spindle.loadRPM > 0) then
			gCode = rcGCode.Clear( )
			-- start spindle and dwell
			gCode = rcGCode.AddLine( rcGCode.Commands.SPIN_CW, rcGCode.s( pData.spindle.loadRPM ) )								
			gCode = rcGCode.AddLine( rcGCode.Commands.DWELL, rcGCode.p( pData.spindle.dwell ) )
			-- plunge and retract thrice
			for _ = 1,3 do
				gCode = rcGCode.AddLine( rcGCode.Commands.INCREMENTAL_POSITION_MODE)															
				gCode = rcGCode.AddLine( rcGCode.Commands.LINEAR_FEED_MOVE, rcGCode.f( pData.spindle.zFeedRate ), rcGCode.z( -pData.lOffset.z ) )
				gCode = rcGCode.AddLine( rcGCode.Commands.LINEAR_FEED_MOVE, rcGCode.f( pData.spindle.zFeedRate ), rcGCode.z( pData.lOffset.z ) )
				gCode = rcGCode.AddLine( rcGCode.Commands.ABSOLUTE_POSITION_MODE)																
			end
			-- stop spindle
			gCode = rcGCode.AddLine( rcGCode.Commands.SPIN_STOP )
			rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
			if ( rc ~= mc.MERROR_NOERROR ) then
				rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
				do return rc end
			end
		end
		-- confirm tool loaded
		response, rc = rcCommon.ShowMessage( rcCommon.TYPE_MESSAGEBOX, rcCommon.LEVEL_USER_INPUT, string.format( "Is tool loaded from pocket %i in magazine %i?", pData.pIndex, pData.mIndex ) )
		
	end
	
	if rc ~= mc.MERROR_NOERROR then
		--assuming that the tool did not load and we have a bare spindle
		gCode = rcGCode.Clear( )
		-- rapid to desired z
		gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.GetZSafeClearance( ) )	
		rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
		if ( rc ~= mc.MERROR_NOERROR ) then
			rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
			do return rc end
		end
		-- terminate with e-stop
		response, rc = rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_ESTOP, "Tool load aborted due to Mach4 error!")						
		do return rc end
		
	end
	if response == wx.wxCANCEL then
		--assuming that the tool did not load and we have a bare spindle
		gCode = rcGCode.Clear( )
		-- rapid to desired z
		gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.GetZSafeClearance( ) )
		rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
		if ( rc ~= mc.MERROR_NOERROR ) then
			rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
		end
		-- terminate with e-stop
		response, rc = rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_ESTOP, "Tool load aborted due to user cancellation!")						
		do return rc end
	end
	-- we have a tool loaded
	rc = mc.mcToolSetCurrent( inst, t )
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end
	
	gCode = rcGCode.Clear( )
	-- rapid to safe xy position, we have a tool onboard
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, 
		rcGCode.x( pData.p.x + pData.lOffset.x ), 
		rcGCode.y( pData.p.y + pData.lOffset.y ) )
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.x( pData.p.x + pData.lOffset.x ), rcGCode.y( pData.p.y + pData.lOffset.y ) )-- rapid to safe xy position, we have a tool onboard
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.GetZSafeClearance( ) )							-- rapid to desired z
	rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
	end
	return rc
	
end

function rcToolChange.UnloadTool( )
	
	local t, tData, pData, response
	rc = mc.MERROR_NOERROR
	
	t, rc = mc.mcToolGetCurrent( inst )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcToolGetCurrent( inst ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
	end
	if t == 0 then return rc end -- do nothing for tool zero
	
	tData, rc =  rcTool.GetData( t )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: rcTool.GetData( t ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
	end
	
	pData, rc =  rcPocket.GetData( t )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: rcPocket.GetData( t ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
	end
	
	gCode = rcGCode.Clear( )
	-- rapid to desired z
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.GetZSafeClearance( ) )
	-- rapid to safe xy position, we have a tool onboard
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.x( pData.p.x + pData.lOffset.x ), rcGCode.y( pData.p.y + pData.lOffset.y ) )
	-- rapid to spindle start position
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.z( pData.p.z + pData.lOffset.z ) )
	gCode = rcGCode.AddLine( rcGCode.Commands.MACH_OFFSET, rcGCode.Commands.RAPID_MOVE, rcGCode.x( pData.p.x ), rcGCode.y( pData.p.y ) )
	rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
	end
	
	-- unload tool and confirm, loop if necessary
	response = wx.wxNO
	while response == wx.wxNO and rc == mc.MERROR_NOERROR do
		
		if ( pData.spindle.unloadRPM > 0 ) then
		-- plunge and retract
			gCode = rcGCode.Clear( )
			-- start spindle in reverse and dwell
			gCode = rcGCode.AddLine( rcGCode.Commands.SPIN_CCW, rcGCode.s( pData.spindle.unloadRPM ) )								
			gCode = rcGCode.AddLine( rcGCode.Commands.DWELL, rcGCode.p( pData.spindle.dwell ) )
			gCode = rcGCode.AddLine( rcGCode.Commands.INCREMENTAL_POSITION_MODE)
			gCode = rcGCode.AddLine( rcGCode.Commands.LINEAR_FEED_MOVE, rcGCode.f( pData.spindle.zFeedRate ), rcGCode.z( -pData.lOffset.z ) )
			gCode = rcGCode.AddLine( rcGCode.Commands.LINEAR_FEED_MOVE, rcGCode.f( pData.spindle.zFeedRate ), rcGCode.z( pData.lOffset.z ) )
			gCode = rcGCode.AddLine( rcGCode.Commands.ABSOLUTE_POSITION_MODE)
			-- stop spindle
			gCode = rcGCode.AddLine( rcGCode.Commands.SPIN_STOP )																				
			rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
			if ( rc ~= mc.MERROR_NOERROR ) then
				rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
				do return rc end
			end
		end
		-- confirm tool unloaded, loop if necessary
		response, rc = rcCommon.ShowMessage( rcCommon.TYPE_MESSAGEBOX, rcCommon.LEVEL_USER_INPUT, string.format( "Is tool unloaded to pocket %i in magazine %i?", pData.pIndex, pData.mIndex ) )
	end
	
	if rc ~= mc.MERROR_NOERROR then
		response, rc = rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_ESTOP, "Tool unload aborted due to Mach4 error!")						-- terminate with e-stop
		do return rc end
	end
	
	if response == wx.wxCANCEL then
		response, rc = rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_ESTOP, "Tool unload aborted due to user cancellation!")						-- terminate with e-stop
		do return rc end
	end
	-- we have a bare spindle
	-- set tool to 0 for bare spindle
	local rc = mc.mcToolSetCurrent(inst, 0)														
	return rc
	
end

function rcToolChange.PreToolChange( )

	rc = mc.MERROR_NOERROR
	
	-- is selected tool same as current tool? HANDLED EXTERNALLY BY m6()
	
	-- is machine homed?
	local machineHomed , rc = rcCommon.GetMachIsHomed()
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end
	if not machineHomed then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_ESTOP, "Machine not homed!" )
		do return rc end
	end
	
	-- record state
	rc = mc.mcCntlMachineStatePush( inst )
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end

	-- record feed rate override
	-- record spindle rate override
	
	-- disable feedrate override
	-- disable spindle rate override

	gCode = rcGCode.Clear( )
	gCode = rcGCode.AddLine( rcGCode.Commands.SPIN_STOP )		-- stop spindle
	gCode = rcGCode.AddLine( rcGCode.Commands.COOLANT_STOP )	-- stop coolant
	gCode = rcGCode.AddLine( rcGCode.Commands.DUST_HOOD_UP )	-- raise dust hood / remove dust foot
	gCode = rcGCode.AddLine( rcGCode.Commands.SAFE_START )		-- set safe gCode
	
	rc = mc.mcCntlGcodeExecuteWait( inst, gCode )
	if ( rc ~= mc.MERROR_NOERROR ) then
		rcCommon.ShowMessage( rcCommon.TYPE_LAST_ERROR, rcCommon.LEVEL_INFORMATION, string.format("Error: mc.mcCntlGcodeExecuteWait( ) - %i: %s", rc, rcDebug.ErrorCodes[ rc ] ) )
		do return rc end
	end

	return rc
	
end

function rcToolChange.PostToolChange( )
	
	rc = mc.MERROR_NOERROR
	
	-- restore state
	rc = mc.mcCntlMachineStatePop( inst )
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end
	
	-- set current tool to selected
	rc = mc.mcToolSetCurrent( inst, mc.mcToolGetSelected( inst ) ) 
	if ( rc ~= mc.MERROR_NOERROR ) then
		-- do error handling
		do return rc end
	end
	
	return rc
	
end

return rcToolChange
