rcDustCover = {}

local inst, dcContinue, oSig, rc

inst = mc.mcGetInstance( "rcDustCover" )
dcContinue = mc.MC_FALSE

local function ReadIni()
	
	oSig = mc.OSIG_OUTPUT52
	
end
ReadIni()

function rcDustCover.Open()
	
	if dcContinue ~= mc.MC_TRUE then return end
	dcContinue = mc.MC_FALSE
	--open dust cover here
	dcContinue = mc.MC_TRUE
end

function rcDustCover.Close()
	
	if dcContinue ~= mc.MC_TRUE then return end
	dcContinue = mc.MC_FALSE
	-- close dust cover here
	dcContinue = mc.MC_TRUE
		
end

local function Pre(compare, msg)
	
	local hSig, hoodState
	dcContinue = mc.MC_FALSE
	ReadIni()
	
	hSig, rcDebug.rc = mc.mcSignalGetHandle(inst, oSig)
	hoodState, rcDebug.rc = mc.mcSignalGetState(hSig)
	if ( hoodState == compare ) then
		-- do nothing
		rcCommon.ShowMessage( TYPE_LOG, LEVEL_INFORMATION, string.format("rcDustCover: already %s.", msg ) )
        return
    end
	-- is machine homed and enabled?
	if rcCommon.GetHomedEnabled() ~= mc.MC_TRUE then return end
	-- record state
	--rc = mc.mcCntlMachineStatePush( inst )
	rcGCode.StartState()
	dcContinue = mc.MC_TRUE
	
end

function rcDustCover.PreOpen()
	
	Pre( 1, "open" )
	
end

function rcDustCover.PreClose()
	
	Pre( 0, "closed" )
	
end

local function Post( set, msg )
	
	local hSig
	rcCommon.ShowMessage( TYPE_LOG, LEVEL_INFORMATION, string.format( "rcDustCover: %s.", msg ) )
	rcGCode.EndState()
	-- restore state
	--rcDebug.rc = mc.mcCntlMachineStatePop( inst )
	hSig, rcDebug.rc = mc.mcSignalGetHandle(inst, oSig)
	rcDebug.rc = mc.mcSignalSetState(hSig, set)
	dcContinue = mc.MC_FALSE
	
end

function rcDustCover.PostOpen()
	
	if dcContinue ~= mc.MC_TRUE then
		--open aborted
		Post( 0, "aborted" )
	else
		--open succeeded
		Post( 1, "open" )
	end	
	
end

function rcDustCover.PostClose()
	
	if dcContinue ~= mc.MC_TRUE then
		Post( 1, "aborted" )
	else
		Post( 0, "closed" )
	end	
	
end

function rcDustCover.GetContinue()
	
	return dcContinue
	
end

return rcDustCover

--[[
MINSTANCE mInst = 0;
HMCSIG hSig;
int rc;
rc = mcSignalGetHandle(mInst, ISIG_INPUT1 &hSig);
if (rc == MERROR_NOERROR) {
	rc = mcSignalHandleWait(hSig, WAIT_MODE_HIGH, .5);
	switch (rc) {
	case MERROR_NOERROR:
		// Signal changed state from low to high
		break;
	case MERROR_TIMED_OUT:
		// The signal didn't change state in the alotted time.
		break;
	case MERROR_NOT_ENABLED:	
		// The control was not enabled at the time of the 
		function call or the control was disabled during the function call.
		break;
	}
}

]]
