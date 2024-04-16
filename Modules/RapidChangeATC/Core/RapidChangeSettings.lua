local RapidChangeSettings = {}
--RapidChange constants
local k = rcConstants

--Get Mach4 instance
local inst = mc.mcGetInstance()

local RC_SECTION = "RapidChangeATC"

--Setting definition creation helpers
local function createDefinition(key, label, description, settingType, defaultValue, options)
  defaultValue = defaultValue or 0
  options = options or {}

  return {
    key = key,
    label = label,
    description = description,
    settingType = settingType,
    defaultValue = defaultValue,
    options = options
  }
end

local function createOptionDefinition(key, label, description, options)
  local value = options[1].value
  --wx.wxMessageBox(string.format("Value: %i", value))
  return createDefinition(key, label, description, k.OPTION_SETTING, value, options)
end

--Setting definitions defined in display order for UI looping
local definitions = {
  --Tool Change
  createOptionDefinition(k.ALIGNMENT, "Alignment", "Axis on which the magazine is aligned.", k.ALIGNMENT_OPTIONS),
  createOptionDefinition(k.DIRECTION, "Direction", "Direction of travel from Pocket 1 to Pocket 2.", k.DIRECTION_OPTIONS),
  createDefinition(k.POCKET_COUNT, "Pocket Count", "The number of tool pockets in your magazine.", k.COUNT_SETTING),
  createDefinition(k.POCKET_OFFSET, "Pocket Offset", "Distance between pockets (center-to-center) along the alignment axis.", k.UDISTANCE_SETTING),
  createDefinition(k.X_POCKET_1, "X Pocket 1", "X Position (Machine Coordinates) of the center of Pocket 1.", k.DISTANCE_SETTING),
  createDefinition(k.Y_POCKET_1, "Y Pocket 1", "Y Position (Machine Coordinates) of the center of Pocket 1.", k.DISTANCE_SETTING),
  createDefinition(k.X_MANUAL, "X Manual", "X Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  createDefinition(k.Y_MANUAL, "Y Manual", "Y Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  --createDefinition(k.Z_MANUAL, "Z Manual", "Z Position (Machine Coordinates) for manual tool changes.", k.DISTANCE_SETTING),
  -- Comment:  I'd like to create the "Z Manual" setting for those that can't access the manual tool change position easily at k.Z_SAFE_CLEARANCE or 0
  createDefinition(k.Z_ENGAGE, "Z Engage", "Z Position (Machine Coordinates) for full engagement with the clamping nut.", k.DISTANCE_SETTING),
  createDefinition(k.Z_MOVE_TO_LOAD, "Z Move To Load", "Z Position to rise to after unloading a tool, before moving to the pocket for loading.", k.DISTANCE_SETTING),
  createDefinition(k.Z_MOVE_TO_PROBE, "Z Move To Probe", "Z Position to rise to after loading a tool, before moving to the tool setter for probing.", k.DISTANCE_SETTING),
  createDefinition(k.Z_SAFE_CLEARANCE, "Z Safe Clearance", "Z Position for the safe clearance of all obstacles.", k.DISTANCE_SETTING),
  createDefinition(k.LOAD_RPM, "Load RPM", "Spindle speed for loading a tool (Clockwise operation).", k.RPM_SETTING),
  createDefinition(k.UNLOAD_RPM, "Unload RPM", "Spindle speed for unloading a tool (Counterclockwise operation).", k.RPM_SETTING),
  createDefinition(k.ENGAGE_FEED_RATE, "Engage Feed Rate", "Feed rate for the engagement process.", k.FEED_SETTING),

  --Tool Touch Off
  --TODO: Add Probe input selection for tool setter?
  -- Comment:  there is the beginning of some code in RapidChangeController.lua
  createDefinition(k.TOUCH_OFF_ENABLED, "Tool Touch Off Enabled", "Calls the configured Tool Touch Off M-Code after loading a tool.", k.SWITCH_SETTING),
  createOptionDefinition(k.TOUCH_OFF_G_CODE, "Tool Setter G-Code", "G-Code for Tool Setter probe signal", k.PROBE_CODE_OPTIONS),  
  createDefinition(k.TOOL_SETTER_INTERNAL, "Tool Setter Internal", "When enabled the dust cover will open for independent tool touch offs.", k.SWITCH_SETTING),
  createDefinition(k.X_TOOL_SETTER, "X Tool Setter", "X Position (Machine Coordinates) of the center of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Y_TOOL_SETTER, "Y Tool Setter", "Y Position (Machine Coordinates) of the center of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Z_TOOL_SETTER, "Z Tool Setter", "Z Position (Machine Coordinates) of the top plate of the tool setter.", k.DISTANCE_SETTING),
  createDefinition(k.Z_SEEK_START, "Z Seek Start", "Z Position (Machine Coordinates) to begin the initial(seek) probe.", k.DISTANCE_SETTING),
  --createDefinition(k.SEEK_MAX_DISTANCE, "Seek Max Distance", "Maximum distance of travel from Z Seek Start on initial probe. Used to calculate a probe target and guard against gross over travel.", k.UDISTANCE_SETTING),
  createDefinition(k.SEEK_OVERSHOOT, "Seek Overshoot", "Maximum distance of travel beyond expected probe strike.", k.DISTANCE_SETTING),
  createDefinition(k.SEEK_FEED_RATE, "Seek Feed Rate", "Feedrate for the initial(seek) probe.", k.FEED_SETTING),
  createDefinition(k.SEEK_RETREAT, "Seek Retreat", "Distance to retreat after trigger, before a subsequent(set) probe.", k.UDISTANCE_SETTING),
  createDefinition(k.SET_FEED_RATE, "Set Feed Rate", "Feedrate for any subsequent(seek) probe.", k.FEED_SETTING),
  createOptionDefinition(k.TOOL_DIAMETER_OFFSET, "Tool Diameter Offset", "Offset directions to allow for tool diameters larger than tool height setter diameter.", k.TOOL_DIAMETER_OFFSET_OPTIONS),
  createDefinition(k.TOOL_SETTER_DIAMETER, "Tool Setter Diameter", "Diameter of tool height setter.", k.DISTANCE_SETTING),  

  --Tool Recognition
  createDefinition(k.TOOL_REC_ENABLED, "Tool Recognition Enabled", "Enable infrared tool recognition.", k.SWITCH_SETTING),
  createDefinition(k.TOOL_REC_OVERRIDE, "Tool Recognition Override", "When enabled will override the default disable behavior of pausing for user confirmation.", k.SWITCH_SETTING),
  createOptionDefinition(k.IR_INPUT, "IR Input", "Input # for the tool recognition IR sensor.", k.INPUT_SIGNAL_OPTIONS),
  createOptionDefinition(k.BEAM_BROKEN_STATE, "Beam Broken State", "The state of the IR input when the beam is broken..", k.BEAM_BROKEN_STATE_OPTIONS),
  createDefinition(k.Z_ZONE_1, "Z Zone 1", "Z Position (Machine Coordinates) for confirming the absence of a nut when unloading and the presence of a nut when loading.", k.DISTANCE_SETTING),
  createDefinition(k.Z_ZONE_2, "Z Zone 2", "Z Position (Machine Coordinates) for confirming complete threading when loading.", k.DISTANCE_SETTING),

  --Dust Cover
  createDefinition(k.COVER_ENABLED, "Dust Cover Enabled", "Enable programmatic dust cover control.", k.SWITCH_SETTING),
  createOptionDefinition(k.COVER_CONTROL, "Dust Cover Control", "Method for controlling the dust cover programmatically.", k.COVER_CONTROL_OPTIONS),
  createOptionDefinition(k.COVER_AXIS, "Dust Cover Axis", "Designated axis for controlling the dust cover with axis control.", k.COVER_AXIS_OPTIONS),
  createDefinition(k.COVER_OPEN_POS, "Dust Cover Open Position", "Designated axis position (machine coordinates) at which the dust cover is fully open.", k.DISTANCE_SETTING),
  createDefinition(k.COVER_CLOSED_POS, "Dust Cover Closed Position", "Designated axis position (machine coordinates) at which the dust cover is fully closed.", k.DISTANCE_SETTING),
  createOptionDefinition(k.COVER_OUTPUT, "Dust Cover Output", "Output # for controlling the dust cover.", k.OUTPUT_SIGNAL_OPTIONS),
  createDefinition(k.COVER_DWELL, "Dust Cover Dwell", "Dwell time (seconds) to allow an output controlled dust cover to fully open or close.", k.DWELL_SETTING),
  createDefinition(k.COVER_OPEN_M_CODE, "Dust Cover Open M-Code", "The assigned M-Code for opening the dust cover.", k.MCODE_SETTING),
  createDefinition(k.COVER_CLOSE_M_CODE, "Dust Cover Close M-Code", "The assigned M-Code for closing the dust cover.", k.MCODE_SETTING),
}

local function isChecked(value)
  if value == k.ENABLED then
    return true
  elseif value == k.DISABLED then
    return false
  else
    return nil
  end
end

local function getOptionLabels(options)
  local labels = {}

  for i, v in ipairs(options) do
    labels[i] = v.label
  end

  return labels
end

local function getOptionValues(options)
  local values = {}

  for i, v in ipairs(options) do
    values[i] = v.value
  end

  return values
end

--[[
local function getSelectedIndex(options, value)
  for i, v in ipairs(options) do
    if v.value == value then
      return i
    else
      return 0
    end
  end
end
]]
local function getSelectedIndex(options, value)
	local retIndex = 0
	for i=1,#options do
		if (options[i].value == value) then
			retIndex = i
			break
		end
	end
	return retIndex
end
	
--Setting Provider helper functions
local function createUISetting(definition)
  local value = RapidChangeSettings.GetValue(definition.key)

  return {
    key = definition.key,
    label = definition.label,
    description = definition.description,
    settingType = definition.settingType,
    optionLabels = getOptionLabels(definition.options),
	optionValues = getOptionValues(definition.options),
    selectedIndex = getSelectedIndex(definition.options, value),
    isChecked = isChecked(value),
    value = value,
  }
end

--Setting Providers

--Local lookup map
local function buildDefinitionMap()
  local map = {}

  for _, v in ipairs(definitions) do
    if v.key ~= nil then
      map[v.key] = v
    end
  end

  return map
end

local definitionMap = buildDefinitionMap()

function RapidChangeSettings.GetRequiredDataType( settingType)
	
	local ValueType = {
		[k.DISTANCE_SETTING] 	= function ( ) return "float" end,
		[k.UDISTANCE_SETTING] 	= function ( ) return "float" end,
		[k.FEED_SETTING] 		= function ( ) return "float" end,
		[k.RPM_SETTING] 		= function ( ) return "float" end,
		[k.MCODE_SETTING] 		= function ( ) return "integer" end,
		[k.OPTION_SETTING] 		= function ( ) return "integer" end,
		[k.SWITCH_SETTING] 		= function ( ) return "integer" end,
		[k.COUNT_SETTING] 		= function ( ) return "integer" end,
		-- [k.PORT_SETTING] 	= function ( ) return "integer" end,
		-- [k.PIN_SETTING] 		= function ( ) return "integer" end,
		[k.DWELL_SETTING] 		= function ( ) return "float" end,
	}	
	
	return ValueType [ settingType ] ( )
	
end
--Retrieve a setting's value
function RapidChangeSettings.GetValue(key)
	
	local definition = definitionMap[key]

	if RapidChangeSettings.GetRequiredDataType( definition.settingType) == "float" then
		return mc.mcProfileGetDouble(inst, RC_SECTION, definition.key, definition.defaultValue)
	elseif RapidChangeSettings.GetRequiredDataType( definition.settingType) == "integer" then
		return mc.mcProfileGetInt(inst, RC_SECTION, definition.key, definition.defaultValue)
	elseif RapidChangeSettings.GetRequiredDataType( definition.settingType) == "string" then
		return mc.mcProfileGetString(inst, RC_SECTION, definition.key, definition.defaultValue)
	end
	
end


function RapidChangeSettings.GetCurrentSettings()
  
  local settings = {}

  for _, value in ipairs(definitions) do
    settings[value.key] = RapidChangeSettings.GetValue(value.key)
  end

  return settings
  
end

--Get an iterable list of settings for UI controls
function RapidChangeSettings.GetUISettingsList()
  
  local settings = {}

  for i, v in ipairs(definitions) do
    settings[i] = createUISetting(v)
  end

  return settings
  
end

function RapidChangeSettings.SetValue(key, value)
  
	local definition = definitionMap[key]

	if RapidChangeSettings.GetRequiredDataType( definition.settingType) == "float" then
		return mc.mcProfileWriteDouble(inst, RC_SECTION, definition.key, value)
		
	elseif RapidChangeSettings.GetRequiredDataType( definition.settingType) == "integer" then
		return mc.mcProfileWriteInt(inst, RC_SECTION, definition.key, value)
		
	elseif RapidChangeSettings.GetRequiredDataType( definition.settingType) == "string" then
		return mc.mcProfileWriteString(inst, RC_SECTION, definition.key, value)
	end
  
end

return RapidChangeSettings
