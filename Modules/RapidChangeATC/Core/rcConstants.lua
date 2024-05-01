rcConstants = { }

TYPE_MESSAGEBOX = 1
TYPE_LAST_ERROR = 2
TYPE_LOG = 3
LEVEL_INFORMATION = 1
LEVEL_USER_INPUT = 2
LEVEL_STOP = 3
LEVEL_ESTOP = 4

UNLOAD = 1
LOAD = 2

CONFIRM_DISABLE = 1 -- assume load/unload works perfectly
CONFIRM_MANUAL = 2  -- manual tool change
CONFIRM_USER = 3	-- user checks

XPLU_YPLU = 1
XPLU_YMIN = 2
XMIN_YPLU = 3
XMIN_YMIN = 4

Multipliers = { 
	[ XPLU_YPLU ] = { x = 1, y = 1, z = 0, }, 
	[ XPLU_YMIN ] = { x = 1, y = -1, z = 0, }, 
	[ XMIN_YPLU ] = { x = -1, y = 1, z = 0, }, 
	[ XMIN_YMIN ] = { x = -1, y = -1, z = 0, }, 
}

F1 = "%.1f"
F2 = "%.2f"
F4 = "%.4f"
I = "%02d"

return rcConstants