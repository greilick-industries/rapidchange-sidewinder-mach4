local inst = mc.mcGetInstance( "rcSpindle" )

local rcSpindle = {}

	local Data, rc
	
	local function LoadData( )
		
		rc = mc.MERROR_NOERROR
		
		local data = {
			-- we need a Data[ 0 ] for manual tool load/unload
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
		return data, rc
	
	end

	Data = LoadData( )
	
	local function GetSpindleInRange( i )
		
		rc = mc.MERROR_NOERROR
		return (i >= 0 and i <= #Data), rc
		
	end
	
	function rcSpindle.GetData( i )
		
		rc = mc.MERROR_NOERROR
		Data, rc = LoadData()	-- this may not be necessary, but should keep user settings up-to-date
		
		if not GetSpindleInRange( i ) then
			rc = mc.MERROR_INVALID_ARG
			return Data [ 0 ], rc 
		end
		
		return Data[ i ], rc
	
	end

return rcSpindle
