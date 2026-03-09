---@class addon
local addon = select(2, ...)
local L = addon.L

local CantRelease = CreateFrame("Frame")
local releaseText = _G["DEATH_RELEASE"] or L["CRes_Message"]
local crTrigger = 0

local REGISTERED_EVENTS = {
	PLAYER_DEAD = true,
	PLAYER_UNGHOST = true,
	PLAYER_ALIVE = true,
	PLAYER_ENTERING_WORLD = true,
}

StaticPopupDialogs["AEONTOOLS_WANT_TO_RELEASE"] = {
	text = L["CRes_Popup"],
	button1 = YES,
	OnAccept = function()
		crTrigger = 1
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
	preferredIndex = 3,
}

function CantRelease:Initialize()
	CantRelease:SetScript("OnEvent", function(_, e, ...)
		if e == "PLAYER_DEAD" and UnitIsDeadOrGhost("player") and StaticPopup1Button1:GetText() == releaseText then
			crTrigger = 0
			StaticPopup_Show("AEONTOOLS_WANT_TO_RELEASE")
		elseif e == "PLAYER_UNGHOST" or e == "PLAYER_ALIVE" then
			StaticPopup_Hide("AEONTOOLS_WANT_TO_RELEASE")
		end
	end)

	CantRelease:SetScript("OnUpdate", function()
		if StaticPopup1:IsShown() then
			local btn = StaticPopup1Button1
			if btn and btn:GetText() == releaseText and btn:GetButtonState() == "NORMAL" then
				if crTrigger == 0 then
					btn:Disable()
				else
					btn:Enable()
				end
			end
		end
	end)
end

function CantRelease:Enable()
	for event in pairs(REGISTERED_EVENTS) do
		self:RegisterEvent(event)
	end
	CantRelease:Initialize()
end

function CantRelease:Disable()
	CantRelease:UnregisterAllEvents()
	CantRelease:SetScript("OnEvent", nil)
	CantRelease:SetScript("OnUpdate", nil)
end

do
	local function EnableModule(state)
		if state then
			CantRelease:Enable()
		else
			CantRelease:Disable()
		end
	end

	local moduleData = {
		name = L["CRes_Title"],
		dbKey = "CantRelease",
		description = L["CRes_Desc"],
		toggleFunc = EnableModule,
		categoryID = 5,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
