rcDebug = {}

local inst, processRC, _t, mt

inst = mc.mcGetInstance( "rcDebug")

processRC = {
	[ mc.MERROR_NOERROR ] = function() --[[ do nothing ]] end,
	[ mc.MERROR_NOT_NOW ] = function()
		mc.mcCntlEnable(inst,0)
		mc.mcCntlEnable(inst,1)
	end,	
}
package.path = string.format(
	"%s;%s\\Modules\\?.lua;",
	package.path,
	mc.mcCntlGetMachDir(inst)
)

if package.loaded.mcErrorCheck == nil then
	package.path = string.format(
		"%s;%s\\Modules\\?.lua;",
		package.path,
		mc.mcCntlGetMachDir(inst)
	)
	mcErrorCheck = require "mcErrorCheck"	
end

ec = mcErrorCheck
_t = rcDebug -- private access to original table
rcDebug = {} -- proxy
rcDebug.prototype = { rc = mc.MERROR_NOERROR, }

mt = { -- create metatable
	__newindex = function ( rcDebug, k, v )
		
		if (tostring( k ) == "rc") then 
			if processRC[ tonumber( v ) ] == nil then
				mc.mcCntlSetLastError(inst, string.format( "rcDebug Errorcode: %i - %s", v, ec[ v ] ) )
			else
				processRC[ tonumber( v ) ]()
			end
		end
		_t[k] = v
	end,

}


setmetatable( rcDebug, mt )

return rcDebug
