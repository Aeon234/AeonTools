---@class addon
local addon = select(2, ...)
local addonName = select(1, ...)

local L = {} -- Locale
local API = {} -- Custom APIs used by this addon
local Commands = {} -- Commands
addon.Commands = Commands
addon.L = L
addon.API = API

local type = type
local pairs = pairs
local lower = string.lower

addon.Expressway = "Interface/AddOns/AeonTools/Assets/Expressway.TTF"
addon.fontList = {
	{ path = "Fonts\\ARIALN.TTF", name = "Arial Narrow" },
	{ path = addon.Expressway, name = "Expressway" },
	{ path = "Fonts\\FRIZQT__.TTF", name = "Friz Quadrata" },
	{ path = "Fonts\\MORPHEUS.TTF", name = "Morpheus" },
	{ path = "Fonts\\SKURRI.TTF", name = "Skurri" },
}
addon.fontByPath = {
	["Fonts\\ARIALN.TTF"] = "Arial Narrow",
	[addon.Expressway] = "Expressway",
	["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata",
	["Fonts\\MORPHEUS.TTF"] = "Morpheus",
	["Fonts\\SKURRI.TTF"] = "Skurri",
}

local DEFAULT_VALUES = {
	DebugMode = false,
	EditModeShow = true,
	-- UI Scale
	UIScale = false,
	UIScaleNum = nil,
	-- Escape Menu Scale
	EscapeMenuScale = false,
	EscapeMenuScaleNum = 0.8,
	-- Cooldown Manager Slash Command
	CooldownManagerSlash = false,
	-- Instance Difficulty
	InstanceDifficulty = false,
	InstanceDifficultySettings = {
		align = "TOPLEFT",
		fontSize = 12,
		fontName = "Fonts\\FRIZQT__.TTF",
		fontOutline = "OUTLINE",
		offsetX = 0,
		offsetY = 0,
	},
	-- Can't Release
	CantRelease = false,
	-- Information Popups
	InformationalPopups = false,
	InformationalPopupsSettings = {
		duration = 3,
		fontName = "Fonts\\FRIZQT__.TTF",
		fontSize = 22,
		posX = nil,
		posY = nil,
		popupTypes = {
			combat = false,
			petMissing = false,
			petPassive = false,
		},
		messages = {
			COMBAT_START = { r = 0.929, g = 0.188, b = 0.243, a = 1 },
			COMBAT_END = { r = 0.451, g = 0.506, b = 1, a = 1 },
			PET_MISSING = { r = 0.522, g = 0.427, b = 0.914, a = 1 },
			PET_PASSIVE = { r = 0.882, g = 0.882, b = 0.882, a = 1 },
		},
	},
	-- Current Expansion Only
	CurrentExpansionFilter = false,
	-- Alt Power Bar Status Text
	AltPowerText = false,
	-- Enlarge Objective & Error Text
	EnlargeObjectiveText = false,
	EnlargeObjectiveTextSettings = {
		fontName = "Fonts\\FRIZQT__.TTF",
		fontSize = 22,
	},
	-- Extra Action Button Click Through
	ExtraActionButtonEnhanced = false,
	ExtraActionButtonHideArt = false,
	-- Cursor Ring
	CursorRing = false,
	CursorRingSettings = {
		combat = false,
		gcdRing = false,
		dot = false,
		size = 56,
		color = nil,
	},
	-- Focus Shortcut
	FocusShortcut = false,
	FocusShortcutSettings = {
		modifier = "SHIFT",
		mouseBtn = "BUTTON1",
		focusTarget = false,
		setMark = false,
		raidMarker = 1,
	},
	-- Raid Markers Bar
	RaidMarkersBar = false,
	RaidMarkersBarSettings = {
		mouseOver = false,
		tooltip = true,
		visibility = "DEFAULT", --"Always Display", "Default", "In Party"
		backdrop = true,
		backdropSpacing = 1,
		buttonSize = 32,
		buttonBackdrop = true,
		buttonSpacing = 3,
		orientation = 1,
		modifier = "SHIFT",
		readyCheck = true,
		countDown = true,
		countDownTime = 12,
		inverse = false,
		posX = nil,
		posY = nil,
	},
	-- World Marker Cycler
	WorldMarkerCycler = false,
	WorldMarkerCyclerSettings = {
		order = { 1, 2, 3, 4, 5, 6, 7, 8 },
		markers = {
			[1] = true, -- Star
			[2] = true, -- Circle
			[3] = true, -- Diamond
			[4] = true, -- Triangle
			[5] = true, -- Moon
			[6] = true, -- Square
			[7] = true, -- Cross
			[8] = true, -- Skull
		},
		placerKeybind = nil,
		removerKeybind = nil,
	},
	-- Prey Bar
	PreyBar = false,
	PreyBarSettings = {
		barOnly = false,
	},
}

-- Keybinds
_G["BINDING_NAME_CLICK AeonTools_WMC_Placer:LeftButton"] = "World Marker Cycler"
_G["BINDING_NAME_CLICK AeonTools_WMC_Remover:LeftButton"] = "World Marker Erase"

-- Load Database
local function MergeDefaults(current, defaults)
	for key, defaultValue in pairs(defaults) do
		local savedValue = current[key]

		if savedValue == nil then
			if type(defaultValue) == "table" then
				current[key] = {}
				MergeDefaults(current[key], defaultValue)
			else
				current[key] = defaultValue
			end
		elseif type(defaultValue) == "table" and type(savedValue) == "table" then
			MergeDefaults(savedValue, defaultValue)
		end
	end
end

local function LoadDatabase()
	AeonToolsDB = AeonToolsDB or {}
	addon.db = AeonToolsDB
	if ElvUI then
		addon.db.UIScale = false
	end

	MergeDefaults(addon.db, DEFAULT_VALUES)

	DEFAULT_VALUES = nil
end

-- Callback Registry
local CallbackRegistry = {}
CallbackRegistry.events = {}
addon.CallbackRegistry = CallbackRegistry
do
	function CallbackRegistry:Register(event, func, owner)
		if not self.events[event] then
			self.events[event] = {}
		end

		local callbackType

		if type(func) == "string" then
			callbackType = 2
		else
			callbackType = 1
		end

		tinsert(self.events[event], { callbackType, func, owner })
	end

	CallbackRegistry.RegisterCallback = CallbackRegistry.Register

	function CallbackRegistry:Trigger(event, ...)
		if self.events[event] then
			for _, cb in ipairs(self.events[event]) do
				if cb[1] == 1 then
					if cb[3] then
						cb[2](cb[3], ...)
					else
						cb[2](...)
					end
				else
					cb[3][cb[2]](cb[3], ...)
				end
			end
		end
	end

	function CallbackRegistry:RegisterSettingCallback(dbKey, func, owner)
		self:Register("SettingChanged." .. dbKey, func, owner)
	end

	function CallbackRegistry:UnregisterCallback(event, callback, owner)
		if not owner then
			return
		end

		if self.events[event] then
			local callbacks = self.events[event]
			local i = 1
			local cb = callbacks[i]

			if type(callback) == "string" then
				while cb do
					if cb[1] == 2 and cb[2] == callback and cb[3] == owner then
						tremove(callbacks, i)
					else
						i = i + 1
					end
					cb = callbacks[i]
				end
			else
				while cb do
					if cb[1] == 1 and cb[2] == callback and cb[3] == owner then
						tremove(callbacks, i)
					else
						i = i + 1
					end
					cb = callbacks[i]
				end
			end
		end
	end

	function CallbackRegistry:UnregisterCallbackOwner(event, owner)
		if not owner then
			return
		end

		if self.events[event] then
			local callbacks = self.events[event]
			local i = 1
			local cb = callbacks[i]
			while cb do
				if cb[3] == owner then
					tremove(callbacks, i)
				else
					i = i + 1
				end
				cb = callbacks[i]
			end
		end
	end
end

-- Slash Commands
function addon:RegisterSlashCommand(name, aliases, func)
	if type(aliases) == "string" then
		aliases = { aliases }
	elseif type(aliases) ~= "table" then
		addon:PrintDebug("RegisterSlashCommand requires aliases to be string or table")
		return
	end

	name = name:upper()

	if SlashCmdList[name] ~= nil then
		addon:PrintDebug("Slash command '" .. name .. "' already exists, skipping registration.")
	end

	for i, alias in ipairs(aliases) do
		_G["SLASH_" .. name .. i] = "/" .. lower(alias)
	end

	SlashCmdList[name] = function(msg)
		func(msg)
	end
end

function addon:RegisterSlashSubCommand(name, func)
	if type(name) ~= "string" or type(func) ~= "function" then
		addon:PrintDebug("RegisterSlashSubCommand requires (string, function)")
		return
	end
	name = name:lower()
	addon.Commands[name] = func
end

local function SlashHandler(msg)
	local cmd, rest = msg:match("^(%S+)%s*(.*)$")
	cmd = cmd and cmd:lower()

	if not cmd then
		if not InCombatLockdown() then
			Settings.OpenToCategory(addon.SettingsID)
		end
		return
	end

	local func = addon.Commands[cmd]
	if func then
		func(rest)
		return
	end

	addon:Print("Available commands:")
	for name in pairs(addon.Commands) do
		addon:Print("   - " .. name)
	end
end

addon:RegisterSlashCommand("RL", "rl", function()
	C_UI.Reload()
end)
addon:RegisterSlashCommand("AEONTOOLS", { "at", "aeontools" }, SlashHandler)
addon:RegisterSlashSubCommand("debug", function()
	addon.db.DebugMode = not addon.db.DebugMode
	if addon.db.DebugMode then
		addon:Print("DEBUG: |cff19ff19Activated|r")
	else
		addon:Print("DEBUG: |c3fff2114Disabled|r")
	end
end)

-- Bootstrap
local ADDON_LOADED = CreateFrame("Frame")
ADDON_LOADED:RegisterEvent("ADDON_LOADED")
ADDON_LOADED:RegisterEvent("PLAYER_ENTERING_WORLD")

ADDON_LOADED:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name == addonName then
			self:UnregisterEvent(event)
			LoadDatabase()
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent(event)
		addon.SettingsPanel:InitializeModules()
	end
end)
