local inst = mc.mcGetInstance("rcGCode")

local rc = mc.MERROR_NOERROR

--Formatting constants
local F1 = "%.1f"
local F2 = "%.2f"
local F4 = "%.4f"
local I = "%02d"

--Word function builder
local function wordFunction(letter, format)
  return function (value)
    return string.format(letter .. format, value)
  end
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

local function GetDefaultUnits()
	
	rc = mc.MERROR_NOERROR
	local units, rc = mc.mcCntlGetUnitsDefault(inst)
	
	if (rc ~= mc.MERROR_NOERROR) then
		do return 0, rc end
	end
	return string.format("G%i", units / 10), rc
end

local rcGCode = {}

	rcGCode.Commands = {
		RAPID_MOVE = "G00",
		LINEAR_FEED_MOVE = "G01",
		DWELL = "G04",
		XY_PLANE_SELECT = "G17",
		DEFAULT_UNITS, rc = GetDefaultUnits(),
		CUTTER_COMPENSATION_CANCEL = "G49",
		MACH_OFFSET = "G53",
		ABSOLUTE_POSITION_MODE = "G90",
		INCREMENTAL_POSITION_MODE = "G91",
		CANNED_CYCLE_CANCEL = "G80",
		SPIN_CW = "M3",
		SPIN_CCW = "M4",
		SPIN_STOP = "M5",
		COOLANT_STOP = "M9",
		DUST_HOOD_UP = "M114",
		DUST_HOOD_DOWN = "M115",
		SAFE_START = Concat(RAPID_MOVE, DEFAULT_UNITS, ABSOLUTE_POSITION_MODE, XY_PLANE_SELECT, CUTTER_COMPENSATION_CANCEL, CANNED_CYCLE_CANCEL)
	}
	
	--Word functions
	rcGCode.a = wordFunction("A", F4)
	rcGCode.b = wordFunction("B", F4)
	rcGCode.c = wordFunction("C", F4)
	rcGCode.x = wordFunction("X", F4)
	rcGCode.y = wordFunction("Y", F4)
	rcGCode.z = wordFunction("Z", F4)

	rcGCode.f = wordFunction("F", F2)
	rcGCode.g = wordFunction("G", I)
	rcGCode.h = wordFunction("H", I)
	rcGCode.m = wordFunction("M", I)
	rcGCode.p = wordFunction("P", F2)
	rcGCode.s = wordFunction("S", I)

	local gCode = ""

	function rcGCode.Clear()
		gCode = ""
		return gCode
	end

	function rcGCode.AddLine(...)
		gCode = gCode .. Concat(...) .. "\n"
		return gCode
	end
	
	function rcGCode.GetZSafeClearance()
		return rcGCode.z(0)
	end

return rcGCode, rc
