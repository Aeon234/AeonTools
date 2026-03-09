---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L
local db

local InCombatLockdown = InCombatLockdown
local ElvUI = ElvUI

local UIScale = CreateFrame("Frame")

local REGISTERED_EVENTS = {
	PLAYER_ENTERING_WORLD = true,
	UI_SCALE_CHANGED = true,
	DISPLAY_SIZE_CHANGED = true,
	EDIT_MODE_LAYOUTS_UPDATED = true,
	PLAYER_REGEN_ENABLED = true,
}

-- Pixel Perfect Scaling
local function PixelPerfectScale()
	local _, screenHeight = GetPhysicalScreenSize()
	if screenHeight and screenHeight > 0 then
		return 768 / screenHeight
	end
end

-- UI Updates
local function UpdateHeader(scale)
	if UIScale.OptionFrame then
		local header = UIScale.OptionFrame:FindWidget("CurrentScaleHeader")
		if header then
			header:SetText(L["UIScale_CurrentScale"] .. tostring(scale))
		end
	end
end
local function ApplyScale(scale)
	if not scale or scale <= 0 then
		return
	end
	UIParent:SetScale(scale)
	UIScale.UIScaleNum = scale
	db.UIScaleNum = scale
	UpdateHeader(scale)
end

-- Event Handler
local function UIScale_EventHandler(self, event)
	if ElvUI then
		UIScale:Disable()
		return
	end
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	local scale = db.UIScaleNum
	if not scale then
		scale = PixelPerfectScale()
	end
	ApplyScale(scale)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

-- Settings
local function SetPixelPerfect()
	local scale = PixelPerfectScale()
	ApplyScale(scale)
end

local function SetScale_1080()
	local scale = 768 / 1080
	ApplyScale(scale)
end

local function SetScale_1440()
	local scale = 768 / 1440
	ApplyScale(scale)
end

local function SetScale_4k()
	local scale = 768 / 2160
	ApplyScale(scale)
end

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["UIScale_Title"],
	widgets = {
		{
			type = "Header",
			label = L["UIScale_CurrentScale"] .. tostring(UIScale.UIScaleNum),
			widgetKey = "CurrentScaleHeader",
		},
		{
			type = "UIPanelButton",
			label = L["UIScale_PP_Label"],
			tooltip = L["UIScale_Btn_PPTooltip"],
			buttonText = "Set Pixel Perfect",
			onClickFunc = SetPixelPerfect,
			widgetKey = "PPScaleButton",
		},
		{
			type = "UIPanelButton",
			label = L["UIScale_1080_Label"],
			tooltip = L["UIScale_Btn_Tooltip"] .. L["UIScale_1080_Label"],
			buttonText = "Set Pixel Perfect",
			onClickFunc = SetScale_1080,
			widgetKey = "PPScaleButton_1080",
		},
		{
			type = "UIPanelButton",
			label = L["UIScale_1440_Label"],
			tooltip = L["UIScale_Btn_Tooltip"] .. L["UIScale_1440_Label"],
			buttonText = "Set Pixel Perfect",
			onClickFunc = SetScale_1440,
			widgetKey = "PPScaleButton_1440",
		},
		{
			type = "UIPanelButton",
			label = L["UIScale_4k_Label"],
			tooltip = L["UIScale_Btn_Tooltip"] .. L["UIScale_4k_Label"],
			buttonText = "Set Pixel Perfect",
			onClickFunc = SetScale_4k,
			widgetKey = "PPScaleButton_4k",
		},
	},
}

function UIScale:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function UIScale:ShowOptions(state, forceUpdate)
	if state then
		self:CreateOptions(forceUpdate)
		self.OptionFrame:Show()
		UpdateHeader(UIScale.UIScaleNum or UIParent:GetEffectiveScale())
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
function UIScale:Enable()
	self.enabled = true
	if not db or ElvUI then
		UIScale:UnregisterAllEvents()
		return
	end
	local scale
	if db.UIScaleNum then
		scale = db.UIScaleNum
	else
		scale = PixelPerfectScale()
	end
	ApplyScale(scale)

	for event in pairs(REGISTERED_EVENTS) do
		UIScale:RegisterEvent(event)
	end
	UIScale:SetScript("OnEvent", UIScale_EventHandler)
end

function UIScale:Disable()
	UIScale:UnregisterAllEvents()
	UIScale:SetScript("OnEvent", nil)
	if self.enabled then
		addon:ReloadPopUp()
	end
end

do
	local function EnableModule(state)
		db = addon.db
		if state then
			UIScale:Enable()
		else
			UIScale:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = UIScale.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			UIScale:ShowOptions(false)
		else
			UIScale:ShowOptions(true)
		end
	end

	local moduleData = {
		name = (ElvUI and L["UIScale_Title_Disabled"] or L["UIScale_Title"]),
		dbKey = "UIScale",
		description = (ElvUI and L["UIScale_Desc_Disabled"] or L["UIScale_Desc"]),
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 1,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
