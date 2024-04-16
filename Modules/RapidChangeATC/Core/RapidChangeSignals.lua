local RapidChangeSignals = {}

local inst = mc.mcGetInstance()
local k = rcConstants

local function getSignalId(prefix, num)
	local signalKey
	if num == nil then
		signalKey = prefix
	else
		signalKey = string.format(prefix .. "%i", num)
	end
  return mc[signalKey]
end

local function getSignalHandle(prefix, num)
	local id = getSignalId(prefix, num)
  local hsig, rc = mc.mcSignalGetHandle(inst, id)
	rcErrors.GuardAPIError(rc)
	return hsig
end

local function getSignalState(prefix, num)
	local hsig = getSignalHandle(prefix, num)
	local state, rc = mc.mcSignalGetState(hsig)
	rcErrors.GuardAPIError(rc)
	return state
end

local function setSignalState(outputNum, state)
	local hsig = getSignalHandle("OSIG_OUTPUT",outputNum)
	local rc = mc.mcSignalSetState(hsig, state)
	rcErrors.GuardAPIError(rc)
end

function RapidChangeSignals.ActivateOutput(outputNum)
	setSignalState(outputNum, k.ACTIVE)
end

function RapidChangeSignals.DeactivateOutput(outputNum)
	setSignalState(outputNum, k.INACTIVE)
end

--Reads input state for Input # inputs based on their number 0-63 
function RapidChangeSignals.GetInputState(inputNum)
	return getSignalState("ISIG_INPUT", inputNum)
end

function RapidChangeSignals.GetOutputState(outputNum)
	return getSignalState("OSIG_OUTPUT", outputNum)
end

function RapidChangeSignals.GetToolChangeState()
	return getSignalState("OSIG_TOOL_CHANGE")
end

return RapidChangeSignals