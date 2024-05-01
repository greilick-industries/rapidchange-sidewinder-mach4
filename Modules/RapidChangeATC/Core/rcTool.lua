rcTool = {}

local inst, data, maxTools

inst = mc.mcGetInstance( "rcTool" )

local function ReadIni()
	
	data = {
		[ 0 ] = {
			tIndex = 0,
			desc = "Bare Spindle",
			diameter = 25.0,
			isMaster = mc.MC_FALSE
		}
	}
	maxTools = mc.mcProfileGetInt( inst, "Preferences", "MaxTools", 99 ) -- value from Configure >> Control >> Tools >> Max Tools
end
ReadIni()

local function GetToolInRange( tool )
	
	local inRange = mc.MC_FALSE
	
	if (tool > 0 and tool <= maxTools) then inRange = mc.MC_TRUE end
	return inRange

end

local function GetToolIsMaster( tool )
	
	local isMaster = mc.MC_FALSE
	if tool == 1  then isMaster = mc.MC_TRUE end
	return isMaster

end

function rcTool.GetData( tool )
	
	local desc, diameter
	
	if tool == 0 then return data[ 0 ] end  -- tool zero
	
	if not GetToolInRange( tool ) then
		response = rcCommon.ShowMessage( TYPE_MESSAGEBOX, LEVEL_STOP, "Error: Invalid Tool Index!" )
		return data [ 0 ]
	end
	
	desc, rcDebug.rc = mc.mcToolGetDesc( inst, tool )
	
	diameter, rcDebug.rc = mc.mcToolGetData( inst, mc.MTOOL_MILL_DIA, tool )
	
	return {
		tIndex = tool,
		desc = desc,
		diameter = diameter,
		isMaster = GetToolIsMaster( tool )
	}

end

function rcTool.GetMasterTool()
	
	return 1
	
end

return rcTool
