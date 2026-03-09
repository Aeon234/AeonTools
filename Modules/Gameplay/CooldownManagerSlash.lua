---@class addon
local addon = select(2, ...)
local L = addon.L

local CDMS = CreateFrame("Frame")
local InCombatLockdown = InCombatLockdown
local _G = _G

function CDMS:ShowCDM()
	local CooldownViewerSettings = _G.CooldownViewerSettings
	if InCombatLockdown() or not CooldownViewerSettings then
		return
	end

	if not CooldownViewerSettings:IsShown() then
		CooldownViewerSettings:Show()
	else
		CooldownViewerSettings:Hide()
	end
end

function CDMS:Enable()
	if CDMS._hooked then
		return
	end

	addon:RegisterSlashCommand("CDMS", "cd", function()
		CDMS:ShowCDM()
	end)

	CDMS._hooked = true
end

function CDMS:Disable()
	if not CDMS._hooked then
		return
	end
	SlashCmdList.CDMS = nil
	SLASH_CDMS1 = nil
	CDMS._hooked = false
end

do
	local function EnableModule(state)
		if state then
			CDMS:Enable()
		else
			CDMS:Disable()
		end
	end

	local moduleData = {
		name = L["CDMS_Title"],
		dbKey = "CooldownManagerSlash",
		description = L["CDMS_Desc"],
		toggleFunc = EnableModule,
		categoryID = 3,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
