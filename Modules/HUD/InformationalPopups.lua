---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L
local FadeFrame = API.UIFrameFade

local tremove = table.remove
local tinsert = table.insert

local EVENT_CATEGORIES = {
	combat = {
		PLAYER_REGEN_DISABLED = "RegenDisabled",
		PLAYER_REGEN_ENABLED = "RegenEnabled",
	},

	petMissing = {
		PLAYER_ENTERING_WORLD = "CheckMissingPet",
		PLAYER_REGEN_DISABLED = "CheckMissingPet",
		PLAYER_REGEN_ENABLED = "OnCombatEnd",
		UNIT_PET = "CheckMissingPet",
	},

	petPassive = {
		PLAYER_ENTERING_WORLD = "CheckPassivePet",
		PLAYER_REGEN_DISABLED = "CheckPassivePet",
		PLAYER_REGEN_ENABLED = "OnCombatEnd",
		PET_BAR_UPDATE = "CheckPassivePet",
		UNIT_PET = "CheckPassivePet",
	},
}

local POPUP_CONFIG = {
	height = 30,
	spacing = 5,
	fadeOutDuration = 0.5,
	displayDuration = 3,
	stickyDisplayDuration = 999,
}

local MESSAGE_TEMPLATES = {
	COMBAT_START = {
		type = "COMBAT_START",
		text = "+Combat",
		color = { r = 0.929, g = 0.188, b = 0.243, a = 1 },
		sticky = false,
	},
	COMBAT_END = {
		type = "COMBAT_END",
		text = "-Combat",
		color = { r = 0.451, g = 0.506, b = 1, a = 1 },
		sticky = false,
	},
	PET_MISSING = {
		type = "PET_MISSING",
		text = "Pet Missing",
		color = { r = 0.522, g = 0.427, b = 0.914, a = 1 },
		sticky = true,
	},
	PET_PASSIVE = {
		type = "PET_PASSIVE",
		text = "Pet Passive",
		color = { r = 0.882, g = 0.882, b = 0.882, a = 1 },
		sticky = true,
	},
}

local IPU = CreateFrame("Frame", "AeonToolsPopupsContainer", UIParent)
IPU:SetSize(200, 200)

function IPU:ShowIPU()
	local db = addon.db and addon.db.InformationalPopupsSettings
	self:ClearAllPoints()
	self:Show()
	if db and db.posX and db.posY then
		if db.posX > 0 then
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.posX, db.posY)
		else
			self:SetPoint("TOP", UIParent, "BOTTOM", 0, db.posY)
		end
	else
		IPU:SetPoint("CENTER", 0, 200)
	end
end

-- Popup Containers
IPU.activePopups = {}
IPU.popupsByType = {}
IPU.previewPopups = {}

-- Popup Handling
function IPU:GetMessageTemplate(msgKey)
	local db = addon.db and addon.db.InformationalPopupsSettings.messages
	local template = MESSAGE_TEMPLATES[msgKey]
	if not template then
		return nil
	end

	local popupMsg = {
		type = template.type,
		text = template.text,
		color = template.color,
		sticky = template.sticky,
	}

	if db then
		local dbColor = db[msgKey]
		if dbColor then
			popupMsg.color = dbColor
		end

		return popupMsg
	end
end

function IPU:RepositionPopups()
	local yOffset = 0
	for i, popup in ipairs(IPU.activePopups) do
		local newY = -yOffset

		if self.isEditing or popup.isPreview then
			if popup.moveAG then
				popup.moveAG:Stop()
			end
			popup:ClearAllPoints()
			popup:SetPoint("TOP", self, "TOP", 0, newY)
		else
			local currentTop = popup:GetTop()
			local containerTop = IPU:GetTop()
			local currentY

			if currentTop and containerTop then
				currentY = currentTop - containerTop
			else
				currentY = nil
			end
			if not currentY or math.abs(currentY - newY) < 0.5 then
				if popup.moveAG then
					popup.moveAG:Stop()
				end
				popup:ClearAllPoints()
				popup:SetPoint("TOP", self, "TOP", 0, newY)
			else
				if not popup.moveAG then
					local ag = popup:CreateAnimationGroup()
					local trans = ag:CreateAnimation("Translation")
					trans:SetDuration(0.5)
					trans:SetSmoothing("OUT")
					popup.moveAG = ag
					popup.moveTrans = trans
				end

				popup.moveAG:Stop()
				popup.moveTrans:SetOffset(0, newY - currentY)
				popup.moveAG:SetScript("OnFinished", function()
					popup:ClearAllPoints()
					popup:SetPoint("TOP", IPU, "TOP", 0, newY)
				end)
				popup.moveAG:Play()
			end
		end

		local height = popup:GetHeight()
		yOffset = yOffset + height + POPUP_CONFIG.spacing
	end
end

function IPU:RemovePopup(popup, instant)
	if not popup then
		return
	end
	if popup.animationGroup then
		popup.animationGroup:Stop()
	end
	if popup.moveAG then
		popup.moveAG:Stop()
	end

	for i, p in ipairs(IPU.activePopups) do
		if p == popup then
			tremove(IPU.activePopups, i)
			break
		end
	end

	IPU.popupsByType[popup.type] = nil

	if instant then
		popup:Hide()
		popup:SetParent(nil)
		popup:ClearAllPoints()
		IPU:RepositionPopups()
	else
		local fadeGroup = popup:CreateAnimationGroup()
		local fade = fadeGroup:CreateAnimation("Alpha")
		fade:SetFromAlpha(popup:GetAlpha())
		fade:SetToAlpha(0)
		fade:SetDuration(POPUP_CONFIG.fadeOutDuration)
		fade:SetSmoothing("OUT")

		fadeGroup:SetScript("OnFinished", function()
			popup:Hide()
			popup:SetParent(nil)
			popup:ClearAllPoints()
			IPU:RepositionPopups()
		end)

		fadeGroup:Play()
	end
end

function IPU:ClearStickyPopup(msgType)
	local popup = IPU.popupsByType[msgType]
	if popup and popup.sticky then
		IPU:RemovePopup(popup, false)
	end
end

function IPU:ClearAllPopups()
	if #IPU.activePopups == 0 then
		return
	end

	for i = 1, #IPU.activePopups do
		IPU:RemovePopup(IPU.activePopups[i], true)
	end
end

function IPU:CreatePopup(msg)
	local frame = CreateFrame("Frame", nil, IPU)
	frame:SetSize(IPU:GetWidth(), POPUP_CONFIG.height)
	frame:SetAlpha(0)

	local text = frame:CreateFontString(nil, "ARTWORK")
	local db = addon.db and addon.db.InformationalPopupsSettings
	if db then
		text:SetFont(db.fontName, db.fontSize, "OUTLINE")
	else
		text:SetFont(addon.Expressway, 22, "OUTLINE")
	end
	text:SetPoint("CENTER")
	text:SetJustifyH("CENTER")
	text:SetJustifyV("BOTTOM")
	text:SetText(msg.text)
	text:SetTextColor(msg.color.r, msg.color.g, msg.color.b, msg.color.a)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	frame.text = text

	frame.type = msg.type
	frame.sticky = msg.sticky
	frame.duration = db.duration
	frame.animationGroup = nil

	return frame
end

function IPU:ShowPopup(msgKey)
	local msgData = IPU:GetMessageTemplate(msgKey)
	if not msgData then
		return
	end

	local existingPopup = IPU.popupsByType[msgData.type]

	if existingPopup then
		IPU:RemovePopup(existingPopup, true)
	end

	local popup = IPU:CreatePopup(msgData)
	tinsert(IPU.activePopups, popup)
	IPU.popupsByType[msgData.type] = popup

	IPU:RepositionPopups()
	popup:Show()
	popup:SetAlpha(1)
	if not popup.sticky then
		C_Timer.After(popup.duration, function()
			if popup and popup:IsShown() then
				IPU:RemovePopup(popup, false)
			end
		end)
	end
end

-- Combat Popups
local Combat = CreateFrame("Frame")
function Combat:RegenDisabled()
	if addon.db.InformationalPopupsSettings and addon.db.InformationalPopupsSettings.popupTypes.combat then
		IPU:ShowPopup("COMBAT_START")
	end
end

function Combat:RegenEnabled()
	if addon.db.InformationalPopupsSettings and addon.db.InformationalPopupsSettings.popupTypes.combat then
		IPU:ShowPopup("COMBAT_END")
	end
end

-- Pet Controller & Helpers
local PetController = CreateFrame("Frame")
local PLAYER_CLASS = select(2, UnitClass("player"))
local IS_PET_CLASS = (PLAYER_CLASS == "HUNTER" or PLAYER_CLASS == "WARLOCK" or PLAYER_CLASS == "DEATHKNIGHT")

PetController:SetScript("OnEvent", function(self, event, arg1)
	if event == "PLAYER_SPECIALIZATION_CHANGED" then
		if arg1 == "player" then
			self:UpdateEligibility()
		end
	elseif event == "PLAYER_LEVEL_UP" then
		self:UpdateEligibility()
		self:CheckMissingPet()
	elseif event == "PLAYER_DEAD" then
		IPU:ClearStickyPopup("PET_MISSING")
		IPU:ClearStickyPopup("PET_PASSIVE")
		C_Timer.After(1, function()
			IPU:ClearAllPopups()
		end)
	end
end)

function PetController:ValidDisplayConditions()
	local inInstance, instanceType = IsInInstance()
	if InCombatLockdown() or inInstance and instanceType ~= "interior" and instanceType ~= "neighborhood" then
		return not IsMounted() and not UnitInVehicle("player")
	end
	C_Timer.After(0, function()
		if InCombatLockdown() then
			self:CheckMissingPet()
			self:CheckPassivePet()
		end
	end)
	return false
end

function PetController:OnCombatEnd()
	IPU:ClearStickyPopup("PET_MISSING")
	IPU:ClearStickyPopup("PET_PASSIVE")
end

function PetController:IsEligibleSpec()
	local specIndex = GetSpecialization()
	if not specIndex then
		return false
	end

	local specID = GetSpecializationInfo(specIndex)
	if PLAYER_CLASS == "WARLOCK" then
		return true -- all specs
	elseif PLAYER_CLASS == "HUNTER" then
		return specID == 253 or specID == 255 -- BM or Survival
	elseif PLAYER_CLASS == "DEATHKNIGHT" then
		return specID == 252 -- Unholy
	end

	return false
end

function PetController:UpdateEligibility()
	local db = addon.db and addon.db.InformationalPopupsSettings.popupTypes
	if not db then
		return
	end

	self:UnregisterAllEvents()

	if not IS_PET_CLASS then
		C_Timer.After(0, function()
			IPU:ClearStickyPopup("PET_MISSING")
			IPU:ClearStickyPopup("PET_PASSIVE")
		end)
		return
	end

	if not self:IsEligibleSpec() then
		C_Timer.After(0, function()
			IPU:ClearStickyPopup("PET_MISSING")
			IPU:ClearStickyPopup("PET_PASSIVE")
		end)
		return
	end

	local missingEnabled = db.petMissing
	local passiveEnabled = db.petPassive

	if not (missingEnabled or passiveEnabled) then
		IPU:ClearStickyPopup("PET_MISSING")
		IPU:ClearStickyPopup("PET_PASSIVE")
		return
	end

	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

	if not missingEnabled then
		IPU:ClearStickyPopup("PET_MISSING")
	end
	if not passiveEnabled then
		IPU:ClearStickyPopup("PET_PASSIVE")
	end
end

-- Pet Passive
function PetController:IsPetPassive()
	local name, _, _, isActive = GetPetActionInfo(10)
	return name == "PET_MODE_PASSIVE" and isActive == true
end

function PetController:CheckPassivePet()
	if not IS_PET_CLASS then
		return
	end
	if not UnitExists("pet") then
		return
	end
	if not self:IsEligibleSpec() then
		IPU:ClearStickyPopup("PET_MISSING")
		return
	end

	local validCondition = PetController:ValidDisplayConditions()

	if not validCondition then
		return
	end

	local isPassive = self:IsPetPassive()

	if isPassive then
		IPU:ShowPopup("PET_PASSIVE")
	else
		IPU:ClearStickyPopup("PET_PASSIVE")
	end
end

-- Pet Missing
function PetController:CheckMissingPet()
	if not IS_PET_CLASS then
		return
	end
	if not self:IsEligibleSpec() then
		IPU:ClearStickyPopup("PET_MISSING")
		return
	end

	local validCondition = PetController:ValidDisplayConditions()
	if not validCondition then
		return
	end

	if not UnitExists("pet") then
		IPU:ClearStickyPopup("PET_PASSIVE")
		IPU:ShowPopup("PET_MISSING")
	else
		IPU:ClearStickyPopup("PET_MISSING")
	end
end

-- Edit Mode
function IPU:EditModePreviewPopups(previewKey)
	if not self.enabled then
		return
	end

	local previewOrder

	if previewKey == "COMBAT_START" then
		previewOrder = { "COMBAT_START", "COMBAT_END" }
	elseif previewKey then
		previewOrder = { previewKey }
	else
		previewOrder = {
			"COMBAT_START",
			"COMBAT_END",
			"PET_MISSING",
			"PET_PASSIVE",
		}
	end

	local db = addon.db and addon.db.InformationalPopupsSettings
	if not db then
		return
	end

	local fontName = db.fontName or addon.Expressway
	local fontSize = db.fontSize or 22

	for i = 1, #previewOrder do
		if not self.previewPopups[i] then
			local msg = self:GetMessageTemplate(previewOrder[i])
			if msg then
				local popup = self:CreatePopup(msg)
				popup.sticky = true
				popup.isPreview = true

				tinsert(self.previewPopups, popup)
			end
		end
	end

	for i = #previewOrder + 1, #self.previewPopups do
		local popup = self.previewPopups[i]
		popup:Hide()
	end

	wipe(self.activePopups)

	for i, msgKey in ipairs(previewOrder) do
		local popup = self.previewPopups[i]
		local msg = self:GetMessageTemplate(msgKey)

		if popup and msg then
			popup.type = msg.type
			popup.sticky = true
			popup.isPreview = true

			popup.text:SetText(msg.text)
			popup.text:SetFont(fontName, fontSize, "OUTLINE")
			popup.text:SetHeight(0) -- forces recalculation
			popup:SetHeight(popup.text:GetStringHeight() + 6)

			popup.text:SetTextColor(msg.color.r, msg.color.g, msg.color.b, msg.color.a)

			popup:SetParent(self)
			popup:Show()
			popup:SetAlpha(1)

			tinsert(self.activePopups, popup)
		end
	end

	self:RepositionPopups()
end

function IPU:ClearPreviewPopups()
	for i = #self.previewPopups, 1, -1 do
		local popup = self.previewPopups[i]

		for j = #self.activePopups, 1, -1 do
			if self.activePopups[j] == popup then
				tremove(self.activePopups, j)
			end
		end

		popup:Hide()
		popup:SetParent(nil)
		popup:ClearAllPoints()

		-- tremove(self.previewPopups, i)
	end

	self:RepositionPopups()
end

function IPU:EnterEditMode()
	if not self.enabled then
		return
	end
	self.isEditing = true

	self:ShowIPU()
	self:EditModePreviewPopups()

	if not self.Selection then
		local uiName = L["IPU_Title"]
		local hideLabel = false
		self.Selection = addon.CreateEditModeSelection(self, uiName, hideLabel)
	end

	self:SetScript("OnUpdate", nil)
	FadeFrame(self, 0, 1)
	self.Selection:ShowHighlighted()
end

function IPU:ExitEditMode()
	if self.Selection then
		self.Selection:Hide()
	end

	self:ClearPreviewPopups()

	self:ShowOptions(false)
	self.isEditing = false
end

function IPU:IsFocused()
	return (self:IsShown() and self:IsMouseOver())
		or (self.OptionFrame and self.OptionFrame:IsShown() and self.OptionFrame:IsMouseOver())
end

function IPU:OnDragStart()
	self:SetMovable(true)
	self:SetDontSavePosition(true)
	self:SetClampedToScreen(true)
	self:StartMoving()
end

function IPU:OnDragStop()
	self:StopMovingOrSizing()

	local centerX = self:GetCenter()
	local uiCenter = UIParent:GetCenter()
	local left = self:GetLeft()
	local top = self:GetTop()

	left = Round(left)
	top = Round(top)

	self:ClearAllPoints()

	--Convert anchor and save position
	if math.abs(uiCenter - centerX) <= 48 then
		--Snap to centeral line
		self:SetPoint("TOP", UIParent, "BOTTOM", 0, top)
		addon.db.InformationalPopupsSettings.posX = -1
	else
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		addon.db.InformationalPopupsSettings.posX = left
	end
	addon.db.InformationalPopupsSettings.posY = top

	if self.OptionFrame and self.OptionFrame:IsOwner(self) then
		local button = self.OptionFrame:FindWidget("ResetButton")
		if button then
			button:Enable()
		end
	end
end

-- Options
function IPU:CreatePreviewFrame()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetSize(384, 192)

	f.Background = f:CreateTexture(nil, "BACKGROUND")
	f.Background:SetAllPoints()
	f.Background:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/PreviewPane.png")

	f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.label:SetPoint("TOP", 0, -8)
	f.label:SetJustifyH("CENTER")
	f.label:SetTextColor(215 / 255, 192 / 255, 163 / 255)
	f.label:SetText("Hover Over a Popup Type to Preview")

	local popupPreview = CreateFrame("Frame", nil, f)
	popupPreview:SetSize(394, 192)
	popupPreview:SetPoint("CENTER")
	f.popupPreview = popupPreview

	return f
end

function IPU:UpdatePreview(previewText)
	if not self.OptionFrame then
		return
	end

	local preview = self.OptionFrame:FindWidget("IPU_Preview")
	if not preview then
		return
	end

	local container = preview.popupPreview
	local popupText = container.texts or {}
	container.texts = popupText

	local db = addon.db.InformationalPopupsSettings
	local fontName = db.fontName or addon.Expressway
	local fontSize = db.fontSize or 22
	local spacing = fontSize * 1.0

	if not previewText then
		for i = 1, #popupText do
			local textPreview = popupText[i]
			textPreview:SetFont(fontName, fontSize, "OUTLINE")
			local offset = ((#popupText + 1) / 2 - i) * spacing
			textPreview:ClearAllPoints()
			textPreview:SetPoint("CENTER", container, "CENTER", 0, offset)
		end
		return
	end

	local messages = {}
	messages[1] = IPU:GetMessageTemplate(previewText)
	if previewText == "COMBAT_START" then
		messages[2] = IPU:GetMessageTemplate("COMBAT_END")
	end

	local N = #messages

	for i = 1, N do
		if not popupText[i] then
			popupText[i] = container:CreateFontString(nil, "ARTWORK")
		end

		local textPreview = popupText[i]
		local msg = messages[i]

		textPreview:SetFont(fontName, fontSize, "OUTLINE")
		textPreview:SetTextColor(msg.color.r, msg.color.g, msg.color.b, msg.color.a)
		textPreview:SetText(msg.text)

		local offset = ((N + 1) / 2 - i) * spacing

		textPreview:ClearAllPoints()
		textPreview:SetPoint("CENTER", container, "CENTER", 0, offset)
		textPreview:Show()
	end

	for i = N + 1, #popupText do
		popupText[i]:Hide()
	end
end

local Options_FontName_Dropdown = API.CreateDropdownOptions(
	"InformationalPopupsSettings.fontName",
	API.SharedMediaFontDropdownOptions(),
	nil,
	function()
		if IPU.isEditing then
			IPU:EditModePreviewPopups()
		end
		IPU:UpdatePreview()
	end
)

local function Options_FontSize(value)
	addon.db.InformationalPopupsSettings.fontSize = value
	IPU:UpdatePreview()
	if IPU.isEditing then
		IPU:EditModePreviewPopups()
	end
end

local function Options_DurationTime(value)
	addon.db.InformationalPopupsSettings.duration = value
end

local function Options_Slider_FormatSeconds(value)
	return format("%ds", value)
end

local function RefreshIPUEvents()
	IPU:UnregisterAllEvents()
	IPU:CompileEventsToRegister()
	for eventName in pairs(IPU.eventHandlers) do
		IPU:RegisterEvent(eventName)
	end
end

local function Options_Combat(state)
	addon.UpdateSettingsDialog()
	RefreshIPUEvents()
end

local function Options_MissingPet(state)
	addon.UpdateSettingsDialog()
	RefreshIPUEvents()
	PetController:UpdateEligibility()
end

local function Options_PassivePet(state)
	addon.UpdateSettingsDialog()
	RefreshIPUEvents()
	PetController:UpdateEligibility()
end

local function Options_ResetPosition_ShouldEnable(self)
	if addon.db.InformationalPopupsSettings.posX and addon.db.InformationalPopupsSettings.posY then
		return true
	else
		return false
	end
end

local function Options_ResetPosition_OnClick(self)
	self:Disable()
	addon.db.InformationalPopupsSettings.posX = nil
	addon.db.InformationalPopupsSettings.posY = nil
	IPU:ShowIPU()
end

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["IPU_Title"],
	widgets = {
		{
			type = "Custom",
			align = "center",
			widgetKey = "IPU_Preview",
			onAcquire = function()
				return IPU:CreatePreviewFrame()
			end,
		},
		{
			type = "Dropdown",
			label = L["FontName"],
			menuData = Options_FontName_Dropdown,
		},
		{
			type = "Slider",
			label = L["FontSize"],
			minValue = 5,
			maxValue = 80,
			valueStep = 1,
			onValueChangedFunc = Options_FontSize,
			formatValueFunc = API.ReturnWholeNum,
			dbKey = "InformationalPopupsSettings.fontSize",
		},
		{
			type = "Slider",
			label = L["IPU_DurationLabel"],
			tooltip = L["IPU_DurationTooltip"],
			minValue = 1,
			maxValue = 10,
			valueStep = 1,
			onValueChangedFunc = Options_DurationTime,
			formatValueFunc = Options_Slider_FormatSeconds,
			dbKey = "InformationalPopupsSettings.duration",
		},
		{
			type = "Divider",
		},
		{
			type = "Header",
			label = L["IPU_PopupTypes"],
		},
		{
			type = "HorizontalGroup",
			spacing = 2,
			widgets = {
				{
					type = "Checkbox",
					label = L["IPU_CombatLabel"],
					tooltip = L["IPU_CombatTooltip"],
					dbKey = "InformationalPopupsSettings.popupTypes.combat",
					onClickFunc = Options_Combat,
					onEnterFunc = function()
						IPU:UpdatePreview("COMBAT_START")
					end,
				},
				{
					type = "ColorPicker",
					label = L["IPU_CombatColorIn"],
					dbKey = "InformationalPopupsSettings.messages.COMBAT_START",
					onEnterFunc = function()
						IPU:UpdatePreview("COMBAT_START")
					end,
					onValueChangedFunc = function()
						if IPU.isEditing then
							IPU:EditModePreviewPopups()
						end
						IPU:UpdatePreview("COMBAT_START")
					end,
				},
				{
					type = "ColorPicker",
					label = L["IPU_CombatColorOut"],
					dbKey = "InformationalPopupsSettings.messages.COMBAT_END",
					onEnterFunc = function()
						IPU:UpdatePreview("COMBAT_START")
					end,
					onValueChangedFunc = function()
						if IPU.isEditing then
							IPU:EditModePreviewPopups()
						end
						IPU:UpdatePreview("COMBAT_START")
					end,
				},
			},
		},
		{
			type = "HorizontalGroup",
			spacing = 18,
			widgets = {
				{
					type = "Checkbox",
					label = L["IPU_MissingPetLabel"],
					tooltip = L["IPU_MissingPetTooltip"],
					dbKey = "InformationalPopupsSettings.popupTypes.petMissing",
					onClickFunc = Options_MissingPet,
					onEnterFunc = function()
						IPU:UpdatePreview("PET_MISSING")
					end,
				},
				{
					type = "ColorPicker",
					label = L["Color"],
					dbKey = "InformationalPopupsSettings.messages.PET_MISSING",
					onEnterFunc = function()
						IPU:UpdatePreview("PET_MISSING")
					end,
					onValueChangedFunc = function()
						if IPU.isEditing then
							IPU:EditModePreviewPopups()
						end
						IPU:UpdatePreview("PET_MISSING")
					end,
				},
			},
		},
		{
			type = "HorizontalGroup",
			spacing = 18,
			widgets = {
				{
					type = "Checkbox",
					label = L["IPU_PassivePetLabel"],
					tooltip = L["IPU_PassivePetTooltip"],
					dbKey = "InformationalPopupsSettings.popupTypes.petPassive",
					onClickFunc = Options_PassivePet,
					onEnterFunc = function()
						IPU:UpdatePreview("PET_PASSIVE")
					end,
				},
				{
					type = "ColorPicker",
					label = L["Color"],
					dbKey = "InformationalPopupsSettings.messages.PET_PASSIVE",
					onEnterFunc = function()
						IPU:UpdatePreview("PET_PASSIVE")
					end,
					onValueChangedFunc = function()
						if IPU.isEditing then
							IPU:EditModePreviewPopups()
						end
						IPU:UpdatePreview("PET_PASSIVE")
					end,
				},
			},
		},
		{ type = "Divider" },
		{
			type = "UIPanelButton",
			label = L["Reset_Position"],
			widgetKey = "ResetButton",
			stateCheckFunc = Options_ResetPosition_ShouldEnable,
			onClickFunc = Options_ResetPosition_OnClick,
		},
	},
}

function IPU:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function IPU:ShowOptions(state)
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
IPU:SetScript("OnEvent", function(self, event, ...)
	local handlers = self.eventHandlers[event]
	if not handlers then
		return
	end
	for _, handler in ipairs(handlers) do
		handler(...)
	end
end)

function IPU:CompileEventsToRegister()
	local db = addon.db and addon.db.InformationalPopupsSettings.popupTypes
	if not db then
		return
	end
	self.eventHandlers = {}

	for popupType, enabled in pairs(db) do
		if enabled then
			local category = EVENT_CATEGORIES[popupType]
			if category then
				for eventName, methodName in pairs(category) do
					self.eventHandlers[eventName] = self.eventHandlers[eventName] or {}
					local module = popupType == "combat" and Combat
						or popupType == "petMissing" and PetController
						or popupType == "petPassive" and PetController

					if module and module[methodName] then
						table.insert(self.eventHandlers[eventName], function(...)
							module[methodName](module, ...)
						end)
					end
				end
			end
		end
	end
	if (db.petMissing or db.petPassive) and PetController then
		PetController:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
		PetController:RegisterEvent("PLAYER_LEVEL_UP")
		PetController:RegisterEvent("PLAYER_DEAD")
	end
end

function IPU:Enable()
	self.enabled = true
	self:ShowIPU()
	self:CompileEventsToRegister()
	for eventName in pairs(self.eventHandlers) do
		self:RegisterEvent(eventName)
	end
end

function IPU:Disable()
	self.enabled = false
	self:Hide()
	self:UnregisterAllEvents()
	self:ClearAllPopups()
end

do
	local function EnableModule(state)
		if state then
			IPU:Enable()
		else
			IPU:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = IPU.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			IPU:ShowOptions(false)
		else
			IPU:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["IPU_Title"],
		dbKey = "InformationalPopups",
		description = L["IPU_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 2,
		visibleInEditMode = true,
		enterEditMode = function()
			IPU:EnterEditMode()
		end,
		exitEditMode = function()
			IPU:ExitEditMode()
		end,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
