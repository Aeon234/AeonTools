---@class addon
local addon = select(2, ...)
local L = addon.L

local EAB = CreateFrame("Frame")

function EAB:ToggleMouse(state)
	EAB.hooked = true
	local enabled = not state

	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", function()
			EAB:ToggleMouse(state)
		end)
		return
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

	if ExtraActionBarFrame then
		ExtraActionBarFrame:EnableMouse(enabled)
	end
	if ExtraAbilityContainer then
		ExtraAbilityContainer:EnableMouse(enabled)
	end
	if ZoneAbilityFrame.Style then
		ZoneAbilityFrame.Style:EnableMouse(enabled)
	end
	if PlayerPowerBarAlt then
		PlayerPowerBarAlt:EnableMouse(enabled)
	end
	if PlayerPowerBarAlt.background then
		PlayerPowerBarAlt.background:EnableMouse(enabled)
	end
end

function EAB:ToggleArt(state)
	if state then
		ExtraActionButton1.style:SetAlpha(0)
		ExtraActionButton1.style:Hide()

		ZoneAbilityFrame.Style:SetAlpha(0)
		ZoneAbilityFrame.Style:Hide()
	else
		ExtraActionButton1.style:SetAlpha(1)
		ExtraActionButton1.style:Show()

		ZoneAbilityFrame.Style:SetAlpha(1)
		ZoneAbilityFrame.Style:Show()
	end
end

-- Settings
local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["EAB_Title"],
	widgets = {
		{
			type = "Checkbox",
			label = L["EAB_HideArt"],
			dbKey = "ExtraActionButtonHideArt",
			onClickFunc = function(state)
				EAB:ToggleArt(state.checked)
			end,
		},
	},
}

function EAB:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function EAB:ShowOptions(state, forceUpdate)
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

-- Enable/Disable
function EAB:Enable()
	self:ToggleMouse(true)
	local hideArt = addon.GetDBValue("ExtraActionButtonHideArt") or false
	self:ToggleArt(hideArt)
end

function EAB:Disable()
	if self and not self.hooked then
		return
	end
	self:ToggleMouse(false)
	self:ToggleArt(false)
end

do
	local function EnableModule(state)
		addon:PrintDebug("ExtraActionButtonEnhanced: ", state and "|cff00ff12ON" or "|cffff2020OFF")
		if state then
			EAB:Enable()
		else
			EAB:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = EAB.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			EAB:ShowOptions(false)
		else
			EAB:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["EAB_Title"],
		dbKey = "ExtraActionButtonEnhanced",
		description = L["EAB_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 1,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
