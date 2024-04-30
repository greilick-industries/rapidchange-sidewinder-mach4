rcGCode = {}

local inst

inst = mc.mcGetInstance("rcGCode")

local function GetDefaultUnits()
	
	local units, rc
	
	units, rc = mc.mcCntlGetUnitsDefault(inst)
	return (units / 10)
	
end

local function Trim(s)
   
	return (s:gsub("^%s*(.-)%s*$", "%1"))

end

--Concats the provided args to a single string
local function Concat(...)
	
	local s = ""
	local arg = {...}

	for _, v in ipairs(arg) do
		s = s .. " ".. v
	end

	return Trim(s)
	
end

--Word function builder
local function wordFunction(letter, format)
  
	return function (value)
		
		return string.format(letter .. format, value)
	
	end

end

--Word functions
a = wordFunction("A", F4)
b = wordFunction("B", F4)
c = wordFunction("C", F4)
f = wordFunction("F", F2)
g = wordFunction("G", I)
h = wordFunction("H", I)
m = wordFunction("M", I)
p = wordFunction("P", F2)
s = wordFunction("S", I)
x = wordFunction("X", F4)
y = wordFunction("Y", F4)
z = wordFunction("Z", F4)

RAPID_MOVE = g(0)
LINEAR_FEED_MOVE = g(1)
DWELL = g(4)
XY_PLANE_SELECT = g(17)
DEFAULT_UNITS = g(GetDefaultUnits())
CUTTER_COMPENSATION_CANCEL = g(49)
MACH_OFFSET = g(53)
CANNED_CYCLE_CANCEL = g(80)
ABSOLUTE_POSITION_MODE = g(90)
INCREMENTAL_POSITION_MODE = g(91)
SPIN_CW = m(3)
SPIN_CCW = m(4)
SPIN_STOP = m(5)
ENABLE_OVERRIDES = m(48)
DISABLE_OVERRIDES = m(49)
SAFE_LINE = Concat(RAPID_MOVE, DEFAULT_UNITS, ABSOLUTE_POSITION_MODE, XY_PLANE_SELECT, CUTTER_COMPENSATION_CANCEL, CANNED_CYCLE_CANCEL)
	
function rcGCode.Line(...)
	
	return Concat(...) .. "\n"
	
end

function rcGCode.StartState()
	
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( SPIN_STOP )			-- stop spindle
		.. rcGCode.Line( DISABLE_OVERRIDES )	-- disable feed/speed rate overrides
		.. rcGCode.Line( SAFE_LINE )			-- set safe gCode
	)
	
end

function rcGCode.EndState()
	
	rcDebug.rc = mc.mcCntlGcodeExecuteWait( inst, ""
		.. rcGCode.Line( SPIN_STOP )		-- stop spindle
		.. rcGCode.Line( ENABLE_OVERRIDES )	-- enable feed/speed rate overrides
	)
	
end


return rcGCode
