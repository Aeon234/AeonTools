---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local EOT = CreateFrame("Frame")
local ORIGINAL_ERRORFRAME = {
	font = nil,
	size = nil,
	flags = nil,
	width = nil,
	height = nil,
}

-- Preview Settings
function EOT:PreviewOptions(visible)
	local db = addon.db and addon.db.EnlargeObjectiveTextSettings
	if not db then
		return
	end

	if not EOT.Preview then
		EOT.Preview = CreateFrame("Frame", nil, UIErrorsFrame)
		EOT.Preview:SetSize(800, 120)
		EOT.Preview:SetPoint("CENTER")
		local text = EOT.Preview:CreateFontString("OVERLAY")
		text:SetPoint("CENTER")
		text:SetFont(db.fontName, db.fontSize, db.fontOutline)
		text:SetText("|cffff2020Out of range.|r\n\n|cffffd200Peons Awoken: 1/5|r")
		EOT.Preview.text = text
	end
	EOT.Preview.text:SetFont(db.fontName, db.fontSize, db.fontOutline)
	if visible then
		EOT.Preview:Show()
	else
		EOT.Preview:Hide()
	end
end

-- Options
local Options_FontName_Dropdown = API.CreateDropdownOptions(
	"EnlargeObjectiveTextSettings.fontName",
	API.SharedMediaFontDropdownOptions(),
	nil,
	function()
		EOT:PreviewOptions(true)
	end
)

local Options_FontFlag_Dropdown = API.CreateDropdownOptions(
	"EnlargeObjectiveTextSettings.fontOutline",
	API.FontFlagDropdownOptions(),
	nil,
	function()
		EOT:PreviewOptions(true)
	end
)

local function Options_FontSize(value)
	addon.db.EnlargeObjectiveTextSettings.fontSize = value
	EOT:Enable()
	EOT:PreviewOptions(true)
end

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["EOT_Title"],
	widgets = {
		{
			type = "Dropdown",
			label = L["FontName"],
			menuData = Options_FontName_Dropdown,
		},
		{
			type = "Dropdown",
			label = L["FontFlag"],
			menuData = Options_FontFlag_Dropdown,
		},
		{
			type = "Slider",
			label = L["FontSize"],
			minValue = 5,
			maxValue = 80,
			valueStep = 1,
			onValueChangedFunc = Options_FontSize,
			formatValueFunc = API.ReturnWholeNum,
			dbKey = "EnlargeObjectiveTextSettings.fontSize",
		},
	},
}

function EOT:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function EOT:ShowOptions(state)
	if state then
		self:CreateOptions(true)
		self.OptionFrame:Show()
		self.OptionFrame:SetScript("OnHide", function()
			EOT:PreviewOptions(false)
		end)
		EOT:PreviewOptions(true)
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

function EOT:Enable()
	local db = addon.db and addon.db.EnlargeObjectiveTextSettings

	if UIErrorsFrame then
		local font, size, flags = UIErrorsFrame:GetFont()
		ORIGINAL_ERRORFRAME.font = ORIGINAL_ERRORFRAME.font or font
		ORIGINAL_ERRORFRAME.size = ORIGINAL_ERRORFRAME.size or size
		ORIGINAL_ERRORFRAME.flags = ORIGINAL_ERRORFRAME.flags or flags
		ORIGINAL_ERRORFRAME.width = ORIGINAL_ERRORFRAME.width or UIErrorsFrame:GetWidth()
		ORIGINAL_ERRORFRAME.height = ORIGINAL_ERRORFRAME.height or UIErrorsFrame:GetHeight()
		UIErrorsFrame:SetFont(db.fontName or font, db.fontSize or 22, db.fontOutline or "OUTLINE")
		UIErrorsFrame:SetWidth(800)
		UIErrorsFrame:SetHeight(120)
	end
end

function EOT:Disable()
	if
		UIErrorsFrame
		and ORIGINAL_ERRORFRAME.font
		and ORIGINAL_ERRORFRAME.size
		and ORIGINAL_ERRORFRAME.flags
		and ORIGINAL_ERRORFRAME.width
		and ORIGINAL_ERRORFRAME.height
	then
		UIErrorsFrame:SetFont(ORIGINAL_ERRORFRAME.font, ORIGINAL_ERRORFRAME.size, ORIGINAL_ERRORFRAME.flags)
		UIErrorsFrame:SetWidth(ORIGINAL_ERRORFRAME.width)
		UIErrorsFrame:SetHeight(ORIGINAL_ERRORFRAME.height)
	end
end

do
	local function EnableModule(state)
		if state then
			EOT:Enable()
		else
			EOT:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = EOT.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			EOT:ShowOptions(false)
		else
			EOT:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["EOT_Title"],
		dbKey = "EnlargeObjectiveText",
		description = L["EOT_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 1,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
