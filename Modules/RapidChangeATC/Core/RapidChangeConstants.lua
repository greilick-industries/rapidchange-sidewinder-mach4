local RapidChangeConstants = {}

-- Setting Types
RapidChangeConstants.DISTANCE_SETTING = 0
RapidChangeConstants.UDISTANCE_SETTING = 1
RapidChangeConstants.FEED_SETTING = 2
RapidChangeConstants.RPM_SETTING = 3
RapidChangeConstants.MCODE_SETTING = 4
RapidChangeConstants.OPTION_SETTING = 5
RapidChangeConstants.SWITCH_SETTING = 6
RapidChangeConstants.COUNT_SETTING = 7
-- RapidChangeConstants.PORT_SETTING = 8
-- RapidChangeConstants.PIN_SETTING = 9
RapidChangeConstants.DWELL_SETTING = 10

--UI Control Types
RapidChangeConstants.INPUT_CONTROL = 0
RapidChangeConstants.CHECK_CONTROL = 1
RapidChangeConstants.RADIO_CONTROL = 2
RapidChangeConstants.SELECT_CONTROL = 3
RapidChangeConstants.LISTBOX_CONTROL = 4
RapidChangeConstants.CHOICE_CONTROL = 5
RapidChangeConstants.SPIN_CONTROL = 6

-- Signal State
RapidChangeConstants.INACTIVE = 0
RapidChangeConstants.ACTIVE = 1

-- Switch Setting state
RapidChangeConstants.DISABLED = 0
RapidChangeConstants.ENABLED = 1

-- True/False
RapidChangeConstants.FALSE = 0
RapidChangeConstants.TRUE = 1

-- Units
RapidChangeConstants.INCHES = 20
RapidChangeConstants.MILLIMETERS = 21

-- Directions
RapidChangeConstants.NEGATIVE = -1
RapidChangeConstants.POSITIVE = 1

--Axes
RapidChangeConstants.X_AXIS = mc.X_AXIS
RapidChangeConstants.Y_AXIS = mc.Y_AXIS
RapidChangeConstants.Z_AXIS = mc.Z_AXIS
RapidChangeConstants.A_AXIS = mc.A_AXIS
RapidChangeConstants.B_AXIS = mc.B_AXIS
RapidChangeConstants.C_AXIS = mc.C_AXIS

--Dust Cover
RapidChangeConstants.COVER_CONTROL_AXIS = 0
RapidChangeConstants.COVER_CONTROL_OUTPUT = 1

--IR State
RapidChangeConstants.ACTIVE_BROKEN = 0
RapidChangeConstants.ACTIVE_CLEAR = 1

--Probes
RapidChangeConstants.PROBE = 0
RapidChangeConstants.PROBE_1 = 1
RapidChangeConstants.PROBE_2 = 2
RapidChangeConstants.PROBE_3 = 3

--Tool DiameterOffset
RapidChangeConstants.X_AXIS_NEGATIVE_Y_AXIS_NEGATIVE = 1
RapidChangeConstants.X_AXIS_POSITIVE_Y_AXIS_NEGATIVE = 2
RapidChangeConstants.X_AXIS_NEGATIVE_Y_AXIS_POSITIVE = 3
RapidChangeConstants.Y_AXIS_POSITIVE_Y_AXIS_POSITIVE = 4

--Setting Keys
--Tool change
RapidChangeConstants.UNITS = "Units"
RapidChangeConstants.ALIGNMENT = "Alignment"
RapidChangeConstants.DIRECTION = "Direction"
RapidChangeConstants.POCKET_COUNT = "PocketCount"
RapidChangeConstants.POCKET_OFFSET = "PocketOffset"
RapidChangeConstants.X_POCKET_1 = "XPocket1"
RapidChangeConstants.Y_POCKET_1 = "YPocket1"
RapidChangeConstants.X_MANUAL = "XManual"
RapidChangeConstants.Y_MANUAL = "YManual"
RapidChangeConstants.Z_ENGAGE = "ZEngage"
RapidChangeConstants.Z_MOVE_TO_LOAD = "ZMoveToLoad"
RapidChangeConstants.Z_MOVE_TO_PROBE = "ZMoveToProbe"
RapidChangeConstants.Z_SAFE_CLEARANCE = "ZSafeClearance"
RapidChangeConstants.LOAD_RPM = "LoadRPM"
RapidChangeConstants.UNLOAD_RPM = "UnloadRPM"
RapidChangeConstants.ENGAGE_FEED_RATE = "EngageFeedRate"

--Touch off
RapidChangeConstants.TOUCH_OFF_ENABLED = "TouchOffEnabled"
RapidChangeConstants.TOOL_SETTER_INTERNAL = "ToolSetterInternal"
RapidChangeConstants.TOUCH_OFF_G_CODE = "TouchOffGCode"
RapidChangeConstants.X_TOOL_SETTER = "XToolSetter"
RapidChangeConstants.Y_TOOL_SETTER = "YToolSetter"
RapidChangeConstants.Z_TOOL_SETTER = "ZToolSetter"
RapidChangeConstants.Z_SEEK_START = "ZSeekStart"
RapidChangeConstants.SEEK_MAX_DISTANCE = "SeekMaxDistance"
RapidChangeConstants.SEEK_OVERSHOOT = "SeekOvershoot"
RapidChangeConstants.SEEK_FEED_RATE = "SeekFeedRate"
RapidChangeConstants.SEEK_RETREAT = "SeekRetreat"
RapidChangeConstants.SET_FEED_RATE = "SetFeedRate"
RapidChangeConstants.TOOL_DIAMETER_OFFSET = "ToolDiameterOffset"
RapidChangeConstants.TOOL_SETTER_DIAMETER = "ToolSetterDiameter"

--Tool recognition
RapidChangeConstants.TOOL_REC_ENABLED = "ToolRecognitionEnabled"
RapidChangeConstants.TOOL_REC_OVERRIDE = "ToolRecognitionOverride"
-- RapidChangeConstants.IR_PORT = "IRPort"
-- RapidChangeConstants.IR_PIN = "IRPin"
RapidChangeConstants.IR_INPUT = "IRInput"
RapidChangeConstants.BEAM_BROKEN_STATE = "BeamBrokenState"
RapidChangeConstants.Z_ZONE_1 = "ZZone1"
RapidChangeConstants.Z_ZONE_2 = "ZZone2"

--Dust Cover
RapidChangeConstants.COVER_ENABLED = "DustCoverEnabled"
RapidChangeConstants.COVER_CONTROL = "DustCoverControl"
RapidChangeConstants.COVER_AXIS = "DustCoverAxis"
RapidChangeConstants.COVER_OPEN_POS = "DustCoverOpenPos"
RapidChangeConstants.COVER_CLOSED_POS = "DustCoverClosedPos"
-- RapidChangeConstants.COVER_PORT = "DustCoverPort"
-- RapidChangeConstants.COVER_PIN = "DustCoverPin"
RapidChangeConstants.COVER_OUTPUT = "DustCoverOutput"
RapidChangeConstants.COVER_DWELL = "DustCoverDwell"
RapidChangeConstants.COVER_OPEN_M_CODE = "DustCoverOpenMCode"
RapidChangeConstants.COVER_CLOSE_M_CODE = "DustCoverCloseMCode"

--Hooks
RapidChangeConstants.BEFORE_CHANGE_M_CODE = "BeforeChangeMCode"
RapidChangeConstants.AFTER_CHANGE_M_CODE = "AfterChangeMCode"

-- Options
RapidChangeConstants.ALIGNMENT_OPTIONS = {
  { value = RapidChangeConstants.X_AXIS, label = "X Axis" },
  { value = RapidChangeConstants.Y_AXIS, label = "Y Axis" },
}

RapidChangeConstants.DIRECTION_OPTIONS = {
  { value = RapidChangeConstants.NEGATIVE, label = "Negative" },
  { value = RapidChangeConstants.POSITIVE, label = "Positive" },
}

RapidChangeConstants.PROBE_CODE_OPTIONS = {
	{ value = RapidChangeConstants.PROBE, label = "31" },
	{ value = RapidChangeConstants.PROBE_1, label = "31.1" },
	{ value = RapidChangeConstants.PROBE_2, label = "31.2" },
	{ value = RapidChangeConstants.PROBE_3, label = "31.3" },
}
RapidChangeConstants.TOOL_DIAMETER_OFFSET_OPTIONS = {
	{ value = RapidChangeConstants.DISABLED, label = "Disabled" },
	{ value = RapidChangeConstants.X_AXIS_NEGATIVE_Y_AXIS_NEGATIVE, label = "X -, Y -" },
	{ value = RapidChangeConstants.X_AXIS_POSITIVE_Y_AXIS_NEGATIVE, label = "X +, Y -" },
	{ value = RapidChangeConstants.X_AXIS_NEGATIVE_Y_AXIS_POSITIVE, label = "X -, Y +" },
	{ value = RapidChangeConstants.Y_AXIS_POSITIVE_Y_AXIS_POSITIVE, label = "Y +, Y +" },
}

RapidChangeConstants.COVER_AXIS_OPTIONS = {
  { value = RapidChangeConstants.A_AXIS, label = "A Axis" },
  { value = RapidChangeConstants.B_AXIS, label = "B Axis" },
  { value = RapidChangeConstants.C_AXIS, label = "C Axis" },
}

RapidChangeConstants.COVER_CONTROL_OPTIONS = {
  { value = RapidChangeConstants.COVER_CONTROL_AXIS, label = "Axis" },
  { value = RapidChangeConstants.COVER_CONTROL_OUTPUT, label = "Output" },
}

RapidChangeConstants.BEAM_BROKEN_STATE_OPTIONS = {
  { value = RapidChangeConstants.ACTIVE, label = "Active" },
  { value = RapidChangeConstants.INACTIVE, label = "Inactive" },
}

RapidChangeConstants.UNIT_OPTIONS = {
  { value = RapidChangeConstants.MILLIMETERS, label = "Millimeters" },
  { value = RapidChangeConstants.INCHES, label = "Inches" },
}

-- Signal Options
local function buildSignalOptions(isInput)
  local options = {}

  local prefix
  if isInput then
    prefix = "Input #"
  else
    prefix = "Output #"
  end

  for i = 0, 63 do
    options[i + 1] = {
      value = i,
      label = prefix .. i
    }
  end

  return options
end

RapidChangeConstants.INPUT_SIGNAL_OPTIONS = buildSignalOptions(true)
RapidChangeConstants.OUTPUT_SIGNAL_OPTIONS = buildSignalOptions(false)

return RapidChangeConstants
