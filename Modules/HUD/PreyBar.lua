---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local FadeFrame = API.UIFrameFade

local PreyWidgetID = 7663

local PB = CreateFrame("Frame", nil, EncounterBar)
PB:SetSize(1, 1)
PB:SetPoint("TOP", UIWidgetPowerBarContainerFrame, "BOTTOM", 0, -14)
PB.status = {
	visible = false,
	stage = 0,
	tooltip = "",
}

local REGISTERED_EVENTS = {
	PLAYER_ENTERING_WORLD = true,
	UPDATE_UI_WIDGET = true,
	QUEST_LOG_UPDATE = true,
}

function PB:CreateBar()
	if PB._created then
		return
	end

	local ProgressBar = addon.CreateMetalProgressBar(self, "compact")
	ProgressBar:SetPoint("CENTER", self, "CENTER", 0, 0)
	ProgressBar:SetSmoothFill(true)
	ProgressBar:SetBarColorTint(3)
	ProgressBar:SetNumThreshold(3)
	ProgressBar:SetValue(1, 4, true)
	self.progressBar = ProgressBar

	ProgressBar:SetScript("OnEnter", function(bar)
		local text = PB.status.tooltip
		if not text or text == "" then
			return
		end
		local title, body = text:match("^(.-)|n(.*)$")
		if not title then
			title = ""
			body = text
		end
		GameTooltip:SetOwner(bar, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		if title ~= "" then
			GameTooltip:SetText(title, 1, 1, 1, 1, true)
		end
		GameTooltip:AddLine(body, nil, nil, nil, true)
		GameTooltip:AddLine("|n|cffffd200Progress:|r " .. PB.status.stage .. "/4", 1, 1, 1, true)

		GameTooltip:Show()
	end)
	ProgressBar:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	PB._created = true
end

function PB:UpdatePreyInfo()
	local widgetInfo = C_UIWidgetManager.GetPreyHuntProgressWidgetVisualizationInfo(PreyWidgetID)
	if not widgetInfo then
		return self.status
	end

	self.status.visible = widgetInfo.shownState == 1 and true or false
	self.status.stage = widgetInfo.progressState and (widgetInfo.progressState + 1) or 0
	self.status.tooltip = widgetInfo.tooltip or ""

	return self.status
end

function PB:UpdatePreyBar()
	self.progressBar:SetValue(self.status.stage, 4, true)
end

function PB:UpdateDisplay()
	local barOnly = addon.GetDBValue("PreyBarSettings.barOnly")
	if barOnly then
		PB:ClearAllPoints()
		PB:SetPoint("CENTER", EncounterBar, "CENTER", 0, 0)
		UIWidgetPowerBarContainerFrame:Hide()
	else
		PB:ClearAllPoints()
		PB:SetPoint("TOP", UIWidgetPowerBarContainerFrame, "BOTTOM", 0, -14)
		UIWidgetPowerBarContainerFrame:Show()
	end

	if self.status.visible and self:IsShown() then
		return
	elseif self.status.visible and not self:IsShown() then
		FadeFrame(PB, 0.2, 1)
	elseif not self.status.visible and not self:IsShown() then
		UIWidgetPowerBarContainerFrame:Show()
	else
		FadeFrame(PB, 0.2, 0)
		C_Timer.After(0.5, function()
			PB:ClearAllPoints()
			PB:SetPoint("TOP", UIWidgetPowerBarContainerFrame, "BOTTOM", 0, -14)
			UIWidgetPowerBarContainerFrame:Show()
		end)
	end
end

local function PB_EventHandler(self, event, w)
	local preyInfo = PB:UpdatePreyInfo()
	if event == "PLAYER_ENTERING_WORLD" or event == "QUEST_LOG_UPDATE" then
		if preyInfo and preyInfo.visible == true then
			PB:UpdateDisplay()
			PB:UpdatePreyBar()
			return
		else
			PB:UpdateDisplay()
			PB:UpdatePreyBar()
		end
		return
	end

	if w.widgetID ~= PreyWidgetID then
		return
	end
	PB:UpdatePreyBar()
	PB:UpdateDisplay()
end

-- Options
local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["PB_Title"],
	widgets = {
		{
			type = "Checkbox",
			label = L["PB_BarOnly"],
			dbKey = "PreyBarSettings.barOnly",
			onClickFunc = function()
				PB:UpdateDisplay()
			end,
		},
	},
}

function PB:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function PB:ShowOptions(state)
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
function PB:Enable()
	self:CreateBar()

	for event in pairs(REGISTERED_EVENTS) do
		self:RegisterEvent(event)
	end

	self:SetScript("OnEvent", PB_EventHandler)
	PB_EventHandler(self, "PLAYER_ENTERING_WORLD")
end

function PB:Disable()
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)

	if self:IsVisible() then
		FadeFrame(PB, 0.2, 0)
	end
end

do
	local function EnableModule(state)
		if state then
			PB:Enable()
		else
			PB:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = PB.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			PB:ShowOptions(false)
		else
			PB:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["PB_Title"],
		dbKey = "PreyBar",
		description = L["PB_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 2,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
