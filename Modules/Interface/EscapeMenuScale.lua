---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L
local db

local EscapeMenuScale = CreateFrame("Frame")

function EscapeMenuScale:SetScale(scale)
	GameMenuFrame:SetScale(scale or db.EscapeMenuScaleNum or 1.0)
	GameMenuFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

local function Options_EscapeMenuScaleNum(value)
	db.EscapeMenuScaleNum = value
	EscapeMenuScale:SetScale(value)
end

-- Settings

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["EMS_Title"],
	widgets = {
		{
			type = "Slider",
			label = L["EMS_Slider_Label"],
			minValue = 0.5,
			maxValue = 1.5,
			valueStep = 0.1,
			onValueChangedFunc = Options_EscapeMenuScaleNum,
			formatValueFunc = API.ReturnPercent,
			dbKey = "EscapeMenuScaleNum",
		},
	},
}

function EscapeMenuScale:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function EscapeMenuScale:ShowOptions(state, forceUpdate)
	if state then
		self:CreateOptions(forceUpdate)
		self.OptionFrame:Show()
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

function EscapeMenuScale:Enable()
	self.enabled = true
	self:SetScale(db.EscapeMenuScaleNum)
	GameMenuFrame:HookScript("OnShow", function()
		EscapeMenuScale:SetScale(db.EscapeMenuScaleNum)
	end)
end

function EscapeMenuScale:Disable()
	GameMenuFrame:HookScript("OnShow", function()
		EscapeMenuScale:SetScale(1.0)
	end)
	if self.enabled then
		addon:ReloadPopUp()
	end
end

do
	local function EnableModule(state)
		db = addon.db
		if state then
			EscapeMenuScale:Enable()
		else
			EscapeMenuScale:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = EscapeMenuScale.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			EscapeMenuScale:ShowOptions(false)
		else
			EscapeMenuScale:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["EMS_Title"],
		dbKey = "EscapeMenuScale",
		description = L["EMS_Desc"],
		toggleFunc = EnableModule,
		categoryID = 1,
		optionToggleFunc = OptionToggle_OnClick,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
