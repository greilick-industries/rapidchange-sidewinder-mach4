local inst = mc.mcGetInstance( "rcTool" )

local rcTool = {}

	local Data, rc
	
	local function LoadData( )
		
		local data
		rc = mc.MERROR_NOERROR
		
		data = {
			[ 0 ] = {
				tIndex = 0,
				desc = "Bare Spindle",
				tOD = 25.0,
				isMaster = false
			}
		}
		return data, rc
		
	end
	
	Data = LoadData( )
	
	local function GetToolInRange( t )
		
		rc = mc.MERROR_NOERROR
		return (t > 0 and t <= 99), rc
	
	end

	local function GetToolIsMaster( t )
		
		rc = mc.MERROR_NOERROR
		return (t == 1), rc
	
	end
	
	function rcTool.GetData( t )
		
		local desc, tOD
		rc = mc.MERROR_NOERROR
		
		Data = LoadData( )	-- this may not be necessary, but should keep user settings up-to-date
		
		if t == 0 then return Data[ 0 ], rc end  -- tool zero
		
		if not GetToolInRange( t ) then
			rc = mc.MERROR_INVALID_ARG
			return Data [ 0 ], rc 
		end
		
		desc, rc = mc.mcToolGetDesc( inst, t )
		if ( rc ~= mc.MERROR_NOERROR ) then
			return Data [ 0 ], rc
		end
		
		tOD, rc = mc.mcToolGetData( inst, mc.MTOOL_MILL_DIA, t )
		if ( rc ~= mc.MERROR_NOERROR ) then
			return Data [ 0 ], rc
		end
		
		return {
			tIndex = t,
			desc = desc,
			tOD = tOD,
			isMaster = GetToolIsMaster( t )
		}, rc
	
	end

return rcTool
