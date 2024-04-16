local RapidChangeLogger = {}

function RapidChangeLogger.LogErrorMachAPI(code, name)
  local header = string.format("[Mach API Error] %i %s", code, name)
  local date = os.date("!*t")
  local dateStamp = string.format("%02i:%02i:%02i %02i/%02i/%0i", date.hour, date.min, date.sec, date.month, date.day, date.year)
  local callStack = string.gsub(debug.traceback(), "\t", "    ")

  local file = io.open("CrashReports\\rapidchange_atc_error_log.txt", "a")

	if file ~= nil then
		file:write(dateStamp .. " " .. header .. "\n",
    "  " .. callStack .. "\n\n")
		file:close()
	end
end

return RapidChangeLogger