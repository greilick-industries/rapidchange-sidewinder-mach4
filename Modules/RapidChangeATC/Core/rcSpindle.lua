rcSpindle = {}

local inst, data, rc

inst= mc.mcGetInstance( "rcSpindle" )

local function ReadIni( )
		
	data = {
		-- we need a data[ 0 ] for manual tool load/unload
		[ 0 ] = {
			loadRPM = 0,
			unloadRPM = 0,
			dwell = 0.0,
			zFeedRate = 0
		},
		[ 1 ] = {
			loadRPM = 1300,
			unloadRPM = 1300,
			dwell = 1.0,
			zFeedRate = 1950
		},
		[ 2 ] = {
			loadRPM = 1300,
			unloadRPM = 1300,
			dwell = 1.0,
			zFeedRate = 1950
		}
	}

end
ReadIni()
	
local function GetSpindleInRange( index )
	
	return (index >= 0 and index <= #data)
	
end

function rcSpindle.GetData( index )
	
	local response
	
	if not GetSpindleInRange( index ) then
		response = rcCommon.ShowMessage( TYPE_MESSAGEBOX, LEVEL_STOP, "Error: Invalid Spindle Index!" )
		return data [ 0 ]
	end
	
	return data[ index ]

end

return rcSpindle
