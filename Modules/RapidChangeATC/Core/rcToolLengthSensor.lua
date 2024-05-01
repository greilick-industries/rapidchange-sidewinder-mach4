rcToolLengthSensor = {}

local inst, tsContinue, data, tData, PROBE_CODE

inst = mc.mcGetInstance( "rcToolLengthSensor" )
tsContinue = mc.MC_FALSE

--[[
local function SaveIni()
	mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "probeCode", probeCode)
	mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "diameter", diameter)
	mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "position.x", position.x)
	mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "position.y", position.y)
	mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "position.z", position.z)
	mc.mcProfileWriteInt(inst, "RCToolLengthSensor", "feedRate.fast", feedRate.fast)
	mc.mcProfileWriteInt(inst, "RCToolLengthSensor", "feedRate.slow", feedRate.slow)
	mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "retract", retract)
	mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "overshoot", overShoot)
	mc.mcProfileWriteInt(inst, "RCToolLengthSensor", "arcOrientation", arcOrientation)
end
]]
local function ReadIni()
	
	probeCode = mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "probeCode", 31.0)
	diameter = math.abs(mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "diameter", 20.0))
	position = {
		--G53 positions
		x= mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "position.x", 0.0),
		y = mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "position.y", 0.0),
		z = mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "position.z", 0.0),
	}
	feedRate = {
		fast = math.abs(mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "feedRate.fast", 0)),
		slow = math.abs(mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "feedRate.slow", 0)),
	}
	retract = math.abs(mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "retract", 15.0))
	overShoot  = math.abs(mc.mcProfileGetDouble(inst, "RCToolLengthSensor", "overShoot", 2.0))
	arcOrientation = mc.mcProfileGetInt(inst, "RCToolLengthSensor", "arcOrientation", 1)
	PROBE_CODE = string.format( "G%.1f", probeCode )
	
end
ReadIni()

----------- Check Probe State -----------
--We can use this function to return the current state CheckProbe()
--or check it for active CheckProbe(1)
--or check it for inactive CheckProbe(0)
function CheckProbe(state)

	----- Select probe signal depending on probe code selected
	ProbeSig = mc.ISIG_PROBE --Default probe signal, G31
	if probeCode == 31.1 then
		ProbeSig = mc.ISIG_PROBE1
	elseif probeCode == 31.2 then
		ProbeSig = mc.ISIG_PROBE2
	elseif probeCode == 31.3 then
		ProbeSig = mc.ISIG_PROBE3
	end
	
	local check = mc.MC_TRUE --Default value of check
	local hsig = mc.mcSignalGetHandle(inst, ProbeSig)
	local ProbeState = mc.mcSignalGetState(hsig)
	
	if (state == nil) then --We did not specify the value of the state parameter so lets return ProbeState
		if (ProbeState == 1) then 
			return (mc.MC_TRUE);
		else
			return (mc.MC_FALSE);
		end
	end
	
	if (ProbeState ~= state) then --CheckProbe failed
		check = mc.MC_FALSE
	end
	
	return check
end

function rcToolLengthSensor.Sense()
	
	if tlsContinue ~= mc.MC_TRUE then return end
	tlsContinue = mc.MC_FALSE
	tool, rcDebug.rc = mc.mcToolGetCurrent( inst )
	tData = rcTool.GetData( tool )
	local saved = {
		x = position.x,
		y = position.y,
		z = position.z,
	}
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) )
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( saved.x ), y( saved.y ) )
	)
	if CheckProbe() == mc.MC_TRUE then return end -- ensure probe is not touched
	-- probe tool center at fast feedrate
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, PROBE_CODE, f( feedRate.fast ), z( saved.z - overShoot ) )
	)
	if CheckProbe() == mc.MC_FALSE then return end -- ensure probe is touched
	saved.z, rcDebug.rc = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, mc.MC_TRUE)
	
	-- do this operation if tool diameter is wider than tool sensor diameter
	if tData.diameter > diameter then
	
		local angle = ( math.asin( diameter / tData.diameter ) ) * 2
		local points = math.floor(math.pi / angle) + 1
		angle = math.pi / points
		local toProbe = {}
		toProbe.z = saved.z
		for i=0,points do
			
			toProbe.x = position.x + ( Multipliers[arcOrientation].x * ( tData.diameter / 2 ) * math.cos( angle * i ) )
			toProbe.y = position.y + ( Multipliers[arcOrientation].y * ( tData.diameter / 2 ) * math.sin( angle * i ) )
			
			rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
				.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( toProbe.z + retract ) )
				.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( toProbe.x ), y( toProbe.y ) )
			)
			if CheckProbe() == mc.MC_TRUE then return end -- ensure probe is not touched
			rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
				.. rcGCode.Line( MACH_OFFSET, PROBE_CODE, f( feedRate.fast ), z( toProbe.z ) ) -- we are only going to probe  to the longest length so far
			)
			if CheckProbe() == mc.MC_TRUE then -- we got a touch
				toProbe.z, rcDebug.rc = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, mc.MC_TRUE)
				saved.x = toProbe.x
				saved.y = toProbe.y
				saved.z = toProbe.z
			end
		end
	end
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( saved.z + retract ) )
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, x( saved.x ), y( saved.y ) )
	)
	if CheckProbe() == mc.MC_TRUE then return end -- ensure probe is not touched
	-- probe saved position at slow feedrate
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, PROBE_CODE, f( feedRate.slow ), z( saved.z - overShoot ) )
	)
	if CheckProbe() == mc.MC_FALSE then return end -- ensure probe is touched
	saved.z, rcDebug.rc = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, mc.MC_TRUE)
	if tData.isMaster == mc.MC_TRUE then
		position.z = saved.z
		rcDebug.rc = mc.mcProfileWriteDouble(inst, "RCToolLengthSensor", "position.z", position.z)
		rcDebug.rc = mc.mcProfileSave( inst )
		rcDebug.rc = mc.mcProfileFlush( inst )
		rcDebug.rc = mc.mcToolSetData(inst, mc.MTOOL_MILL_HEIGHT, tool, 0)
	else
		rcDebug.rc = mc.mcToolSetData(inst, mc.MTOOL_MILL_HEIGHT, tool, saved.z - position.z)
	end
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( MACH_OFFSET, RAPID_MOVE, z( 0 ) )
	)
	tlsContinue = mc.MC_TRUE
	
end

function rcToolLengthSensor.preSense()
	
	tlsContinue = mc.MC_FALSE
	--ensure latest data
	ReadIni()
	if diameter == 0 then return end
	-- is machine homed and enabled?
	if rcCommon.GetHomedEnabled() ~= mc.MC_TRUE then return end
	
	
	-- record state
	--rcDebug.rc = mc.mcCntlMachineStatePush( inst )
	rcGCode.CallCustomM( 114 )
	rcGCode.StartState()
	tlsContinue = mc.MC_TRUE
	
end

function rcToolLengthSensor.postSense()
	if tlsContinue == mc.MC_TRUE then
		rcGCode.CallCustomM( 115 )
		rcGCode.EndState()
		-- restore state
		--rcDebug.rc = mc.mcCntlMachineStatePop( inst )
		rcCommon.ShowMessage( TYPE_LOG, LEVEL_INFORMATION, "M1005: Tool length sensing complete." )
		rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
			.. rcGCode.Line( "G43", h( tData.tIndex) )
		)
		tlsContinue = mc.MC_FALSE
	else
		rcGCode.EndState()
		-- restore state
		--rcDebug.rc = mc.mcCntlMachineStatePop( inst )
	end
end

return rcToolLengthSensor
