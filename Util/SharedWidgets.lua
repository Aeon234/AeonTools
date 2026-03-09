---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local BUTTON_MIN_SIZE = 48
local Mixin = API.Mixin

local Util = {}
addon.Util = Util
local CreateObjectPool = API.CreateObjectPool

local ipairs = ipairs
local unpack = unpack
local IsMouseButtonDown = IsMouseButtonDown
local PlaySound = PlaySound
local CreateFrame = CreateFrame
local UIParent = UIParent
local GameTooltip = GameTooltip

local Def = {
	CheckboxTexture = "Interface/AddOns/AeonTools/Assets/Settings/Button/Checkbox.png",
	SliderTexture = "Interface/AddOns/AeonTools/Assets/Settings/Button/Slider.png",
	DropdownTexture = "Interface/AddOns/AeonTools/Assets/Settings/Button/Dropdown.png",
}
local TEXTURE_FILE = "Interface/AddOns/AeonTools/Assets/Settings/ExpansionBorder_TWW"

local function DisableSharpening(texture)
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)
end
API.DisableSharpening = DisableSharpening

do -- Slice Frame
	function API.CreateThreeSliceTextures(
		parent,
		layer,
		sideWidth,
		sideHeight,
		sideOffset,
		file,
		disableSharpenging,
		useTrilinearFilter
	)
		local slices = {}
		slices[1] = parent:CreateTexture(nil, layer)
		slices[2] = parent:CreateTexture(nil, layer)
		slices[3] = parent:CreateTexture(nil, layer)
		slices[1]:SetPoint("LEFT", parent, "LEFT", -sideOffset, 0)
		slices[3]:SetPoint("RIGHT", parent, "RIGHT", sideOffset, 0)
		slices[2]:SetPoint("TOPLEFT", slices[1], "TOPRIGHT", 0, 0)
		slices[2]:SetPoint("BOTTOMRIGHT", slices[3], "BOTTOMLEFT", 0, 0)

		if sideWidth and sideHeight then
			slices[1]:SetSize(sideWidth, sideHeight)
			slices[3]:SetSize(sideWidth, sideHeight)
		end

		if file then
			local filter = useTrilinearFilter and "TRILINEAR" or "LINEAR"
			slices[1]:SetTexture(file, nil, nil, filter)
			slices[2]:SetTexture(file, nil, nil, filter)
			slices[3]:SetTexture(file, nil, nil, filter)
		end

		if disableSharpenging then
			DisableSharpening(slices[1])
			DisableSharpening(slices[2])
			DisableSharpening(slices[3])
		end

		return slices
	end

	local SliceFrameMixin = {}

	function SliceFrameMixin:CreatePieces(n)
		--[[
        if n == 9 then
            NiceSlice_CreatePieces(self)
            NiceSlice_SetCornerSize(self, 16)
            return
        end
        --]]

		if self.pieces then
			return
		end
		self.pieces = {}
		self.numSlices = n

		-- 1 2 3
		-- 4 5 6
		-- 7 8 9

		for i = 1, n do
			self.pieces[i] = self:CreateTexture(nil, "BORDER")
			DisableSharpening(self.pieces[i])
			self.pieces[i]:ClearAllPoints()
		end

		self:SetCornerSize(16)

		if n == 3 then
			self.pieces[1]:SetPoint("CENTER", self, "LEFT", 0, 0)
			self.pieces[3]:SetPoint("CENTER", self, "RIGHT", 0, 0)
			self.pieces[2]:SetPoint("TOPLEFT", self.pieces[1], "TOPRIGHT", 0, 0)
			self.pieces[2]:SetPoint("BOTTOMRIGHT", self.pieces[3], "BOTTOMLEFT", 0, 0)

			self.pieces[1]:SetTexCoord(0, 0.25, 0, 1)
			self.pieces[2]:SetTexCoord(0.25, 0.75, 0, 1)
			self.pieces[3]:SetTexCoord(0.75, 1, 0, 1)
		elseif n == 9 then
			self.pieces[1]:SetPoint("CENTER", self, "TOPLEFT", 0, 0)
			self.pieces[3]:SetPoint("CENTER", self, "TOPRIGHT", 0, 0)
			self.pieces[7]:SetPoint("CENTER", self, "BOTTOMLEFT", 0, 0)
			self.pieces[9]:SetPoint("CENTER", self, "BOTTOMRIGHT", 0, 0)
			self.pieces[2]:SetPoint("TOPLEFT", self.pieces[1], "TOPRIGHT", 0, 0)
			self.pieces[2]:SetPoint("BOTTOMRIGHT", self.pieces[3], "BOTTOMLEFT", 0, 0)
			self.pieces[4]:SetPoint("TOPLEFT", self.pieces[1], "BOTTOMLEFT", 0, 0)
			self.pieces[4]:SetPoint("BOTTOMRIGHT", self.pieces[7], "TOPRIGHT", 0, 0)
			self.pieces[5]:SetPoint("TOPLEFT", self.pieces[1], "BOTTOMRIGHT", 0, 0)
			self.pieces[5]:SetPoint("BOTTOMRIGHT", self.pieces[9], "TOPLEFT", 0, 0)
			self.pieces[6]:SetPoint("TOPLEFT", self.pieces[3], "BOTTOMLEFT", 0, 0)
			self.pieces[6]:SetPoint("BOTTOMRIGHT", self.pieces[9], "TOPRIGHT", 0, 0)
			self.pieces[8]:SetPoint("TOPLEFT", self.pieces[7], "TOPRIGHT", 0, 0)
			self.pieces[8]:SetPoint("BOTTOMRIGHT", self.pieces[9], "BOTTOMLEFT", 0, 0)

			self.pieces[1]:SetTexCoord(0, 0.25, 0, 0.25)
			self.pieces[2]:SetTexCoord(0.25, 0.75, 0, 0.25)
			self.pieces[3]:SetTexCoord(0.75, 1, 0, 0.25)
			self.pieces[4]:SetTexCoord(0, 0.25, 0.25, 0.75)
			self.pieces[5]:SetTexCoord(0.25, 0.75, 0.25, 0.75)
			self.pieces[6]:SetTexCoord(0.75, 1, 0.25, 0.75)
			self.pieces[7]:SetTexCoord(0, 0.25, 0.75, 1)
			self.pieces[8]:SetTexCoord(0.25, 0.75, 0.75, 1)
			self.pieces[9]:SetTexCoord(0.75, 1, 0.75, 1)
		end
	end

	function SliceFrameMixin:SetCornerSize(a)
		if self.numSlices == 3 then
			self.pieces[1]:SetSize(a, 2 * a)
			self.pieces[3]:SetSize(a, 2 * a)
		elseif self.numSlices == 9 then
			--if true then
			--    NiceSlice_SetCornerSize(self, a)
			--    return
			--end
			self.pieces[1]:SetSize(a, a)
			self.pieces[3]:SetSize(a, a)
			self.pieces[7]:SetSize(a, a)
			self.pieces[9]:SetSize(a, a)
		end
	end

	function SliceFrameMixin:SetCornerSizeByScale(scale)
		self:SetCornerSize(16 * scale)
	end

	function SliceFrameMixin:SetTexture(tex)
		--if self.NineSlice then
		--    NiceSlice_SetTexture(self, tex)
		--    return
		--end
		for i = 1, #self.pieces do
			self.pieces[i]:SetTexture(tex)
		end
	end

	function SliceFrameMixin:SetDisableSharpening(state)
		for i = 1, #self.pieces do
			self.pieces[i]:SetSnapToPixelGrid(not state)
		end
	end

	function SliceFrameMixin:SetColor(r, g, b)
		for i = 1, #self.pieces do
			self.pieces[i]:SetVertexColor(r, g, b)
		end
	end

	function SliceFrameMixin:CoverParent(padding)
		padding = padding or 0
		local parent = self:GetParent()
		if parent then
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", parent, "TOPLEFT", -padding, padding)
			self:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", padding, -padding)
		end
	end

	function SliceFrameMixin:ShowBackground(state)
		for _, piece in ipairs(self.pieces) do
			piece:SetShown(state)
		end
	end

	local function CreateNineSliceFrame(parent, layoutName)
		if not (layoutName and NineSliceLayouts[layoutName]) then
			layoutName = "WhiteBorder"
		end
		local f = CreateFrame("Frame", nil, parent)
		Mixin(f, SliceFrameMixin)
		f:CreatePieces(9)
		f:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/" .. layoutName)
		f:ClearAllPoints()
		return f
	end
	addon.CreateNineSliceFrame = CreateNineSliceFrame
end

do -- Color Picker
	local LABEL_OFFSET = 32
	local BUTTON_HITBOX_MIN_WIDTH = 120

	local ColorPickerMixin = {}

	function ColorPickerMixin:OnEnter()
		if IsMouseButtonDown() then
			return
		end

		if self.tooltip then
			local f = GameTooltip
			f:Hide()
			f:SetOwner(self, "ANCHOR_RIGHT")
			f:SetText(self.Label:GetText(), 1, 1, 1, 1, true)
			f:AddLine(self.tooltip, 1, 0.82, 0, true)
			if self.tooltip2 then
				local tooltip2
				if type(self.tooltip2) == "function" then
					tooltip2 = self.tooltip2()
				else
					tooltip2 = self.tooltip2
				end
				if tooltip2 then
					f:AddLine(" ", 1, 0.82, 0, true)
					f:AddLine(tooltip2, 1, 0.82, 0, true)
				end
			end
			f:Show()
		end

		if self.onEnterFunc then
			self.onEnterFunc(self)
		end
	end

	function ColorPickerMixin:OnLeave()
		GameTooltip:Hide()
	end

	function ColorPickerMixin:OnClick()
		local initial = self.color or { r = 1, g = 1, b = 1 }

		-- Create callback functions
		local function colorCallback()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			self:SetColor(r, g, b)

			-- Save to database
			if self.dbKey then
				addon.SetDBValue(self.dbKey, { r = r, g = g, b = b })
			end

			-- Trigger callback for real-time updates
			if self.onValueChangedFunc then
				self.onValueChangedFunc(self, r, g, b)
			end
		end

		local function cancelCallback(prev)
			local r, g, b = unpack(prev)
			self:SetColor(r, g, b)

			-- Save previous color back to database
			if self.dbKey then
				addon.SetDBValue(self.dbKey, { r = r, g = g, b = b })
			end

			-- Trigger callback to update visuals with old color
			if self.onValueChangedFunc then
				self.onValueChangedFunc(self, r, g, b)
			end
		end

		-- Check which API version is available
		if ColorPickerFrame.SetupColorPickerAndShow then
			-- New API (10.2.5+)
			local info = {
				r = initial.r,
				g = initial.g,
				b = initial.b,
				opacity = nil,
				hasOpacity = false,
				swatchFunc = colorCallback,
				cancelFunc = function()
					cancelCallback({ initial.r, initial.g, initial.b })
				end,
			}
			ColorPickerFrame:SetupColorPickerAndShow(info)
		else
			-- Old API (pre-10.2.5)
			ColorPickerFrame.hasOpacity = false
			ColorPickerFrame.previousValues = { initial.r, initial.g, initial.b }
			ColorPickerFrame.func = colorCallback
			ColorPickerFrame.cancelFunc = function()
				cancelCallback({ initial.r, initial.g, initial.b })
			end

			-- Set initial color using the Content.ColorSelect widget (new internal structure)
			-- or fall back to old SetColorRGB method
			if ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
				ColorPickerFrame.Content.ColorPicker:SetColorRGB(initial.r, initial.g, initial.b)
			elseif ColorPickerFrame.SetColorRGB then
				ColorPickerFrame:SetColorRGB(initial.r, initial.g, initial.b)
			end

			-- Ensure OnShow handler runs
			ColorPickerFrame:Hide()
			ColorPickerFrame:Show()
		end
	end

	function ColorPickerMixin:SetColor(r, g, b)
		self.ColorTexture:SetVertexColor(r, g, b)
		self.color = { r = r, g = g, b = b }
	end

	function ColorPickerMixin:GetColor()
		if self.color then
			return self.color.r, self.color.g, self.color.b
		end
		return 1, 1, 1
	end

	function ColorPickerMixin:SetFixedWidth(width)
		self.fixedWidth = width
		self:SetWidth(width)
	end

	function ColorPickerMixin:SetMaxWidth(maxWidth)
		--this width includes box and label
		self.Label:SetWidth(maxWidth - LABEL_OFFSET)
		self.SetWidth(maxWidth)
	end

	function ColorPickerMixin:SetLabel(label)
		self.Label:SetText(label)
		local width = self.Label:GetWrappedWidth() + LABEL_OFFSET
		local height = self.Label:GetHeight()
		local lines = self.Label:GetNumLines()

		self.Label:ClearAllPoints()
		if lines > 1 then
			self.Label:SetPoint("TOPLEFT", self, "TOPLEFT", LABEL_OFFSET, -4)
		else
			self.Label:SetPoint("LEFT", self, "LEFT", LABEL_OFFSET, 0)
		end

		if self.fixedWidth then
			return self.fixedWidth
		else
			self:SetWidth(math.max(BUTTON_HITBOX_MIN_WIDTH, width))
			return width
		end
	end

	function ColorPickerMixin:SetData(data)
		self.dbKey = data.dbKey
		self.tooltip = data.tooltip
		self.tooltip2 = data.tooltip2
		self.onValueChangedFunc = data.onValueChangedFunc
		self.onClickFunc = data.onClickFunc
		self.onEnterFunc = data.onEnterFunc
		self.onLeaveFunc = data.onLeaveFunc

		local saved = addon.GetDBValue(self.dbKey)
		if saved and saved.r and saved.g and saved.b then
			self:SetColor(saved.r, saved.g, saved.b)
		else
			self:SetColor(1, 1, 1)
		end

		if data.label then
			return self:SetLabel(data.label)
		else
			return 0
		end
	end

	local function CreateColorPicker(parent, name, size)
		size = size or BUTTON_MIN_SIZE

		local f = CreateFrame("Button", name, parent)
		f:SetSize(size, size)

		Mixin(f, ColorPickerMixin)

		f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.Label:SetJustifyH("LEFT")
		f.Label:SetJustifyV("TOP")
		f.Label:SetPoint("LEFT", f, "LEFT", LABEL_OFFSET, 0)
		f.Label:SetTextColor(1, 1, 1)

		f.Border = f:CreateTexture(nil, "ARTWORK")
		f.Border:SetTexture(Def.CheckboxTexture)
		f.Border:SetTexCoord(0, 0.5, 0, 0.5)
		f.Border:SetPoint("CENTER", f, "LEFT", 14, 0)
		f.Border:SetSize(size, size)
		DisableSharpening(f.Border)

		f.ColorTexture = f:CreateTexture(nil, "OVERLAY")
		f.ColorTexture:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Octagonal_Button")
		local interiorSize = size * 0.35
		f.ColorTexture:SetSize(interiorSize, interiorSize)
		f.ColorTexture:SetPoint("CENTER", f.Border, "CENTER", 0, 0)

		f.Highlight = f:CreateTexture(nil, "HIGHLIGHT")
		f.Highlight:SetTexture(Def.CheckboxTexture)
		f.Highlight:SetTexCoord(0, 0.5, 0.5, 1)
		f.Highlight:SetPoint("CENTER", f.Border, "CENTER", 0, 0)
		f.Highlight:SetSize(size, size)
		DisableSharpening(f.Highlight)

		-- Set up scripts
		Mixin(f, ColorPickerMixin)
		f.isAeonToolsColorPicker = true
		f:SetScript("OnClick", f.OnClick)
		f:SetScript("OnEnter", f.OnEnter)
		f:SetScript("OnLeave", f.OnLeave)

		return f
	end

	addon.CreateColorPicker = CreateColorPicker
end

do -- Checkbox
	local LABEL_OFFSET = 32 -- 26
	local BUTTON_HITBOX_MIN_WIDTH = 120

	local SFX_CHECKBOX_ON = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856
	local SFX_CHECKBOX_OFF = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857

	local CheckboxMixin = {}

	function CheckboxMixin:OnEnter()
		if IsMouseButtonDown() then
			return
		end

		if self.tooltip then
			local f = GameTooltip
			f:Hide()
			f:SetOwner(self, "ANCHOR_RIGHT")
			f:SetText(self.Label:GetText(), 1, 1, 1, 1, true)
			f:AddLine(self.tooltip, 1, 0.82, 0, true)
			if self.tooltip2 then
				local tooltip2
				if type(self.tooltip2) == "function" then
					tooltip2 = self.tooltip2()
				else
					tooltip2 = self.tooltip2
				end
				if tooltip2 then
					f:AddLine(" ", 1, 0.82, 0, true)
					f:AddLine(tooltip2, 1, 0.82, 0, true)
				end
			end
			f:Show()
		end

		if self.onEnterFunc then
			self.onEnterFunc(self)
		end
	end

	function CheckboxMixin:OnLeave()
		GameTooltip:Hide()

		if self.onLeaveFunc then
			self.onLeaveFunc(self)
		end
	end

	function CheckboxMixin:OnClick()
		local newState

		if self.dbKey and ElvUI and self.dbKey == "UIScale" then
			addon.SetDBValue(self.dbKey, false)
		elseif self.dbKey then
			newState = not addon.GetDBValue(self.dbKey)
			addon.SetDBValue(self.dbKey, newState)
			self:SetChecked(newState)
		else
			newState = not self:GetChecked()
			self:SetChecked(newState)
		end

		if self.onClickFunc then
			self.onClickFunc(self, newState)
		end

		if self.checked then
			PlaySound(SFX_CHECKBOX_ON)
		else
			PlaySound(SFX_CHECKBOX_OFF)
		end

		GameTooltip:Hide()
	end

	function CheckboxMixin:GetChecked()
		return self.checked
	end

	function CheckboxMixin:SetChecked(state)
		state = state or false
		self.CheckedTexture:SetShown(state)
		self.checked = state
	end

	function CheckboxMixin:SetFixedWidth(width)
		self.fixedWidth = width
		self:SetWidth(width)
	end

	function CheckboxMixin:SetMaxWidth(maxWidth)
		--this width includes box and label
		self.Label:SetWidth(maxWidth - LABEL_OFFSET)
		self.SetWidth(maxWidth)
	end

	function CheckboxMixin:SetLabel(label)
		self.Label:SetText(label)
		local width = self.Label:GetWrappedWidth() + LABEL_OFFSET
		local height = self.Label:GetHeight()
		local lines = self.Label:GetNumLines()

		self.Label:ClearAllPoints()
		if lines > 1 then
			self.Label:SetPoint("TOPLEFT", self, "TOPLEFT", LABEL_OFFSET, -4)
		else
			self.Label:SetPoint("LEFT", self, "LEFT", LABEL_OFFSET, 0)
		end

		if self.fixedWidth then
			return self.fixedWidth
		else
			self:SetWidth(math.max(BUTTON_HITBOX_MIN_WIDTH, width))
			return width
		end
	end

	function CheckboxMixin:SetDBKey(dbKey)
		self.dbKey = dbKey
	end

	function CheckboxMixin:SetData(data)
		self.dbKey = data.dbKey
		self.tooltip = data.tooltip
		self.tooltip2 = data.tooltip2
		self.onClickFunc = data.onClickFunc
		self.onEnterFunc = data.onEnterFunc
		self.onLeaveFunc = data.onLeaveFunc

		if data.label then
			return self:SetLabel(data.label)
		else
			return 0
		end
	end

	local function CreateCheckbox(parent, name, size)
		size = size or BUTTON_MIN_SIZE

		local b = CreateFrame("Button", name, parent)
		b:SetSize(size, size)

		b.Label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		b.Label:SetJustifyH("LEFT")
		b.Label:SetJustifyV("TOP")
		b.Label:SetTextColor(1, 0.82, 0) --labelcolor
		b.Label:SetPoint("LEFT", b, "LEFT", LABEL_OFFSET, 0)

		b.Border = b:CreateTexture(nil, "ARTWORK")
		b.Border:SetTexture(Def.CheckboxTexture)
		b.Border:SetTexCoord(0, 0.5, 0, 0.5)
		b.Border:SetPoint("CENTER", b, "LEFT", 14, 0)
		b.Border:SetSize(size, size)
		DisableSharpening(b.Border)

		b.CheckedTexture = b:CreateTexture(nil, "OVERLAY")
		b.CheckedTexture:SetTexture(Def.CheckboxTexture)
		b.CheckedTexture:SetTexCoord(0.5, 0.75, 0.5, 0.75)
		b.CheckedTexture:SetPoint("CENTER", b.Border, "CENTER", 0, 0)
		b.CheckedTexture:SetSize(size / 2.4, size / 2.4)
		DisableSharpening(b.CheckedTexture)
		b.CheckedTexture:Hide()

		b.Highlight = b:CreateTexture(nil, "HIGHLIGHT")
		b.Highlight:SetTexture(Def.CheckboxTexture)
		b.Highlight:SetTexCoord(0, 0.5, 0.5, 1)
		b.Highlight:SetPoint("CENTER", b.Border, "CENTER", 0, 0)
		b.Highlight:SetSize(size, size)
		DisableSharpening(b.Highlight)

		Mixin(b, CheckboxMixin)
		b:SetScript("OnClick", CheckboxMixin.OnClick)
		b:SetScript("OnEnter", CheckboxMixin.OnEnter)
		b:SetScript("OnLeave", CheckboxMixin.OnLeave)

		return b
	end

	local function CreateCheckboxOnly(parent, name, size)
		size = size or BUTTON_MIN_SIZE

		local b = CreateFrame("Button", name, parent)
		b:SetSize(size, size)

		b.Border = b:CreateTexture(nil, "ARTWORK")
		b.Border:SetTexture(Def.CheckboxTexture)
		b.Border:SetTexCoord(0.13, 0.38, 0.13, 0.38)
		b.Border:SetPoint("CENTER")
		b.Border:SetSize(size, size)
		DisableSharpening(b.Border)

		b.CheckedTexture = b:CreateTexture(nil, "OVERLAY")
		b.CheckedTexture:SetTexture(Def.CheckboxTexture)
		b.CheckedTexture:SetTexCoord(0.5, 0.75, 0.5, 0.75)
		b.CheckedTexture:SetPoint("CENTER", b.Border, "CENTER", -1, -1)
		b.CheckedTexture:SetSize(size / 1.22, size / 1.22)
		DisableSharpening(b.CheckedTexture)
		b.CheckedTexture:Hide()

		b.Highlight = b:CreateTexture(nil, "HIGHLIGHT")
		b.Highlight:SetTexture(Def.CheckboxTexture)
		b.Highlight:SetTexCoord(0.13, 0.38, 0.63, 0.88)

		b.Highlight:SetPoint("CENTER", b.Border, "CENTER", 0, 0)
		b.Highlight:SetSize(size, size)
		DisableSharpening(b.Highlight)

		Mixin(b, CheckboxMixin)
		b:SetScript("OnClick", CheckboxMixin.OnClick)
		b:SetScript("OnEnter", CheckboxMixin.OnEnter)
		b:SetScript("OnLeave", CheckboxMixin.OnLeave)

		return b
	end

	addon.CreateCheckbox = CreateCheckbox
	addon.CreateCheckboxOnly = CreateCheckboxOnly
end

do --Blizzard Check Button
	local BlizzardCheckButtonMixin = {}

	BlizzardCheckButtonMixin.ButtonMixin = {}
	do
		function BlizzardCheckButtonMixin.ButtonMixin:OnEnter()
			if self.tooltip1 then
				local tooltip1, tooltip2
				if type(self.tooltip1 == "function") then
					tooltip1, tooltip2 = self.tooltip1()
				else
					tooltip1 = self.tooltip1
					tooltip2 = self.tooltip2
				end

				if tooltip1 then
					local GameTooltip = GameTooltip
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText(tooltip1, 1, 1, 1)
					if tooltip2 then
						GameTooltip:AddLine(tooltip2, 1, 0.82, 0, true)
					end
					GameTooltip:Show()
				end
			end
		end

		function BlizzardCheckButtonMixin.ButtonMixin:OnLeave()
			GameTooltip:Hide()
		end

		function BlizzardCheckButtonMixin.ButtonMixin:OnClick()
			local checked = self:GetChecked()
			local dbKey = self:GetParent().dbKey

			if dbKey then
				addon.SetDBValue(dbKey, checked, true)
			end
			if self.onCheckedFunc then
				self.onCheckedFunc(self, checked)
			end

			if checked then
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			else
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
			end
		end
	end

	function BlizzardCheckButtonMixin:SetLabel(label)
		self.Label:SetText(label)
		self:Layout()
	end

	function BlizzardCheckButtonMixin:Layout()
		local textWidth = 5 + self.Label:GetWrappedWidth()
		self:SetSize(API.Round(32 + textWidth + 6), 32)
		self.Button:SetHitRectInsets(0, -textWidth, 0, 0)
	end

	function BlizzardCheckButtonMixin:SetTooltip(tooltip1, tooltip2)
		self.Button.tooltip1 = tooltip1
		self.Button.tooltip2 = tooltip2
	end

	function BlizzardCheckButtonMixin:SetChecked(state)
		self.Button:SetChecked(state)
	end

	function BlizzardCheckButtonMixin:GetChecked()
		return self.Button:GetChecked()
	end

	function BlizzardCheckButtonMixin:SetDBKey(dbKey)
		self.dbKey = dbKey
	end

	function BlizzardCheckButtonMixin:SetOnCheckedFunc(onCheckedFunc)
		self.Button.onCheckedFunc = onCheckedFunc
	end

	function addon.CreateBlizzardCheckButton(parent)
		local f = CreateFrame("Frame", nil, parent, "AeonToolsBlizzardCheckButtonTemplate")
		Mixin(f, BlizzardCheckButtonMixin)
		Mixin(f.Button, BlizzardCheckButtonMixin.ButtonMixin)
		for method, func in pairs(BlizzardCheckButtonMixin.ButtonMixin) do
			f.Button:SetScript(method, func)
		end
		return f
	end
end

do --Slider
	local SliderFrameMixin = {}

	local TEX_COORDS = {
		Thumb_Nomral = { 0, 0.5, 0, 0.25 },
		Thumb_Disable = { 0.5, 1, 0, 0.25 },
		Thumb_Highlight = { 0, 0.5, 0.25, 0.5 },

		Back_Nomral = { 0, 0.25, 0.5, 0.625 },
		Back_Disable = { 0.25, 0.5, 0.5, 0.625 },
		Back_Highlight = { 0.5, 0.75, 0.5, 0.625 },

		Forward_Nomral = { 0, 0.25, 0.625, 0.75 },
		Forward_Disable = { 0.25, 0.5, 0.625, 0.75 },
		Forward_Highlight = { 0.5, 0.75, 0.625, 0.75 },

		Slider_Left = { 0, 0.125, 0.875, 1 },
		Slider_Middle = { 0.125, 0.375, 0.875, 1 },
		Slider_Right = { 0.375, 0.5, 0.875, 1 },
	}

	local function SetTextureCoord(texture, key)
		texture:SetTexCoord(unpack(TEX_COORDS[key]))
	end

	local SharedMethods = {
		"GetValue",
		"SetValue",
		"SetMinMaxValues",
	}

	for k, v in ipairs(SharedMethods) do
		SliderFrameMixin[v] = function(self, ...)
			return self.Slider[v](self.Slider, ...)
		end
	end

	local SliderScripts = {}

	function SliderScripts:OnMinMaxChanged(min, max)
		if self.formatMinMaxValueFunc then
			self.formatMinMaxValueFunc(min, max)
		end
	end

	function SliderScripts:OnValueChanged(value, userInput)
		if value ~= self.value then
			self.value = value
		else
			return
		end

		self.ThumbTexture:SetPoint("CENTER", self.Thumb, "CENTER", 0, 0)

		if self.ValueText then
			if self.formatValueFunc then
				self.ValueText:SetText(self.formatValueFunc(value))
			else
				self.ValueText:SetText(value)
			end
		end

		if userInput then
			if self.onValueChangedFunc then
				self.onValueChangedFunc(value, true)
			end
		end
	end

	function SliderScripts:OnMouseDown()
		if self:IsEnabled() then
			self:LockHighlight()
			self:GetParent().isDraggingThumb = true
			if self.onMouseDownFunc then
				self.onMouseDownFunc(self)
			end
		else
			self:GetParent().isDraggingThumb = false
		end
		GameTooltip:Hide()
	end

	function SliderScripts:OnMouseUp()
		self:UnlockHighlight()
		self:GetParent().isDraggingThumb = false
		if self.onMouseUpFunc then
			self.onMouseUpFunc(self)
		end
	end

	local ValueFormatter = {}

	function ValueFormatter.NoChange(value)
		return value
	end

	function ValueFormatter.Percentage(value)
		return string.format("%.0f%%", value * 100)
	end

	function ValueFormatter.Decimal0(value)
		return string.format("%.0f", value)
	end

	function ValueFormatter.Decimal1(value)
		return string.format("%.1f", value)
	end

	function ValueFormatter.Decimal2(value)
		return string.format("%.2f", value)
	end

	local function BackForwardButton_OnClick(self)
		if self.delta then
			self:GetParent():SetValueByDelta(self.delta, true)
		end
	end

	function SliderFrameMixin:OnLoad()
		for k, v in pairs(SliderScripts) do
			self.Slider:SetScript(k, v)
		end

		self.Back:SetScript("OnClick", BackForwardButton_OnClick)
		self.Forward:SetScript("OnClick", BackForwardButton_OnClick)

		self.Slider.Left:SetTexture(Def.SliderTexture)
		self.Slider.Middle:SetTexture(Def.SliderTexture)
		self.Slider.Right:SetTexture(Def.SliderTexture)
		self.Slider.ThumbTexture:SetTexture(Def.SliderTexture)
		self.Slider.ThumbHighlight:SetTexture(Def.SliderTexture)
		self.Slider.ThumbHighlight:SetBlendMode("ADD")
		self.Slider.ThumbHighlight:SetVertexColor(0.5, 0.5, 0.5)

		SetTextureCoord(self.Slider.Left, "Slider_Left")
		SetTextureCoord(self.Slider.Middle, "Slider_Middle")
		SetTextureCoord(self.Slider.Right, "Slider_Right")
		SetTextureCoord(self.Slider.ThumbTexture, "Thumb_Nomral")
		SetTextureCoord(self.Slider.ThumbHighlight, "Thumb_Highlight")

		self.Back.Texture:SetTexture(Def.SliderTexture)
		self.Back.Highlight:SetTexture(Def.SliderTexture)
		SetTextureCoord(self.Back.Texture, "Back_Nomral")
		SetTextureCoord(self.Back.Highlight, "Back_Highlight")
		self.Back.Highlight:SetBlendMode("ADD")
		self.Back.Highlight:SetVertexColor(0.5, 0.5, 0.5)

		self.Forward.Texture:SetTexture(Def.SliderTexture)
		self.Forward.Highlight:SetTexture(Def.SliderTexture)
		SetTextureCoord(self.Forward.Texture, "Forward_Nomral")
		SetTextureCoord(self.Forward.Highlight, "Forward_Highlight")
		self.Forward.Highlight:SetBlendMode("ADD")
		self.Forward.Highlight:SetVertexColor(0.5, 0.5, 0.5)

		self:SetMinMaxValues(0, 100)
		self:SetValueStep(10)
		self:SetObeyStepOnDrag(true)
		self:SetValue(0)

		self:Enable()

		DisableSharpening(self.Slider.Left)
		DisableSharpening(self.Slider.Middle)
		DisableSharpening(self.Slider.Right)

		self:SetLabelWidth(144)

		local function OnEnter()
			self:OnEnter()
		end

		local function OnLeave()
			self:OnLeave()
		end

		self:SetScript("OnEnter", OnEnter)
		self:SetScript("OnLeave", OnLeave)
		self.Back:SetScript("OnEnter", OnEnter)
		self.Back:SetScript("OnLeave", OnLeave)
		self.Forward:SetScript("OnEnter", OnEnter)
		self.Forward:SetScript("OnLeave", OnLeave)
		self.Slider:SetScript("OnEnter", OnEnter)
		self.Slider:SetScript("OnLeave", OnLeave)

		self:SetFormatValueFunc(nil)
	end

	function SliderFrameMixin:Enable()
		self.Slider:Enable()
		self.Back:Enable()
		self.Forward:Enable()
		SetTextureCoord(self.Slider.ThumbTexture, "Thumb_Nomral")
		SetTextureCoord(self.Back.Texture, "Back_Nomral")
		SetTextureCoord(self.Forward.Texture, "Forward_Nomral")
		self.Label:SetTextColor(1, 1, 1)
		self.RightText:SetTextColor(1, 0.82, 0)
	end

	function SliderFrameMixin:Disable()
		self.Slider:Disable()
		self.Back:Disable()
		self.Forward:Disable()
		self.Slider:UnlockHighlight()
		SetTextureCoord(self.Slider.ThumbTexture, "Thumb_Disable")
		SetTextureCoord(self.Back, "Back_Disable")
		SetTextureCoord(self.Forward.Texture, "Forward_Disable")
		self.Label:SetTextColor(0.5, 0.5, 0.5)
		self.RightText:SetTextColor(0.5, 0.5, 0.5)
	end

	function SliderFrameMixin:SetValueByDelta(delta, userInput)
		local value = self:GetValue()
		self:SetValue(value + delta)

		if userInput then
			if self.onValueChangedFunc then
				self.onValueChangedFunc(self:GetValue())
			end
		end
	end

	function SliderFrameMixin:SetValueStep(valueStep)
		self.Slider:SetValueStep(valueStep)
		self.Back.delta = -valueStep
		self.Forward.delta = valueStep
	end

	function SliderFrameMixin:SetObeyStepOnDrag(obey)
		self.Slider:SetObeyStepOnDrag(obey)
		if not obey then
			local min, max = self.GetMinMaxValues()
			local delta = (max - min) * 0.1
			self.Back.delta = -delta
			self.Forward.delta = delta
		end
	end

	function SliderFrameMixin:SetLabel(label)
		self.Label:SetText(label)
	end

	function SliderFrameMixin:SetFormatValueFunc(formatValueFunc)
		if not formatValueFunc then
			formatValueFunc = ValueFormatter.NoChange
		end
		self.Slider.formatValueFunc = formatValueFunc
		self.RightText:SetText(formatValueFunc(self:GetValue() or 0))
	end

	function SliderFrameMixin:SetFormatValueMethod(method)
		self:SetFormatValueFunc(ValueFormatter[method])
	end

	function SliderFrameMixin:SetOnValueChangedFunc(onValueChangedFunc)
		self.Slider.onValueChangedFunc = onValueChangedFunc
		self.onValueChangedFunc = onValueChangedFunc
	end

	function SliderFrameMixin:SetOnMouseDownFunc(onMouseDownFunc)
		self.Slider.onMouseDownFunc = onMouseDownFunc
	end

	function SliderFrameMixin:SetOnMouseUpFunc(onMouseUpFunc)
		self.Slider.onMouseUpFunc = onMouseUpFunc
	end

	function SliderFrameMixin:SetLabelWidth(width)
		self.Label:SetWidth(width)
		self:SetWidth(242 + width)
		self.Slider:SetPoint("LEFT", self, "LEFT", 28 + width, 0)
	end

	function SliderFrameMixin:OnEnter()
		if self.tooltip then
			local f = GameTooltip
			f:Hide()
			f:SetOwner(self, "ANCHOR_RIGHT")
			f:SetText(self.Label:GetText(), 1, 1, 1, 1, true)
			f:AddLine(self.tooltip, 1, 0.82, 0, true)
			if self.tooltip2 then
				local tooltip2
				if type(self.tooltip2) == "function" then
					tooltip2 = self.tooltip2()
				else
					tooltip2 = self.tooltip2
				end
				if tooltip2 then
					f:AddLine(" ", 1, 0.82, 0, true)
					f:AddLine(tooltip2, 1, 0.82, 0, true)
				end
			end
			f:Show()
		end
		if self.onEnterFunc then
			self.onEnterFunc(self)
		end
	end

	function SliderFrameMixin:OnLeave()
		GameTooltip:Hide()
		if self.onLeaveFunc and not self.isDraggingThumb then
			self.onLeaveFunc(self)
		end
	end

	function SliderFrameMixin:IsDraggingThumb()
		return self.isDraggingThumb
	end

	function SliderFrameMixin:SetEnabled(enabled)
		if enabled then
			self:Enable()
		else
			self:Disable()
		end
	end

	local function CreateSlider(parent)
		local f = CreateFrame("Frame", nil, parent, "AeonToolsMinimalSliderWithControllerTemplate")
		Mixin(f, SliderFrameMixin)

		f.Slider.ValueText = f.RightText
		f.Slider.Back = f.Back
		f.Slider.Forward = f.Forward

		f:OnLoad()

		return f
	end
	addon.CreateSlider = CreateSlider
end

do --UIPanelButton
	local UIPanelButtonMixin = {}

	function UIPanelButtonMixin:OnClick(button) end

	function UIPanelButtonMixin:SetButtonState(stateIndex)
		--1 Normal  2 Pushed  3 Disabled
		if stateIndex == 1 then
			self.Background:SetTexCoord(0 / 512, 128 / 512, 0, 0.125)
		elseif stateIndex == 2 then
			self.Background:SetTexCoord(132 / 512, 260 / 512, 0, 0.125)
		elseif stateIndex == 3 then
			self.Background:SetTexCoord(264 / 512, 392 / 512, 0, 0.125)
		end
	end

	function UIPanelButtonMixin:OnMouseDown(button)
		if self:IsEnabled() then
			self:SetButtonState(2)
		end
	end

	function UIPanelButtonMixin:OnMouseUp(button)
		if self:IsEnabled() then
			self:SetButtonState(1)
		end
	end

	function UIPanelButtonMixin:OnDisable()
		self:SetButtonState(3)
	end

	function UIPanelButtonMixin:OnEnable()
		self:SetButtonState(1)
	end

	function UIPanelButtonMixin:OnEnter() end

	function UIPanelButtonMixin:OnLeave() end

	function UIPanelButtonMixin:SetButtonText(text)
		self:SetText(text)
	end

	local function CreateUIPanelButton(parent)
		local f = CreateFrame("Button", nil, parent)
		f:SetSize(144, 24)
		Mixin(f, UIPanelButtonMixin)

		f:SetScript("OnMouseDown", f.OnMouseDown)
		f:SetScript("OnMouseUp", f.OnMouseUp)
		f:SetScript("OnEnter", f.OnEnter)
		f:SetScript("OnLeave", f.OnLeave)
		f:SetScript("OnEnable", f.OnEnable)
		f:SetScript("OnDisable", f.OnDisable)

		f.Background = f:CreateTexture(nil, "BACKGROUND")
		f.Background:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/UIPanelButton")
		f.Background:SetTextureSliceMargins(32, 16, 32, 16)
		f.Background:SetTextureSliceMode(1)
		f.Background:SetAllPoints(true)
		DisableSharpening(f.Background)

		f.Highlight = f:CreateTexture(nil, "HIGHLIGHT")
		f.Highlight:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/UIPanelButton")
		f.Highlight:SetTextureSliceMargins(32, 16, 32, 16)
		f.Highlight:SetTextureSliceMode(0)
		f.Highlight:SetAllPoints(true)
		f.Highlight:SetBlendMode("ADD")
		f.Highlight:SetVertexColor(0.5, 0.5, 0.5)
		f.Highlight:SetTexCoord(396 / 512, 1, 0, 0.125)

		f:SetNormalFontObject("GameFontNormal")
		f:SetHighlightFontObject("GameFontHighlight")
		f:SetDisabledFontObject("GameFontDisable")
		f:SetPushedTextOffset(0, -1)

		f:SetButtonState(1)

		return f
	end
	addon.CreateUIPanelButton = CreateUIPanelButton
end

do --KeybindButton (Enhanced with Modifiers + Blizzard Integration)
	local KeybindListener = CreateFrame("Frame")

	function KeybindListener:SetOwner(keybindButton)
		if keybindButton:IsVisible() then
			self:OnHide()
			self:SetParent(keybindButton)
			self.owner = keybindButton
			self:SetScript("OnKeyDown", self.OnKeyDown)
			self:SetScript("OnMouseDown", self.OnMouseDown)
			self:EnableKeyboard(true)
			self:SetPropagateKeyboardInput(false)
			self:Show()
		end
	end

	function KeybindListener:OnHide()
		self:Hide()
		self:SetScript("OnKeyDown", nil)
		self:SetScript("OnMouseDown", nil)
		self:EnableKeyboard(false)
		if self.owner then
			self.owner:ListenKey(false)
			self.owner = nil
		end
	end

	KeybindListener:SetScript("OnHide", KeybindListener.OnHide)

	KeybindListener.invalidKeys = {
		ESCAPE = true,
		UNKNOWN = true,
		PRINTSCREEN = true,
		LSHIFT = true,
		RSHIFT = true,
		LCTRL = true,
		RCTRL = true,
		LALT = true,
		RALT = true,
	}

	-- Convert key to Blizzard binding format
	local function FormatKeybind(key, modifiers)
		local bindString = ""

		if modifiers.shift then
			bindString = bindString .. "SHIFT-"
		end
		if modifiers.ctrl then
			bindString = bindString .. "CTRL-"
		end
		if modifiers.alt then
			bindString = bindString .. "ALT-"
		end

		bindString = bindString .. key
		return bindString
	end

	-- Convert Blizzard binding format back to display
	local function ParseKeybind(bindString)
		if not bindString or bindString == "" then
			return nil, {}
		end

		local modifiers = {
			shift = bindString:match("SHIFT%-"),
			ctrl = bindString:match("CTRL%-"),
			alt = bindString:match("ALT%-"),
		}

		-- Extract the base key (everything after the last -)
		local key = bindString:match("([^%-]+)$")

		return key, modifiers
	end

	-- Display format: "Alt+C" instead of "ALT-C"
	local function GetDisplayText(bindString)
		if not bindString or bindString == "" then
			return NOT_BOUND or "Not Bound"
		end

		local key, modifiers = ParseKeybind(bindString)
		local display = ""

		if modifiers.shift then
			display = display .. "Shift+"
		end
		if modifiers.ctrl then
			display = display .. "Ctrl+"
		end
		if modifiers.alt then
			display = display .. "Alt+"
		end

		display = display .. key
		return display
	end

	function KeybindListener:OnKeyDown(key)
		-- If it's a pure modifier, ignore and wait for real key
		if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
			return
		end

		-- Hard-invalid keys that cancel listening
		if key == "ESCAPE" or key == "PRINTSCREEN" or key == "UNKNOWN" then
			self:Hide()
			return
		end

		-- Capture modifier state
		local modifiers = {
			shift = IsShiftKeyDown(),
			ctrl = IsControlKeyDown(),
			alt = IsAltKeyDown(),
		}

		if self.owner then
			local bindString = FormatKeybind(key, modifiers)

			-- Set in Blizzard keybind system if binding name is provided
			if self.owner.bindingName and not InCombatLockdown() then
				-- Clear existing bindings for this action
				local key1, key2 = GetBindingKey(self.owner.bindingName)
				if key1 then
					SetBinding(key1)
				end
				if key2 then
					SetBinding(key2)
				end

				-- Set new binding
				local success = SetBinding(bindString, self.owner.bindingName)
				if success then
					SaveBindings(GetCurrentBindingSet())
					addon:PrintDebug("Keybind set: " .. bindString .. " -> " .. self.owner.bindingName)
				else
					addon:PrintDebug("Failed to set keybind: " .. bindString)
				end
			end

			-- Update widget display
			self.owner:SetKeyText(bindString)

			-- Save to database
			if self.owner.dbKey then
				addon.SetDBValue(self.owner.dbKey, bindString, true)
			end
		end

		self:Hide()
	end

	function KeybindListener:OnMouseDown(button)
		-- Allow mouse buttons as keybinds
		local mouseKey
		if button == "LeftButton" then
			mouseKey = "BUTTON1"
		elseif button == "RightButton" then
			mouseKey = "BUTTON2"
		elseif button == "MiddleButton" then
			mouseKey = "BUTTON3"
		elseif button == "Button4" then
			mouseKey = "BUTTON4"
		elseif button == "Button5" then
			mouseKey = "BUTTON5"
		end

		if mouseKey and self.owner then
			local modifiers = {
				shift = IsShiftKeyDown(),
				ctrl = IsControlKeyDown(),
				alt = IsAltKeyDown(),
			}

			local bindString = FormatKeybind(mouseKey, modifiers)

			-- Set in Blizzard keybind system
			if self.owner.bindingName and not InCombatLockdown() then
				local key1, key2 = GetBindingKey(self.owner.bindingName)
				if key1 then
					SetBinding(key1)
				end
				if key2 then
					SetBinding(key2)
				end

				local success = SetBinding(bindString, self.owner.bindingName)
				if success then
					SaveBindings(GetCurrentBindingSet())
				end
			end

			self.owner:SetKeyText(bindString)

			if self.owner.dbKey then
				addon.SetDBValue(self.owner.dbKey, bindString, true)
			end
		end

		self:Hide()
	end

	local KeybindButtonMixin = {}

	function KeybindButtonMixin:OnClick(button)
		if button == "LeftButton" then
			self.isActive = not self.isActive
			self:ListenKey(self.isActive)
		else
			-- Right-click to clear binding
			self:ClearKeybind()
		end
	end

	function KeybindButtonMixin:ClearKeybind()
		-- Clear from Blizzard system
		if self.bindingName then
			local key1, key2 = GetBindingKey(self.bindingName)
			if key1 then
				SetBinding(key1)
			end
			if key2 then
				SetBinding(key2)
			end
			SaveBindings(GetCurrentBindingSet())
		end

		-- Clear from DB
		if self.dbKey then
			addon.SetDBValue(self.dbKey, nil, true)
		end

		-- Clear display
		self:SetKeyText(nil)

		self:ListenKey(false)
	end

	function KeybindButtonMixin:ListenKey(state)
		self.isActive = state
		if state then
			self:SetButtonState(3)
			KeybindListener:SetOwner(self)
		else
			self:SetButtonState(1)
			if KeybindListener.owner == self then
				KeybindListener:Hide()
			end
		end
	end

	function KeybindButtonMixin:SetButtonState(stateIndex)
		--1 Normal  2 Pushed  3 Activated
		if stateIndex == 1 then
			self.Background:SetTexCoord(0 / 512, 128 / 512, 68 / 512, 132 / 512)
			self.Highlight:SetTexCoord(396 / 512, 1, 68 / 512, 132 / 512)
			self:UnlockHighlight()
			self.Highlight:SetVertexColor(0.5, 0.5, 0.5)
		elseif stateIndex == 2 then
			self.Background:SetTexCoord(132 / 512, 260 / 512, 68 / 512, 132 / 512)
			self.Highlight:SetTexCoord(396 / 512, 1, 68 / 512, 132 / 512)
			self:UnlockHighlight()
			self.Highlight:SetVertexColor(0.5, 0.5, 0.5)
		elseif stateIndex == 3 then
			self.Background:SetTexCoord(0 / 512, 128 / 512, 68 / 512, 132 / 512)
			self.Highlight:SetTexCoord(270 / 512, 386 / 512, 68 / 512, 132 / 512)
			self.Highlight:SetVertexColor(0.8, 0.8, 0.8)
			self:LockHighlight()
		end
	end

	function KeybindButtonMixin:OnMouseDown(button)
		if not self.isActive then
			self:SetButtonState(2)
		end
	end

	function KeybindButtonMixin:OnMouseUp(button)
		if not self.isActive then
			self:SetButtonState(1)
		end
	end

	function KeybindButtonMixin:OnDisable() end

	function KeybindButtonMixin:OnEnable() end

	function KeybindButtonMixin:OnEnter()
		if self.tooltip then
			local f = GameTooltip
			f:Hide()
			f:SetOwner(self, "ANCHOR_RIGHT")
			f:SetText(self.Label:GetText(), 1, 1, 1, 1, true)
			f:AddLine(self.tooltip, 1, 0.82, 0, true)
			f:AddLine(" ", 1, 0.82, 0, true)
			f:AddLine("Left-click: Set keybind", 0.5, 0.5, 0.5, true)
			f:AddLine("Right-click: Clear keybind", 0.5, 0.5, 0.5, true)
			f:Show()
		end
	end

	function KeybindButtonMixin:OnLeave()
		GameTooltip:Hide()
	end

	function KeybindButtonMixin:SetLabel(text)
		self.Label:SetText(text)
		self.effectiveWidth = self:GetWidth() + 20 + self.Label:GetWrappedWidth()
	end

	function KeybindButtonMixin:SetKeyText(bindString)
		if bindString and type(bindString) == "string" and bindString ~= "" then
			local displayText = GetDisplayText(bindString)
			self:SetText(displayText)
			self.currentBind = bindString
		else
			local text = NOT_BOUND or "Not Bound"
			self:SetText("|cff808080" .. text .. "|r")
			self.currentBind = nil
		end
	end

	function KeybindButtonMixin:SetBindingName(bindingName)
		self.bindingName = bindingName

		-- Load existing binding from Blizzard system
		local key1, key2 = GetBindingKey(bindingName)
		if key1 then
			self:SetKeyText(key1)
			-- Also save to DB if dbKey is set
			if self.dbKey then
				addon.SetDBValue(self.dbKey, key1, true)
			end
		end
	end

	function KeybindButtonMixin:GetCurrentBind()
		return self.currentBind
	end

	local function CreateKeybindButton(parent)
		local f = CreateFrame("Button", nil, parent)
		f:SetSize(144, 24)
		f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		Mixin(f, KeybindButtonMixin)

		f:SetScript("OnMouseDown", f.OnMouseDown)
		f:SetScript("OnMouseUp", f.OnMouseUp)
		f:SetScript("OnEnter", f.OnEnter)
		f:SetScript("OnLeave", f.OnLeave)
		f:SetScript("OnEnable", f.OnEnable)
		f:SetScript("OnDisable", f.OnDisable)
		f:SetScript("OnClick", f.OnClick)

		f.Background = f:CreateTexture(nil, "BACKGROUND")
		f.Background:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Button/UIPanelButton")
		f.Background:SetTextureSliceMargins(32, 16, 32, 16)
		f.Background:SetTextureSliceMode(1)
		f.Background:SetAllPoints(true)
		DisableSharpening(f.Background)

		f.Highlight = f:CreateTexture(nil, "HIGHLIGHT")
		f.Highlight:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Button/UIPanelButton")
		f.Highlight:SetTextureSliceMargins(32, 16, 32, 16)
		f.Highlight:SetTextureSliceMode(0)
		f.Highlight:SetAllPoints(true)
		f.Highlight:SetBlendMode("ADD")
		f.Highlight:SetVertexColor(0.5, 0.5, 0.5)
		f.Highlight:SetTexCoord(396 / 512, 1, 68 / 512, 132 / 512)

		f:SetNormalFontObject("GameFontHighlight")
		f:SetHighlightFontObject("GameFontHighlight")
		f:SetDisabledFontObject("GameFontDisable")
		f:SetPushedTextOffset(0, -1)

		f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.Label:SetJustifyH("RIGHT")
		f.Label:SetJustifyV("MIDDLE")
		f.Label:SetTextColor(1, 0.82, 0)
		f.Label:SetPoint("RIGHT", f, "LEFT", -20, 0)
		f.Label:SetWidth(144)

		f.effectiveWidth = 288
		f.align = "center"

		f:SetButtonState(1)

		return f
	end
	addon.CreateKeybindButton = CreateKeybindButton
end

do --Button Highlight
	local function CreateButtonHighlight(parent)
		local f = CreateFrame("Frame", nil, parent)
		f:Hide()
		f:SetUsingParentLevel(true)
		f:SetSize(232, 40)
		local tex = f:CreateTexture(nil, "BACKGROUND")
		f.Texture = tex
		tex:SetAllPoints(true)
		tex:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/HorizontalButtonHighlight")
		tex:SetBlendMode("ADD")
		tex:SetVertexColor(51 / 255, 29 / 255, 17 / 255)
		return f
	end
	Util.CreateButtonHighlight = CreateButtonHighlight
end

do --Frame Reposition Button
	local GetScaledCursorPosition = API.GetScaledCursorPosition

	local function OnUpdate_Frequency(self, elapsed)
		self.t = self.t + elapsed
		if self.t > 0.016 then
			self.t = 0
			return true
		end
		return false
	end

	local function OnUpdate_OnMoving(self, elapsed)
		if OnUpdate_Frequency(self, elapsed) then
			local x, y = GetScaledCursorPosition()
			local offsetX, offsetY
			local anyChange

			if self.orientation == "x" then
				offsetX = x - self.fromX
				if offsetX ~= self.offsetX then
					self.offsetX = offsetX
					anyChange = true
				end
			elseif self.orientation == "y" then
				offsetY = y - self.fromX
				if offsetY ~= self.offsetY then
					self.offsetY = offsetY
					anyChange = true
				end
			end

			if anyChange then
				self.frameToControl:RepositionFrame(offsetX, offsetY)
			end
		end
	end

	local function OnUpdate_MonitorDiff(self, elapsed)
		--start moving Owner once the cursor moves 2 units
		if OnUpdate_Frequency(self, elapsed) then
			local diff = 0
			local x, y = GetScaledCursorPosition()
			if self.orientation == "x" then
				diff = x - self.fromX
			elseif self.orientation == "y" then
				diff = y - self.fromY
			end
			if diff < 0 then
				diff = -diff
			end
			if diff >= 4 then --Threshold
				self.fromX, self.fromY = x, y
				self.isMovingFrame = true
				self:OnLeave()
				self.frameToControl:SnapShotFramePosition()
				self:SetScript("OnUpdate", OnUpdate_OnMoving)
			end
		end
	end

	local RepositionButtonMixin = {}

	function RepositionButtonMixin:OnMouseDown(button)
		if self:IsEnabled() then
			self.Icon:SetPoint("CENTER", self, "CENTER", 0, -1)
			if button == "LeftButton" then
				--Pre Frame Reposition
				self:LockHighlight()
				self.t = 0
				self.fromX, self.fromY = GetScaledCursorPosition()
				self:SetScript("OnUpdate", OnUpdate_MonitorDiff)
			end
		end
	end

	function RepositionButtonMixin:StopReposition()
		self:SetScript("OnUpdate", nil)
		self.isMovingFrame = false
		self.fromX, self.fromY = nil, nil
		self.offsetX, self.offsetY = nil, nil
	end

	function RepositionButtonMixin:OnMouseUp()
		if self.isMovingFrame then
			self.frameToControl:ConfirmNewPosition()
			self:StopReposition()
		end
		self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0)
		self:UnlockHighlight()
	end

	function RepositionButtonMixin:OnClick(button)
		if button == "RightButton" then
			self:OnDoubleClick()
		end
	end

	function RepositionButtonMixin:OnDoubleClick()
		self:StopReposition()
		if self.frameToControl then
			self.frameToControl:ResetFramePosition()
		end
	end

	function RepositionButtonMixin:OnEnable()
		self.Icon:SetDesaturated(false)
		self.Icon:SetVertexColor(1, 1, 1)
		self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0)
		self:RefreshOnEnter()
	end

	function RepositionButtonMixin:OnDisable()
		self.Icon:SetDesaturated(true)
		self.Icon:SetVertexColor(0.8, 0.8, 0.8)
		self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0)
		--self.Highlight:Hide();
		self:RefreshOnEnter()
	end

	function RepositionButtonMixin:RefreshOnEnter()
		if self:IsVisible() and self:IsMouseOver() then
			self:OnEnter()
		end
	end

	function RepositionButtonMixin:OnShow() end

	function RepositionButtonMixin:OnHide()
		self:StopReposition()
	end

	function RepositionButtonMixin:OnEnter()
		if self.isMovingFrame then
			return
		end
		--self.Highlight:Show();

		-- local tooltip = GameTooltip;
		-- tooltip:Hide();
		-- tooltip:SetOwner(self, "ANCHOR_RIGHT");

		-- if self.orientation == "x" then
		-- 	tooltip:SetText(L["Horizontal_Reposition"], 1, 1, 1);
		-- end

		-- tooltip:AddLine(L["Reposition_Tooltip"], 1, 0.82, 0, true);
		-- tooltip:Show();
	end

	function RepositionButtonMixin:OnLeave()
		GameTooltip:Hide()
		-- self.Highlight:Hide();
	end

	function RepositionButtonMixin:SetOrientation(xy)
		self.orientation = xy
		local tex
		if xy == "x" then
			tex = "Interface/AddOns/AeonTools/Assets/Settings/Button/MoveButton-X"
		elseif xy == "y" then
			tex = "Interface/AddOns/AeonTools/Assets/Settings/Button/MoveButton-Y"
		end
		self.Highlight:SetTexture(tex)
		self.Icon:SetTexture(tex)
	end

	local function CreateRepositionButton(frameToControl, size)
		local btnSize = size or 20
		local button = CreateFrame("Button", nil, frameToControl)
		button.frameToControl = frameToControl
		button:SetSize(btnSize, btnSize)
		button:SetMotionScriptsWhileDisabled(true)
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		Mixin(button, RepositionButtonMixin)

		local tex = "Interface/AddOns/AeonTools/Assets/Settings/Button/MoveButton-X"

		local hlSize = size and (size + 12) or 32
		button.Highlight = button:CreateTexture(nil, "HIGHLIGHT")
		--button.Highlight:Hide();
		button.Highlight:SetSize(hlSize, hlSize)
		button.Highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
		button.Highlight:SetTexture(tex)
		button.Highlight:SetTexCoord(0.5, 1, 0, 1)

		local iconSize = size and (size + 12) or 32
		button.Icon = button:CreateTexture(nil, "ARTWORK")
		button.Icon:SetSize(iconSize, iconSize)
		button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0)
		button.Icon:SetTexture(tex)
		button.Icon:SetTexCoord(0, 0.5, 0, 1)

		button:SetScript("OnMouseDown", button.OnMouseDown)
		button:SetScript("OnMouseUp", button.OnMouseUp)
		button:SetScript("OnClick", button.OnClick)
		button:SetScript("OnDoubleClick", button.OnDoubleClick)
		button:SetScript("OnEnable", button.OnEnable)
		button:SetScript("OnDisable", button.OnDisable)
		button:SetScript("OnShow", button.OnShow)
		button:SetScript("OnHide", button.OnHide)
		button:SetScript("OnEnter", button.OnEnter)
		button:SetScript("OnLeave", button.OnLeave)

		return button
	end
	addon.CreateRepositionButton = CreateRepositionButton
end

local MainDropdownMenu
local MainContextMenu
do --Dropdown Menu
	local SharedMenuMixin = {}
	local MenuButtonMixin = {}

	function MenuButtonMixin:OnEnter()
		self.Text:SetTextColor(1, 1, 1)
		self.parent:HighlightButton(self)
		if self.tooltip then
			local tooltip = GameTooltip
			tooltip:SetOwner(self, "ANCHOR_NONE")
			tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 4, 4)
			tooltip:SetText(self.Text:GetText(), 1, 1, 1, 1, true)
			tooltip:AddLine(self.tooltip, 1, 0.82, 0, true)
			tooltip:Show()
		end
	end

	function MenuButtonMixin:OnLeave()
		self:UpdateVisual()
		self.parent:HighlightButton(nil)
		GameTooltip:Hide()
	end

	function MenuButtonMixin:UpdateVisual()
		if self.isHeader then
			self.Text:SetTextColor(148 / 255, 124 / 255, 102 / 255) --0.804, 0.667, 0.498
			return
		end

		if self:IsEnabled() then
			if self.isDangerousAction then
				self.Text:SetTextColor(1.000, 0.125, 0.125)
			else
				self.Text:SetTextColor(215 / 255, 192 / 255, 163 / 255) --0.922, 0.871, 0.761
			end
			self.LeftTexture:SetDesaturated(false)
			self.LeftTexture:SetVertexColor(1, 1, 1)
		else
			self.Text:SetTextColor(0.5, 0.5, 0.5)
			self.LeftTexture:SetDesaturated(true)
			self.LeftTexture:SetVertexColor(0.6, 0.6, 0.6)
		end
	end

	function MenuButtonMixin:OnClick(button)
		if self.onClickFunc then
			self.onClickFunc(button)
		end

		if self.closeAfterClick then
			self.parent:HideMenu()
		elseif self.refreshAfterClick then
			self.parent:RefreshMenu()
		end
	end

	function MenuButtonMixin:SetLeftText(text)
		self.Text:SetText(text)
	end

	function MenuButtonMixin:SetRightTexture(icon)
		self.RightTexture:SetTexture(icon)
		if icon then
			self.rightOffset = 20
		else
			self.rightOffset = 4
		end
	end

	function MenuButtonMixin:SetRegular()
		self.leftOffset = 4
		self.selected = nil
		self.isHeader = nil
		self.LeftTexture:Hide()
		self:Layout()
	end

	function MenuButtonMixin:SetHeader(text)
		self.leftOffset = 4
		self.selected = nil
		self.isHeader = true
		self.LeftTexture:Hide()
		self.Text:SetText(text)
		self:Disable()
		self:Layout()
	end

	function MenuButtonMixin:SetRadio(selected)
		self.leftOffset = 20
		self.selected = selected
		self.isHeader = nil
		self.refreshAfterClick = true
		self.LeftTexture:SetTexture(
			"Interface/AddOns/AeonTools/Assets/Settings/Button/DropdownMenu",
			nil,
			nil,
			"LINEAR"
		)
		if selected then
			self.LeftTexture:SetTexCoord(32 / 512, 64 / 512, 0 / 512, 32 / 512)
		else
			self.LeftTexture:SetTexCoord(0 / 512, 32 / 512, 0 / 512, 32 / 512)
		end
		self.LeftTexture:Show()
		self:Layout()
	end

	function MenuButtonMixin:SetCheckbox(selected)
		self.leftOffset = 20
		self.selected = selected
		self.isHeader = nil
		self.refreshAfterClick = true
		self.LeftTexture:SetTexture(
			"Interface/AddOns/AeonTools/Assets/Settings/Button/DropdownMenu",
			nil,
			nil,
			"LINEAR"
		)
		if selected then
			self.LeftTexture:SetTexCoord(96 / 512, 128 / 512, 0 / 512, 32 / 512)
		else
			self.LeftTexture:SetTexCoord(64 / 512, 96 / 512, 0 / 512, 32 / 512)
		end
		self.LeftTexture:Show()
		self:Layout()
	end

	function MenuButtonMixin:Layout()
		self.Text:SetPoint("LEFT", self, "LEFT", self.paddingH + self.leftOffset, 0)
	end

	function MenuButtonMixin:GetContentWidth()
		return self.Text:GetWrappedWidth() + self.leftOffset + self.rightOffset + 2 * self.paddingH
	end

	local function CreateMenuButton(parent)
		local f = CreateFrame("Button", nil, parent)
		f:SetSize(240, 24)
		Mixin(f, MenuButtonMixin)
		f.leftOffset = 0
		f.rightOffset = 0
		f.paddingH = 8

		f.Text = f:CreateFontString(nil, "OVERLAY")
		f.Text:SetPoint("LEFT", f, "LEFT", f.paddingH, 0)
		f.Text:SetJustifyH("LEFT")
		f.Text:SetTextColor(0.922, 0.871, 0.761)

		f.LeftTexture = f:CreateTexture(nil, "OVERLAY")
		f.LeftTexture:SetSize(16, 16)
		f.LeftTexture:SetPoint("LEFT", f, "LEFT", f.paddingH, 0)
		f.LeftTexture:Hide()

		f.RightTexture = f:CreateTexture(nil, "OVERLAY")
		f.RightTexture:SetSize(18, 18)
		f.RightTexture:SetPoint("RIGHT", f, "RIGHT", -f.paddingH, 0)

		f.RightText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.RightText:SetPoint("LEFT", f, "LEFT", f.paddingH, 0)
		f.RightText:SetJustifyH("LEFT")
		f.RightText:SetTextColor(0.922, 0.871, 0.761)
		f.RightText:Hide()

		f:SetScript("OnEnter", f.OnEnter)
		f:SetScript("OnLeave", f.OnLeave)
		f:SetScript("OnClick", f.OnClick)

		function f:SetFont(fontPath, size, flags)
			size = size or 12
			flags = flags or "OUTLINE" -- or "" if you prefer no outline
			f.Text:SetFont(fontPath or "Fonts\\FRIZQT__.TTF", size, flags)
		end
		f:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

		return f
	end

	function SharedMenuMixin:SetSize(width, height)
		if width < 40 then
			width = 40
		end

		if height < 40 then
			height = 40
		end

		if self.Frame then
			self.Frame:SetSize(width, height)
		end
	end

	function SharedMenuMixin:SetPaddingV(paddingV)
		self.paddingV = paddingV
	end

	function SharedMenuMixin:SetContentSize(width, height)
		local padding = 2 * self.paddingV
		self:SetSize(width, height + padding)
	end

	function SharedMenuMixin:Show()
		if self.Frame then
			self.Frame:Show()
		end
	end

	function SharedMenuMixin:ReleaseAllObjects()
		self.buttonPool:ReleaseAll()
		self.texturePool:ReleaseAll()
	end

	function SharedMenuMixin:IsShown()
		if self.Frame then
			return self.Frame:IsShown()
		end
	end

	function SharedMenuMixin:HideMenu()
		if self.Frame then
			self.Frame:Hide()
			self.Frame:ClearAllPoints()
			if not self.keepContentOnHide then
				self:ReleaseAllObjects()
			end
		end
		self.menuInfoGetter = nil
	end

	function SharedMenuMixin:SetKeepContentOnHide(keepContentOnHide)
		self.keepContentOnHide = keepContentOnHide
	end

	function SharedMenuMixin:SetNoAutoHide(noAutoHide)
		self.noAutoHide = noAutoHide
	end

	function SharedMenuMixin:SetNoContentAlert(text)
		self.useNoContentAlert = text ~= nil
		if self.NoContentAlert then
			self.NoContentAlert:SetText(text)
		else
			self.noContentAlertText = text
		end
	end

	function SharedMenuMixin:AnchorToObject(object)
		local f = self.Frame
		if f then
			f:ClearAllPoints()
			if self.independent then
				f:SetParent(UIParent)
				local x, y = object:GetCenter()
				f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 12, y + 8)
			else
				f:SetParent(object)
				f:SetPoint("TOPLEFT", object, "BOTTOMLEFT", 0, -6)
			end
		end
	end

	function SharedMenuMixin:AnchorToCursor(owner, offsetX, offsetY)
		local f = self.Frame
		if f then
			f:ClearAllPoints()
			f:SetParent(UIParent)
			local x, y = API.GetScaledCursorPosition()
			offsetX = offsetX or 0
			offsetY = offsetY or 0
			f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + offsetX, y + offsetY)
		end
	end

	function SharedMenuMixin:ShowMenu(owner, menuInfo)
		if self.Init then
			self:Init()
		end

		self.buttonPool:ReleaseAll()
		self.owner = owner
		self.independent = nil

		if not owner then
			return
		end

		if menuInfo and menuInfo.widgets then
			self.NoContentAlert:Hide()
			self.independent = menuInfo.independent

			local f = self.Frame
			if self.openAtCursorPosition or menuInfo.openAtCursorPosition then
				self:AnchorToCursor(owner, 16, 8)
			else
				self:AnchorToObject(owner)
			end

			local buttonHeight = 24
			local n = 0
			local widget
			local offsetX = 0
			local offsetY = self.paddingV
			local contentWidth = ((menuInfo.fitToOwner or self.fitToOwner) and owner:GetWidth()) or 0
			local contentHeight = 0
			local widgetWidth
			local widgets = {}
			local numWidgets = #menuInfo.widgets

			for _, v in ipairs(menuInfo.widgets) do
				n = n + 1
				if v.type == "Checkbox" or v.type == "Radio" or v.type == "Button" or v.type == "Header" then
					widget = self.buttonPool:Acquire()
					widget:SetRightTexture(v.rightTexture)

					if numWidgets == 1 then
						widget:SetPoint("CENTER", f, "CENTER", 0, 0)
					else
						widget:SetPoint("TOPLEFT", f, "TOPLEFT", offsetX, -offsetY)
					end
					offsetY = offsetY + buttonHeight
					contentHeight = contentHeight + buttonHeight
					widget.onClickFunc = v.onClickFunc
					widget.closeAfterClick = v.closeAfterClick
					widget.refreshAfterClick = v.refreshAfterClick
					widget.isDangerousAction = v.isDangerousAction
					widget:SetLeftText(v.text)
					if v.type == "Radio" then
						widget:SetRadio(v.selected)
					elseif v.type == "Checkbox" then
						widget:SetCheckbox(v.selected)
					elseif v.type == "Header" then
						widget:SetHeader(v.text)
					else
						widget:SetRegular()
					end
					if v.disabled then
						widget:Disable()
					end
					if v.font then
						widget:SetFont(v.font, 13, "") -- adjust size & flags to taste
					else
						widget:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE") -- fallback
					end
					widget:UpdateVisual()
				elseif v.type == "Divider" then
					widget = self.texturePool:Acquire()
					widget:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Button/DropdownMenu")
					widget:SetTexCoord(0 / 512, 128 / 512, 32 / 512, 48 / 512)
					widget:SetSize(64, 8)
					local dividerHeight = 8
					local gap = 2
					offsetY = offsetY + gap
					widget:SetPoint("TOPLEFT", f, "TOPLEFT", offsetX, -offsetY)
					offsetY = offsetY + dividerHeight + gap
					contentHeight = contentHeight + dividerHeight + 2 * gap
				end
				widget.parent = self
				widget.tooltip = v.tooltip
				widgets[n] = widget
				if widget.GetContentWidth then
					widgetWidth = widget:GetContentWidth()
					if widgetWidth > contentWidth then
						contentWidth = widgetWidth
					end
				end
			end

			if contentWidth < 96 then
				contentWidth = 96
			end
			contentWidth = API.Round(contentWidth)
			contentHeight = API.Round(contentHeight)

			for _, widget in ipairs(widgets) do
				widget:SetWidth(contentWidth)
			end

			self:SetContentSize(contentWidth, contentHeight)

			f:Show()
			self.visible = true
		else
			if self.useNoContentAlert then
				self.NoContentAlert:Show()
				local contentWidth = owner:GetWidth()
				local contentHeight = 24
				contentWidth = API.Round(contentWidth)
				contentHeight = API.Round(contentHeight)
				self:SetContentSize(contentWidth, contentHeight)
				self:AnchorToObject(owner)
				self.Frame:Show()
				self.visible = true
			end
		end

		-- We also use this for EditModeDropdownFrame, whose border is greyscale
		-- Desaturated to match color

		local desaturateBorder = menuInfo and menuInfo.desaturateBorder
		local a = desaturateBorder and 0.9 or 1
		for _, p in ipairs(self.Frame.Background.pieces) do
			p:SetDesaturated(desaturateBorder)
			p:SetVertexColor(a, a, a)
		end
	end

	function SharedMenuMixin:ToggleMenu(owner, menuInfoGetter)
		if self.owner == owner and (self.Frame and self.Frame:IsShown()) then
			self:HideMenu()
		else
			self.menuInfoGetter = owner.menuInfoGetter or menuInfoGetter
			local menuInfo = self.menuInfoGetter and self.menuInfoGetter() or nil
			self:ShowMenu(owner, menuInfo)
		end
	end

	function SharedMenuMixin:RefreshMenu()
		if self.owner and self.owner:IsVisible() and self:IsShown() and self.menuInfoGetter then
			local menuInfo = self.menuInfoGetter and self.menuInfoGetter() or nil
			self:ShowMenu(self.owner, menuInfo)
		end
	end

	function SharedMenuMixin:Init()
		self.Init = nil

		local Frame = CreateFrame("Frame", nil, self.parent or UIParent)
		self.Frame = Frame
		Frame:Hide()
		Frame:SetSize(112, 112)
		Frame:SetFrameStrata("FULLSCREEN_DIALOG")
		Frame:SetFixedFrameStrata(true)
		Frame:EnableMouse(true)
		Frame:EnableMouseMotion(true)
		Frame:SetClampedToScreen(true)
		self:SetPaddingV(6)

		local f = addon.CreateNineSliceFrame(Frame, "ExpansionBorder_TWW")
		Frame.Background = f
		f:SetUsingParentLevel(true)
		f:SetCornerSize(16, 16)
		f:SetDisableSharpening(false)
		f:CoverParent(0)
		f:SetTexture(TEXTURE_FILE)
		f.pieces[1]:SetTexCoord(512 / 1024, 544 / 1024, 320 / 1024, 352 / 1024)
		f.pieces[2]:SetTexCoord(544 / 1024, 736 / 1024, 320 / 1024, 352 / 1024)
		f.pieces[3]:SetTexCoord(736 / 1024, 768 / 1024, 320 / 1024, 352 / 1024)
		f.pieces[4]:SetTexCoord(512 / 1024, 544 / 1024, 352 / 1024, 544 / 1024)
		f.pieces[5]:SetTexCoord(544 / 1024, 736 / 1024, 352 / 1024, 544 / 1024)
		f.pieces[6]:SetTexCoord(736 / 1024, 768 / 1024, 352 / 1024, 544 / 1024)
		f.pieces[7]:SetTexCoord(512 / 1024, 544 / 1024, 544 / 1024, 576 / 1024)
		f.pieces[8]:SetTexCoord(544 / 1024, 736 / 1024, 544 / 1024, 576 / 1024)
		f.pieces[9]:SetTexCoord(736 / 1024, 768 / 1024, 544 / 1024, 576 / 1024)

		local NoContentAlert = Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.NoContentAlert = NoContentAlert
		NoContentAlert:Hide()
		NoContentAlert:SetPoint("LEFT", Frame, "LEFT", 16, 0)
		NoContentAlert:SetPoint("RIGHT", Frame, "RIGHT", -16, 0)
		NoContentAlert:SetTextColor(0.5, 0.5, 0.5)
		NoContentAlert:SetJustifyH("CENTER")
		if self.noContentAlertText then
			NoContentAlert:SetText(self.noContentAlertText)
		end

		local function MenuButton_Create()
			return CreateMenuButton(Frame)
		end

		local function MenuButton_OnAcquire(obj)
			obj:Enable()
		end

		self.buttonPool = CreateObjectPool(MenuButton_Create, nil, MenuButton_OnAcquire)

		local function Texture_Create()
			local tex = Frame:CreateTexture(nil, "OVERLAY")
			return tex
		end
		self.texturePool = CreateObjectPool(Texture_Create)

		self.Highlight = Util.CreateButtonHighlight(Frame)
		self.Highlight.Texture:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Button/DropdownMenu")
		self.Highlight.Texture:SetTexCoord(368 / 512, 512 / 512, 0 / 512, 48 / 512)
		self.Highlight.Texture:SetVertexColor(119 / 255, 96 / 255, 74 / 255)
		self.Highlight.Texture:SetBlendMode("ADD")

		if self.noAutoHide then
			Frame:SetScript("OnShow", function()
				addon.PlayUISound("DropdownOpen")
			end)

			Frame:SetScript("OnHide", function()
				addon.PlayUISound("DropdownClose")
			end)
		else
			Frame:SetScript("OnShow", function()
				Frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
				addon.PlayUISound("DropdownOpen")
			end)

			Frame:SetScript("OnHide", function()
				self:HideMenu()
				Frame:UnregisterEvent("GLOBAL_MOUSE_DOWN")
				addon.PlayUISound("DropdownClose")
			end)

			Frame:SetScript("OnEvent", function()
				if not (Frame:IsMouseOver() or (self.owner and self.owner:IsMouseMotionFocus())) then
					Frame:Hide()
				end
			end)
		end
	end

	function SharedMenuMixin:HighlightButton(button)
		self.Highlight:Hide()
		self.Highlight:ClearAllPoints()
		if button then
			self.Highlight:SetParent(button)
			self.Highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
			self.Highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
			self.Highlight:Show()
		end
	end

	local function CreateMenuFrame(parent, obj)
		obj = obj or {}
		Mixin(obj, SharedMenuMixin)
		obj.parent = parent
		return obj
	end
	Util.CreateMenuFrame = CreateMenuFrame

	MainDropdownMenu = CreateMenuFrame(UIParent, { name = "MainDropdownMenu" })
	MainDropdownMenu.fitToOwner = true
	Util.DropdownMenu = MainDropdownMenu

	MainContextMenu = CreateMenuFrame(UIParent, { name = "MainContextMenu" })
	MainContextMenu.openAtCursorPosition = true
	Util.MainContextMenu = MainContextMenu
end

do --DropdownFrame--
	local DropdownFrameMixin = {}

	function DropdownFrameMixin:SetLabel(label)
		self.Label:SetText(label)
	end

	function DropdownFrameMixin:SetButtonText(text)
		self.Button.Text:SetText(text)
	end

	function DropdownFrameMixin:SetPushed(pushed)
		if pushed then
			self.Textures[3]:SetTexCoord(176 / 256, 1, 80 / 256, 160 / 256)
		else
			self.Textures[3]:SetTexCoord(176 / 256, 1, 0, 80 / 256)
		end
	end

	function DropdownFrameMixin:SetLabelWidth(width)
		self.Label:SetWidth(width)
		self:SetWidth(242 + width)
		self.Button:SetPoint("LEFT", self, "LEFT", 14 + width, 0)
	end

	function DropdownFrameMixin:UpdateSelectedText()
		if self.menuData and self.menuData.GetSelectedText then
			self:SetButtonText(self.menuData.GetSelectedText())
		else
			self:SetButtonText(nil)
		end
	end

	function DropdownFrameMixin:UpdateEnabledState()
		local enabled = self.menuData and self.menuData.ShouldEnable and self.menuData.ShouldEnable()
		self:SetEnabled(enabled)
	end

	function DropdownFrameMixin:SetMenuData(menuData)
		self.menuData = menuData
		self:UpdateSelectedText()
		self:UpdateEnabledState()
	end

	function DropdownFrameMixin:IsEnabled()
		return self.enabled
	end

	function DropdownFrameMixin:SetEnabled(enabled)
		if enabled then
			self:Enable()
		else
			self:Disable()
		end
	end

	function DropdownFrameMixin:Enable()
		if self.enabled then
			return
		end
		self.enabled = true
		self.Button:Enable()
		self.Label:SetTextColor(1, 1, 1)
		self.Button.Text:SetTextColor(1, 1, 1)
		for _, tex in ipairs(self.Textures) do
			tex:SetDesaturated(false)
			tex:SetVertexColor(1, 1, 1)
		end
	end

	function DropdownFrameMixin:Disable()
		if not self.enabled then
			return
		end
		self.enabled = false
		self.Button:Disable()
		self.Label:SetTextColor(0.5, 0.5, 0.5)
		self.Button.Text:SetTextColor(0.5, 0.5, 0.5)
		for _, tex in ipairs(self.Textures) do
			tex:SetDesaturated(true)
			tex:SetVertexColor(0.5, 0.5, 0.5)
		end
	end

	function DropdownFrameMixin:ToggleMenu()
		local menuInfoGetter = self.menuData and self.menuData.MenuInfoGetter or nil
		addon.Util.DropdownMenu:ToggleMenu(self.Button, menuInfoGetter)
	end

	local DropdownButtonMixin = {}

	function DropdownButtonMixin:OnEnter()
		if self.Text:IsTruncated() then
			local tooltip = GameTooltip
			tooltip:SetOwner(self, "ANCHOR_RIGHT")
			tooltip:SetText(self.Text:GetText(), 1, 1, 1)
			tooltip:Show()
		end
	end

	function DropdownButtonMixin:OnLeave()
		GameTooltip:Hide()
	end

	function DropdownButtonMixin:OnMouseDown()
		if self:IsEnabled() then
			self:GetParent():SetPushed(true)
		end
	end

	function DropdownButtonMixin:OnMouseUp()
		self:GetParent():SetPushed(false)
	end

	function DropdownButtonMixin:OnClick()
		self:GetParent():ToggleMenu()
	end

	addon.CreateDropdownFrame = function(parent)
		local f = CreateFrame("Frame", nil, parent)
		Mixin(f, DropdownFrameMixin)
		f:SetSize(342, 36)

		local Label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
		f.Label = Label
		Label:SetJustifyH("LEFT")
		Label:SetPoint("LEFT", f, "LEFT", 0, 0)

		local Button = CreateFrame("Button", nil, f)
		f.Button = Button

		f.Textures = API.CreateThreeSliceTextures(Button, "BACKGROUND", 16, 40, 8, Def.DropdownTexture, true)
		f.Textures[1]:SetTexCoord(0, 32 / 256, 0, 80 / 256)
		f.Textures[2]:SetTexCoord(32 / 256, 176 / 256, 0, 80 / 256)
		f.Textures[3]:SetTexCoord(176 / 256, 1, 0, 80 / 256)
		f.Textures[3]:SetSize(40, 40)

		f.HighlightTextures = API.CreateThreeSliceTextures(Button, "HIGHLIGHT", 16, 40, 8, Def.DropdownTexture, true)
		f.HighlightTextures[1]:SetTexCoord(0, 32 / 256, 160 / 256, 240 / 256)
		f.HighlightTextures[2]:SetTexCoord(32 / 256, 176 / 256, 160 / 256, 240 / 256)
		f.HighlightTextures[3]:SetTexCoord(176 / 256, 1, 160 / 256, 240 / 256)
		f.HighlightTextures[3]:SetSize(40, 40)

		local a = 0.25
		for _, tex in ipairs(f.HighlightTextures) do
			tex:SetVertexColor(a, a, a)
			tex:SetBlendMode("ADD")
		end

		Button:SetSize(240, 26)
		Button:SetPoint("RIGHT", f, "RIGHT", -18, 0)

		Button.Text = Button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		Button.Text:SetPoint("LEFT", Button, "LEFT", 8, 0)
		Button.Text:SetPoint("RIGHT", Button, "RIGHT", -46, 0)
		Button.Text:SetMaxLines(1)
		Button.Text:SetJustifyH("LEFT")

		Mixin(Button, DropdownButtonMixin)
		Button:SetScript("OnEnter", Button.OnEnter)
		Button:SetScript("OnLeave", Button.OnLeave)
		Button:SetScript("OnClick", Button.OnClick)
		Button:SetScript("OnMouseDown", Button.OnMouseDown)
		Button:SetScript("OnMouseUp", Button.OnMouseUp)
		Button:SetMotionScriptsWhileDisabled(true)

		f:SetLabelWidth(144)
		f:Enable()

		return f
	end
end
