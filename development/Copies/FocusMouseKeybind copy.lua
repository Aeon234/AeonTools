local _, addon = ...
local L = addon.L
local API = addon.API

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
		"Boss1TargetFrame",
		"Boss2TargetFrame",
		"Boss3TargetFrame",
		"Boss4TargetFrame",
		"Boss5TargetFrame",
	}

	for _, name in ipairs(blizzFrames) do
		local frame = _G[name]
		if frame and not Focus.processedFrames[frame] then
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
	if not UF or not UF.units then
		return
	end
	for unit in pairs(UF.units) do
		local frame = UF[unit]
		if frame and not Focus.processedFrames[frame] then
			self:SetupFrame(frame)
		end
	end
	for unit in pairs(UF.groupunits or {}) do
		local frame = UF[unit]
		if frame and not Focus.processedFrames[frame] then
			self:SetupFrame(frame)
		end
	end
	-- for _, header in pairs(UF.headers or {}) do
	--     if header.GetChildren and header:GetNumChildren() > 0 then
	--         for _, child in pairs({ header:GetChildren() }) do
	--             if child.GetChildren and child:GetNumChildren() > 0 then
	--                 for _, subChild in pairs({ child:GetChildren() }) do
	--                     self:SetupFrame(subChild)
	--                 end
	--             else
	--                 self:SetupFrame(child)
	--             end
	--         end
	--     end
	-- end

	for _, header in pairs(UF.headers) do
		if header.GetChildren and header:GetNumChildren() > 0 then
			for _, child in pairs({ header:GetChildren() }) do
				if child.groupName and child.GetChildren and child:GetNumChildren() > 0 then
					for _, subChild in pairs({ child:GetChildren() }) do
						if subChild and not Focus.processedFrames[subChild] then
							self:SetupFrame(subChild)
						end
					end
				end
			end
		end
	end
end

-- oUF
function Focus:SetupoUFrames()
	local oUF = oUF
	if not oUF or not oUF.objects then
		return
	end

	for _, obj in next, oUF.objects do
		if not Focus.processedFrames[obj] then
			self:SetupFrame(obj)
		end
	end
end

-- Cell
function Focus:SetupCellFrames()
	if not Cell or not Cell.unitButtons then
		return
	end

	for _, group in pairs(Cell.unitButtons) do
		for _, button in pairs(group) do
			if not Focus.processedFrames[button] then
				self:SetupFrame(button)
			end
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

	for _, name in ipairs(UUF) do
		local frame = _G[name]
		if frame and not Focus.processedFrames[frame] then
			self:SetupFrame(frame)
		end
	end

	for _, name in ipairs(EQOL) do
		local frame = _G[name]
		if frame and not Focus.processedFrames[frame] then
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
				if DF.partyFrames[i] and not Focus.processedFrames[DF.partyFrames[i]] then
					self:SetupFrame(DF.partyFrames[i])
				end
			end
		end
		if DF.raidFrames then
			for i = 1, 40 do
				if DF.raidFrames[i] and not Focus.processedFrames[DF.raidFrames[i]] then
					self:SetupFrame(DF.raidFrames[i])
				end
			end
		end
	end
end

-- Setup Frames
function Focus:SetupFrame(frame)
	if not frame then
		return
	end

	local unit = frame:GetAttribute("unit")
	if not unit then
		return
	end

	-- Skip nameplates (they often have their own mouseover logic)
	-- local name = frame.GetName and frame:GetName()
	-- if name and (name:match("^NamePlate") or name:match("Nameplate") or name:match("oUF_NPs")) then
	--     return
	-- end

	if not InCombatLockdown() then
		local db = addon.db.FocusShortcutSettings
		if not db then
			return
		end

		local btnNum = strsub(db.mouseBtn, 7, 7)
		frame:SetAttribute(db.modifier .. "-type" .. btnNum, "focus")

		self.pendingFrames[frame] = nil
		self.processedFrames[frame] = true
	else
		self.pendingFrames[frame] = true
	end
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
		tinsert(lines, "/tm [@focus,exists] 0")
		tinsert(lines, "/tm [@focus,exists] " .. db.raidMarker)
		-- tinsert(lines, "/tm [@focus,noexists] 0")
	end

	return tconcat(lines, "\n")
end

function Focus:UpdateKeybind()
	if not self.button or InCombatLockdown() then
		return
	end
	local db = addon.db and addon.db.FocusShortcutSettings
	if not db then
		return
	end

	ClearOverrideBindings(self.button)

	local btnNum = strsub(db.mouseBtn, 7, 7)
	self.button:SetAttribute("type" .. btnNum, "macro")
	self.button:SetAttribute("macrotext", self:GetMacroText())
	self.button:RegisterForClicks("AnyDown")
	SetOverrideBindingClick(self.button, true, db.modifier .. "-" .. db.mouseBtn, "AeonToolsFocusButton")
end

-- Options
function Focus:ModifierUpdate()
	Focus:UpdateKeybind()
end

local Options_Modifier_Dropdown = API.CreateDropdownOptions(
	"FocusShortcutSettings.modifier",
	API.ModifierDropdownOptions(),
	nil,
	function()
		Focus:UpdateKeybind()
	end
)

function Focus:FocusShortcutUpdate()
	Focus:UpdateKeybind()
end

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
		addon.db.FocusShortcutSettings.focusTarget = not state
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
		if next(Focus.pendingFrames) then
			for frame in next, Focus.pendingFrames do
				self:SetupFrame(frame)
			end
		end
		Focus:SetupAllSources()
	elseif event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(1, function()
			Focus:SetupAllSources()
		end)
	elseif event == "GROUP_ROSTER_UPDATE" then
		C_Timer.After(0.5, function()
			Focus:SetupAllSources()
		end)
	else
		Focus:SetupAllSources()
	end
end)

function Focus:Enable()
	self:Show()
	local db = addon.db and addon.db.FocusShortcutSettings
	if not db then
		return
	end
	if not self.button then
		self.button = CreateFrame("Button", "AeonToolsFocusButton", UIParent, "SecureActionButtonTemplate")
		self.button:SetAttribute("type" .. strsub(db.mouseBtn, 7, 7), "macro")
		self.button:SetAttribute("macrotext", self:GetMacroText())
		self.button:RegisterForClicks("AnyDown")
		SetOverrideBindingClick(self.button, true, db.modifier .. "-" .. db.mouseBtn, "AeonToolsFocusButton")
	end

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	Focus:SetupAllSources()
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
		categoryID = 2,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
