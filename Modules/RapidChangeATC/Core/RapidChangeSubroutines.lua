local RapidChangeSubroutines = {}
--Constants
local k = rcConstants
local CONVERSION_MULTIPLIER = 0.03937 --(mm to in conversion multiplier)
local Z_RETREAT_OFFSET = 12 --(mm)
local Z_SPINDLE_START_OFFSET = 23 --(mm)

--Mach4 Settings
local units = 0

--Tool Change Settings
local alignment = 0
local direction = 0
local pocketCount = 0
local pocketOffset = 0
local engageFeed = 0
local rpmLoad = 0
local rpmUnload = 0
local xPocket1 = 0
local yPocket1 = 0
local xLoad = 0
local yLoad = 0
local xUnload = 0
local yUnload = 0
local xManual = 0
local yManual = 0
local zEngage = 0
local zMoveToLoad = 0
local zMoveToProbe = 0
local zRetreat = 0
local zSafeClearance = 0
local zSpindleStart = 0
local pocketMappingEnabled = 1

--Tool Recognition Settings
local toolRecEnabled = 0
local toolRecOverride = 0
local irInput = 0
local irBrokenState = 0
local zZone1 = 0
local zZone2 = 0

--Dust Cover Settings
local coverEnabled = 0
local coverControl = 0
local coverAxis = 0
local coverOpenPos = 0
local coverClosedPos = 0
local coverOutput = 0
local coverDwell = 0

--Touch Off Settings
local touchOffEnabled = 0
local toolSetterInternal = 0
local toolSetterProbeCode = 0
local xSetter = 0
local ySetter = 0
local zSetter = 0
local zSeekStart = 0
local seekOvershoot = 0
local seekRetreat = 0
local seekFeed = 0
local setFeed = 0
local toolDiameterOffset = 0
local toolHeightSetterDiameter = 0

--Mach Tool Numbers
local currentTool = 0
local selectedTool = 0

local function convert(mmValue)
  if units == k.MILLIMETERS then
    return mmValue
  else
    return mmValue * CONVERSION_MULTIPLIER
  end
end

local function getPocket( tool )
	local inst = mc.mcGetInstance()
	return( mc.mcToolGetData( inst, mc.MTOOL_MILL_POCKET,tool ) )
end

local function isPocketInRange(pocket)
  if pocket > 0 and pocket <= pocketCount then
    return k.TRUE
  else
    return k.FALSE
  end
end

local function isToolInRange(tool)
  if tool > 0 and tool <= 99 then
	if pocketMappingEnabled then
		return isPocketInRange(getPocket(tool))
	else
		return k.TRUE
	end
  else
    return k.FALSE
  end
end


local function getManualPos(axis)
  if axis == k.X_AXIS then
    return xManual
  else
    return yManual
  end
end


local function getPocket1Pos(axis)
  if axis == k.X_AXIS then
    return xPocket1
  else
    return yPocket1
  end
end

local function calculateAlignedPocketPosition(tool)
  local refPos = getPocket1Pos(alignment)
  return refPos + (direction * pocketOffset * (tool - 1))
end

local function getPocketPos(axis, pocket)
  if isPocketInRange(pocket) == k.FALSE then
    return getManualPos(axis)
  end

  if axis == alignment then
    return calculateAlignedPocketPosition(pocket)
  else
    return getPocket1Pos(axis)
  end
end

local function getMachToolNumbers()
	currentTool = rcCntl.GetCurrentTool()
	selectedTool = rcCntl.GetSelectedTool()

	if pocketMappingEnabled then
		local currentToolPocket = getPocket( currentTool )
		local selectedToolPocket = getPocket( selectedTool )
		xLoad = getPocketPos(k.X_AXIS, selectedToolPocket)
		yLoad = getPocketPos(k.Y_AXIS, selectedToolPocket)
		xUnload = getPocketPos(k.X_AXIS, currentToolPocket)
		yUnload = getPocketPos(k.Y_AXIS, currentToolPocket)
	else
		xLoad = getPocketPos(k.X_AXIS, selectedTool)
		yLoad = getPocketPos(k.Y_AXIS, selectedTool)
		xUnload = getPocketPos(k.X_AXIS, currentTool)
		yUnload = getPocketPos(k.Y_AXIS, currentTool)
	end
end

local function setupATCMotion()
  RapidChangeSubroutines.UpdateSettings()
  rcCntl.RecordState()
  rcCntl.SetDefaultUnits()
  rcCntl.CoolantStop()
  rcCntl.SpinStop()
  rcCntl.CancelTLO()
  rcCntl.RapidToMachCoord_Z(zSafeClearance)
end

function RapidChangeSubroutines.Validate_HomeXYZ()
  if rcCntl.IsHomed(k.X_AXIS) == k.FALSE or rcCntl.IsHomed(k.Y_AXIS) == k.FALSE or rcCntl.IsHomed(k.Z_AXIS) == k.FALSE then
    local message = "Machine is not homed, it is not safe to perform this function."
    rcCntl.ShowBox(message)
    rcCntl.Terminate(message)
  end
end

local function getProbeCode(settingValue)
	local probeCode = {31, 31.1, 31.2, 31.3}
	return probeCode[settingValue+1]
end

function RapidChangeSubroutines.UpdateSettings()
  --Mach4 Settings
  units = rcCntl.GetDefaultUnits() / 10

  --Tool Change Settings
  alignment = rcSettings.GetValue(k.ALIGNMENT)
  direction = rcSettings.GetValue(k.DIRECTION)
  pocketCount = rcSettings.GetValue(k.POCKET_COUNT)
  pocketOffset = rcSettings.GetValue(k.POCKET_OFFSET)
  engageFeed = rcSettings.GetValue(k.ENGAGE_FEED_RATE)
  rpmLoad = rcSettings.GetValue(k.LOAD_RPM)
  rpmUnload = rcSettings.GetValue(k.UNLOAD_RPM)
  xManual = rcSettings.GetValue(k.X_MANUAL)
  yManual = rcSettings.GetValue(k.Y_MANUAL)
  xPocket1 = rcSettings.GetValue(k.X_POCKET_1)
  yPocket1 = rcSettings.GetValue(k.Y_POCKET_1)
  zEngage = rcSettings.GetValue(k.Z_ENGAGE)
  zMoveToLoad = rcSettings.GetValue(k.Z_MOVE_TO_LOAD)
  zMoveToProbe = rcSettings.GetValue(k.Z_MOVE_TO_PROBE)
  zRetreat = zEngage + convert(Z_RETREAT_OFFSET)
  zSafeClearance = rcSettings.GetValue(k.Z_SAFE_CLEARANCE)
  zSpindleStart = zEngage + convert(Z_SPINDLE_START_OFFSET)
  pocketMappingEnabled = k.TRUE  

  --Tool Recognition Settings
  toolRecEnabled = rcSettings.GetValue(k.TOOL_REC_ENABLED)
  toolRecOverride = rcSettings.GetValue(k.TOOL_REC_OVERRIDE)
  irInput = rcSettings.GetValue(k.IR_INPUT)
  irBrokenState = rcSettings.GetValue(k.BEAM_BROKEN_STATE)
  zZone1 = rcSettings.GetValue(k.Z_ZONE_1)
  zZone2 = rcSettings.GetValue(k.Z_ZONE_2)

  --Dust Cover Settings
  coverEnabled = rcSettings.GetValue(k.COVER_ENABLED)
  coverControl = rcSettings.GetValue(k.COVER_CONTROL)
  coverAxis = rcSettings.GetValue(k.COVER_AXIS)
  coverOpenPos = rcSettings.GetValue(k.COVER_OPEN_POS)
  coverClosedPos = rcSettings.GetValue(k.COVER_CLOSED_POS)
  coverOutput = rcSettings.GetValue(k.COVER_OUTPUT)
  coverDwell = rcSettings.GetValue(k.COVER_DWELL)

  --Touch Off Settings
  touchOffEnabled = rcSettings.GetValue(k.TOUCH_OFF_ENABLED)
  toolSetterInternal = rcSettings.GetValue(k.TOOL_SETTER_INTERNAL)
  toolSetterProbeCode = getProbeCode(rcSettings.GetValue(k.TOUCH_OFF_G_CODE))
  xSetter = rcSettings.GetValue(k.X_TOOL_SETTER)
  ySetter = rcSettings.GetValue(k.Y_TOOL_SETTER)
  zSetter = rcSettings.GetValue(k.Z_TOOL_SETTER)  
  zSeekStart = rcSettings.GetValue(k.Z_SEEK_START)
  --maxDistance = rcSettings.GetValue(k.SEEK_MAX_DISTANCE)
  seekOvershoot = math.max(rcSettings.GetValue(k.SEEK_OVERSHOOT),(-1 * rcSettings.GetValue(k.SEEK_OVERSHOOT)))  
  seekRetreat = math.max(rcSettings.GetValue(k.SEEK_RETREAT),(-1 * rcSettings.GetValue(k.SEEK_RETREAT)))
  seekFeed = rcSettings.GetValue(k.SEEK_FEED_RATE)
  setFeed = rcSettings.GetValue(k.SET_FEED_RATE) 
  toolDiameterOffset = rcSettings.GetValue(k.TOOL_DIAMETER_OFFSET)
  toolHeightSetterDiameter = rcSettings.GetValue(k.TOOL_SETTER_DIAMETER)  
   
end

--Tool change subroutines
function RapidChangeSubroutines.ConfirmLoad_Override()
  rcCntl.RapidToMachCoord_Z(zSafeClearance)
  rcCntl.SetCurrentTool(selectedTool)
  currentTool = selectedTool
end

function RapidChangeSubroutines.ConfirmLoad_ToolRecognition()
  rcCntl.RapidToMachCoord_Z(zZone1)
  wx.wxMillisleep(100)

  local irInputState = rcSignals.GetInputState(irInput)

  if irInputState ~= irBrokenState then --Failure Zone 1
    rcCntl.RapidToMachCoords_Z_XY_Z(zSafeClearance, xManual, yManual, zSafeClearance)
    rcCntl.ShowBoxWithAbort(string.format("Tool %i failed Zone 1 recognition.\n\nManually load tool %i and press \"OK\" to resume ATC operations.\nPress \"Cancel\" to abort.", selectedTool, selectedTool))
  else --Next check
    rcCntl.RapidToMachCoord_Z(zZone2)
    wx.wxMillisleep(100)

    irInputState = rcSignals.GetInputState(irInput)
    if irInputState == irBrokenState then --Failure Zone 2
      rcCntl.RapidToMachCoords_Z_XY_Z(zSafeClearance, xManual, yManual, zSafeClearance)
      rcCntl.ShowBoxWithAbort(string.format("Tool %i failed Zone 2 recognition.\n\nManually load tool %i and press \"OK\" to resume ATC operations.\nPress \"Cancel\" to abort.", selectedTool, selectedTool))
    else --Success
      rcCntl.RapidToMachCoord_Z(zMoveToProbe)
    end
  end

  --We should now have loaded the tool and be at the appropriate height
  rcCntl.SetCurrentTool(selectedTool)
  currentTool = selectedTool
end

function RapidChangeSubroutines.ConfirmLoad_User()
  rcCntl.SpinStop()
  rcCntl.RapidToMachCoord_Z(zMoveToProbe)

  local message = string.format("Confirm tool %i has properly loaded and press \"OK\" to resume ATC.", selectedTool)
  if pocketMappingEnabled then message = string.format( "Confirm tool %i from pocket %i has properly loaded and press \"OK\" to resume ATC.", selectedTool, getPocket(selectedTool) )  end
  rcCntl.ShowBox(message)

  rcCntl.SetCurrentTool(selectedTool)
  currentTool = selectedTool
end

function RapidChangeSubroutines.ConfirmUnload_Override()
  rcCntl.SpinStop()
  rcCntl.RapidToMachCoord_Z(zSafeClearance)
  rcCntl.SetCurrentTool(0)
  currentTool = 0
end

function RapidChangeSubroutines.ConfirmUnload_ToolRecognition()
  rcCntl.RapidToMachCoord_Z(zZone1)
  wx.wxMillisleep(100)

  local irInputState = rcSignals.GetInputState(irInput)

  if irInputState == irBrokenState then --We still have a tool, try again
    rcCntl.LinearToMachCoords_Z_Z(zEngage, zRetreat, engageFeed)
    rcCntl.RapidToMachCoord_Z(zZone1)
    wx.wxMillisleep(100)
    rcCntl.SpinStop()


    irInputState = rcSignals.GetInputState(irInput)
    if irInputState == irBrokenState then --We failed again, go to manual
      rcCntl.RapidToMachCoords_Z_XY_Z(zSafeClearance, xManual, yManual, zSafeClearance)
      rcCntl.ShowBoxWithAbort(string.format("Tool %i failed to unload properly.\n\nManually unload tool %i and press \"OK\" to resume ATC operations.\nPress \"Cancel\" to abort.", currentTool, currentTool))
    else -- Success on second attempt
      rcCntl.RapidToMachCoord_Z(zMoveToLoad)
    end
  else --Success on first attempt
    rcCntl.SpinStop()
    rcCntl.RapidToMachCoord_Z(zMoveToLoad)
  end

  --We should now have unloaded the tool and be at the appropriate height
  rcCntl.SetCurrentTool(0)
  currentTool = 0
end

function RapidChangeSubroutines.ConfirmUnload_User()
  rcCntl.SpinStop()
  rcCntl.RapidToMachCoord_Z(zMoveToLoad)

  local message = string.format("Confirm tool %i has properly unloaded and press \"OK\" to resume ATC.", currentTool)
  if pocketMappingEnabled then message = string.format( "Confirm tool %i from pocket %i has properly unloaded and press \"OK\" to resume ATC.", currentTool, getPocket(currentTool) ) end
  rcCntl.ShowBox(message)

  rcCntl.SetCurrentTool(0)
  currentTool = 0
end

function RapidChangeSubroutines.Execute_CoverClose()
  if coverEnabled == k.DISABLED and rcSignals.GetToolChangeState() == k.ACTIVE then
    return
  end

  if coverControl == k.COVER_CONTROL_AXIS then
    RapidChangeSubroutines.CoverCloseAxis()
  else
    RapidChangeSubroutines.CoverCloseOutput()
  end
end

function RapidChangeSubroutines.CoverCloseAxis()
  rcCntl.RapidToMachCoord(coverAxis, coverClosedPos)
end

function RapidChangeSubroutines.CoverCloseOutput()
  if rcSignals.GetOutputState(coverOutput) == k.INACTIVE then return end

  rcSignals.DeactivateOutput(coverOutput)
  rcCntl.Dwell(coverDwell)
end

function RapidChangeSubroutines.CoverOpenAxis()
  rcCntl.RapidToMachCoord(coverAxis, coverOpenPos)
end

function RapidChangeSubroutines.CoverOpenOutput()
  if rcSignals.GetOutputState(coverOutput) == k.ACTIVE then return end

  rcSignals.ActivateOutput(coverOutput)
  rcCntl.Dwell(coverDwell)
end

function RapidChangeSubroutines.Execute_CoverOpen()
  if coverEnabled == k.DISABLED and rcSignals.GetToolChangeState() == k.ACTIVE then
    return
  end

  if coverControl == k.COVER_CONTROL_AXIS then
    RapidChangeSubroutines.CoverOpenAxis()
  else
    RapidChangeSubroutines.CoverOpenOutput()
  end
end

-- This function assumes that the spindle is already at a safe height!
-- Should only be called from m6 or after SetupToolTouchOff in m131.
function RapidChangeSubroutines.Execute_ToolTouchOff()
  
	if currentTool == 0 or (touchOffEnabled == k.DISABLED and rcSignals.GetToolChangeState() == k.ACTIVE) then
		rcCntl.RapidToMachCoord_Z(zSafeClearance)
    	return end
	
	local inst = mc.mcGetInstance()
	local probeCode = toolSetterProbeCode
	
	local xSaved = xSetter
	local ySaved = ySetter
	local pointZ = 0
	local toolDiameter, rc = mc.mcToolGetData(inst, mc.MTOOL_MILL_DIA, currentTool)
	local toolDescription = mc.mcToolGetDesc(inst, currentTool)
	local toolLength = 0
	
	-- move to probe xy position at zSeekStart plane
	rcCntl.RapidToMachCoords_XY_Z(xSaved, ySaved, zSeekStart)
	
	--fast
	-- confirm probe is free
	rc = rcCntl.CheckProbe(0, probeCode) 
	if not rc then RapidChangeSubroutines.OnFailedProbeStatus(k.FALSE) return end
	
	-- seek tool setter surface
	rcCntl.ProbeDown(zSetter - zSeekStart - seekOvershoot, seekFeed)
	
	-- confirm probe strike
	rc = rcCntl.CheckProbe(1, probeCode) 
	if not rc then RapidChangeSubroutines.OnFailedProbeStatus(k.TRUE) return end
	
	pointZ, rc = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, mc.MC_TRUE)
	if rc ~= mc.MERROR_NOERROR then return end
	toolLength = pointZ - zSetter
	
	-- do this operation if tool diameter is wider than tool setter
	if ((toolDiameter > toolHeightSetterDiameter) and (toolDiameterOffset ~= k.DISABLED)) then
		local hyp = toolDiameter / 2
		local opp = toolHeightSetterDiameter / 2
		local angle = math.asin(opp / hyp) * 2
		local points = math.floor(math.pi / angle) + 1
		angle = math.pi / points
		local pointX, pointY
		local xOffset = { -1, 1, -1, 1 }
		local yOffset = { -1, -1, 1, 1 }
		
		for i=0,points,1
		do
			pointX = xSetter + (math.cos(angle * i) * hyp * xOffset[toolDiameterOffset])
			pointY = ySetter + (math.sin(angle * i) * hyp * yOffset[toolDiameterOffset])
			
			-- retract
			rcCntl.LinearIncremental_Z(seekRetreat, seekFeed)
			rc = rcCntl.CheckProbe(0, probeCode) -- ensure probe is not touched
			if not rc then return end
			
			rcCntl.RapidToMachCoords_XY( pointX, pointY )
			-- seek tool setter surface
			rcCntl.ProbeDown(-seekRetreat - seekOvershoot, seekFeed) -- probe -z, but we are only interested in longer tool length results
			
			rc = rcCntl.CheckProbe(1, probeCode) 
			if not rc then
				-- the tool geometry wasn't longer at this xy location
			else
				pointZ, rc = mc.mcAxisGetProbePos(inst, mc.Z_AXIS, mc.MC_TRUE)
				if (pointZ - zSetter) > toolLength then
					xSaved = pointX
					ySaved = pointY
					toolLength = pointZ - zSetter
				end
			end
		end
	end
	
	-- retract
	rcCntl.LinearIncremental_Z(seekRetreat, seekFeed)
	-- confirm probe is free
	rc = rcCntl.CheckProbe(0, probeCode) 
	if not rc then RapidChangeSubroutines.OnFailedProbeStatus(k.FALSE) return end
	
	-- rapid to saved x,y
	rcCntl.RapidToMachCoords_XY(xSaved, ySaved)
	
	--slow
	-- seek tool setter surface
	rcCntl.ProbeDown(-seekRetreat - seekOvershoot, setFeed)
	
	-- confirm probe strike
	rc = rcCntl.CheckProbe(1, probeCode) 
	if not rc then RapidChangeSubroutines.OnFailedProbeStatus(k.TRUE) return end
	
	rcCntl.SetTLO(currentTool, zSetter)
	
	toolLength = mc.mcToolGetData(inst, mc.MTOOL_MILL_HEIGHT, currentTool)
	rcCntl.ShowStatus(string.format("Tool: %i %s length set to %.4f", currentTool, toolDescription, toolLength))
	
	-- retract
	rcCntl.RapidToMachCoord_Z(zSafeClearance)
	
	if coverEnabled == k.TRUE then
		RapidChangeSubroutines.Execute_CoverClose()
	end
  
end

function RapidChangeSubroutines.LoadTool()
	if selectedTool == 0 then
		RapidChangeSubroutines.LoadToolZero()
	elseif isToolInRange(selectedTool) == k.TRUE then
		RapidChangeSubroutines.LoadToolAuto()
	else
		RapidChangeSubroutines.LoadToolManual()
	end
end

function RapidChangeSubroutines.LoadToolAuto()
  rcCntl.RapidToMachCoords_XY_Z(xLoad, yLoad, zSpindleStart)
  rcCntl.SpinCW(rpmLoad)
  rcCntl.LinearToMachCoords_Z_Z(zEngage, zRetreat, engageFeed)
  rcCntl.LinearToMachCoords_Z_Z(zEngage, zRetreat, engageFeed)
  rcCntl.SpinStop()

  if toolRecEnabled == k.ENABLED then
    RapidChangeSubroutines.ConfirmLoad_ToolRecognition()
  elseif toolRecOverride == k.DISABLED then
    RapidChangeSubroutines.ConfirmLoad_User()
  else
    RapidChangeSubroutines.ConfirmLoad_Override()
  end
end

function RapidChangeSubroutines.LoadToolManual()
  rcCntl.RapidToMachCoords_Z_XY_Z(zSafeClearance, xManual, yManual, zSafeClearance)

  local message = string.format("Tool %i is out of range.\n\nManually load tool %i and press \"OK\" to resume ATC operations.\n\n", selectedTool, selectedTool)
  rcCntl.ShowBox(message)
  rcCntl.SetCurrentTool(selectedTool)
  currentTool = selectedTool
end

function RapidChangeSubroutines.LoadToolZero()
  --Do nothing
end

function RapidChangeSubroutines.OnFailedProbeStatus(expectingStrike)
	
local message = ""

	if (expectingStrike == k.TRUE) then
		rcCntl.ShowStatus("Probe not triggered")
		message = "Probe was not triggered.\nProcess aborted."
	else
		rcCntl.ShowStatus("Probe already triggered")
		message = "Probe already triggered.\nProcess aborted."
	end
  
  rcCntl.RapidToMachCoord_Z(zSafeClearance)

  if coverEnabled == k.TRUE and toolSetterInternal == k.TRUE then
    RapidChangeSubroutines.Execute_CoverClose()
  end
  
  rcCntl.ShowBox(message)
  rcCntl.Terminate(message)
end

function RapidChangeSubroutines.Setup_CoverControl()
  if coverControl == k.COVER_CONTROL_AXIS then
    rcCntl.RecordState()
    rcCntl.SetDefaultUnits()
  end
end

function RapidChangeSubroutines.Setup_m6()
  setupATCMotion()
  RapidChangeSubroutines.Execute_CoverOpen()
end

function RapidChangeSubroutines.Setup_ToolTouchOff()
  setupATCMotion()

  if toolSetterInternal == k.TRUE then
    RapidChangeSubroutines.Execute_CoverOpen()
  end
end

function RapidChangeSubroutines.Teardown_CoverControl()
  if coverControl == k.COVER_CONTROL_AXIS then
    rcCntl.RecordState() -- should this be RestoreState?
  end
end

function RapidChangeSubroutines.Teardown_m6()
  RapidChangeSubroutines.Execute_CoverClose()
  rcCntl.RestoreState()
  rcCntl.SetCurrentTool(currentTool)

  if touchOffEnabled == k.ENABLED then
    rcCntl.SetTLO(currentTool, zSetter)
    rcCntl.ActivateTLO(currentTool)
  end
end

function RapidChangeSubroutines.Teardown_ToolTouchOff()
  if toolSetterInternal == k.TRUE then
    RapidChangeSubroutines.Execute_CoverClose()
  end

  rcCntl.RestoreState()
  rcCntl.SetTLO(currentTool, zSetter)
  rcCntl.ActivateTLO(currentTool)
end

function RapidChangeSubroutines.UnloadTool()
  if currentTool == 0 then
    RapidChangeSubroutines.UnloadToolZero()
  elseif isToolInRange(currentTool) == k.TRUE then
    RapidChangeSubroutines.UnloadToolAuto()
  else
    RapidChangeSubroutines.UnloadToolManual()
  end
end

function RapidChangeSubroutines.UnloadToolAuto()
  rcCntl.RapidToMachCoords_XY_Z(xUnload, yUnload, zSpindleStart)
  rcCntl.SpinCCW(rpmUnload)
  rcCntl.LinearToMachCoords_Z_Z(zEngage, zRetreat, engageFeed)

  if toolRecEnabled == k.ENABLED then
    RapidChangeSubroutines.ConfirmUnload_ToolRecognition()
  elseif toolRecOverride == k.DISABLED then
    RapidChangeSubroutines.ConfirmUnload_User()
  else
    RapidChangeSubroutines.ConfirmUnload_Override()
  end
end

function RapidChangeSubroutines.UnloadToolManual()
  rcCntl.RapidToMachCoords_Z_XY_Z(zSafeClearance, xManual, yManual, zSafeClearance)

  local message = string.format("Tool %i is out of range.\n\nManually unload tool %i and press \"OK\" to resume ATC operations.\n\n", currentTool, currentTool)
  rcCntl.ShowBox(message)
  rcCntl.SetCurrentTool(0)
  currentTool = 0
end

function RapidChangeSubroutines.UnloadToolZero()
  --Do nothing
end

function RapidChangeSubroutines.Validate_CoverControl()
  --Do nothing
end

function RapidChangeSubroutines.Validate_m6()
  getMachToolNumbers()
  if currentTool == selectedTool then
    local message = string.format("Tool %i loaded. Tool change bypassed.", selectedTool)
    rcCntl.Terminate(message)
  end
end

function RapidChangeSubroutines.Validate_ToolTouchOff()
  getMachToolNumbers()
  if currentTool == 0 then
    rcCntl.Terminate("Tool touch off aborted. No current tool.")
  end
  if toolHeightSetterDiameter == 0 then
	rcCntl.Terminate("Tool touch off aborted. Setter diameter cannot be zero.") 
  end
end

return RapidChangeSubroutines
