---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local _G = _G
local format = format
local gsub = gsub
local pairs = pairs
local select = select
local CreateFrame = CreateFrame
local GetInstanceInfo = GetInstanceInfo
local IsInInstance = IsInInstance
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local C_ChallengeMode_GetActiveKeystoneInfo = C_ChallengeMode.GetActiveKeystoneInfo

local REGISTERED_EVENTS = {
	PLAYER_ENTERING_WORLD = true,
	CHALLENGE_MODE_START = true,
	CHALLENGE_MODE_COMPLETED = true,
	CHALLENGE_MODE_RESET = true,
	PLAYER_DIFFICULTY_CHANGED = true,
	GUILD_PARTY_STATE_UPDATED = true,
	ZONE_CHANGED_NEW_AREA = true,
	GROUP_ROSTER_UPDATE = true,
}

local LFR_SUFFIX = format("|cffff8000%s|r", "LFR")
local NORM_SUFFIX = format("|cff1eff00%s|r", "N")
local HERO_SUFFIX = format("|cff0070dd%s|r", "H")
local MYTH_SUFFIX = format("|cffa335ee%s|r", "M")

local DIFFICULTY_STRINGS = {
	["PvP"] = format("|cffFFFF00%s|r", "PvP"),
	["5-player Normal"] = "5" .. NORM_SUFFIX,
	["5-player Heroic"] = "5" .. HERO_SUFFIX,
	["10-player Normal"] = "10" .. NORM_SUFFIX,
	["25-player Normal"] = "25" .. NORM_SUFFIX,
	["10-player Heroic"] = "10" .. HERO_SUFFIX,
	["25-player Heroic"] = "25" .. HERO_SUFFIX,
	["LFR"] = LFR_SUFFIX,
	["Mythic Keystone"] = format("|cffff3860%s|r", "M+") .. "%mplus%",
	["40-player"] = "40",
	["Normal Scenario"] = format("%s %s", NORM_SUFFIX, "Scen"),
	["Heroic Scenario"] = format("%s %s", HERO_SUFFIX, "Scen"),
	["Mythic Scenario"] = format("%s %s", MYTH_SUFFIX, "Scen"),
	["Normal Raid"] = "%numPlayers%" .. NORM_SUFFIX,
	["Heroic Raid"] = "%numPlayers%" .. HERO_SUFFIX,
	["Mythic Raid"] = "%numPlayers%" .. MYTH_SUFFIX,
	["LFR Raid"] = "%numPlayers%" .. LFR_SUFFIX,
	["Event Scenario"] = "EScen",
	["Mythic Party"] = "5" .. MYTH_SUFFIX,
	["Timewalking"] = "TW",
	["World PvP Scenario"] = format("|cffFFFF00%s |r", "PvP"),
	["PvEvP Scenario"] = "PvEvP",
	["Timewalking Raid"] = "TW",
	["PvP Heroic"] = format("|cffFFFF00%s |r", "PvP"),
	["Warfronts Normal"] = "WF",
	["Warfronts Heroic"] = format("|cffff7d0aH|r%s", "WF"),
	["Normal Scaling Party"] = "NSP",
	["Visions of N'Zoth"] = "Visions",
	["Teeming Island"] = "Teeming",
	["Torghast"] = "Torghast",
	["Path of Ascension: Courage"] = "PoA",
	["Path of Ascension: Loyalty"] = "PoA",
	["Path of Ascension: Wisdom"] = "PoA",
	["Path of Ascension: Humility"] = "PoA",
	["World Boss"] = "WB",
	["Challenge Level 1"] = "CL1",
	["Follower"] = "Follower",
	["Delves"] = "Delves",
	["Quest"] = "Quest",
	["Story"] = "Story",
}
local DIFFICULTY_BY_ID = {
	[-1] = DIFFICULTY_STRINGS["PvP"],
	[1] = DIFFICULTY_STRINGS["5-player Normal"],
	[2] = DIFFICULTY_STRINGS["5-player Heroic"],
	[3] = DIFFICULTY_STRINGS["10-player Normal"],
	[4] = DIFFICULTY_STRINGS["25-player Normal"],
	[5] = DIFFICULTY_STRINGS["10-player Heroic"],
	[6] = DIFFICULTY_STRINGS["25-player Heroic"],
	[7] = DIFFICULTY_STRINGS["LFR"],
	[8] = DIFFICULTY_STRINGS["Mythic Keystone"],
	[9] = DIFFICULTY_STRINGS["40-player"],
	[11] = DIFFICULTY_STRINGS["Heroic Scenario"],
	[12] = DIFFICULTY_STRINGS["Normal Scenario"],
	[14] = DIFFICULTY_STRINGS["Normal Raid"],
	[15] = DIFFICULTY_STRINGS["Heroic Raid"],
	[16] = DIFFICULTY_STRINGS["Mythic Raid"],
	[17] = DIFFICULTY_STRINGS["LFR Raid"],
	[18] = DIFFICULTY_STRINGS["Event Scenario"],
	[19] = DIFFICULTY_STRINGS["Event Scenario"],
	[20] = DIFFICULTY_STRINGS["Event Scenario"],
	[23] = DIFFICULTY_STRINGS["Mythic Party"],
	[24] = DIFFICULTY_STRINGS["Timewalking"],
	[25] = DIFFICULTY_STRINGS["World PvP Scenario"],
	[29] = DIFFICULTY_STRINGS["PvEvP Scenario"],
	[30] = DIFFICULTY_STRINGS["Event Scenario"],
	[32] = DIFFICULTY_STRINGS["World PvP Scenario"],
	[33] = DIFFICULTY_STRINGS["Timewalking Raid"],
	[34] = DIFFICULTY_STRINGS["PvP Heroic"],
	[38] = DIFFICULTY_STRINGS["Normal Scenario"],
	[39] = DIFFICULTY_STRINGS["Heroic Scenario"],
	[40] = DIFFICULTY_STRINGS["Mythic Scenario"],
	[45] = DIFFICULTY_STRINGS["PvP"],
	[147] = DIFFICULTY_STRINGS["Warfronts Normal"],
	[149] = DIFFICULTY_STRINGS["Warfronts Heroic"],
	[150] = DIFFICULTY_STRINGS["Normal Scaling Party"],
	[151] = DIFFICULTY_STRINGS["LFR"],
	[152] = DIFFICULTY_STRINGS["Visions of N'Zoth"],
	[153] = DIFFICULTY_STRINGS["Teeming Island"],
	[167] = DIFFICULTY_STRINGS["Torghast"],
	[168] = DIFFICULTY_STRINGS["Path of Ascension: Courage"],
	[169] = DIFFICULTY_STRINGS["Path of Ascension: Loyalty"],
	[170] = DIFFICULTY_STRINGS["Path of Ascension: Wisdom"],
	[171] = DIFFICULTY_STRINGS["Path of Ascension: Humility"],
	[172] = DIFFICULTY_STRINGS["World Boss"],
	[192] = DIFFICULTY_STRINGS["Challenge Level 1"],
	[205] = DIFFICULTY_STRINGS["Follower"],
	[208] = DIFFICULTY_STRINGS["Delves"],
	[216] = DIFFICULTY_STRINGS["Quest"],
	[220] = DIFFICULTY_STRINGS["Story"],
}

local ID = CreateFrame("Frame", "InstanceDifficultyFrame", _G.Minimap)
ID:SetScript("OnEvent", function(self, event, ...)
	self:UpdateFrame()
end)

-- Frame Updates
function ID:LoadPosition()
	local db = addon.db and addon.db.InstanceDifficultySettings
	if not db or not self then
		return
	end

	local difficulty = _G.MinimapCluster.InstanceDifficulty
	local container = _G.MinimapCluster.MinimapContainer

	difficulty:ClearAllPoints()

	local anchor = db.align or "TOPLEFT"

	difficulty:SetPoint(anchor, container, anchor, db.offsetX, db.offsetY)
end

function ID:UpdateFrame()
	local inInstance, instanceType = IsInInstance()
	local difficulty = select(3, GetInstanceInfo())
	local numplayers = select(9, GetInstanceInfo())
	local mplusdiff = select(1, C_ChallengeMode_GetActiveKeystoneInfo()) or ""

	if difficulty == 0 then
		self.text:SetText("")
	elseif instanceType == "party" or instanceType == "raid" or instanceType == "scenario" then
		local text = DIFFICULTY_BY_ID[difficulty]

		if not text then
			addon:PrintDebug(format("difficutly %s not found", difficulty))
			text = ""
		end

		text = gsub(text, "%%mplus%%", mplusdiff)
		text = gsub(text, "%%numPlayers%%", numplayers)
		self.text:SetText(text)
	elseif instanceType == "pvp" or instanceType == "arena" then
		self.text:SetText(DIFFICULTY_BY_ID[-1])
	else
		self.text:SetText("")
	end

	self:SetShown(inInstance)
end

function ID:SettingsUpdate()
	local db = addon.db and addon.db.InstanceDifficultySettings
	if not db or not self then
		return
	end

	self.text:SetFont(db.fontName, db.fontSize, db.fontOutline)
	self:LoadPosition()
end

-- Create Frame
function ID:ConstructFrame()
	local db = addon.db and addon.db.InstanceDifficultySettings
	if not db or not self then
		return
	end
	local difficulty = _G.MinimapCluster.InstanceDifficulty

	self:SetSize(30, 20)
	self:SetPoint("CENTER", difficulty, "CENTER", 0, 0)

	local text = self:CreateFontString(nil, "OVERLAY")
	text:SetFont(db.fontName or addon.Expressway, db.fontSize or 12, db.fontOutline)
	text:SetPoint("LEFT")

	self.text = text

	self.hooked = true
end

-- Options
function ID:SettingsExampleTest()
	local inInstance, _ = IsInInstance()

	if self:IsShown() and inInstance then
		return
	elseif self:IsShown() and not self.OptionFrame:IsShown() then
		self.text:Hide()
	else
		self.text:SetText("|cffff3860M+|r21")
		self.text:Show()
	end
end

local function Options_TextAlign(value)
	addon.db.InstanceDifficultySettings.align = value
	addon.db.InstanceDifficultySettings.offsetX = 0
	addon.db.InstanceDifficultySettings.offsetY = 0
	if ID.OptionFrame then
		local sx = ID.OptionFrame:FindWidget("ID_OffsetX")
		if sx and sx.SetValue then
			sx:SetValue(0)
		end
		local sy = ID.OptionFrame:FindWidget("ID_OffsetY")
		if sy and sy.SetValue then
			sy:SetValue(0)
		end
	end
	ID:SettingsUpdate()
end

local function Options_FontSize(value)
	addon.db.InstanceDifficultySettings.fontSize = value
	ID:SettingsUpdate()
end

local function Options_OffsetX(value)
	addon.db.InstanceDifficultySettings.offsetX = value
	ID:SettingsUpdate()
end

local function Options_OffsetY(value)
	addon.db.InstanceDifficultySettings.offsetY = value
	ID:SettingsUpdate()
end

local Options_TextAlign_Content = API.CreateDropdownOptions(
	"InstanceDifficultySettings.align",
	API.AlignmentDropdownOptions(),
	nil,
	function(value)
		Options_TextAlign(value)
	end
)

local Options_FontName_Dropdown = API.CreateDropdownOptions(
	"InstanceDifficultySettings.fontName",
	API.SharedMediaFontDropdownOptions(),
	nil,
	function()
		ID:SettingsUpdate()
	end
)

local Options_FontFlag_Dropdown = API.CreateDropdownOptions(
	"InstanceDifficultySettings.fontOutline",
	API.FontFlagDropdownOptions(),
	nil,
	function()
		ID:SettingsUpdate()
	end
)

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["ID_Title"],
	widgets = {
		{
			type = "Dropdown",
			label = L["ID_Alignment"],
			menuData = Options_TextAlign_Content,
		},
		{
			type = "Dropdown",
			label = L["FontName"],
			menuData = Options_FontName_Dropdown,
		},
		{
			type = "Dropdown",
			label = L["FontFlag"],
			menuData = Options_FontFlag_Dropdown,
		},
		{
			type = "Slider",
			label = L["FontSize"],
			minValue = 5,
			maxValue = 60,
			valueStep = 1,
			onValueChangedFunc = Options_FontSize,
			formatValueFunc = API.ReturnWholeNum,
			dbKey = "InstanceDifficultySettings.fontSize",
		},
		{
			type = "Slider",
			label = L["ID_OffsetX"],
			minValue = -50,
			maxValue = 50,
			valueStep = 1,
			onValueChangedFunc = Options_OffsetX,
			formatValueFunc = API.ReturnWholeNum,
			dbKey = "InstanceDifficultySettings.offsetX",
			widgetKey = "ID_OffsetX",
		},
		{
			type = "Slider",
			label = L["ID_OffsetY"],
			minValue = -50,
			maxValue = 50,
			valueStep = 1,
			onValueChangedFunc = Options_OffsetY,
			formatValueFunc = API.ReturnWholeNum,
			dbKey = "InstanceDifficultySettings.offsetY",
			widgetKey = "ID_OffsetY",
		},
	},
}

function ID:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function ID:ShowOptions(state)
	if state then
		self:CreateOptions(true)
		self.OptionFrame:Show()
		self.OptionFrame:SetScript("OnHide", function()
			ID:SettingsExampleTest()
		end)
		ID:SettingsExampleTest()
		if self.OptionFrame.requireResetPosition then
			self.OptionFrame.requireResetPosition = false
			self.OptionFrame:ClearAllPoints()
			self.OptionFrame:SetPoint("LEFT", UIParent, "CENTER", 256, 0)
		end
	else
		if self.OptionFrame then
			self.OptionFrame:HideOption(self)
		end
	end
end

-- Enable/Disable
function ID:ADDON_LOADED(_, addon)
	if addon == "Blizzard_Minimap" then
		self:UnregisterEvent("ADDON_LOADED")

		local difficulty = _G.MinimapCluster.InstanceDifficulty
		self:LoadPosition()
		for _, frame in pairs({ difficulty.Default, difficulty.Guild, difficulty.ChallengeMode }) do
			frame:SetAlpha(0)
		end
	end
end

function ID:Enable()
	for event in pairs(REGISTERED_EVENTS) do
		ID:RegisterEvent(event)
	end

	self:ConstructFrame()

	if C_AddOns_IsAddOnLoaded("Blizzard_Minimap") then
		self:ADDON_LOADED("ADDON_LOADED", "Blizzard_Minimap")
	else
		self:RegisterEvent("ADDON_LOADED")
	end

	self:SettingsUpdate()
end

function ID:Disable()
	ID:UnregisterAllEvents()
	if self.hooked then
		self:Hide()
		addon:ReloadPopUp()
	end
end

do
	local function EnableModule(state)
		if state then
			ID:Enable()
		else
			ID:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = ID.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			ID:ShowOptions(false)
		else
			ID:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["ID_Title"],
		dbKey = "InstanceDifficulty",
		description = L["ID_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 2,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
