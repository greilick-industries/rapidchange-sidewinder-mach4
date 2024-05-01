rcPocket = {}

local inst

inst = mc.mcGetInstance( "rcPocket" )

local function GetPocketIndexInRange ( index, data )
	
	return (index > 0 and index <= data.pockets)
	
end

function rcPocket.GetData ( tool )
	
	local mcPocket, mcTOD, mIndex, pIndex, mData
	
	if tool == 0 then return nil end --tool zero
	
	mcPocket, rc  = mc.mcToolGetData( inst, mc.MTOOL_MILL_POCKET, tool )
	mcTOD, rc = mc.mcToolGetData( inst, mc.MTOOL_MILL_DIA, tool )
	mIndex, pIndex = rcMagazine.GetMagazineIndices( mcPocket )
	mData = rcMagazine.GetData( mIndex )
	--this is really a double check. necessary?
	if not GetPocketIndexInRange( pIndex, mData ) then
		-- should maybe handle an error here in case
		return nil
	end
	
	return {
		mDesc = mData.desc,
		mConf = mData.conf,
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
	}

end

return rcPocket
