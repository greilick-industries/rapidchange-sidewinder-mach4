local RapidChangeErrorHandler = {}

local inst = mc.mcGetInstance()

local function showAPIError(rc)
  --TODO: Handle ERROR_NOT_NOW from gcode execution better
  --[[
  Comment:  https://www.machsupport.com/forum/index.php?topic=36507.0
            The workaround goes something like this:
          1) Try the GcodeExecuteWait() API
          2) Test the return code, if rc=0 the call has succeeded. If rc==MERROR_NOT_NOW then mc.mcCntlEnable(inst,0) mc.mcCntlEnable(inst,1)
          3) Try the GcodeExecuteWait() API call again
          4) By now the return code should be rc==MERROR_NO_ERROR
  ]]
  local errorName = mc.mcCntlGetErrorString(inst, rc)
  local title = "MachAPI Error"
  local header = string.format("MachAPI Error: %i %s\n\n", rc, errorName)
  local message = "A RapidChange script has encountered an unexpected error.\nThe error has been logged. If the problem persists, please contact RapidChange ATC support."

  rcLog.LogErrorMachAPI(rc, errorName)
  wx.wxMessageBox(header .. message, title)
  error(message)
end

function RapidChangeErrorHandler.GuardAPIError(rc)
  if rc == mc.MERROR_NOERROR then
    return
  else
    showAPIError(rc)
  end
end

function RapidChangeErrorHandler.Throw(message, title)
  title = title or "RapidChange ATC Error"
  message = message or "An unexpected error occured. No message provided."
  wx.wxMessageBox(message, title)
  error(message)
end

return RapidChangeErrorHandler
