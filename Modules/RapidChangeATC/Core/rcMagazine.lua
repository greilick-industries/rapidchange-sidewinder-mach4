rcMagazine = {}

local inst, data, rc

inst = mc.mcGetInstance( "rcMagazine" )

--[[
mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "",  )
mc.mcProfileGetInt( inst, string.format("RCMagazine%i", i), "",  )
mc.mcProfileGetString( inst, string.format("RCMagazine%i", i), "",  )

desc = mc.mcProfileGetString( inst, string.format("RCMagazine%i", i), "desc", "" )
conf = mc.mcProfileGetInt( inst, string.format("RCMagazine%i", i), "conf", 1 )
mPocket1 = mc.mcProfileGetInt( inst, string.format("RCMagazine%i", i), "mPocket1", 1 )
pockets = mc.mcProfileGetInt( inst, string.format("RCMagazine%i", i), "pockets",  )
p1 = {
	x = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "p1.x", 0.0 ),
	y = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "p1.y", 0.0 ),
	z = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "p1.z", 0.0 ),
}
pOffset = {
	x = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "pOffset.x", 0.0 ),
	y = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "pOffset.y", 0.0 ),
	z = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "pOffset.z", 0.0 ),
}
lOffset = {
	x = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "lOffset.x", 0.0 ),
	y = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "lOffset.y", 0.0 ),
	z = mc.mcProfileGetDouble( inst, string.format("RCMagazine%i", i), "lOffset.z", 0.0 ),
}
spindle = rcSpindle.GetData( i )
]]
local function ReadIni( )
	
	data = {
		[ 0 ] = { -- manual tool load/unload
			desc = "Manual toolchange position",
			conf = CONFIRM_MANUAL,
			mcPocket1 = 0,
			pockets = 1,
			p1 = { 					--g53 positions
				x = 2555.0,
				y = 600.0,
				z = 0.0
			},
			pOffset = { 			-- positive or negative for direction
				x = 0.0,
				y = 0.0,
				z = 0.0
			},
			lOffset = { 			-- positive or negative for direction. the distance a 70mm diameter tool needs to travel from pocket positions
				x = 0.0,			-- x distance to travel with tool in spindle AFTER loading
				y = 0.0,			-- y distance to travel with tool in spindle AFTER loading
				z = 0.0				-- z distance to travel with tool in spindle AFTER loading
			},
			spindle = rcSpindle.GetData( 0 )
		},
		[ 1 ] = {
			desc = "Sidewinder 16 pocket ATC",
			conf = CONFIRM_USER,
			mcPocket1 = 1,
			pockets = 16,
			p1 = {
				x = 2505.25,
				y = 1204.1355,
				z = -184.0
			},
			pOffset = { 
				x = 0.0,
				y = -70,
				z = 0.0
			},
			lOffset = { 
				x = 50.5,
				y = 0.0,
				z = 7.5
			},
			spindle = rcSpindle.GetData( 1 )
		},
		[ 2 ] = {
			desc = "RapidChange 6 pocket ATC",
			conf = CONFIRM_DISABLE,
			mcPocket1 = 17,
			pockets = 6,
			p1 = {
				x = 1737.7,
				y = 1292.5,
				z = -196.0
			},
			pOffset = {
				x = 45.1,
				y = 0.0,
				z = 0.0
			},
			lOffset = {
				x = 0,
				y = 0,
				z = 7.5
			},
			spindle = rcSpindle.GetData( 2 )
		}
	}
	
end
ReadIni()

local function GetMagazineInRange( i )
	
	rc = mc.MERROR_NOERROR
	return (i >= 0 and i <= #data ), rc
	
end

function rcMagazine.GetMagazineIndices( p )
	
	local mIndex, pIndex
	rc = mc.MERROR_NOERROR
	
	mIndex = 0
	pIndex = 1
	
	for i = #data, 0, -1 do  --looping backwards here, so that if we don't find the magazine, we end up with a manual tool change
		if p >= data[ i ].mcPocket1 and p < (data[ i ].mcPocket1 + data[ i ].pockets) then
			mIndex = i
			break
		end
	end
	
	pIndex = p - data[ mIndex ].mcPocket1 + 1
	
	return mIndex, pIndex
	
end

function rcMagazine.GetData( i )
	
	if not GetMagazineInRange( i ) then
		-- force manual tool change
		return data [ 0 ]
	end
	
	return data[ i ]
	
end

return rcMagazine
