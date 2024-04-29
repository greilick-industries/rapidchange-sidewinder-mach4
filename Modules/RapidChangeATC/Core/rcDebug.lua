rcDebug = {}

local inst, _t, mt

inst = mc.mcGetInstance( "rcDebug")

package.path = string.format(
	"%s;%s\\Modules\\?.lua;",
	package.path,
	mc.mcCntlGetMachDir(inst)
)

ec = require("mcErrorCheck")

_t = rcDebug -- private access to original table
rcDebug = {} -- proxy
rcDebug.prototype = { rc = mc.MERROR_NOERROR, }

mt = { -- create metatable
	__newindex = function ( rcDebug, k, v )
		
		if (tostring( k ) == "rc") then 
			
			if (tonumber( v ) ~= mc.MERROR_NOERROR) then
				
				mc.mcCntlSetLastError(inst, string.format( "rcDebug Errorcode: %i - %s", v, ec[ v ] ) )
			
			end
			
		end
		
		_t[k] = v
		
	end,

}


setmetatable( rcDebug, mt )

return rcDebug
