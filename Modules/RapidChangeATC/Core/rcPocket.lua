local inst = mc.mcGetInstance( "rcPocket" )

local rcMagazine, rc

rcMagazine = require "rcMagazine"

local rcPocket = {}

	local function GetPocketIndexInRange ( i, d )
		
		rc = mc.MERROR_NOERROR
		return (i > 0 and i <= d.pockets), rc
		
	end
	
	function rcPocket.GetData ( t )
		
		local mcPocket, mcTOD, mIndex, pIndex, mData,
		rc = mc.MERROR_NOERROR
		
		if t == 0 then return nil, rc end --tool zero
		
		mcPocket, rc  = mc.mcToolGetData( inst, mc.MTOOL_MILL_POCKET, t )
		if ( rc ~= mc.MERROR_NOERROR ) then
			return nil, rc
		end
		
		mcTOD, rc = mc.mcToolGetData( inst, mc.MTOOL_MILL_DIA, t )
		if ( rc ~= mc.MERROR_NOERROR ) then
			return nil, rc
		end
		
		mIndex, pIndex, rc = rcMagazine.GetMagazineIndices( mcPocket )
		if ( rc ~= mc.MERROR_NOERROR ) then
			return nil, rc
		end
	
		mData, rc = rcMagazine.GetData( mIndex )
		if ( rc ~= mc.MERROR_NOERROR ) then
			return nil, rc
		end
		
		--this is really a double check. necessary?
		if not GetPocketIndexInRange( pIndex, mData ) then
			rc = mc.MERROR_INVALID_ARG
			return nil, rc
		end
		
		return {
			mDesc = mData.desc,
			mIndex = mIndex,
			pIndex = pIndex,
			p = {
				x = mData.p1.x + ( ( pIndex - 1 ) * mData.pOffset.x ),
				y = mData.p1.y + ( ( pIndex - 1 ) * mData.pOffset.y ),
				z = mData.p1.z + ( ( pIndex - 1 ) * mData.pOffset.z )
			},
			lOffset = {
				x = mData.lOffset.x,
				y = mData.lOffset.y,
				z = mData.lOffset.z
			},
			spindle = mData.spindle
		}, rc
  
	end

return rcPocket
