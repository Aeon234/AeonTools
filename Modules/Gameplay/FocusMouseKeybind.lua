---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local ElvUI = ElvUI
local Cell = Cell
local oUF = oUF
local DandersFrames = DandersFrames

local InCombatLockdown = InCombatLockdown
local SetOverrideBindingClick = SetOverrideBindingClick
local ClearOverrideBindings = ClearOverrideBindings
local CreateFrame = CreateFrame
local next = next
local pairs = pairs
local strmatch = strmatch
local strsub = strsub
local strjoin = strjoin
local tinsert = table.insert
local tconcat = table.concat

local Focus = CreateFrame("Frame")
Focus.processedFrames = {}
Focus.pendingFrames = {}
Focus.button = nil

local function IsNameplateFrame(frame)
	if not frame or not frame.GetName then
		return false
	end
	local name = frame:GetName()
	if not name then
		return false
	end
	return strmatch(name, "^NamePlate") or strmatch(name, "Nameplate") or strmatch(name, "oUF_NPs")
end

-- Blizzard Frames
function Focus:SetupBlizzardFrames()
	local blizzFrames = {
		"PlayerFrame",
		"PetFrame",
		"TargetFrame",
		"TargetFrameToT",
		"FocusFrame",
		"PartyMemberFrame1",
		"PartyMemberFrame2",
		"PartyMemberFrame3",
		"PartyMemberFrame4",
		"CompactPartyFrameMember1",
		"CompactPartyFrameMember2",
		"CompactPartyFrameMember3",
		"CompactPartyFrameMember4",
		"CompactPartyFrameMember5",
		"Boss1TargetFrame",
		"Boss2TargetFrame",
		"Boss3TargetFrame",
		"Boss4TargetFrame",
		"Boss5TargetFrame",
	}

	for _, name in ipairs(blizzFrames) do
		local frame = _G[name]
		if frame then
			self:SetupFrame(frame)
		end
	end
end

-- ElvUI
function Focus:SetupElvUIFrames()
	local E = ElvUI and ElvUI[1]
	if not E then
		return
	end

	local UF = E:GetModule("UnitFrames")
	if not UF then
		return
	end

	if UF.units then
		for unit in pairs(UF.units) do
			local frame = UF[unit]
			if frame then
				self:SetupFrame(frame)
			end
		end
	end

	if UF.groupunits then
		for unit in pairs(UF.groupunits) do
			local frame = UF[unit]
			if frame then
				self:SetupFrame(frame)
			end
		end
	end

	if UF.headers then
		for _, header in pairs(UF.headers) do
			if header.GetChildren and header:GetNumChildren() > 0 then
				for _, child in pairs({ header:GetChildren() }) do
					if child.groupName and child.GetChildren and child:GetNumChildren() > 0 then
						for _, subChild in pairs({ child:GetChildren() }) do
							if subChild then
								self:SetupFrame(subChild)
							end
						end
					else
						self:SetupFrame(child)
					end
				end
			end
		end
	end
end

-- oUF
function Focus:SetupoUFrames()
	if not oUF or not oUF.objects then
		return
	end

	for _, obj in next, oUF.objects do
		self:SetupFrame(obj)
	end
end

-- Cell
function Focus:SetupCellFrames()
	if not Cell or not Cell.unitButtons then
		return
	end

	for _, group in pairs(Cell.unitButtons) do
		for _, button in pairs(group) do
			self:SetupFrame(button)
		end
	end
end

-- Other Frames
function Focus:SetupOtherFrames()
	local UUF = {
		"UUF_Player",
		"UUF_Pet",
		"UUF_Target",
		"UUF_TargetTarget",
		"UUF_Focus",
		"UUF_FocusTarget",
		"UUF_Boss1",
		"UUF_Boss2",
		"UUF_Boss3",
		"UUF_Boss4",
		"UUF_Boss5",
		"UUF_Boss6",
		"UUF_Boss7",
		"UUF_Boss8",
		"UUF_Boss9",
		"UUF_Boss10",
	}

	for _, name in ipairs(UUF) do
		local frame = _G[name]
		if frame then
			self:SetupFrame(frame)
		end
	end

	local EQOL = {
		"EQOLUFPlayerFrame",
		"EQOLUFTargetFrame",
		"EQOLUFToTFrame",
		"EQOLUFFocusFrame",
		"EQOLUFBoss1Frame",
		"EQOLUFBoss2Frame",
		"EQOLUFBoss3Frame",
		"EQOLUFBoss4Frame",
		"EQOLUFBoss5Frame",
	}

	for _, name in ipairs(EQOL) do
		local frame = _G[name]
		if frame then
			self:SetupFrame(frame)
		end
	end

	-- Danders
	local DF = DandersFrames
	if DF then
		if DF.playerFrame then
			self:SetupFrame(DF.playerFrame)
		end
		if DF.partyFrames then
			for i = 1, 4 do
				if DF.partyFrames[i] then
					self:SetupFrame(DF.partyFrames[i])
				end
			end
		end
		if DF.raidFrames then
			for i = 1, 40 do
				if DF.raidFrames[i] then
					self:SetupFrame(DF.raidFrames[i])
				end
			end
		end
	end
end

-- Setup Frames
function Focus:SetupFrame(frame)
	if not frame or self.processedFrames[frame] then
		return
	end

	if frame.GetAttribute and not frame:GetAttribute("unit") then
		return
	end

	-- Skip nameplates (they often have their own mouseover logic)
	-- if IsNameplateFrame(frame) then
	-- 	return
	-- end

	local db = addon.db and addon.db.FocusShortcutSettings
	if not db then
		return
	end

	if InCombatLockdown() then
		self.pendingFrames[frame] = true
		return
	end

	local btnNum = strsub(db.mouseBtn or "BUTTON1", 7, 7)
	if not btnNum or btnNum == "" then
		return
	end

	frame:SetAttribute((db.modifier or "SHIFT") .. "-type" .. btnNum, "focus")

	self.pendingFrames[frame] = nil
	self.processedFrames[frame] = true
end

function Focus:SetupAllSources()
	if InCombatLockdown() then
		return
	end

	self:SetupBlizzardFrames()
	self:SetupElvUIFrames()
	self:SetupoUFrames()
	self:SetupCellFrames()
	self:SetupOtherFrames()
end

-- Keybind
function Focus:GetMacroText()
	local db = addon.db and addon.db.FocusShortcutSettings
	if not db then
		return ""
	end

	local lines = {
		"/clearfocus [@mouseover,noexists]",
	}

	if db.focusTarget then
		tinsert(lines, "/focus [@mouseover,exists] mouseover; target")
	else
		tinsert(lines, "/focus [@mouseover,exists] mouseover")
	end

	if db.setMark and db.raidMarker and db.raidMarker >= 1 and db.raidMarker <= 8 then
		tinsert(lines, "/tm [@focus,exists,help][@focus,exists,harm] 0; /tm 0")
		tinsert(lines, "/tm [@focus,exists,help][@focus,exists,harm] " .. db.raidMarker .. "; /tm 0")
	end

	return tconcat(lines, "\n")
end

function Focus:UpdateKeybind()
	if InCombatLockdown() then
		return
	end

	local db = addon.db and addon.db.FocusShortcutSettings
	if not db then
		return
	end

	if not self.button then
		self.button = CreateFrame("Button", "AeonToolsFocusButton", UIParent, "SecureActionButtonTemplate")
	end

	local button = self.button

	button:SetAttribute("type*", "macro")
	button:SetAttribute("macrotext", self:GetMacroText())
	button:RegisterForClicks("AnyDown")

	ClearOverrideBindings(button)

	local modifier = db.modifier or "SHIFT"
	local mouseBtn = db.mouseBtn or "BUTTON1"
	SetOverrideBindingClick(button, true, modifier .. "-" .. mouseBtn, "AeonToolsFocusButton")
end

-- Options
local Options_Modifier_Dropdown = API.CreateDropdownOptions(
	"FocusShortcutSettings.modifier",
	API.ModifierDropdownOptions(),
	nil,
	function()
		Focus:UpdateKeybind()
	end
)

local Options_Mouse_Dropdown = API.CreateDropdownOptions(
	"FocusShortcutSettings.mouseBtn",
	API.ButtonDropdownOptions(),
	nil,
	function()
		Focus:UpdateKeybind()
	end
)

local Options_RaidMarker_Dropdown = API.CreateDropdownOptions(
	"FocusShortcutSettings.raidMarker",
	API.RaidMarkerDropdownOptions(),
	function()
		return addon.GetDBValue("FocusShortcutSettings.setMark")
	end,
	function()
		Focus:UpdateKeybind()
	end
)

local function Options_FocusTarget(state)
	if InCombatLockdown() then
		if addon.db and addon.db.FocusShortcutSettings then
			addon.db.FocusShortcutSettings.focusTarget = not state
		end
		addon:Print(L["Generic_Combat_Error"])
		addon.UpdateSettingsDialog()
		return
	end
	Focus:UpdateKeybind()
end

local function Options_SetMark()
	addon.UpdateSettingsDialog()
	Focus:UpdateKeybind()
end

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["Focus_Title"],
	widgets = {
		{
			type = "Header",
			label = L["Focus_KeybindHeader"],
		},
		{
			type = "Dropdown",
			label = L["Modifier_Label"],
			tooltip = L["Focus_ModifierTooltip"],
			menuData = Options_Modifier_Dropdown,
		},
		{
			type = "Dropdown",
			label = L["Focus_ButtonLabel"],
			tooltip = L["Focus_ButtonTooltip"],
			dbKey = "FocusShortcutSettings.mouseBtn",
			menuData = Options_Mouse_Dropdown,
		},
		{
			type = "Checkbox",
			label = L["Focus_FocusTargetLabel"],
			tooltip = L["Focus_FocusTargetTooltip"],
			dbKey = "FocusShortcutSettings.focusTarget",
			onClickFunc = Options_FocusTarget,
		},
		{
			type = "Divider",
		},
		{
			type = "Header",
			label = L["Focus_RaidMarkingHeader"],
		},
		{
			type = "Checkbox",
			label = L["Focus_SetMarkLabel"],
			tooltip = L["Focus_SetMarkTooltip"],
			dbKey = "FocusShortcutSettings.setMark",
			onClickFunc = Options_SetMark,
		},
		{
			type = "Dropdown",
			label = L["Focus_MarkNumberLabel"],
			tooltip = L["Focus_MarkNumberTooltip"],
			dbKey = "FocusShortcutSettings.raidMarker",
			menuData = Options_RaidMarker_Dropdown,
		},
	},
}
function Focus:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function Focus:ShowOptions(state)
	if state then
		self:CreateOptions(true)
		self.OptionFrame:Show()
		self.OptionFrame:SetScript("OnHide", function() end)
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
Focus:SetScript("OnEvent", function(self, event, unit, ...)
	if event == "PLAYER_REGEN_ENABLED" then
		if next(self.pendingFrames) then
			for frame in next, self.pendingFrames do
				self:SetupFrame(frame)
			end
		end
		self:SetupAllSources()
	elseif event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(1, function()
			self:SetupAllSources()
		end)
	elseif event == "GROUP_ROSTER_UPDATE" then
		C_Timer.After(0.5, function()
			self:SetupAllSources()
		end)
	else
		self:SetupAllSources()
	end
end)

function Focus:Enable()
	self:Show()

	if not addon.db or not addon.db.FocusShortcutSettings then
		return
	end

	self:UpdateKeybind()

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	self:SetupAllSources()
end

function Focus:Disable()
	self:Hide()
	self:UnregisterAllEvents()

	if self.button then
		ClearOverrideBindings(self.button)
	end

	self.processedFrames = {}
	self.pendingFrames = {}
end

do
	local function EnableModule(state)
		if state then
			Focus:Enable()
		else
			Focus:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = Focus.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			Focus:ShowOptions(false)
		else
			Focus:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["Focus_Title"],
		dbKey = "FocusShortcut",
		description = L["Focus_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 3,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
