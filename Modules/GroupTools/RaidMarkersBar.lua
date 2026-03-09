---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local _G = _G
local GameTooltip = _G.GameTooltip

local abs = abs
local format = format
local gsub = gsub
local strupper = strupper
local strlower = strlower

local FadeFrame = API.UIFrameFade
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local slashCountdown = _G["SLASH_COUNTDOWN1"] or "/countdown"
local TargetToWorld = {
	[1] = 5,
	[2] = 6,
	[3] = 3,
	[4] = 2,
	[5] = 7,
	[6] = 1,
	[7] = 4,
	[8] = 8,
}

local RM = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

function RM:SettingsDriversUpdate(visible)
	local db = addon.db and addon.db.RaidMarkersBarSettings
	if not db or InCombatLockdown() then
		return
	end

	if visible then
		UnregisterStateDriver(self.bar, "visibility")
		self:Show()
	else
		self.Selection:Hide()
		RegisterStateDriver(
			self.bar,
			"visibility",
			db.visibility == "DEFAULT" and "[noexists, nogroup] hide; show"
				or db.visibility == "ALWAYS" and "[petbattle] hide; show"
				or "[group] show; [petbattle] hide; hide"
		)
	end
end

function RM:ToggleSettings()
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", function()
			RM:ToggleSettings()
		end)
		return
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

	if not self.bar then
		return
	end

	if self.bar and not addon.db.RaidMarkersBar then
		UnregisterStateDriver(self.bar, "visibility")
		self.bar:Hide()
		return
	end

	self:UpdateButtons()
	self:UpdateBar()

	local db = addon.db and addon.db.RaidMarkersBarSettings
	if not db then
		return
	end

	if self.bar and db.visibility then
		RegisterStateDriver(
			self.bar,
			"visibility",
			db.visibility == "DEFAULT" and "[noexists, nogroup] hide; show"
				or db.visibility == "ALWAYS" and "[petbattle] hide; show"
				or "[group] show; [petbattle] hide; hide"
		)
	end

	-- Fade in/out for mouseover
	if db.mouseOver then
		self.bar:SetScript("OnEnter", function(bar)
			bar:SetAlpha(1)
		end)

		self.bar:SetScript("OnLeave", function(bar)
			bar:SetAlpha(0)
		end)

		self.bar:SetAlpha(0)
	else
		self.bar:SetScript("OnEnter", nil)
		self.bar:SetScript("OnLeave", nil)
		self.bar:SetAlpha(1)
	end
end

-- Load Bar Position
function RM:LoadPosition()
	local db = addon.db and addon.db.RaidMarkersBarSettings
	if not db then
		return
	end
	self:ClearAllPoints()

	if db.posX and db.posY then
		if db.posX > 0 then
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.posX, db.posY)
		else
			self:SetPoint("TOP", UIParent, "BOTTOM", 0, db.posY)
		end
	else
		self:SetPoint("TOP", UIParent, "TOP", 0, -5)
	end
end

-- Update Bar & Buttons
function RM:UpdateBar()
	if not self.bar then
		return
	end

	local db = addon.db and addon.db.RaidMarkersBarSettings
	if not db then
		return
	end

	-- if not self.db.enable then
	--     self.bar:Hide()
	--     return
	-- end

	local previousButton
	local numButtons = 0

	for i = 1, 11 do
		local button = self.bar.buttons[i]
		button:ClearAllPoints()
		button:SetSize(db.buttonSize, db.buttonSize)
		button.tex:SetSize(db.buttonSize, db.buttonSize)

		if (i == 10 and not db.readyCheck) or (i == 11 and not db.countDown) then
			button:Hide()
		else
			button:Show()
			if db.orientation == 2 then
				if i == 1 then
					button:SetPoint("TOP", 0, -db.backdropSpacing)
				else
					button:SetPoint("TOP", previousButton, "BOTTOM", 0, -db.buttonSpacing)
				end
			else
				if i == 1 then
					button:SetPoint("LEFT", db.backdropSpacing, 0)
				else
					button:SetPoint("LEFT", previousButton, "RIGHT", db.buttonSpacing, 0)
				end
			end
			previousButton = button
			numButtons = numButtons + 1
		end
	end

	local height = db.buttonSize + db.backdropSpacing * 2
	local width = db.backdropSpacing * 2 + db.buttonSize * numButtons + db.buttonSpacing * (numButtons - 1)

	if db.orientation == 2 then
		width, height = height, width
	end

	self.bar:Show()
	self.bar:SetSize(width, height)
	self:SetSize(width, height)

	if db.backdrop then
		self.bar.backdrop:Show()
	else
		self.bar.backdrop:Hide()
	end
end

function RM:UpdateButtons()
	if not self.bar or not self.bar.buttons then
		return
	end
	local db = addon.db and addon.db.RaidMarkersBarSettings
	if not db then
		return
	end

	self.modifierString = gsub(db.modifier, "^%l", strupper)

	for i = 1, 11 do
		local button = self.bar.buttons[i]

		if db.buttonBackdrop then
			button.backdrop:Show()
		else
			button.backdrop:Hide()
		end

		if button and button.backdrop.shadow then
			if db.backdrop then
				button.backdrop.shadow:Hide()
			else
				button.backdrop.shadow:Show()
			end
		end

		-- Key bindings
		if button.isMarkButton then
			button:SetAttribute("shift-type*", nil)
			button:SetAttribute("alt-type*", nil)
			button:SetAttribute("ctrl-type*", nil)

			button:SetAttribute(format("%s-type*", db.modifier), "macro")

			if not db.inverse then
				button:SetAttribute("macrotext1", format("/tm %d", i))
				button:SetAttribute("macrotext2", "/tm 0")
				button:SetAttribute(format("%s-macrotext1", db.modifier), format("/wm %d", TargetToWorld[i]))
				button:SetAttribute(format("%s-macrotext2", db.modifier), format("/cwm %d", TargetToWorld[i]))
			else
				button:SetAttribute("macrotext1", format("/wm %d", TargetToWorld[i]))
				button:SetAttribute("macrotext2", format("/cwm %d", TargetToWorld[i]))
				button:SetAttribute(format("%s-macrotext1", db.modifier), format("/tm %d", i))
				button:SetAttribute(format("%s-macrotext2", db.modifier), "/tm 0")
			end
		end
	end
end

function RM:UpdateCountDownButton()
	local db = addon.db and addon.db.RaidMarkersBarSettings
	if not (db and self.db and self.bar and self.bar.buttons and self.bar.buttons[11]) then
		return
	end

	local button = self.bar.buttons[11]
	if C_AddOns_IsAddOnLoaded("BigWigs") then
		button:SetAttribute("macrotext1", "/pull " .. db.countDownTime)
		button:SetAttribute("macrotext2", "/pull 0")
	elseif C_AddOns_IsAddOnLoaded("DBM-Core") then
		button:SetAttribute("macrotext1", "/dbm pull " .. db.countDownTime)
		button:SetAttribute("macrotext2", "/dbm pull 0")
	else
		-- button:SetAttribute("macrotext1", _G.SLASH_COUNTDOWN1 .. " " .. db.countDownTime)
		-- button:SetAttribute("macrotext1", _G.SLASH_COUNTDOWN1 .. " " .. 0)
		button:SetAttribute("macrotext1", slashCountdown .. " " .. db.countDownTime)
		button:SetAttribute("macrotext2", slashCountdown .. " " .. 0)
	end
end

-- Create Bar & Buttons
function RM:CreateBar()
	if self.bar then
		return
	end

	self:SetResizable(false)
	self:SetClampedToScreen(true)
	self:SetFrameStrata("LOW")
	API.CreateBackdrop(self, "Transparent")

	self:LoadPosition()

	self.buttons = {}
	self.bar = self
	self:CreateButtons()
	self:ToggleSettings()
end

function RM:CreateButtons()
	local db = addon.db and addon.db.RaidMarkersBarSettings
	if not db then
		return
	end

	self.modifierString = db.modifier:gsub("^%l", strupper)

	for i = 1, 11 do
		local button = self.buttons[i]
		if not button then
			button = CreateFrame("Button", nil, self.bar, "SecureActionButtonTemplate, BackdropTemplate")
			API.CreateBackdrop(button, "Transparent")
		end
		button:SetSize(db.buttonSize, db.buttonSize)

		local tex = button:CreateTexture(nil, "ARTWORK")
		tex:SetSize(db.buttonSize, db.buttonSize)
		tex:SetPoint("CENTER")
		button.tex = tex
		if i < 9 then -- Markers
			tex:SetTexture(format("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d", i))

			button:SetAttribute("type*", "macro")
			button:SetAttribute(format("%s-type*", db.modifier), "macro")

			button.isMarkButton = true
		elseif i == 9 then -- Clear All
			tex:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
			button:ClearAttribute("marker")
			local prefix = strlower(RM.modifierString)
			if not db.inverse then
				button:SetAttribute(prefix .. "-type*", "worldmarker")
				button:SetAttribute(prefix .. "-action*", "clear")
				button:SetAttribute("type*", "raidtarget")
				button:SetAttribute("action", "clear-all")
			else
				button:SetAttribute(prefix .. "-type*", "raidtarget")
				button:SetAttribute(prefix .. "-action*", "clear-all")
				button:SetAttribute("type*", "worldmarker")
				button:SetAttribute("action", "clear")
			end
		elseif i == 10 then -- Ready Check & Combat Log
			tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			button:SetAttribute("type*", "macro")
			button:SetAttribute("macrotext1", "/readycheck")
			button:SetAttribute("macrotext2", "/combatlog")
		elseif i == 11 then -- Pull Countdown
			tex:SetTexture("Interface\\Icons\\Spell_unused2")
			tex:SetTexCoord(0.25, 0.8, 0.2, 0.75)
			button:SetAttribute("type*", "macro")
			if C_AddOns_IsAddOnLoaded("BigWigs") then
				button:SetAttribute("macrotext1", "/pull " .. db.countDownTime)
				button:SetAttribute("macrotext2", "/pull 0")
			elseif C_AddOns_IsAddOnLoaded("DBM-Core") then
				button:SetAttribute("macrotext1", "/dbm pull " .. db.countDownTime)
				button:SetAttribute("macrotext2", "/dbm pull 0")
			else
				-- button:SetAttribute("macrotext1", _G.SLASH_COUNTDOWN1 .. " " .. db.countDownTime)
				-- button:SetAttribute("macrotext2", _G.SLASH_COUNTDOWN1 .. " " .. 0)
				button:SetAttribute("macrotext1", slashCountdown .. " " .. db.countDownTime)
				button:SetAttribute("macrotext2", slashCountdown .. " " .. 0)
			end
		end

		button:RegisterForClicks("AnyDown")

		-- local tooltipText = ""
		-- if i < 9 then
		--     if not db.inverse then
		--         tooltipText = format(
		--             "%s\n%s\n%s\n%s",
		--             L["RM_RaidMarkerTooltipLeft"],
		--             L["RM_RaidMarkerTooltipRight"],
		--             format(L["RM_WorldMarkerTooltipLeft_Modifier"], RM.modifierString),
		--             format(L["RM_WorldMarkerTooltipRight_Modifier"], RM.modifierString)
		--         )
		--     else
		--         tooltipText = format(
		--             "%s\n%s\n%s\n%s",
		--             L["RM_WorldMarkerTooltipLeft"],
		--             L["RM_WorldMarkerTooltipRight"],
		--             format(L["RM_RaidMarkerTooltipLeft_Modifier"], RM.modifierString),
		--             format(L["RM_RaidMarkerTooltipRight_Modifier"], RM.modifierString)
		--         )
		--     end
		-- elseif i == 9 then
		--     if not db.inverse then
		--         tooltipText = format(
		--             "%s\n%s",
		--             L["RM_ClearMarks"],
		--             format(L["RM_ClearMarks_Modifier"], RM.modifierString)
		--         )
		--     else
		--         tooltipText = format(
		--             "%s\n%s",
		--             L["RM_ClearWorldMarks"],
		--             format(L["RM_ClearWorldMarks_Modifier"], RM.modifierString)
		--         )
		--     end
		-- elseif i == 10 then
		--     tooltipText =
		--         format("%s\n%s", L["RM_ReadyCheck"], L["RM_CombatLog"])
		-- elseif i == 11 then
		--     tooltipText = format("%s\n%s", L["RM_Countdown_Start"], L["RM_Countdown_Stop"])
		-- end

		-- local tooltipTitle = i <= 9 and L["RM_RaidMarkersLabel"] or L["RM_RaidUtilityLabel"]

		-- button:SetScript("OnEnter", function(btn)
		--     btn:SetBackdropBorderColor(0.7, 0.7, 0)
		--     if db.tooltip then
		--         GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
		--         GameTooltip:SetText(tooltipTitle)
		--         GameTooltip:AddLine(tooltipText, 1, 1, 1)
		--         GameTooltip:Show()
		--     end
		-- end)

		button:SetScript("OnEnter", function(btn)
			btn:SetBackdropBorderColor(0.7, 0.7, 0)

			if not db.tooltip then
				return
			end

			local currentDB = addon.db.RaidMarkersBarSettings
			local modifierString = currentDB.modifier:gsub("^%l", strupper)

			local tooltipText

			if i < 9 then
				if not currentDB.inverse then
					tooltipText = format(
						"%s\n%s\n%s\n%s",
						L["RM_RaidMarkerTooltipLeft"],
						L["RM_RaidMarkerTooltipRight"],
						format(L["RM_WorldMarkerTooltipLeft_Modifier"], modifierString),
						format(L["RM_WorldMarkerTooltipRight_Modifier"], modifierString)
					)
				else
					tooltipText = format(
						"%s\n%s\n%s\n%s",
						L["RM_WorldMarkerTooltipLeft"],
						L["RM_WorldMarkerTooltipRight"],
						format(L["RM_RaidMarkerTooltipLeft_Modifier"], modifierString),
						format(L["RM_RaidMarkerTooltipRight_Modifier"], modifierString)
					)
				end
			elseif i == 9 then
				if not currentDB.inverse then
					tooltipText =
						format("%s\n%s", L["RM_ClearMarks"], format(L["RM_ClearMarks_Modifier"], modifierString))
				else
					tooltipText = format(
						"%s\n%s",
						L["RM_ClearWorldMarks"],
						format(L["RM_ClearWorldMarks_Modifier"], modifierString)
					)
				end
			elseif i == 10 then
				tooltipText = format("%s\n%s", L["RM_ReadyCheck"], L["RM_CombatLog"])
			elseif i == 11 then
				tooltipText = format("%s\n%s", L["RM_Countdown_Start"], L["RM_Countdown_Stop"])
			end

			local tooltipTitle = i <= 9 and L["RM_RaidMarkersLabel"] or L["RM_RaidUtilityLabel"]

			GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
			---@diagnostic disable-next-line: missing-parameter
			GameTooltip:SetText(tooltipTitle)
			GameTooltip:AddLine(tooltipText, 1, 1, 1)
			GameTooltip:Show()
		end)

		button:SetScript("OnLeave", function(btn)
			btn:SetBackdropBorderColor(0, 0, 0)
			if db.tooltip then
				GameTooltip:Hide()
			end
		end)

		-- Fade in/out for mouseover
		button:HookScript("OnEnter", function()
			if not db.mouseOver then
				return
			end
			self.bar:SetAlpha(1)
			button:SetBackdropBorderColor(0.7, 0.7, 0)
		end)

		button:HookScript("OnLeave", function()
			if not db.mouseOver then
				return
			end
			self.bar:SetAlpha(0)
			button:SetBackdropBorderColor(0, 0, 0)
		end)

		self.bar.buttons[i] = button
	end
end

-- Edit Mode
function RM:EnterEditMode()
	if not self.enabled then
		return
	end

	if not self.bar then
		self:CreateBar()
	end

	if not self.Selection then
		local uiName = L["RM_Title"]
		local hideLabel = false
		self.Selection = addon.CreateEditModeSelection(self, uiName, hideLabel)
	end

	RM:SettingsDriversUpdate(true)
	self.isEditing = true
	self:SetScript("OnUpdate", nil)
	FadeFrame(self, 0, 1)
	self.Selection:ShowHighlighted()
end

function RM:ExitEditMode()
	if self.Selection then
		self.Selection:Hide()
	end
	self:ShowOptions(false)
	self.isEditing = false
	self:ToggleSettings()
end

function RM:IsFocused()
	return (self:IsShown() and self:IsMouseOver())
		or (self.OptionFrame and self.OptionFrame:IsShown() and self.OptionFrame:IsMouseOver())
end

function RM:OnDragStart()
	self:SetMovable(true)
	self:SetDontSavePosition(true)
	self:SetClampedToScreen(true)
	self:StartMoving()
end

function RM:OnDragStop()
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
		addon.db.RaidMarkersBarSettings.posX = -1
	else
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		addon.db.RaidMarkersBarSettings.posX = left
	end
	addon.db.RaidMarkersBarSettings.posY = top

	if self.OptionFrame and self.OptionFrame:IsOwner(self) then
		local button = self.OptionFrame:FindWidget("ResetButton")
		if button then
			button:Enable()
		end
	end
end

function RM:Nudge(posX, posY)
	local db = addon.db.RaidMarkersBarSettings

	-- Determine current anchor style (same logic as OnDragStop)
	local left = self:GetLeft()
	local top = self:GetTop()

	-- Apply 1-pixel nudge
	left = left + posX
	top = top + posY

	-- Snap-to-center logic (mirror of OnDragStop: within 48px of UI center X)
	local centerX = self:GetCenter()
	local uiCenter = UIParent:GetCenter()

	self:ClearAllPoints()

	if math.abs(uiCenter - (centerX + posX)) <= 48 then
		self:SetPoint("TOP", UIParent, "BOTTOM", 0, top)
		db.posX = -1
	else
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		db.posX = left
	end
	db.posY = top

	-- Update the Reset button in the options dialog if open
	if self.OptionFrame and self.OptionFrame:IsOwner(self) then
		local button = self.OptionFrame:FindWidget("ResetButton")
		if button then
			button:Enable()
		end
	end
end

-- Options
local function Options_Tooltip() end

local function Options_InverseMode()
	RM:UpdateButtons()
	RM:UpdateBar()
end

local function Options_Mouseover()
	RM:ToggleSettings()
end

local Options_Modifier_Dropdown = API.CreateDropdownOptions(
	"RaidMarkersBarSettings.modifier",
	API.ModifierDropdownOptions(),
	nil,
	function()
		RM:UpdateButtons()
	end
)

local Options_Visibility_Dropdown = API.CreateDropdownOptions(
	"RaidMarkersBarSettings.visibility",
	API.VisibilityDropdownOptions(),
	nil,
	function()
		RM:UpdateButtons()
	end
)

local function Options_BarOrientation(value)
	addon.db.RaidMarkersBarSettings.orientation = value
	RM:UpdateBar()
end

local function Options_BarBackdrop()
	RM:UpdateBar()
end

local function Options_BarOrientation_FormatValue(value)
	return value == 1 and L["Horizontal"] or L["Vertical"]
end

local function Options_BarBackdropSpacing(value)
	addon.db.RaidMarkersBarSettings.backdropSpacing = value
	RM:UpdateBar()
end

local function Options_Slider_FormatWholeValue(value)
	return format("%d", value)
end

local function Options_ButtonBackdrop()
	RM:UpdateButtons()
end

local function Options_ButtonSize(value)
	addon.db.RaidMarkersBarSettings.buttonSize = value
	RM:UpdateButtons()
	RM:UpdateBar()
end

local function Options_ButtonSpacing(value)
	addon.db.RaidMarkersBarSettings.buttonSpacing = value
	RM:UpdateButtons()
	RM:UpdateBar()
end

local function Options_ReadyCheck()
	RM:UpdateButtons()
	RM:UpdateBar()
end

local function Options_Countdown()
	RM:UpdateButtons()
	RM:UpdateBar()
end

local function Options_CountdownTime(value)
	addon.db.RaidMarkersBarSettings.countDownTime = value
	RM:UpdateCountDownButton()
end

local function Options_ResetPosition_ShouldEnable(self)
	if addon.db.RaidMarkersBarSettings.posX and addon.db.RaidMarkersBarSettings.posY then
		return true
	else
		return false
	end
end

local function Options_ResetPosition_OnClick(self)
	self:Disable()
	addon.db.RaidMarkersBarSettings.posX = nil
	addon.db.RaidMarkersBarSettings.posY = nil
	RM:LoadPosition()
end

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["RM_Title"],
	widgets = {
		{
			type = "HorizontalGroup",
			spacing = 2,
			widgets = {
				{
					type = "Checkbox",
					label = L["RM_Options_Tooltip_Label"],
					tooltip = L["RM_Options_Tooltip_Tooltip"],
					dbKey = "RaidMarkersBarSettings.tooltip",
					onClickFunc = Options_Tooltip,
				},
				{
					type = "Checkbox",
					label = L["RM_Options_Inverse_Label"],
					tooltip = L["RM_Options_Inverse_Tooltip"],
					dbKey = "RaidMarkersBarSettings.inverse",
					onClickFunc = Options_InverseMode,
				},
				{
					type = "Checkbox",
					label = L["RM_Options_Mouseover_Label"],
					tooltip = L["RM_Options_Mouseover_Tooltip"],
					dbKey = "RaidMarkersBarSettings.mouseOver",
					onClickFunc = Options_Mouseover,
				},
			},
		},
		{
			type = "Dropdown",
			label = L["Modifier_Label"],
			menuData = Options_Modifier_Dropdown,
		},
		{
			type = "Dropdown",
			label = L["RM_Options_Visibility"],
			menuData = Options_Visibility_Dropdown,
		},
		{
			type = "Slider",
			label = L["RM_Options_Orientation"],
			dbKey = "RaidMarkersBarSettings.orientation",
			minValue = 1,
			maxValue = 2,
			valueStep = 1,
			onValueChangedFunc = Options_BarOrientation,
			formatValueFunc = Options_BarOrientation_FormatValue,
		},
		{ type = "Divider" },
		{ type = "Header", label = L["Category_Appearance"] },
		{
			type = "HorizontalGroup",
			spacing = 50,
			widgets = {
				{
					type = "Checkbox",
					label = L["RM_Options_BarBackdrop_Label"],
					tooltip = L["RM_Options_BarBackdrop_Tooltip"],
					dbKey = "RaidMarkersBarSettings.backdrop",
					onClickFunc = Options_BarBackdrop,
				},
				{
					type = "Checkbox",
					label = L["RM_Options_ButtonBackdrop_Label"],
					tooltip = L["RM_Options_ButtonBackdrop_Tooltip"],
					dbKey = "RaidMarkersBarSettings.buttonBackdrop",
					onClickFunc = Options_ButtonBackdrop,
				},
			},
		},

		{
			type = "Slider",
			label = L["RM_Options_BackdropSpacing_Label"],
			tooltip = L["RM_Options_BackdropSpacing_Tooltip"],
			dbKey = "RaidMarkersBarSettings.backdropSpacing",
			minValue = 1,
			maxValue = 30,
			valueStep = 1,
			onValueChangedFunc = Options_BarBackdropSpacing,
			formatValueFunc = Options_Slider_FormatWholeValue,
		},

		{
			type = "Slider",
			label = L["RM_Options_ButtonSize_Label"],
			tooltip = L["RM_Options_ButtonSize_Tooltip"],
			dbKey = "RaidMarkersBarSettings.buttonSize",
			minValue = 15,
			maxValue = 60,
			valueStep = 1,
			onValueChangedFunc = Options_ButtonSize,
			formatValueFunc = Options_Slider_FormatWholeValue,
		},
		{
			type = "Slider",
			label = L["RM_Options_ButtonSpacing_Label"],
			tooltip = L["RM_Options_ButtonSpacing_Tooltip"],
			dbKey = "RaidMarkersBarSettings.buttonSpacing",
			minValue = 1,
			maxValue = 30,
			valueStep = 1,
			onValueChangedFunc = Options_ButtonSpacing,
			formatValueFunc = Options_Slider_FormatWholeValue,
		},
		{ type = "Divider" },
		{ type = "Header", label = L["RM_Options_Divider_RC"] },
		{
			type = "Checkbox",
			label = L["RM_Options_RC_Label"],
			tooltip = L["RM_ReadyCheck"] .. "\n" .. L["RM_CombatLog"],
			dbKey = "RaidMarkersBarSettings.readyCheck",
			onClickFunc = Options_ReadyCheck,
		},
		{
			type = "Checkbox",
			label = L["RM_Options_Countdown_Label"],
			tooltip = L["RM_Options_Countdown_Tooltip"],
			dbKey = "RaidMarkersBarSettings.countDown",
			onClickFunc = Options_Countdown,
		},
		{
			type = "Slider",
			label = L["RM_Options_CDTime_Label"],
			tooltip = L["RM_Options_CDTime_Tooltip"],
			dbKey = "RaidMarkersBarSettings.countDownTime",
			minValue = 1,
			maxValue = 30,
			valueStep = 1,
			onValueChangedFunc = Options_CountdownTime,
			formatValueFunc = Options_Slider_FormatWholeValue,
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

function RM:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function RM:ShowOptions(state)
	if state then
		self:CreateOptions(true)
		self.OptionFrame:Show()
		self.OptionFrame:SetScript("OnHide", function()
			RM:ToggleSettings()
		end)
		RM:SettingsDriversUpdate(true)
		addon.UpdateSettingsDialog()
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

function addon:RM_ToggleOptions()
	local OptionFrame = RM.OptionFrame
	if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
		RM:ShowOptions(false)
	else
		RM:ShowOptions(true)
	end
end

addon:RegisterSlashSubCommand("rm", function()
	if not addon.db.RaidMarkersBar then
		return
	end
	addon:RM_ToggleOptions()
end)

-- Enable/Disable
function RM:Enable()
	self.enabled = true
	if not self.bar then
		self:CreateBar()
	else
		self:ToggleSettings()
	end
end

function RM:Disable()
	self.enabled = false
	UnregisterStateDriver(self, "visibility")
	self:Hide()
	if self.bar then
		addon:ReloadPopUp()
	end
end

do
	local function EnableModule(state)
		if state then
			RM:Enable()
		else
			RM:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = RM.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			RM:ShowOptions(false)
		else
			RM:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["RM_Title"],
		dbKey = "RaidMarkersBar",
		description = L["RM_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 5,
		visibleInEditMode = true,
		enterEditMode = function()
			RM:EnterEditMode()
		end,
		exitEditMode = function()
			RM:ExitEditMode()
		end,
		-- hasMovableWidget = true,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
