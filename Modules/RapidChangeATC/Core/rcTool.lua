rcTool = {}

local inst

inst = mc.mcGetInstance( "rcTool" )

local function ReadIni()
	
	data = {
		[ 0 ] = {
			tIndex = 0,
			desc = "Bare Spindle",
			tOD = 25.0,
			isMaster = false
		}
	}
	
end
ReadIni()

local function GetToolInRange( tool )
	
	return (tool > 0 and tool <= 99)

end

local function GetToolIsMaster( tool )
	
	return (tool == 1)

end

function rcTool.GetData( tool )
	
	local desc, tOD
	
	if tool == 0 then return data[ 0 ] end  -- tool zero
	
	if not GetToolInRange( tool ) then
		response = rcCommon.ShowMessage( TYPE_MESSAGEBOX, LEVEL_STOP, "Error: Invalid Spindle Index!" )
		return data [ 0 ]
	end
	
	desc, rcDebug.rc = mc.mcToolGetDesc( inst, tool )
	
	tOD, rcDebug.rc = mc.mcToolGetData( inst, mc.MTOOL_MILL_DIA, tool )
	
	return {
		tIndex = tool,
		desc = desc,
		tOD = tOD,
		isMaster = GetToolIsMaster( tool )
	}

end

return rcTool
