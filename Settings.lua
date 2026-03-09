local addonName = select(1, ...)
---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local CATEGORIES = {
	[0] = { name = "Development", collapse = false },
	-- [1] = { name = "UI & Visual Enhancements" },
	-- [2] = { name = "Gameplay Enhancements" },
	-- [3] = { name = "Automations & Conveniences" },
	-- [4] = { name = "Group & Raid Tools" },
	-- [5] = { name = "Combat Enhancements" },
	[1] = { name = "Interface" },
	[2] = { name = "HUD & Overlays" },
	[3] = { name = "Gameplay" },
	[4] = { name = "Automation" },
	[5] = { name = "Group & Raid" },
}

local PREVIEW_ASPECT = {
	AltPowerText = 1 / 3,
	CooldownManagerSlash = 1 / 999,
	CursorRing = 1 / 3,
	ExtraActionButtonEnhanced = 1 / 3,
	FocusShortcut = 1 / 999,
	InformationalPopups = 1 / 3,
	InstanceDifficulty = 1 / 3,
	PreyBar = 1 / 3,
	RaidMarkersBar = 1 / 3,
	WorldMarkerCycler = 1 / 3,
}

local Def = {
	TextureFile = "Interface/AddOns/AeonTools/Assets/Settings/SettingsPanel.png",
	ButtonSize = 28,
	WidgetGap = 14,
	PageHeight = 576,
	CategoryGap = 40,
	TabButtonHeight = 40,

	ChangelogLineSpacing = 4,
	ChangelogParagraphSpacing = 16,
	ChangelogLineBreakHeight = 32,
	ChangelogIndent = 16, --22 to match Checkbox Label
	ChangelogImageSize = 240,
	ChangelogImageSizeLarge = 300,

	TextColorNormal = { 215 / 255, 192 / 255, 163 / 255 },
	TextColorHighlight = { 1, 1, 1 },
	TextColorNonInteractable = { 148 / 255, 124 / 255, 102 / 255 },
	TextColorDisabled = { 0.5, 0.5, 0.5 },
	TextColorReadable = { 163 / 255, 157 / 255, 147 / 255 },
}

local function SkinObjects(obj, texture)
	if obj.SkinnableObjects then
		for _, _obj in ipairs(obj.SkinnableObjects) do
			SkinObjects(_obj, texture)
		end
	elseif obj.SetTexture then
		if obj.useTrilinearFilter then
			obj:SetTexture(texture, nil, nil, "TRILINEAR")
		else
			obj:SetTexture(texture)
		end
	end
end

local function SetTexCoord(obj, x1, x2, y1, y2)
	obj:SetTexCoord(x1 / 1024, x2 / 1024, y1 / 1024, y2 / 1024)
end

local function SetTextColor(obj, color)
	obj:SetTextColor(color[1], color[2], color[3])
end

local CreateFrame = CreateFrame
local tinsert = table.insert
local tsort = table.sort
local GetDBValue = addon.GetDBValue

-- ==============================
-- === Initial Settings Frame ===
-- ==============================

local RATIO = 0.85
local FRAME_WIDTH = 680
local HEADER_HEIGHT = 18
local BUTTON_OFFSET_H = 16
local SCROLL_FRAME_SHRINK = 4
local PADDING = 16
local BUTTON_HEIGHT = 30
local OPTION_GAP_Y = 2
local DIFFERENT_CATEGORY_OFFSET = 8
local LEFT_SECTOR_WIDTH = math.floor(0.5 * FRAME_WIDTH + 0.5)

local CollapsedCategory = {}

local SettingsPanel = CreateFrame("Frame", nil, UIParent)
addon.SettingsPanel = SettingsPanel
SettingsPanel:SetSize(FRAME_WIDTH, FRAME_WIDTH * RATIO)
SettingsPanel:SetPoint("TOP", UIParent, "BOTTOM", 0, -64)
SettingsPanel:Hide()
SettingsPanel.modules = {}

-- ==================================
-- === New Feat. & Highlight Fade ===
-- ==================================

local function CreateNewFeatureMark(button)
	local newTag = button:CreateTexture(nil, "OVERLAY")
	newTag:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/NewFeature")
	newTag:SetSize(18, 18)
	newTag:SetPoint("RIGHT", button, "LEFT", 2, 0)
	newTag:Show()
	return newTag
end

local function GenericFadeIn_OnUpdate(self, elapsed)
	self.alpha = self.alpha + 8 * elapsed
	if self.alpha >= 1 then
		self.alpha = 1
		self:SetScript("OnUpdate", nil)
	end
	self:SetAlpha(self.alpha)
end

-- =============================
-- === Category Button Mixin ===
-- =============================

local CategoryButtonMixin = {}
do
	function CategoryButtonMixin:SetCategory(categoryID, categoryName)
		self.categoryID = categoryID
		self.Label:SetText(categoryName or "Unknown")
	end

	function CategoryButtonMixin:OnLoad()
		self.collapsed = false
		self:UpdateArrow()
		self:SetScript("OnClick", self.OnClick)
		self:SetScript("OnEnter", self.OnEnter)
		self:SetScript("OnLeave", self.OnLeave)
	end

	function CategoryButtonMixin:UpdateArrow()
		if self.collapsed then
			self.Arrow:SetTexCoord(0, 0.5, 0, 1)
		else
			self.Arrow:SetTexCoord(0.5, 1, 0, 1)
		end
	end

	function CategoryButtonMixin:Expand()
		if self.collapsed then
			self.collapsed = false
			CollapsedCategory[self.categoryID] = false
			self:UpdateArrow()
			SettingsPanel:UpdateContent()
		end
	end

	function CategoryButtonMixin:Collapse()
		if not self.collapsed then
			self.collapsed = true
			CollapsedCategory[self.categoryID] = true
			self:UpdateArrow()
			SettingsPanel:UpdateContent()
		end
	end

	function CategoryButtonMixin:ToggleCollapse()
		self.collapsed = CollapsedCategory[self.categoryID]
		if self.collapsed then
			self:Expand()
		else
			self:Collapse()
		end
	end

	function CategoryButtonMixin:OnClick()
		self:ToggleCollapse()
	end

	function CategoryButtonMixin:OnEnter()
		self.HighlightFrame.alpha = 0
		self.HighlightFrame:SetScript("OnUpdate", GenericFadeIn_OnUpdate)
		self.HighlightFrame:Show()
		SetTextColor(self.Label, Def.TextColorHighlight)
	end

	function CategoryButtonMixin:OnLeave()
		self.HighlightFrame:SetScript("OnUpdate", nil)
		self.HighlightFrame:Hide()
		self.HighlightFrame:SetAlpha(0)
		SetTextColor(self.Label, Def.TextColorNormal)
	end

	function CategoryButtonMixin:UpdateCategoryButton()
		if self.subModules then
			local total = #self.subModules
			local numEnabled = 0
			for _, data in ipairs(self.subModules) do
				if GetDBValue(data.dbKey) then
					numEnabled = numEnabled + 1
				end
			end
			self.Count:SetText(string.format("%d/%d", numEnabled, total))
		else
			self.Count:SetText(nil)
		end

		self.collapsed = CollapsedCategory[self.categoryID]
		self:UpdateArrow()
	end
end

local function CreateCategoryButton(parent)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(LEFT_SECTOR_WIDTH - 2 * PADDING, BUTTON_HEIGHT)

	local textureFile = "Interface/AddOns/AeonTools/Assets/Settings/SettingsPanelWidget.png"

	local disableSharpenging = true
	local useTrilinearFilter = true
	b.BackgroundTextures =
		API.CreateThreeSliceTextures(b, "BACKGROUND", 16, 40, 8, textureFile, disableSharpenging, useTrilinearFilter)
	b.BackgroundTextures[1]:SetTexCoord(36 / 512, 68 / 512, 0, 80 / 512)
	b.BackgroundTextures[2]:SetTexCoord(68 / 512, 132 / 512, 0, 80 / 512)
	b.BackgroundTextures[3]:SetTexCoord(132 / 512, 164 / 512, 0, 80 / 512)

	b.Arrow = b:CreateTexture(nil, "OVERLAY")
	b.Arrow:SetSize(18, 18)
	b.Arrow:SetPoint("LEFT", b, "LEFT", 8, 0)
	b.Arrow:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/CollapseExpand")

	b.Label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	b.Label:SetJustifyH("LEFT")
	b.Label:SetJustifyV("TOP")
	b.Label:SetTextColor(Def.TextColorNormal[1], Def.TextColorNormal[2], Def.TextColorNormal[3])
	b.Label:SetPoint("LEFT", b, "LEFT", 28, 0)

	b.Count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	b.Count:SetJustifyH("RIGHT")
	b.Count:SetJustifyV("TOP")
	b.Count:SetTextColor(0.5, 0.5, 0.5)
	b.Count:SetPoint("RIGHT", b, "RIGHT", -8, 0)

	local HighlightFrame = CreateFrame("Frame", nil, b)
	b.HighlightFrame = HighlightFrame
	HighlightFrame:SetUsingParentLevel(true)
	HighlightFrame:SetSize(128, 40)
	HighlightFrame:SetPoint("LEFT", b, "LEFT", -24, 0)
	HighlightFrame:SetPoint("RIGHT", b, "RIGHT", 24, 0)
	HighlightFrame.Texture = HighlightFrame:CreateTexture(nil, "ARTWORK")
	HighlightFrame.Texture:SetAllPoints(true)
	HighlightFrame.Texture:SetTexture(textureFile)
	HighlightFrame.Texture:SetTexCoord(168 / 512, 296 / 512, 0, 80 / 512)
	HighlightFrame:Hide()
	HighlightFrame:SetAlpha(0)

	API.Mixin(b, CategoryButtonMixin)
	b:OnLoad()

	return b
end

-- =============================
-- === Option Toggle Button  ===
-- =============================

local function OptionToggle_SetFocused(optionToggle, focused)
	if focused then
		optionToggle.Texture:SetTexCoord(0.5, 1, 0, 1)
	else
		optionToggle.Texture:SetTexCoord(0, 0.5, 0, 1)
	end
end

local function OptionToggle_OnHide(self)
	OptionToggle_SetFocused(self, false)
end

local function CreateOptionToggle(checkbox)
	local b = CreateFrame("Button", nil, checkbox, "AeonToolsPropagateMouseMotionTemplate")
	b:SetSize(48, BUTTON_HEIGHT)
	b:SetPoint("RIGHT", checkbox, "RIGHT", 0, 0)
	b.Texture = b:CreateTexture(nil, "OVERLAY")
	b.Texture:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/OptionToggle")
	b.Texture:SetSize(20, 20)
	b.Texture:SetPoint("RIGHT", b, "RIGHT", -4, 0)
	b.Texture:SetVertexColor(0.6, 0.6, 0.6)
	API.DisableSharpening(b.Texture)
	b:SetScript("OnHide", OptionToggle_OnHide)
	b.isAeonToolsSettingsPanelToggle = true
	OptionToggle_SetFocused(b, false)
	return b
end

-- =============================
-- === Selection Highlight   ===
-- =============================

local CreateSelectionHighlight
do
	local SelectionHighlightMixin = {}

	function SelectionHighlightMixin:FadeIn()
		self.alpha = 0
		self:SetAlpha(0)
		self:SetScript("OnUpdate", self.OnUpdate)
		self:Show()
	end

	function SelectionHighlightMixin:OnUpdate(elapsed)
		self.alpha = self.alpha + 5 * elapsed
		if self.alpha >= 1 then
			self.alpha = 1
			self:SetScript("OnUpdate", nil)
		end
		self:SetAlpha(self.alpha)
	end

	function SelectionHighlightMixin:OnHide()
		self:SetScript("OnUpdate", nil)
		self:SetAlpha(0)
	end

	function CreateSelectionHighlight(parent)
		local f = CreateFrame("Frame", nil, parent, "AeonToolsSettingsAnimSelectionTemplate")
		API.Mixin(f, SelectionHighlightMixin)

		SkinObjects(f, Def.TextureFile)

		SetTexCoord(f.Left, 0, 32, 80, 160)
		SetTexCoord(f.Center, 32, 160, 80, 160)
		SetTexCoord(f.Right, 160, 192, 80, 160)

		f:Hide()
		f:SetScript("OnHide", f.OnHide)

		return f
	end
end

-- =============================
-- === UI Creation (Plumber) ===
-- =============================

local function CreateUI()
	local parent = SettingsPanel
	local headerHeight = HEADER_HEIGHT
	local previewSize = FRAME_WIDTH - LEFT_SECTOR_WIDTH - 2 * PADDING

	-- Preview
	local preview = parent:CreateTexture(nil, "OVERLAY")
	parent.Preview = preview
	preview:SetSize(previewSize, previewSize)
	preview:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING, -headerHeight - PADDING)

	local mask = parent:CreateMaskTexture(nil, "OVERLAY")
	parent.PreviewMask = mask
	mask:SetPoint("TOPLEFT", preview, "TOPLEFT", 0, 0)
	mask:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", 0, 0)
	mask:SetTexture(
		"Interface/AddOns/AeonTools/Assets/Settings/PreviewMask",
		"CLAMPTOBLACKADDITIVE",
		"CLAMPTOBLACKADDITIVE"
	)
	preview:AddMaskTexture(mask)

	-- Description
	local description = parent:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	parent.Description = description
	description:SetTextColor(0.659, 0.659, 0.659)
	description:SetJustifyH("LEFT")
	description:SetJustifyV("TOP")
	description:SetSpacing(2)
	local visualOffset = 4
	description:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", visualOffset, -PADDING)
	description:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -PADDING - visualOffset, PADDING)
	description:SetShadowColor(0, 0, 0)
	description:SetShadowOffset(1, -1)

	-- Divider
	local DividerFrame = CreateFrame("Frame", nil, parent)
	parent.DividerFrame = DividerFrame
	local dividerHeight = parent:GetHeight() - headerHeight
	DividerFrame:SetSize(4, dividerHeight)
	DividerFrame:SetPoint("TOP", parent, "TOPLEFT", LEFT_SECTOR_WIDTH, -headerHeight)

	local dividerTop = DividerFrame:CreateTexture(nil, "OVERLAY")
	dividerTop:SetSize(16, 16)
	dividerTop:SetPoint("TOPRIGHT", DividerFrame, "TOP", 2, 0)
	dividerTop:SetTexCoord(0, 1, 0, 0.25)

	local dividerBottom = DividerFrame:CreateTexture(nil, "OVERLAY")
	dividerBottom:SetSize(16, 16)
	dividerBottom:SetPoint("BOTTOMRIGHT", DividerFrame, "BOTTOM", 2, 0)
	dividerBottom:SetTexCoord(0, 1, 0.75, 1)

	local dividerMiddle = DividerFrame:CreateTexture(nil, "OVERLAY")
	dividerMiddle:SetPoint("TOPLEFT", dividerTop, "BOTTOMLEFT", 0, 0)
	dividerMiddle:SetPoint("BOTTOMRIGHT", dividerBottom, "TOPRIGHT", 0, 0)
	dividerMiddle:SetTexCoord(0, 1, 0.25, 0.75)

	dividerTop:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Divider_DropShadow_Vertical")
	dividerBottom:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Divider_DropShadow_Vertical")
	dividerMiddle:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Divider_DropShadow_Vertical")

	SettingsPanel.dividers = {
		dividerTop,
		dividerMiddle,
		dividerBottom,
	}

	API.DisableSharpening(dividerTop)
	API.DisableSharpening(dividerBottom)
	API.DisableSharpening(dividerMiddle)

	-- ScrollBar (Plumber-style)
	local ScrollBar = API.CreateScrollBarWithDynamicSize(parent)
	ScrollBar:SetPoint("TOP", DividerFrame, "TOP", 0, -4)
	ScrollBar:SetPoint("BOTTOM", DividerFrame, "BOTTOM", 0, 4)
	ScrollBar:SetFrameLevel(20)
	SettingsPanel.ScrollBar = ScrollBar

	-- ScrollView (Plumber-style)
	local ScrollView = API.CreateScrollView(SettingsPanel, ScrollBar)
	SettingsPanel.ScrollView = ScrollView
	ScrollView:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", SCROLL_FRAME_SHRINK, -HEADER_HEIGHT - SCROLL_FRAME_SHRINK)
	ScrollView:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", SCROLL_FRAME_SHRINK, SCROLL_FRAME_SHRINK)
	ScrollView:SetWidth(LEFT_SECTOR_WIDTH)
	ScrollView:SetStepSize((BUTTON_HEIGHT + OPTION_GAP_Y) * 2)
	ScrollView:OnSizeChanged()
	ScrollView:EnableMouseBlocker(true)
	ScrollView:SetBottomOvershoot(DIFFERENT_CATEGORY_OFFSET)
	ScrollBar.ScrollView = ScrollView

	-- Selection highlight for options
	local SelectionTexture = CreateFrame("Frame", nil, ScrollView)
	SelectionTexture:SetSize(LEFT_SECTOR_WIDTH, 64)
	SelectionTexture.Texture = SelectionTexture:CreateTexture(nil, "ARTWORK")
	SelectionTexture.Texture:SetAllPoints(true)
	SelectionTexture.Texture:SetTexture(
		"Interface/AddOns/AeonTools/Assets/Settings/OptionEntryHighlight.png",
		nil,
		nil,
		"TRILINEAR"
	)
	API.DisableSharpening(SelectionTexture.Texture)
	SelectionTexture:Hide()

	if ScrollView.SetOnScrollStartCallback then
		ScrollView:SetOnScrollStartCallback(function()
			SelectionTexture:Hide()
		end)
	end

	parent.Checkboxs = {}
	parent.CategoryButtons = {}

	-- Checkbox behavior (Plumber-style, virtualized)
	local function Checkbox_OnEnter(self)
		local data = self.data
		local desc = data.description
		if data.descriptionFunc then
			local extra = data.descriptionFunc()
			if extra then
				if desc then
					desc = desc .. "\n\n" .. extra
				else
					desc = extra
				end
			end
		end
		description:SetText(desc)

		local previewKey = self.parentDBKey or self.dbKey
		if previewKey then
			preview:SetTexture("Interface/AddOns/AeonTools/Assets/Modules/Preview_" .. previewKey)
		end

		local mask = SettingsPanel.PreviewMask
		local maskTexture = PREVIEW_ASPECT[previewKey] and "Interface/AddOns/AeonTools/Assets/Settings/PreviewMask_25"
			or "Interface/AddOns/AeonTools/Assets/Settings/PreviewMask"

		mask:SetTexture(maskTexture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

		local aspect = PREVIEW_ASPECT[previewKey] or 1
		local width = previewSize
		local height = previewSize * aspect
		preview:SetSize(width, height)

		SelectionTexture:ClearAllPoints()
		SelectionTexture:SetPoint("LEFT", self, "LEFT", -32, 0)
		SelectionTexture:SetPoint("RIGHT", self, "RIGHT", 32, 0)
		SelectionTexture.alpha = 0
		SelectionTexture:SetAlpha(0)
		SelectionTexture:SetScript("OnUpdate", GenericFadeIn_OnUpdate)
		SelectionTexture:Show()

		if self.OptionToggle then
			OptionToggle_SetFocused(self.OptionToggle, true)
		end
	end

	local function Checkbox_OnLeave(self)
		if not self:IsMouseOver() then
			SelectionTexture:Hide()
			if self.OptionToggle then
				OptionToggle_SetFocused(self.OptionToggle, false)
			end
		end
	end

	local function Checkbox_OnClick(self)
		if self.dbKey and self.data.toggleFunc then
			self.data.toggleFunc(self:GetChecked())
		end

		if self.subOptionWidgets then
			local enabled = GetDBValue(self.dbKey)
			for _, widget in ipairs(self.subOptionWidgets) do
				widget:SetChecked(GetDBValue(widget.dbKey))
				widget:SetEnabled(enabled)
			end
		end

		if self.data.subOptions then
			SettingsPanel:UpdateCheckboxes()
		else
			self:UpdateChecked()
		end

		SettingsPanel:UpdateCategoryButtons()
	end

	local function OptionToggle_OnEnter(self)
		self.Texture:SetVertexColor(1, 1, 1)
		local tooltip = GameTooltip
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
		tooltip:SetText(SETTINGS, 1, 1, 1, 1)
		tooltip:Show()
	end

	local function OptionToggle_OnLeave(self)
		self.Texture:SetVertexColor(0.6, 0.6, 0.6)
		GameTooltip:Hide()
	end

	local function Checkbox_UpdateChecked(self)
		if self.data.virtual then
			self:SetChecked(true)
			if self.OptionToggle then
				self.OptionToggle:Hide()
			end
			self:Disable()
			return
		end

		local isChecked = GetDBValue(self.dbKey)
		self:SetChecked(isChecked)
		if self.dbKey and self.data.toggleFunc then
			self.data.toggleFunc(isChecked)
		end

		if self.subOptionWidgets then
			local enabled = GetDBValue(self.dbKey)
			for _, widget in ipairs(self.subOptionWidgets) do
				widget:SetChecked(GetDBValue(widget.dbKey))
				widget:SetEnabled(enabled)
			end
		end

		if self.data.optionToggleFunc and isChecked then
			if not self.OptionToggle then
				self.OptionToggle = CreateOptionToggle(self)
				self.OptionToggle:SetScript("OnEnter", OptionToggle_OnEnter)
				self.OptionToggle:SetScript("OnLeave", OptionToggle_OnLeave)
			end
			self.OptionToggle:SetScript("OnClick", self.data.optionToggleFunc)
			self.OptionToggle:Show()
			OptionToggle_SetFocused(self.OptionToggle, self:IsMouseMotionFocus())
		else
			if self.OptionToggle then
				self.OptionToggle:Hide()
			end
		end

		if self.parentDBKey and not GetDBValue(self.parentDBKey) then
			self:Disable()
		else
			self:Enable()
		end
	end

	local function SetupCheckboxFromData(checkbox, data)
		checkbox.dbKey = data.dbKey
		checkbox.data = data
		checkbox:SetLabel(data.name)
		checkbox:UpdateChecked()

		if data.isNewFeature then
			if not checkbox.NewTag then
				checkbox.NewTag = CreateNewFeatureMark(checkbox)
			end
			checkbox.NewTag:Show()
		elseif checkbox.NewTag then
			checkbox.NewTag:Hide()
		end
	end

	local function Checkbox_Create()
		local obj = addon.CreateCheckbox(ScrollView, nil, 38)
		obj.onEnterFunc = Checkbox_OnEnter
		obj.onLeaveFunc = Checkbox_OnLeave
		obj.onClickFunc = Checkbox_OnClick
		obj:SetMotionScriptsWhileDisabled(true)
		obj.SetupCheckboxFromData = SetupCheckboxFromData
		obj.UpdateChecked = Checkbox_UpdateChecked
		obj:SetHeight(BUTTON_HEIGHT)
		return obj
	end

	ScrollView:AddTemplate("Checkbox", Checkbox_Create)

	local function CategoryButton_Create()
		local obj = CreateCategoryButton(ScrollView)
		return obj
	end

	local function CategoryButton_Remove(obj)
		obj:OnLeave()
	end

	ScrollView:AddTemplate("CategoryButton", CategoryButton_Create, CategoryButton_Remove)

	-- Title
	local OptionsTitle = SettingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge2")
	if ElvUI then
		OptionsTitle:SetPoint("TOPLEFT", 8, 0)
	else
		OptionsTitle:SetPoint("TOPLEFT", -8, 0)
	end
	OptionsTitle:SetText("|cffffc700Aeon:|r |cff1fcecbTools|r")

	-- Version Text
	local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version")
	local VersionText = SettingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	VersionText:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", -PADDING, PADDING)
	VersionText:SetTextColor(0.24, 0.24, 0.24)
	VersionText:SetJustifyH("RIGHT")
	VersionText:SetJustifyV("BOTTOM")
	VersionText:SetText(addonVersion)

	function SettingsPanel:UpdateLayout()
		local frameWidth = math.floor(self:GetWidth() + 0.5)
		if frameWidth == self.frameWidth then
			return
		end
		self.frameWidth = frameWidth

		local leftSectorWidth = math.floor(0.5 * frameWidth + 0.5)

		self.DividerFrame:SetPoint("TOP", self, "TOPLEFT", leftSectorWidth, -headerHeight)
		self.DividerFrame:SetHeight(self:GetHeight() - HEADER_HEIGHT)

		previewSize = frameWidth - leftSectorWidth - 2 * PADDING
		preview:SetSize(previewSize, previewSize)

		ScrollView:SetWidth(leftSectorWidth)
		ScrollView:OnSizeChanged()
		self.ScrollBar:OnSizeChanged()
	end

	function SettingsPanel:ShowScrollBar(state)
		if state then
			self.ScrollBar:Show()
			self.ScrollBar:SetScrollable(true)
			dividerTop:SetShown(false)
			dividerMiddle:SetShown(false)
			dividerBottom:SetShown(false)
			if self.ScrollBar.UpdateVisibleExtentPercentage then
				self.ScrollBar:UpdateVisibleExtentPercentage()
			end
		else
			self.ScrollBar:Hide()
			self.ScrollBar:SetScrollable(false)
			dividerTop:SetShown(true)
			dividerMiddle:SetShown(true)
			dividerBottom:SetShown(true)
		end
	end
	parent._created = true
end

-- =============================
-- === Content & ScrollView  ===
-- =============================

function SettingsPanel:UpdateContent()
	local ScrollView = self.ScrollView
	if not ScrollView then
		return
	end

	local content = {}
	local n = 0
	local offsetY = 12

	local buttonHeight = BUTTON_HEIGHT
	local categoryButtonWidth = LEFT_SECTOR_WIDTH - 2 * PADDING
	local checkboxWidth = LEFT_SECTOR_WIDTH - 2 * PADDING - BUTTON_OFFSET_H
	local buttonGap = OPTION_GAP_Y
	local subOptionOffset = 20
	local offsetX = -4

	-- Build category -> subModules mapping like Plumber
	local categoryInfos = {}
	for _, data in ipairs(self.modules) do
		if (not data.validityCheck) or data.validityCheck() then
			local categoryID = data.categoryID or 0
			if not categoryInfos[categoryID] then
				categoryInfos[categoryID] = {
					categoryID = categoryID,
					categoryName = (CATEGORIES[categoryID] and CATEGORIES[categoryID].name) or "Unknown",
					subModules = {},
				}
			end
			tinsert(categoryInfos[categoryID].subModules, data)
		end
	end

	-- Sort categories by ID
	local orderedCategories = {}
	for categoryID, info in pairs(categoryInfos) do
		tinsert(orderedCategories, info)
	end
	tsort(orderedCategories, function(a, b)
		return a.categoryID < b.categoryID
	end)

	for _, categoryInfo in ipairs(orderedCategories) do
		n = n + 1
		local top = offsetY
		local bottom = offsetY + buttonHeight + buttonGap
		content[n] = {
			dataIndex = n,
			templateKey = "CategoryButton",
			setupFunc = function(obj)
				obj:SetCategory(categoryInfo.categoryID, categoryInfo.categoryName)
				obj.subModules = categoryInfo.subModules
				obj:UpdateCategoryButton()
				obj:SetWidth(categoryButtonWidth)
			end,
			top = top,
			bottom = bottom,
			offsetX = offsetX,
		}
		offsetY = bottom

		if not CollapsedCategory[categoryInfo.categoryID] then
			for _, data in ipairs(categoryInfo.subModules) do
				n = n + 1
				top = offsetY
				bottom = offsetY + buttonHeight + buttonGap
				content[n] = {
					dataIndex = n,
					templateKey = "Checkbox",
					setupFunc = function(obj)
						obj.parentDBKey = nil
						obj.subOptionWidgets = nil
						obj:SetupCheckboxFromData(data)
						obj:SetWidth(checkboxWidth)
					end,
					top = top,
					bottom = bottom,
					offsetX = offsetX,
				}
				offsetY = bottom

				if data.subOptions then
					for _, v in ipairs(data.subOptions) do
						n = n + 1
						top = offsetY
						bottom = offsetY + buttonHeight + buttonGap
						content[n] = {
							dataIndex = n,
							templateKey = "Checkbox",
							setupFunc = function(obj)
								obj.parentDBKey = data.dbKey
								obj:SetupCheckboxFromData(v)
								obj:SetWidth(checkboxWidth - subOptionOffset)
							end,
							top = top,
							bottom = bottom,
							offsetX = offsetX + 0.5 * subOptionOffset,
						}
						offsetY = bottom
					end
				end
			end

			offsetY = offsetY + DIFFERENT_CATEGORY_OFFSET
		end
	end

	local retainPosition = true
	ScrollView:SetContent(content, retainPosition)
	self:ShowScrollBar(ScrollView:IsScrollable())
end

function SettingsPanel:UpdateCheckboxes()
	if self.ScrollView and self.ScrollView.CallObjectMethod then
		self.ScrollView:CallObjectMethod("Checkbox", "UpdateChecked")
	end
end

function SettingsPanel:UpdateCategoryButtons()
	if self.ScrollView and self.ScrollView.CallObjectMethod then
		self.ScrollView:CallObjectMethod("CategoryButton", "UpdateCategoryButton")
	end
end

function SettingsPanel:UpdateButtonStates()
	self:UpdateCheckboxes()
	self:UpdateCategoryButtons()
end

-- ==============================
-- === Modules ===
-- ==============================

function SettingsPanel:InitializeModules()
	for _, moduleData in pairs(self.modules) do
		moduleData.toggleFunc(GetDBValue(moduleData.dbKey))
	end
end

function SettingsPanel:AddModule(moduleData)
	if not moduleData.categoryID then
		moduleData.categoryID = 0
		moduleData.uiOrder = 0
	end

	table.insert(self.modules, moduleData)

	if moduleData.visibleInEditMode then
		addon.AddEditModeVisibleModule(moduleData)
	end
end

-- =====================================
-- === Registering Addon to Settings ===
-- =====================================

function SettingsPanel:ShowUI()
	if not SettingsPanel._created then
		CreateUI()
	end

	self:Show()
	self:UpdateLayout()
	self:UpdateContent()
	self:UpdateButtonStates()
end

SettingsPanel:SetScript("OnShow", function(self)
	self:ShowUI()
end)

if Settings then
	local category = Settings.RegisterCanvasLayoutCategory(SettingsPanel, "Aeon: |cff1fcecbTools|r")
	Settings.RegisterAddOnCategory(category)
	addon.SettingsID = category:GetID()
end
