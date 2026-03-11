---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local tonumber = tonumber
local lower = string.lower
local format = string.format
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local floor = math.floor
local unpack = unpack
local CreateFrame = CreateFrame

-- ==================================
-- === Debug and Helper Functions ===
-- ==================================

local PRINT_PREFIX = "|cffffc700Aeon:|r |cff1fcecbTools|r "
local PRINT_DEBUG_PREFIX = "|cffffc700Aeon:|r |cff1fcecbTools|r DEBUG: "

function addon:Print(...)
	print(PRINT_PREFIX, ...)
end

function addon:PrintDebug(...)
	if not self.db or not self.db.DebugMode then
		return
	end
	local msg = ""
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if type(arg) == "table" then
			arg = self:DumpTable(arg)
		end
		msg = msg .. tostring(arg) .. " "
	end

	print(PRINT_DEBUG_PREFIX .. msg)
end

function addon:DumpTable(tbl, indent)
	indent = indent or 0
	local spacing = string.rep("  ", indent)
	local output = "{\n"
	for i, k in pairs(tbl) do
		output = output .. spacing .. "  " .. tostring(i) .. " = "
		if type(k) == "table" then
			output = output .. addon:DumpTable(k, indent + 1)
		else
			output = output .. tostring(k)
		end
		output = output .. ",\n"
	end

	output = output .. spacing .. "}"
	return output
end

function addon:ReloadPopUp()
	if not StaticPopupDialogs["AEONTOOLS_RELOAD"] then
		StaticPopupDialogs["AEONTOOLS_RELOAD"] = {
			text = L["Reload_Warning"],
			button1 = L["Yes"],
			button2 = L["Later"],
			OnAccept = function()
				C_UI.Reload()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	end
	StaticPopup_Show("AEONTOOLS_RELOAD")
end

local function GetDBValue(dbKey)
	local value = addon.db

	if type(value) ~= "table" then
		-- DB not ready yet
		return
	end

	for segment in string.gmatch(dbKey, "[^.]+") do
		local arrayKey, index = segment:match("^([^%[]+)%[(%d+)%]$")

		if arrayKey then
			-- It's bracket notation: first access the table, then the numeric index
			value = value[arrayKey]
			if value == nil then
				return
			end
			value = value[tonumber(index)]
			if value == nil then
				return
			end
		else
			-- Regular dot notation
			value = value[segment]
			if value == nil then
				return
			end
		end
	end

	return value
end
addon.GetDBValue = GetDBValue

local function SetDBValue(dbKey, newValue)
	local ref = addon.db
	if not ref then
		return
	end

	local segments = {}
	for segment in string.gmatch(dbKey, "[^.]+") do
		table.insert(segments, segment)
	end

	for i = 1, #segments - 1 do
		local segment = segments[i]
		local arrayKey, index = segment:match("^([^%[]+)%[(%d+)%]$")

		if arrayKey then
			ref = ref[arrayKey]
			if not ref then
				return
			end
			ref = ref[tonumber(index)]
			if not ref then
				return
			end
		else
			ref = ref[segment]
			if not ref then
				return
			end
		end
	end

	local lastSegment = segments[#segments]
	local arrayKey, index = lastSegment:match("^([^%[]+)%[(%d+)%]$")

	if arrayKey then
		if not ref[arrayKey] then
			ref[arrayKey] = {}
		end
		ref[arrayKey][tonumber(index)] = newValue
	else
		ref[lastSegment] = newValue
	end
end
addon.SetDBValue = SetDBValue

function addon.PlayUISound(key)
	local PlaySound = PlaySound

	local SoundEffects = {
		ScrollBarThumbDown = SOUNDKIT.U_CHAT_SCROLL_BUTTON,
		ScrollBarStep = SOUNDKIT.SCROLLBAR_STEP,
		CheckboxOn = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON,
		CheckboxOff = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF,
		DropdownOpen = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON,
		DropdownClose = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF,
		PageOpen = SOUNDKIT.IG_QUEST_LOG_OPEN,
		PageClose = SOUNDKIT.IG_QUEST_LOG_CLOSE,
	}

	if SoundEffects[key] then
		PlaySound(SoundEffects[key])
	end
end

-- ============
-- === Math ===
-- ============

do -- Math
	local function Round(n)
		return floor(n + 0.5)
	end
	API.Round = Round

	local function Options_Slider_FormatWholeValue(value)
		return format("%d", value)
	end
	API.ReturnWholeNum = Options_Slider_FormatWholeValue

	local function Options_Slider_EscapeMenuScaleNum(value)
		return format("%.0f%%", value * 100)
	end
	API.ReturnPercent = Options_Slider_EscapeMenuScaleNum

	local function DeltaLerp(current, target, lerp, dt)
		return current + (target - current) * (1 - math.exp(-lerp * dt))
	end
	API.DeltaLerp = DeltaLerp

	local function Clamp(v, min, max)
		if v < min then
			return min
		end
		if v > max then
			return max
		end
		return v
	end
	API.Clamp = Clamp
end

do -- Easing
	local EasingFunctions = {}
	addon.EasingFunctions = EasingFunctions

	local sin = math.sin
	local cos = math.cos
	local pow = math.pow
	local pi = math.pi

	--t: total time elapsed
	--b: beginning position
	--e: ending position
	--d: animation duration

	function EasingFunctions.linear(t, b, e, d)
		return (e - b) * t / d + b
	end

	function EasingFunctions.outSine(t, b, e, d)
		return (e - b) * sin(t / d * (pi / 2)) + b
	end

	function EasingFunctions.inOutSine(t, b, e, d)
		return -(e - b) / 2 * (cos(pi * t / d) - 1) + b
	end

	function EasingFunctions.outQuart(t, b, e, d)
		t = t / d - 1
		return (b - e) * (pow(t, 4) - 1) + b
	end

	function EasingFunctions.outQuint(t, b, e, d)
		t = t / d
		return (b - e) * (pow(1 - t, 5) - 1) + b
	end

	function EasingFunctions.inQuad(t, b, e, d)
		t = t / d
		return (e - b) * pow(t, 2) + b
	end
end

-- =========================
-- === Settings Creation ===
-- =========================

do -- System
	local GetMouseFoci = GetMouseFoci

	local function GetMouseFocus()
		local objects = GetMouseFoci()
		return objects and objects[1]
	end
	API.GetMouseFocus = GetMouseFocus
end

do -- Fade Frame
	local abs = math.abs
	local tinsert = table.insert
	local wipe = wipe

	local fadeInfo = {}
	local fadingFrames = {}

	local f = CreateFrame("Frame")

	local function OnUpdate(self, elpased)
		local i = 1
		local frame, info, timer, alpha
		local isComplete = true
		while fadingFrames[i] do
			frame = fadingFrames[i]
			info = fadeInfo[frame]
			if info then
				timer = info.timer + elpased
				if timer >= info.duration then
					alpha = info.toAlpha
					fadeInfo[frame] = nil
					if info.alterShownState and alpha <= 0 then
						frame:Hide()
					end
				else
					alpha = info.fromAlpha + (info.toAlpha - info.fromAlpha) * timer / info.duration
					info.timer = timer
				end
				frame:SetAlpha(alpha)
				isComplete = false
			end
			i = i + 1
		end

		if isComplete then
			f:Clear()
		end
	end

	function f:Clear()
		self:SetScript("OnUpdate", nil)
		wipe(fadingFrames)
		wipe(fadeInfo)
	end

	function f:Add(frame, fullDuration, fromAlpha, toAlpha, alterShownState, useConstantDuration)
		local alpha = frame:GetAlpha()
		if alterShownState then
			if toAlpha > 0 then
				frame:Show()
			end
			if toAlpha == 0 then
				if not frame:IsShown() then
					frame:SetAlpha(0)
					alpha = 0
				end
				if alpha == 0 then
					frame:Hide()
				end
			end
		end
		if fromAlpha == toAlpha or alpha == toAlpha then
			if fadeInfo[frame] then
				fadeInfo[frame] = nil
			end
			return
		end
		local duration
		if useConstantDuration then
			duration = fullDuration
		else
			if fromAlpha then
				duration = fullDuration * (alpha - toAlpha) / (fromAlpha - toAlpha)
			else
				duration = fullDuration * abs(alpha - toAlpha)
			end
		end
		if duration <= 0 then
			frame:SetAlpha(toAlpha)
			if toAlpha == 0 then
				frame:Hide()
			end
			return
		end
		fadeInfo[frame] = {
			fromAlpha = alpha,
			toAlpha = toAlpha,
			duration = duration,
			timer = 0,
			alterShownState = alterShownState,
		}
		for i = 1, #fadingFrames do
			if fadingFrames[i] == frame then
				return
			end
		end
		tinsert(fadingFrames, frame)
		self:SetScript("OnUpdate", OnUpdate)
	end

	function f:SimpleFade(frame, toAlpha, alterShownState, speedMultiplier)
		--Use a constant fading speed: 1.0 in 0.25s
		--alterShownState: if true, run Frame:Hide() when alpha reaches zero / run Frame:Show() at the beginning
		speedMultiplier = speedMultiplier or 1
		local alpha = frame:GetAlpha()
		local duration = abs(alpha - toAlpha) * 0.25 * speedMultiplier
		if duration <= 0 then
			return
		end

		self:Add(frame, duration, alpha, toAlpha, alterShownState, true)
	end

	function f:Snap()
		local i = 1
		local frame, info
		while fadingFrames[i] do
			frame = fadingFrames[i]
			info = fadeInfo[frame]
			if info then
				frame:SetAlpha(info.toAlpha)
			end
			i = i + 1
		end
		self:Clear()
	end

	local function UIFrameFade(frame, duration, toAlpha, initialAlpha)
		if initialAlpha then
			frame:SetAlpha(initialAlpha)
			f:Add(frame, duration, initialAlpha, toAlpha, true, false)
		else
			f:Add(frame, duration, nil, toAlpha, true, false)
		end
	end

	local function UIFrameFadeIn(frame, duration)
		frame:SetAlpha(0)
		f:Add(frame, duration, 0, 1, true, false)
	end

	API.UIFrameFade = UIFrameFade --from current alpha
	API.UIFrameFadeIn = UIFrameFadeIn --from 0 to 1
end

do -- Dropdown
	local function CreateDropdownOptions(dbPath, options, enableFunc, clickFunc)
		if not options then
			addon.PrintDebug("CreateDropdownOptions requires an options table")
			return
		end

		local UpdateSettingsDialog = addon.UpdateSettingsDialog
		local menuKey = dbPath:gsub("Settings%.", "_"):gsub("%.(%w)", string.upper)

		local items = {}
		if options.items then
			if #options.items > 0 then
				-- Already an array
				items = options.items
			else
				-- Convert key-value pairs to array
				for key, text in pairs(options.items) do
					table.insert(items, { value = key, text = text })
				end
			end
		else
			addon.PrintDebug("CreateDropdownOptions requires options.items")
			return
		end

		if options.sort then
			tsort(items, function(a, b)
				local textA = tostring(a.text or a.value)
				local textB = tostring(b.text or b.value)

				return lower(textA) < lower(textB)
			end)
		end

		return {
			ShouldEnable = enableFunc or function()
				return true
			end,

			GetSelectedText = function()
				local current = GetDBValue(dbPath) or options.default

				if options.getDisplayText then
					return options.getDisplayText(current)
				end

				for _, item in ipairs(items) do
					if item.value == current then
						local text = item.text or tostring(item.value)
						local icon = item.icon or ""
						return icon .. (icon ~= "" and " " or "") .. text
					end
				end

				return tostring(current)
			end,

			MenuInfoGetter = function()
				local current = GetDBValue(dbPath) or options.default
				local widgets = {}

				for _, item in ipairs(items) do
					local displayText = item.text or tostring(item.value)
					local icon = item.icon or ""

					widgets[#widgets + 1] = {
						type = "Radio",
						font = item.font,
						text = icon .. (icon ~= "" and " " or "") .. displayText,
						closeAfterClick = true,
						selected = (item.value == current),

						onClickFunc = function()
							if options.checkCombat and InCombatLockdown() then
								addon:Print(L["Cannot change keybind in combat!"])
								return
							end

							SetDBValue(dbPath, item.value)
							UpdateSettingsDialog()

							if clickFunc then
								clickFunc(item.value)
							end
						end,
					}
				end

				return {
					key = menuKey,
					desaturateBorder = true,
					widgets = widgets,
				}
			end,
		}
	end
	API.CreateDropdownOptions = CreateDropdownOptions
end

do -- Dropdown Presets
	local function FontDropdownOptions()
		return {
			default = "Fonts\\FRIZQT__.TTF",
			items = addon.fontByPath,
			sort = true,
			getDisplayText = function(value)
				return addon.fontByPath[value] or "Friz Quadrata"
			end,
		}
	end
	API.FontDropdownOptions = FontDropdownOptions

	function API.SharedMediaFontDropdownOptions()
		local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

		-- If LSM is missing, fall back to your built‑in font list
		if not LSM then
			return API.FontDropdownOptions()
		end

		-- Pull all LSM font names
		local fontList = LSM:List("font") or {}

		-- Ensure Expressway is included
		local expresswayPath = addon.Expressway
		local expresswayName = "Expressway"

		local hasExpressway = false
		for _, name in ipairs(fontList) do
			if name == expresswayName then
				hasExpressway = true
				break
			end
		end

		if not hasExpressway then
			table.insert(fontList, expresswayName)
		end

		-- Sort alphabetically (case‑insensitive)
		table.sort(fontList, function(a, b)
			return a:lower() < b:lower()
		end)

		-- Build dropdown items with live preview
		local items = {}
		for _, fontName in ipairs(fontList) do
			local fontPath

			if fontName == expresswayName then
				fontPath = expresswayPath
			else
				fontPath = LSM:Fetch("font", fontName)
			end

			table.insert(items, {
				value = fontPath,
				text = fontName,
				font = fontPath, -- enables LIVE PREVIEW in your dropdown
			})
		end

		return {
			default = expresswayPath,
			items = items,
			sort = false, -- already sorted
			getDisplayText = function(value)
				-- Find the matching item
				for _, item in ipairs(items) do
					if item.value == value then
						return item.text
					end
				end
				return expresswayName
			end,
		}
	end

	local function FontFlagDropdownOptions()
		return {
			default = "OUTLINE",
			checkCombat = true,
			items = {
				{ value = "", text = L["Flag_None"] },
				{ value = "MONOCHROME", text = L["Flag_Monochrome"] },
				{ value = "OUTLINE", text = L["Flag_Outline"] },
				{ value = "THICKOUTLINE", text = L["Flag_ThickOutline"] },
			},
		}
	end
	API.FontFlagDropdownOptions = FontFlagDropdownOptions

	local function ModifierDropdownOptions()
		return {
			default = "SHIFT",
			checkCombat = true,
			items = {
				{ value = "SHIFT", text = L["Shift"] },
				{ value = "CTRL", text = L["Ctrl"] },
				{ value = "ALT", text = L["Alt"] },
				{ value = "SHIFT-CTRL", text = L["Shift + Ctrl"] },
				{ value = "SHIFT-ALT", text = L["Shift + Alt"] },
				{ value = "CTRL-ALT", text = L["Ctrl + Alt"] },
			},
		}
	end
	API.ModifierDropdownOptions = ModifierDropdownOptions

	local function ButtonDropdownOptions()
		return {
			default = "BUTTON1",
			checkCombat = true,
			items = {
				{ value = "BUTTON1", text = L["Left Click"] },
				{ value = "BUTTON2", text = L["Right Click"] },
				{ value = "BUTTON3", text = L["Middle Click"] },
				{ value = "BUTTON4", text = L["Mouse Button 4"] },
				{ value = "BUTTON5", text = L["Mouse Button 5"] },
			},
		}
	end
	API.ButtonDropdownOptions = ButtonDropdownOptions

	local function RaidMarkerDropdownOptions()
		return {
			default = 0,
			items = {
				-- { value = 0, text = L["None"],     icon = "|TInterface\\Buttons\\UI-GroupLoot-Pass-Up:16|t" },
				{ value = 1, text = L["Star"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16|t" },
				{ value = 2, text = L["Circle"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:16|t" },
				{ value = 3, text = L["Diamond"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:16|t" },
				{ value = 4, text = L["Triangle"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:16|t" },
				{ value = 5, text = L["Moon"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:16|t" },
				{ value = 6, text = L["Square"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:16|t" },
				{ value = 7, text = L["Cross"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:16|t" },
				{ value = 8, text = L["Skull"], icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16|t" },
			},
		}
	end
	API.RaidMarkerDropdownOptions = RaidMarkerDropdownOptions

	local function VisibilityDropdownOptions()
		return {
			default = "DEFAULT",
			items = {
				{ value = "ALWAYS", text = "Always" },
				{ value = "DEFAULT", text = "Default" },
				{ value = "IN PARTY", text = "In party" },
			},
		}
	end
	API.VisibilityDropdownOptions = VisibilityDropdownOptions

	local function AlignmentDropdownOptions(includeVertical)
		local items

		if includeVertical ~= false then
			-- Full alignment set (9 positions)
			items = {
				{ value = "BOTTOM", text = L["ID_Align_Bottom"] },
				{ value = "BOTTOMLEFT", text = L["ID_Align_BottomLeft"] },
				{ value = "BOTTOMRIGHT", text = L["ID_Align_BottomRight"] },
				{ value = "CENTER", text = L["ID_Align_Center"] },
				{ value = "LEFT", text = L["ID_Align_Left"] },
				{ value = "RIGHT", text = L["ID_Align_Right"] },
				{ value = "TOP", text = L["ID_Align_Top"] },
				{ value = "TOPLEFT", text = L["ID_Align_TopLeft"] },
				{ value = "TOPRIGHT", text = L["ID_Align_TopRight"] },
			}
		else
			items = {
				{ value = "BOTTOMLEFT", text = L["ID_Align_BottomLeft"] },
				{ value = "BOTTOMRIGHT", text = L["ID_Align_BottomRight"] },
				{ value = "TOPLEFT", text = L["ID_Align_TopLeft"] },
				{ value = "TOPRIGHT", text = L["ID_Align_TopRight"] },
			}
		end

		return {
			default = "TOPLEFT",
			items = items,
		}
	end
	API.AlignmentDropdownOptions = AlignmentDropdownOptions

	local function HorizontalAlignmentDropdownOptions()
		return {
			default = "LEFT",
			items = {
				{ value = "LEFT", text = L["Left"] or "Left" },
				{ value = "CENTER", text = L["Center"] or "Center" },
				{ value = "RIGHT", text = L["Right"] or "Right" },
			},
		}
	end
	API.HorizontalAlignmentDropdownOptions = HorizontalAlignmentDropdownOptions

	local function VerticalAlignmentDropdownOptions()
		return {
			default = "TOP",
			items = {
				{ value = "TOP", text = L["Top"] or "Top" },
				{ value = "MIDDLE", text = L["Middle"] or "Middle" },
				{ value = "BOTTOM", text = L["Bottom"] or "Bottom" },
			},
		}
	end
	API.VerticalAlignmentDropdownOptions = VerticalAlignmentDropdownOptions
end

do --Metal Progress Bar
	local ProgressBarMixin = {}

	function ProgressBarMixin:SetBarWidth(width)
		self:SetWidth(width)
		self.maxBarFillWidth = width
	end

	function ProgressBarMixin:SetValueByRatio(ratio)
		self.BarFill:SetWidth(ratio * self.maxBarFillWidth)
		self.BarFill:SetTexCoord(0, ratio, self.barfillTop, self.barfillBottom)
		self.visualRatio = ratio
	end

	local FILL_SIZE_PER_SEC = 100
	local EasingFunc = addon.EasingFunctions.outQuart

	local function SmoothFill_OnUpdate(self, elapsed)
		self.t = self.t + elapsed
		local ratio = EasingFunc(self.t, self.fromRatio, self.toRatio, self.easeDuration)
		if self.t >= self.easeDuration then
			ratio = self.toRatio
			self.easeDuration = nil
			self:SetScript("OnUpdate", nil)
		end
		self:SetValueByRatio(ratio)
	end

	function ProgressBarMixin:SetValue(barValue, barMax, playPulse)
		if barValue > barMax then
			barValue = barMax
		end
		if self.BarValue then
			self.BarValue:SetText(barValue .. "/" .. barMax)
		end
		if barValue == 0 or barMax == 0 then
			self.BarFill:Hide()
			self:SetScript("OnUpdate", nil)
		else
			self.BarFill:Show()
			local newRatio = barValue / barMax
			if self.smoothFill then
				local deltaRatio, oldRatio

				if self.barMax and self.visualRatio then
					if self.barMax == 0 then
						oldRatio = 0
					else
						oldRatio = self.visualRatio
					end
					deltaRatio = newRatio - oldRatio
				else
					oldRatio = 0
					deltaRatio = newRatio
				end

				if oldRatio < 0 then
					oldRatio = -oldRatio
				end

				if deltaRatio < 0 then
					deltaRatio = -deltaRatio
				end

				local easeDuration = deltaRatio * self.maxBarFillWidth / FILL_SIZE_PER_SEC

				if self.wasHidden then
					--don't animte if the bar was hidden
					self.wasHidden = false
					easeDuration = 0
				end
				if easeDuration > 0.25 then
					self.toRatio = newRatio
					self.fromRatio = oldRatio
					if easeDuration > 1.5 then
						easeDuration = 1.5
					end
					self.easeDuration = easeDuration
					self.t = 0
					self:SetScript("OnUpdate", SmoothFill_OnUpdate)
				else
					self.easeDuration = nil
					self:SetValueByRatio(newRatio)
					self:SetScript("OnUpdate", nil)
				end
			else
				self:SetValueByRatio(newRatio)
			end
		end

		if playPulse and barValue > self.barValue then
			self:Flash()
		end

		self.barValue = barValue
		self.barMax = barMax
	end

	function ProgressBarMixin:OnHide()
		self.wasHidden = true
	end

	function ProgressBarMixin:GetValue()
		return self.barValue
	end

	function ProgressBarMixin:GetBarMax()
		return self.barMax
	end

	function ProgressBarMixin:SetSmoothFill(state)
		state = state or false
		self.smoothFill = state
		if not state then
			self:SetScript("OnUpdate", nil)
			if self.barValue and self.barMax then
				self:SetValue(self.barValue, self.barMax)
			end
			self.easeDuration = nil
		end
	end

	function ProgressBarMixin:Flash()
		self.BarPulse.AnimPulse:Stop()
		self.BarPulse.AnimPulse:Play()
		if self.playShake then
			self.BarShake:Play()
		end
	end

	function ProgressBarMixin:SetBarColor(r, g, b)
		self.BarFill:SetVertexColor(r, g, b)
	end

	function ProgressBarMixin:SetBarColorTint(index)
		if index < 1 or index > 8 then
			index = 2
		end --White

		if index ~= self.colorTint then
			self.colorTint = index
		else
			return
		end

		self.BarFill:SetVertexColor(1, 1, 1)
		self.barfillTop = (index - 1) * 0.125
		self.barfillBottom = index * 0.125

		if self.barValue and self.barMax then
			self:SetValue(self.barValue, self.barMax)
		end
	end

	function ProgressBarMixin:GetBarColorTint()
		return self.colorTint
	end

	local function SetupNotchTexture_Normal(notch)
		notch:SetTexCoord(0.815, 0.875, 0, 0.375)
		notch:SetSize(16, 24)
	end

	local function SetupNotchTexture_Large(notch)
		notch:SetTexCoord(0.5625, 0.59375, 0, 0.25)
		notch:SetSize(16, 64)
	end

	local function SetupNotchTexture_Compact(notch)
		notch:SetTexCoord(0.815, 0.875, 0, 0.375)
		notch:SetSize(16, 36)
	end

	function ProgressBarMixin:SetNumThreshold(numThreshold)
		--Divide the bar evenly
		--"partitionValues", in Blizzard's term
		if numThreshold == self.numThreshold then
			return
		end
		self.numThreshold = numThreshold

		if not self.notches then
			self.notches = {}
		end

		for _, n in ipairs(self.notches) do
			n:Hide()
		end

		if numThreshold == 0 then
			return
		end

		local d = self.maxBarFillWidth / (numThreshold + 1)
		for i = 1, numThreshold do
			if not self.notches[i] then
				self.notches[i] = self.Container:CreateTexture(nil, "OVERLAY", nil, 2)
				self.notches[i]:SetTexture(self.textureFile)
				self.SetupNotchTexture(self.notches[i])
				API.DisableSharpening(self.notches[i])
			end
			self.notches[i]:ClearAllPoints()
			self.notches[i]:SetPoint("CENTER", self.Container, "LEFT", i * d, 0)
			self.notches[i]:Show()
		end
	end

	local function CreateMetalProgressBar(parent, sizeType)
		sizeType = sizeType or "normal"

		local f = CreateFrame("Frame", nil, parent)
		Mixin(f, ProgressBarMixin)

		f:SetScript("OnHide", ProgressBarMixin.OnHide)

		local Container = CreateFrame("Frame", nil, f) --Textures are attached to this frame, so we can setup animations
		f.Container = Container
		Container:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		Container:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

		f.visualRatio = 0
		f.wasHidden = true

		f.BarFill = Container:CreateTexture(nil, "ARTWORK")
		f.BarFill:SetTexCoord(0, 1, 0, 0.125)
		f.BarFill:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/ProgressBar-Fill")
		f.BarFill:SetPoint("LEFT", Container, "LEFT", 0, 0)

		f.Background = Container:CreateTexture(nil, "BACKGROUND")
		f.Background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
		f.Background:SetPoint("TOPLEFT", Container, "TOPLEFT", 0, -2)
		f.Background:SetPoint("BOTTOMRIGHT", Container, "BOTTOMRIGHT", 0, 2)

		f.BarLeft = Container:CreateTexture(nil, "OVERLAY")
		f.BarLeft:SetPoint("CENTER", Container, "LEFT", 0, 0)

		f.BarRight = Container:CreateTexture(nil, "OVERLAY")
		f.BarRight:SetPoint("CENTER", Container, "RIGHT", 0, 0)

		f.BarMiddle = Container:CreateTexture(nil, "OVERLAY")
		f.BarMiddle:SetPoint("TOPLEFT", f.BarLeft, "TOPRIGHT", 0, 0)
		f.BarMiddle:SetPoint("BOTTOMRIGHT", f.BarRight, "BOTTOMLEFT", 0, 0)

		local file, barWidth, barHeight
		if sizeType == "normal" then
			file = "ProgressBar-Metal-Normal"
			barWidth, barHeight = 168, 18
			f.BarLeft:SetTexCoord(0, 0.09375, 0, 0.375)
			f.BarRight:SetTexCoord(0.65625, 0.75, 0, 0.375)
			f.BarMiddle:SetTexCoord(0.09375, 0.65625, 0, 0.375)
			f.BarLeft:SetSize(24, 24)
			f.BarRight:SetSize(24, 24)
			f.BarFill:SetSize(barWidth, 12)
			f.SetupNotchTexture = SetupNotchTexture_Normal
		elseif sizeType == "large" then
			file = "ProgressBar-Metal-Large"
			barWidth, barHeight = 248, 28 --32
			f.BarLeft:SetTexCoord(0, 0.0625, 0, 0.25)
			f.BarRight:SetTexCoord(0.46875, 0.53125, 0, 0.25)
			f.BarMiddle:SetTexCoord(0.0625, 0.46875, 0, 0.25)
			f.BarLeft:SetSize(32, 64)
			f.BarRight:SetSize(32, 64)
			f.BarFill:SetSize(barWidth, 20) --24
			f.SetupNotchTexture = SetupNotchTexture_Large
		elseif sizeType == "compact" then
			file = "ProgressBar-Metal-Normal"
			barWidth, barHeight = 120, 27
			f.BarLeft:SetTexCoord(0, 0.09375, 0, 0.375)
			f.BarRight:SetTexCoord(0.65625, 0.75, 0, 0.375)
			f.BarMiddle:SetTexCoord(0.09375, 0.65625, 0, 0.375)
			f.BarLeft:SetSize(36, 36)
			f.BarRight:SetSize(36, 36)
			f.BarFill:SetSize(barWidth, 18)
			f.SetupNotchTexture = SetupNotchTexture_Compact
		end

		local barFile = "Interface/AddOns/AeonTools/Assets/Settings/" .. file
		f.textureFile = barFile
		f.BarLeft:SetTexture(barFile)
		f.BarRight:SetTexture(barFile)
		f.BarMiddle:SetTexture(barFile)

		API.DisableSharpening(f.BarFill)
		API.DisableSharpening(f.BarLeft)
		API.DisableSharpening(f.BarRight)
		API.DisableSharpening(f.BarMiddle)

		f:SetBarWidth(barWidth)
		f:SetHeight(barHeight)
		f:SetBarColorTint(2)
		--f:SetNumThreshold(0);
		f:SetValue(0, 100)

		local BarPulse = CreateFrame("Frame", nil, f, "AeonToolsBarPulseTemplate")
		BarPulse:SetPoint("RIGHT", f.BarFill, "RIGHT", 0, 0)
		f.BarPulse = BarPulse

		local BarShake = Container:CreateAnimationGroup()
		f.BarShake = BarShake
		local a1 = BarShake:CreateAnimation("Translation")
		a1:SetOrder(1)
		a1:SetStartDelay(0.15)
		a1:SetOffset(3, 0)
		a1:SetDuration(0.05)
		local a2 = BarShake:CreateAnimation("Translation")
		a2:SetOrder(2)
		a2:SetOffset(-4, 0)
		a2:SetDuration(0.1)
		local a3 = BarShake:CreateAnimation("Translation")
		a3:SetOrder(3)
		a3:SetOffset(1, 0)
		a3:SetDuration(0.1)

		return f
	end
	addon.CreateMetalProgressBar = CreateMetalProgressBar
end

do -- Game UI
	local function IsInEditMode()
		return EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
	end
	API.IsInEditMode = IsInEditMode
end

do -- AeonTools Settings
	local ModuleOptionFrames = {
		--[frame] = "CloseMethod" (function)
	}

	addon.AddModuleOptionExitMethod = function(frame, method)
		ModuleOptionFrames[frame] = method
	end

	addon.CloseAllModuleOptions = function()
		--return true: any closed
		for frame, method in pairs(ModuleOptionFrames) do
			if method(frame) then
				return true
			end
		end
		return false
	end

	addon.AnyShownModuleOptions = function()
		for frame in pairs(ModuleOptionFrames) do
			if frame.IsShown and frame:IsShown() then
				return true
			end
		end
	end
end

local CreateObjectPool
do -- ObjectPool
	local ObjectPoolMixin = {}

	function ObjectPoolMixin:ReleaseAll()
		for _, obj in ipairs(self.activeObjects) do
			obj:Hide()
			obj:ClearAllPoints()
			if self.onRemoved then
				self.onRemoved(obj)
			end
		end

		local tbl = {}
		for k, object in ipairs(self.objects) do
			tbl[k] = object
		end
		self.unusedObjects = tbl
		self.activeObjects = {}
	end

	function ObjectPoolMixin:ReleaseObject(object)
		object:Hide()
		object:ClearAllPoints()

		if self.onRemoved then
			self.onRemoved(object)
		end

		local found
		for k, obj in ipairs(self.activeObjects) do
			if obj == object then
				found = true
				tremove(self.activeObjects, k)
				break
			end
		end

		if found then
			tinsert(self.unusedObjects, object)
		end
	end

	function ObjectPoolMixin:Acquire()
		local object = tremove(self.unusedObjects)
		if not object then
			object = self.create()
			object.Release = self.Object_Release
			tinsert(self.objects, object)
		end
		tinsert(self.activeObjects, object)
		if self.onAcquired then
			self.onAcquired(object)
		end
		object:Show()
		return object
	end

	function ObjectPoolMixin:CallMethod(method, ...)
		for _, object in ipairs(self.activeObjects) do
			object[method](object, ...)
		end
	end

	function ObjectPoolMixin:CallMethodByPredicate(predicate, method, ...)
		for _, object in ipairs(self.activeObjects) do
			if predicate(object) then
				object[method](object, ...)
			end
		end
	end

	function ObjectPoolMixin:EnumerateActive()
		return ipairs(self.activeObjects)
	end

	function ObjectPoolMixin:ProcessActiveObjects(processFunc)
		for _, object in ipairs(self.activeObjects) do
			if processFunc(object) then
				return
			end
		end
	end

	function CreateObjectPool(create, onAcquired, onRemoved)
		local pool = {}
		Mixin(pool, ObjectPoolMixin)

		pool.objects = {}
		pool.activeObjects = {}
		pool.unusedObjects = {}

		pool.create = create
		pool.onAcquired = onAcquired
		pool.onRemoved = onRemoved

		function pool.Object_Release(obj)
			pool:ReleaseObject(obj)
		end

		return pool
	end

	function ObjectPoolMixin:RemoveObject(obj)
		obj:Hide()
		obj:ClearAllPoints()

		if obj.OnRemoved then
			obj:OnRemoved()
		end

		if self.onRemovedFunc then
			self.onRemovedFunc(obj)
		end
	end

	function ObjectPoolMixin:RecycleObject(obj)
		local isActive

		for i, activeObject in ipairs(self.activeObjects) do
			if activeObject == obj then
				tremove(self.activeObjects, i)
				isActive = true
				break
			end
		end

		if isActive then
			self:RemoveObject(obj)
			self.numUnused = self.numUnused + 1
			self.unusedObjects[self.numUnused] = obj
		end
	end

	function ObjectPoolMixin:CreateObject()
		local obj = self.createObjectFunc()
		tinsert(self.objects, obj)
		obj.Release = self.Object_Release
		return obj
	end

	-- function ObjectPoolMixin:Acquire()
	-- 	local obj

	-- 	if self.numUnused > 0 then
	-- 		obj = tremove(self.unusedObjects, self.numUnused)
	-- 		self.numUnused = self.numUnused - 1
	-- 	end

	-- 	if not obj then
	-- 		obj = self:CreateObject()
	-- 	end

	-- 	tinsert(self.activeObjects, obj)
	-- 	obj:Show()

	-- 	if self.onAcquiredFunc then
	-- 		self.onAcquiredFunc(obj)
	-- 	end

	-- 	return obj
	-- end

	-- function ObjectPoolMixin:CallMethod(method, ...)
	-- 	for _, object in ipairs(self.activeObjects) do
	-- 		object[method](object, ...)
	-- 	end
	-- end

	-- function ObjectPoolMixin:ReleaseAll()
	-- 	if #self.activeObjects == 0 then
	-- 		return
	-- 	end

	-- 	for _, obj in ipairs(self.activeObjects) do
	-- 		self:RemoveObject(obj)
	-- 	end

	-- 	self.activeObjects = {}
	-- 	self.unusedObjects = {}

	-- 	for index, obj in ipairs(self.objects) do
	-- 		self.unusedObjects[index] = obj
	-- 	end

	-- 	self.numUnused = #self.objects
	-- end

	ObjectPoolMixin.Release = ObjectPoolMixin.ReleaseAll

	function ObjectPoolMixin:GetTotalObjects()
		return #self.objects
	end

	function ObjectPoolMixin:CallAllObjects(method, ...)
		for i, obj in ipairs(self.objects) do
			obj[method](obj, ...)
		end
	end

	function ObjectPoolMixin:Object_Release()
		--Override
	end

	function ObjectPoolMixin:GetActiveObjects()
		return self.activeObjects
	end

	-- function ObjectPoolMixin:EnumerateActive()
	-- 	return ipairs(self.activeObjects)
	-- end

	function ObjectPoolMixin:DebugPrint()
		addon:PrintDebug(#self.objects, self.numUnused, #self.activeObjects)
	end

	-- local function CreateObjectPool(createObjectFunc, onRemovedFunc, onAcquiredFunc)
	-- 	local pool = {}
	-- 	API.Mixin(pool, ObjectPoolMixin)

	-- 	local function Object_Release(f)
	-- 		pool:RecycleObject(f)
	-- 	end
	-- 	pool.Object_Release = Object_Release

	-- 	pool.objects = {}
	-- 	pool.activeObjects = {}
	-- 	pool.unusedObjects = {}
	-- 	pool.numUnused = 0
	-- 	pool.createObjectFunc = createObjectFunc
	-- 	pool.onRemovedFunc = onRemovedFunc
	-- 	pool.onAcquiredFunc = onAcquiredFunc

	-- 	return pool
	-- end
	API.CreateObjectPool = CreateObjectPool
end

do -- Table
	local function Mixin(object, ...)
		for i = 1, select("#", ...) do
			local mixin = select(i, ...)
			for k, v in pairs(mixin) do
				object[k] = v
			end
		end
		return object
	end
	API.Mixin = Mixin
end

do -- ScrollBar
	local GetCursorPosition = GetCursorPosition

	local ArrowButtonMixin = {}
	do
		function ArrowButtonMixin:OnLoad()
			self.OnLoad = nil

			self:SetScript("OnMouseDown", self.OnMouseDown)
			self:SetScript("OnMouseUp", self.OnMouseUp)
			self:SetScript("OnEnable", self.OnEnable)
			self:SetScript("OnDisable", self.OnDisable)
			self:SetScript("OnEnter", self.OnEnter)
			self:SetScript("OnLeave", self.OnLeave)

			self.Highlight:SetAlpha(0.5)
		end

		function ArrowButtonMixin:OnMouseDown(button)
			if not self:IsEnabled() then
				return
			end
			if button == "LeftButton" then
				self.Highlight:SetAlpha(1)
				self:GetParent().ScrollView:OnMouseWheel(self.delta)
				self:GetParent():StartPushingArrow(self.delta)
				addon.PlayUISound("ScrollBarStep")
			end
		end

		function ArrowButtonMixin:OnMouseUp()
			self.Highlight:SetAlpha(0.5)
			self:GetParent():StopUpdating()
			self:GetParent().ScrollView:StopSteadyScroll()
		end

		function ArrowButtonMixin:OnEnable()
			self.Texture:SetVertexColor(1, 1, 1)
			self.Texture:SetDesaturated(false)
		end

		function ArrowButtonMixin:OnDisable()
			self.Texture:SetVertexColor(0.5, 0.5, 0.5)
			self.Texture:SetDesaturated(true)
		end

		function ArrowButtonMixin:OnEnter()
			self:GetParent():UpdateVisual()
		end

		function ArrowButtonMixin:OnLeave()
			self:GetParent():UpdateVisual()
		end
	end

	local ThumbButtonMixin = {}
	do
		function ThumbButtonMixin:OnLoad()
			self.OnLoad = nil

			self:SetScript("OnMouseDown", self.OnMouseDown)
			self:SetScript("OnMouseUp", self.OnMouseUp)
			self:SetScript("OnEnter", self.OnEnter)
			self:SetScript("OnLeave", self.OnLeave)
			self:SetScript("OnHide", self.OnHide)

			self.HighlightTop:SetAlpha(0.2)
			self.HighlightMiddle:SetAlpha(0.2)
			self.HighlightBottom:SetAlpha(0.2)
		end

		function ThumbButtonMixin:OnMouseDown(button)
			if button == "LeftButton" then
				self.HighlightTop:SetAlpha(0.5)
				self.HighlightMiddle:SetAlpha(0.5)
				self.HighlightBottom:SetAlpha(0.5)
				self:GetParent():StartDraggingThumb()
				self:LockHighlight()
				addon.PlayUISound("ScrollBarThumbDown")
			end
		end

		function ThumbButtonMixin:OnMouseUp(button)
			if button == "LeftButton" then
				self.HighlightTop:SetAlpha(0.2)
				self.HighlightMiddle:SetAlpha(0.2)
				self.HighlightBottom:SetAlpha(0.2)
				self:UnlockHighlight()
				self:GetParent():StopUpdating()
				self:GetParent():UpdateVisual()
			end
		end

		local function Thumb_Expand_OnUpdate(self, elapsed)
			self.capSize = self.capSize + 128 * elapsed
			if self.capSize >= 16 then
				self.capSize = 16
				self:SetScript("OnUpdate", nil)
			end
			self.Top:SetSize(self.capSize, self.capSize)
			self.Bottom:SetSize(self.capSize, self.capSize)
		end

		local function Thumb_Shrink_OnUpdate(self, elapsed)
			self.capSize = self.capSize - 128 * elapsed
			if self.capSize <= 16 then
				self.capSize = 16
				self:SetScript("OnUpdate", nil)
			end
			self.Top:SetSize(self.capSize, self.capSize)
			self.Bottom:SetSize(self.capSize, self.capSize)
		end

		function ThumbButtonMixin:Expand()
			self.expanded = true
			self.Top:SetTexCoord(0 / 512, 32 / 512, 264 / 512, 296 / 512)
			self.Middle:SetTexCoord(0 / 512, 32 / 512, 296 / 512, 360 / 512)
			self.Bottom:SetTexCoord(0 / 512, 32 / 512, 360 / 512, 392 / 512)
			self.HighlightTop:SetTexCoord(0 / 512, 32 / 512, 264 / 512, 296 / 512)
			self.HighlightMiddle:SetTexCoord(0 / 512, 32 / 512, 296 / 512, 360 / 512)
			self.HighlightBottom:SetTexCoord(0 / 512, 32 / 512, 360 / 512, 392 / 512)

			self.capSize = self.Top:GetWidth() * 0.5
			self:SetScript("OnUpdate", Thumb_Expand_OnUpdate)
			Thumb_Expand_OnUpdate(self, 0)
		end

		function ThumbButtonMixin:Shrink()
			self.Top:SetTexCoord(0 / 512, 32 / 512, 132 / 512, 164 / 512)
			self.Middle:SetTexCoord(0 / 512, 32 / 512, 164 / 512, 228 / 512)
			self.Bottom:SetTexCoord(0 / 512, 32 / 512, 228 / 512, 260 / 512)
			self.HighlightTop:SetTexCoord(0 / 512, 32 / 512, 132 / 512, 164 / 512)
			self.HighlightMiddle:SetTexCoord(0 / 512, 32 / 512, 164 / 512, 228 / 512)
			self.HighlightBottom:SetTexCoord(0 / 512, 32 / 512, 228 / 512, 260 / 512)

			self.capSize = self.Top:GetWidth() * 2
			self:SetScript("OnUpdate", Thumb_Shrink_OnUpdate)
			Thumb_Shrink_OnUpdate(self, 0)
		end

		function ThumbButtonMixin:OnEnter()
			self:GetParent():UpdateVisual()
		end

		function ThumbButtonMixin:OnLeave()
			self:GetParent():UpdateVisual()
		end

		function ThumbButtonMixin:OnHide()
			self:OnMouseUp("LeftButton")
		end
	end

	local ScrollBarMixin = {}
	do
		function ScrollBarMixin:OnLoad()
			self.OnLoad = nil

			Mixin(self.UpArrow, ArrowButtonMixin)
			Mixin(self.DownArrow, ArrowButtonMixin)
			Mixin(self.Thumb, ThumbButtonMixin)
			self.UpArrow:OnLoad()
			self.UpArrow.delta = 1
			self.DownArrow:OnLoad()
			self.DownArrow.delta = -1
			self.Thumb:OnLoad()

			self.textureObjects = {}

			local function AddTexture(obj)
				self.textureObjects[obj] = true
			end

			local function SetTexCoord(obj, x1, x2, y1, y2)
				AddTexture(obj)
				obj:SetTexCoord(x1 / 512, x2 / 512, y1 / 512, y2 / 512)
			end

			SetTexCoord(self.Rail.Top, 0, 32, 0, 32)
			SetTexCoord(self.Rail.Middle, 0, 32, 32, 96)
			SetTexCoord(self.Rail.Bottom, 0, 32, 96, 128)

			SetTexCoord(self.Thumb.Top, 0, 32, 132, 164)
			SetTexCoord(self.Thumb.HighlightTop, 0, 32, 132, 164)
			SetTexCoord(self.Thumb.Middle, 0, 32, 164, 228)
			SetTexCoord(self.Thumb.HighlightMiddle, 0, 32, 164, 228)
			SetTexCoord(self.Thumb.Bottom, 0, 32, 228, 260)
			SetTexCoord(self.Thumb.HighlightBottom, 0, 32, 228, 260)

			SetTexCoord(self.UpArrow.Texture, 0, 32, 396, 428)
			SetTexCoord(self.UpArrow.Highlight, 0, 32, 396, 428)
			SetTexCoord(self.DownArrow.Texture, 0, 32, 428, 460)
			SetTexCoord(self.DownArrow.Highlight, 0, 32, 428, 460)

			self.Rail:SetScript("OnMouseDown", function(_, button)
				if button == "LeftButton" then
					self:ScrollToMouseDownPosition()
					addon.PlayUISound("ScrollBarThumbDown")
				end
			end)

			self.Rail:SetScript("OnEnter", function()
				self:UpdateVisual()
			end)

			self.Rail:SetScript("OnLeave", function()
				self:UpdateVisual()
			end)
		end

		function ScrollBarMixin:SetTexture(texture)
			for obj in pairs(self.textureObjects) do
				obj:SetTexture(texture)
			end
		end

		function ScrollBarMixin:ShowArrowButtons(showArrows)
			if showArrows == self.showArrows then
				return
			end
			self.showArrows = showArrows

			self.UpArrow:SetShown(showArrows)
			self.DownArrow:SetShown(showArrows)

			local offsetY
			if showArrows then
				offsetY = 16
			else
				offsetY = 0
			end

			self.Rail:ClearAllPoints()
			self.Rail:SetPoint("TOP", self, "TOP", 0, -offsetY)
			self.Rail:SetPoint("BOTTOM", self, "BOTTOM", 0, offsetY)
		end

		function ScrollBarMixin:SetVisibleExtentPercentage(ratio)
			local height = API.Round(ratio * self.Rail:GetHeight())
			if height < 32 then
				height = 32
			end
			self.Thumb:SetHeight(height)
		end

		function ScrollBarMixin:UpdateVisibleExtentPercentage()
			local range = self.ScrollView:GetScrollRange()
			local viewHeight = self.ScrollView:GetHeight()
			local ratio = viewHeight / (viewHeight + range)
			if ratio > 0.95 then
				ratio = 0.95
			end
			self:SetVisibleExtentPercentage(ratio)
			self:UpdateThumbRange()
			self:SetValueByRatio(self.ratio or 0)
		end

		function ScrollBarMixin:OnSizeChanged()
			self:UpdateVisibleExtentPercentage()
		end

		function ScrollBarMixin:SetValueByRatio(ratio)
			if ratio < 0.001 then
				ratio = 0
				self.isTop = true
				self.isBottom = false
			elseif ratio > 0.999 then
				ratio = 1
				self.isTop = false
				self.isBottom = true
			else
				self.isTop = false
				self.isBottom = false
			end

			if self.isTop then
				self.UpArrow:Disable()
			else
				self.UpArrow:Enable()
			end

			if self.isBottom then
				self.DownArrow:Disable()
			else
				self.DownArrow:Enable()
			end

			self.ratio = ratio
			self.Thumb:SetPoint("TOP", self.Rail, "TOP", 0, -ratio * self.thumbRange)
		end

		function ScrollBarMixin:UpdateThumbRange()
			local railLength = self.Rail:GetHeight()
			local range = API.Round(railLength - self.Thumb:GetHeight())
			self.thumbRange = range
			if range > 0 then
				self.ratioPerUnit = 1 / range
			else
				self.ratioPerUnit = 1
			end
		end

		function ScrollBarMixin:SetScrollable(scrollable)
			if scrollable then
				self.Thumb:Show()
				self.UpArrow:Show()
				self.DownArrow:Show()
				self.isTop = self.ScrollView:IsAtTop()
				self.isBottom = self.ScrollView:IsAtBottom()
				self:SetAlpha(1)
			else
				self.Thumb:Hide()
				self.UpArrow:Hide()
				self.DownArrow:Hide()
				self.isTop = true
				self.isBottom = true
				self:SetAlpha(0.5)
			end
			self.scrollable = scrollable
			self.UpArrow:SetEnabled(not self.isTop)
			self.DownArrow:SetEnabled(not self.isBottom)
			self:UpdateThumbRange()
		end

		function ScrollBarMixin:UpdateVisual()
			if self.Rail:IsMouseMotionFocus() or self.Thumb:IsMouseMotionFocus() or self:IsDraggingThumb() then
				if not self.expanded then
					self.expanded = true
					self.Thumb:Expand()
				end
			else
				if self.expanded then
					self.expanded = nil
					self.Thumb:Shrink()
				end
			end
		end

		function ScrollBarMixin:StartDraggingThumb()
			self:Snapshot()
			self:UpdateThumbRange()
			self.t = 0
			self.isDraggingThumb = true
			self:SetScript("OnUpdate", self.OnUpdate_ThumbDragged)
		end

		function ScrollBarMixin:IsDraggingThumb()
			return self.isDraggingThumb
		end

		function ScrollBarMixin:OnUpdate_ThumbDragged(elapsed)
			self.x, self.y = GetCursorPosition()
			self.x = self.x / self.scale
			self.y = self.y / self.scale
			self.dx = self.x - self.x0
			self.dy = self.y - self.y0
			self:SetValueByRatio(self.fromRatio - self.dy * self.ratioPerUnit)
			self.ScrollView:SnapToRatio(self.ratio)
		end

		function ScrollBarMixin:Snapshot()
			self.x0, self.y0 = GetCursorPosition()
			self.scale = self:GetEffectiveScale()
			self.x0 = self.x0 / self.scale
			self.y0 = self.y0 / self.scale
			self.fromRatio = self.ratio
		end

		function ScrollBarMixin:StartPushingArrow(delta)
			self:Snapshot()
			self:UpdateThumbRange()
			self.t = 0
			self.delta = delta or -1
			self:SetScript("OnUpdate", self.OnUpdate_ArrowPushed)
		end

		function ScrollBarMixin:OnUpdate_ArrowPushed(elapsed)
			self.t = self.t + elapsed
			if self.t > 0.3 then
				self.t = 0
				self.ScrollView:SteadyScroll(-self.delta)
			end
		end

		function ScrollBarMixin:StopUpdating()
			self:SetScript("OnUpdate", nil)
			self.t = nil
			self.x, self.y = nil, nil
			self.x0, self.y0 = nil, nil
			self.dx, self.dy = nil, nil
			self.scale = nil
			self.isDraggingThumb = nil
		end

		function ScrollBarMixin:ScrollToMouseDownPosition()
			local x, y = GetCursorPosition()
			local scale = self:GetEffectiveScale()
			x, y = x / scale, y / scale

			local top = self.Rail:GetTop()
			local bottom = self.Rail:GetBottom()

			local ratio
			if (top - y) < 4 then
				ratio = 0
			elseif (y - bottom) < 4 then
				ratio = 1
			else
				ratio = (y - top) / (bottom - top)
			end

			self.ScrollView:ScrollToRatio(ratio)
		end

		function ScrollBarMixin:GetScrollView()
			return self.ScrollView
		end

		function ScrollBarMixin:Update()
			if self.ScrollView then
				self:UpdateVisibleExtentPercentage()
			end
		end
	end

	local DebugScrollView = {}
	do
		function DebugScrollView:ScrollToRatio() end

		function DebugScrollView:SnapToRatio() end

		function DebugScrollView:OnMouseWheel() end

		function DebugScrollView:IsAtTop() end

		function DebugScrollView:IsAtBottom() end

		function DebugScrollView:SteadyScroll() end

		function DebugScrollView:StopSteadyScroll() end
	end

	local function CreateScrollBarWithDynamicSize(parent)
		local f = CreateFrame("Frame", nil, parent, "AeonToolsScrollBarWithDynamicSizeTemplate")

		Mixin(f, ScrollBarMixin)
		f:OnLoad()
		f:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/SettingsPanelWidget.png")
		f:ShowArrowButtons(true)
		f:UpdateThumbRange()
		f:SetValueByRatio(0)

		f.ScrollView = DebugScrollView

		return f
	end
	API.CreateScrollBarWithDynamicSize = CreateScrollBarWithDynamicSize
end

do -- CreateBackdrop adapted from ElvUI
	local DEFAULT_BACKDROP_COLOR = { 0, 0, 0, 0.5 } -- RGBA
	local DEFAULT_BORDER_COLOR = { 0, 0, 0, 1 } -- RGBA
	local DEFAULT_EDGE_FILE = "Interface\\Buttons\\WHITE8X8"
	local function SetOutside(obj, anchor, xOffset, yOffset)
		xOffset = xOffset or 0
		yOffset = yOffset or 0
		anchor = anchor or obj:GetParent()

		if obj:GetPoint() then
			obj:ClearAllPoints()
		end
		obj:SetPoint("TOPLEFT", anchor, "TOPLEFT", -xOffset, yOffset)
		obj:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", xOffset, -yOffset)
	end

	local function CreateBackdrop(frame, template)
		local backdrop = frame.backdrop or CreateFrame("Frame", nil, frame, "BackdropTemplate")
		if not frame.backdrop then
			frame.backdrop = backdrop
		end

		backdrop:SetFrameLevel(frame:GetFrameLevel() - 1)

		-- Default Backdrop Settings
		backdrop:SetBackdrop({
			bgFile = DEFAULT_EDGE_FILE,
			edgeFile = DEFAULT_EDGE_FILE,
			edgeSize = 1,
		})

		if template == "Transparent" then
			backdrop:SetBackdropColor(unpack(DEFAULT_BACKDROP_COLOR))
			backdrop:SetBackdropBorderColor(unpack(DEFAULT_BORDER_COLOR))
		else
			backdrop:SetBackdropColor(0, 0, 0, 1)
			backdrop:SetBackdropBorderColor(1, 1, 1, 1)
		end

		SetOutside(backdrop, frame, 1, 1)
	end
	API.CreateBackdrop = CreateBackdrop
end

local CreateScrollBar
do
	local GetCursorPosition = GetCursorPosition
	local ScrollBarMixin = {}
	local ArrowButtonMixin = {}
	do
		function ArrowButtonMixin:OnLoad()
			self:SetScript("OnEnter", self.OnEnter)
			self:SetScript("OnLeave", self.OnLeave)
			self:SetScript("OnMouseDown", self.OnMouseDown)
			self:SetScript("OnMouseUp", self.OnMouseUp)
			self:SetScript("OnEnable", self.OnEnable)
			self:SetScript("OnDisable", self.OnDisable)
		end

		function ArrowButtonMixin:OnEnter() end

		function ArrowButtonMixin:OnLeave() end

		function ArrowButtonMixin:OnMouseDown(button)
			if not self:IsEnabled() then
				return
			end
			if button == "LeftButton" then
				self:SharedOnMouseDown(button)
				self:GetParent():GetScrollView():OnMouseWheel(self.delta)
				self:GetParent():StartPushingArrow(self.delta)
				addon.PlayUISound("ScrollBarStep")
			end
		end

		function ArrowButtonMixin:OnMouseUp(button)
			self:SharedOnMouseUp(button)
			self:GetParent():StopUpdating()
			self:GetParent():GetScrollView():StopSteadyScroll()
		end

		function ArrowButtonMixin:OnEnable()
			self.Texture:SetVertexColor(1, 1, 1)
			self.Texture:SetDesaturated(false)
		end

		function ArrowButtonMixin:OnDisable()
			self.Texture:SetVertexColor(0.5, 0.5, 0.5)
			self.Texture:SetDesaturated(true)
		end
	end

	function ScrollBarMixin:SetValueByRatio(ratio)
		if ratio < 0.001 then
			ratio = 0
			self.isTop = true
			self.isBottom = false
		elseif ratio > 0.999 then
			ratio = 1
			self.isTop = false
			self.isBottom = true
		else
			self.isTop = false
			self.isBottom = false
		end

		if self.isTop then
			self.UpArrow:Disable()
		else
			self.UpArrow:Enable()
		end
		if self.isBottom then
			self.DownArrow:Disable()
		else
			self.DownArrow:Enable()
		end

		self.ratio = ratio
		self.Thumb:SetPoint("TOP", self.Rail, "TOP", 0, -ratio * self.thumbRange)
	end

	function ScrollBarMixin:UpdateThumbRange()
		local railLength = self.Rail:GetHeight()
		local range = API.Round(railLength - self.Thumb:GetHeight())
		self.thumbRange = range
		self.ratioPerUnit = 1 / range
	end

	function ScrollBarMixin:SetScrollable(scrollable)
		if scrollable then
			self.Thumb:Show()
			self.UpArrow:Show()
			self.DownArrow:Show()
			self.isTop = self:GetScrollView():IsAtTop()
			self.isBottom = self:GetScrollView():IsAtBottom()
			self:SetAlpha(1)
		else
			self.Thumb:Hide()
			self.UpArrow:Hide()
			self.DownArrow:Hide()
			self.isTop = true
			self.isBottom = true
			self:SetAlpha(0.5)
		end
		self.scrollable = scrollable
		self.UpArrow:SetEnabled(not self.isTop)
		self.DownArrow:SetEnabled(not self.isBottom)
		self:UpdateThumbRange()
	end

	function ScrollBarMixin:StartDraggingThumb()
		self:Snapshot()
		self:UpdateThumbRange()
		self.t = 0
		self:SetScript("OnUpdate", self.OnUpdate_ThumbDragged)
	end

	function ScrollBarMixin:OnUpdate_ThumbDragged(elapsed)
		self.x, self.y = GetCursorPosition()
		self.x = self.x / self.scale
		self.y = self.y / self.scale
		self.dx = self.x - self.x0
		self.dy = self.y - self.y0
		self:SetValueByRatio(self.fromRatio - self.dy * self.ratioPerUnit)
		self.ScrollView:SnapToRatio(self.ratio)
	end

	function ScrollBarMixin:Snapshot()
		self.x0, self.y0 = GetCursorPosition()
		self.scale = self:GetEffectiveScale()
		self.x0 = self.x0 / self.scale
		self.y0 = self.y0 / self.scale
		self.fromRatio = self.ratio
	end

	function ScrollBarMixin:StartPushingArrow(delta)
		self:Snapshot()
		self:UpdateThumbRange()
		self.t = 0
		self.delta = delta or -1
		self:SetScript("OnUpdate", self.OnUpdate_ArrowPushed)
	end

	function ScrollBarMixin:OnUpdate_ArrowPushed(elapsed)
		self.t = self.t + elapsed
		if self.t > 0.3 then
			self.t = 0
			self:GetScrollView():SteadyScroll(-self.delta)
		end
	end

	function ScrollBarMixin:StopUpdating()
		self:SetScript("OnUpdate", nil)
		self.t = nil
		self.x, self.y = nil, nil
		self.x0, self.y0 = nil, nil
		self.dx, self.dy = nil, nil
		self.scale = nil
	end

	function ScrollBarMixin:ScrollToMouseDownPosition()
		local x, y = GetCursorPosition()
		local scale = self:GetEffectiveScale()
		x, y = x / scale, y / scale

		local top = self.Rail:GetTop()
		local bottom = self.Rail:GetBottom()

		local ratio
		if (top - y) < 4 then
			ratio = 0
		elseif (y - bottom) < 4 then
			ratio = 1
		else
			ratio = (y - top) / (bottom - top)
		end

		self:GetScrollView():ScrollToRatio(ratio)
	end

	function ScrollBarMixin:GetScrollView()
		return self.ScrollView
	end

	local function TextureButton_SetupTexture(self, file, l, r, t, b)
		if file then
			self.Texture:SetTexture(file)
			self.Highlight:SetTexture(file)
		end
		self.Texture:SetTexCoord(l, r, t, b)
		self.Highlight:SetTexCoord(l, r, t, b)
	end

	function ScrollBarMixin:SetMinimized(minimized)
		--Reduce the size of Up/Down buttons for smaller frame

		local arrowOffsetY, arrowWidth, arrowHeight
		local sideOffsetY, railWidth, railHeight
		local railOffesetY

		if minimized then
			arrowOffsetY = 4
			arrowWidth, arrowHeight = 16, 16
			sideOffsetY = -8
			railWidth, railHeight = 16, 16
			railOffesetY = -1
			TextureButton_SetupTexture(self.UpArrow, nil, 64 / 1024, 96 / 1024, 656 / 1024, 688 / 1024)
			TextureButton_SetupTexture(self.DownArrow, nil, 96 / 1024, 64 / 1024, 688 / 1024, 656 / 1024)
			TextureButton_SetupTexture(self.Thumb, nil, 64 / 1024, 96 / 1024, 768 / 1024, 840 / 1024)
			self.Thumb.Texture:SetSize(16, 36)
			self.Rail.Top:SetTexCoord(64 / 1024, 96 / 1024, 696 / 1024, 728 / 1024)
			self.Rail.Bottom:SetTexCoord(64 / 1024, 96 / 1024, 728 / 1024, 760 / 1024)
			self:SetWidth(8)
		else
			arrowOffsetY = -5
			arrowWidth, arrowHeight = 16, 20
			sideOffsetY = 6
			railWidth, railHeight = 32, 64
			railOffesetY = -22
			TextureButton_SetupTexture(self.UpArrow, nil, 64 / 1024, 96 / 1024, 616 / 1024, 656 / 1024)
			TextureButton_SetupTexture(self.DownArrow, nil, 64 / 1024, 96 / 1024, 656 / 1024, 616 / 1024)
			TextureButton_SetupTexture(self.Thumb, nil, 64 / 1024, 96 / 1024, 512 / 1024, 616 / 1024)
			self.Thumb.Texture:SetSize(16, 52)
			self.Rail.Top:SetTexCoord(0 / 1024, 64 / 1024, 512 / 1024, 640 / 1024)
			self.Rail.Bottom:SetTexCoord(0 / 1024, 64 / 1024, 896 / 1024, 1024 / 1024)
			self:SetWidth(16)
		end

		self.UpArrow.Texture:SetSize(arrowWidth, arrowHeight)
		self.DownArrow.Texture:SetSize(arrowWidth, arrowHeight)
		self.UpArrow:SetPoint("TOP", self, "TOP", 0, arrowOffsetY)
		self.DownArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowOffsetY)

		self.Rail.Top:SetPoint("TOP", self, "TOP", 0, sideOffsetY)
		self.Rail.Top:SetSize(railWidth, railHeight)
		self.Rail.Bottom:SetPoint("BOTTOM", self, "BOTTOM", 0, -sideOffsetY)
		self.Rail.Bottom:SetSize(railWidth, railHeight)

		self.Rail:SetPoint("TOP", self, "TOP", 0, railOffesetY)
		self.Rail:SetPoint("BOTTOM", self, "BOTTOM", 0, -railOffesetY)
	end

	local function TextureButton_SharedOnMouseDown(self, button)
		if self:IsEnabled() and button == "LeftButton" then
			self.Highlight:SetAlpha(0.5)
		end
	end

	local function TextureButton_SharedOnMouseUp(self, button)
		self.Highlight:SetAlpha(0.2)
	end

	local function CreateTextureButton(parent)
		local b = CreateFrame("Button", nil, parent)
		b.Texture = b:CreateTexture(nil, "ARTWORK")
		b.Texture:SetPoint("CENTER", b, "CENTER", 0, 0)
		b.Highlight = b:CreateTexture(nil, "HIGHLIGHT")
		b.Highlight:SetPoint("TOPLEFT", b.Texture, "TOPLEFT", 0, 0)
		b.Highlight:SetPoint("BOTTOMRIGHT", b.Texture, "BOTTOMRIGHT", 0, 0)
		b.Highlight:SetBlendMode("ADD")
		TextureButton_SharedOnMouseUp(b)
		b.SetupTexture = TextureButton_SetupTexture
		b.SharedOnMouseDown = TextureButton_SharedOnMouseDown
		b.SharedOnMouseUp = TextureButton_SharedOnMouseUp
		return b
	end

	function CreateScrollBar(parent)
		local textureFile = "Interface/AddOns/AeonTools/Assets/Settings/ExpansionBorder_TWW"

		local f = CreateFrame("Frame", nil, parent)
		f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -16)
		f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 16)
		f:SetSize(16, 256)
		f.ScrollView = parent

		local function CreateArrowButton(delta)
			local b = CreateTextureButton(f)
			b:SetSize(16, 20)
			b.Texture:SetSize(16, 20)
			API.Mixin(b, ArrowButtonMixin)
			b:OnLoad()
			b.delta = delta

			if delta > 0 then
				b:SetupTexture(textureFile, 64 / 1024, 96 / 1024, 616 / 1024, 656 / 1024)
			else
				b:SetupTexture(textureFile, 64 / 1024, 96 / 1024, 656 / 1024, 616 / 1024)
			end

			return b
		end

		f.UpArrow = CreateArrowButton(1)
		f.UpArrow:SetPoint("TOP", f, "TOP", 0, -5)

		f.DownArrow = CreateArrowButton(-1)
		f.DownArrow:SetPoint("BOTTOM", f, "BOTTOM", 0, 5)

		local Rail = CreateFrame("Frame", nil, f)
		f.Rail = Rail
		Rail:SetPoint("TOP", f, "TOP", 0, -22)
		Rail:SetPoint("BOTTOM", f, "BOTTOM", 0, 22)
		Rail:SetSize(16, 208)
		Rail:SetUsingParentLevel(true)

		Rail.Top = f:CreateTexture(nil, "ARTWORK")
		Rail.Top:SetPoint("TOP", f, "TOP", 0, 6)
		Rail.Top:SetSize(32, 64)
		Rail.Top:SetTexture(textureFile)

		Rail.Bottom = f:CreateTexture(nil, "ARTWORK")
		Rail.Bottom:SetPoint("BOTTOM", f, "BOTTOM", 0, -6)
		Rail.Bottom:SetSize(32, 64)
		Rail.Bottom:SetTexture(textureFile)

		Rail.Middle = f:CreateTexture(nil, "ARTWORK")
		Rail.Middle:SetSize(32, 32)
		Rail.Middle:SetPoint("TOP", Rail.Top, "BOTTOM", 0, 0)
		Rail.Middle:SetPoint("BOTTOM", Rail.Bottom, "TOP", 0, 0)
		Rail.Middle:SetTexture(textureFile)
		Rail.Middle:SetTexCoord(0 / 1024, 64 / 1024, 640 / 1024, 896 / 1024)

		Rail:SetScript("OnMouseDown", function(_, button)
			if button == "LeftButton" then
				f:ScrollToMouseDownPosition()
				addon.PlayUISound("ScrollBarThumbDown")
			end
		end)

		local Thumb = CreateTextureButton(f)
		f.Thumb = Thumb
		Thumb:SetSize(16, 64)
		Thumb:SetPoint("TOP", Rail, "TOP", 0, 0)
		Thumb:SetupTexture(textureFile, 64 / 1024, 96 / 1024, 512 / 1024, 616 / 1024)
		Thumb.Texture:SetSize(16, 52)

		API.Mixin(f, ScrollBarMixin)

		f:UpdateThumbRange()
		f:SetValueByRatio(0)
		f:SetMinimized(false)

		Thumb:SetScript("OnMouseDown", function(_, button)
			if button == "LeftButton" then
				f:StartDraggingThumb()
				Thumb:LockHighlight()
				Thumb:SharedOnMouseDown(button)
				addon.PlayUISound("ScrollBarThumbDown")
			end
		end)

		Thumb:SetScript("OnMouseUp", function(_, button)
			f:StopUpdating()
			Thumb:UnlockHighlight()
			Thumb:SharedOnMouseUp(button)
		end)

		Thumb:SetScript("OnHide", function()
			Thumb:UnlockHighlight()
			Thumb:SharedOnMouseUp()
		end)

		API.DisableSharpening(f.Rail.Top)
		API.DisableSharpening(f.Rail.Middle)
		API.DisableSharpening(f.Rail.Bottom)

		return f
	end
end

local CreateObjectPool = API.CreateObjectPool
local ScrollViewMixin = {}

local function CreateScrollView(parent, scrollBar)
	local f = CreateFrame("Frame", nil, parent)
	API.Mixin(f, ScrollViewMixin)
	f:SetClipsChildren(true)

	f.ScrollRef = CreateFrame("Frame", nil, f)
	f.ScrollRef:SetSize(4, 4)
	f.ScrollRef:SetPoint("TOP", f, "TOP", 0, 0)

	f.pools = {}
	f.content = {}
	f.indexedObjects = {}
	f.offset = 0
	f.scrollTarget = 0
	f.range = 0
	f.viewportSize = 0
	f.blendSpeed = 0.15

	f:SetStepSize(32)
	f:SetBottomOvershoot(0)

	f:SetScript("OnMouseWheel", f.OnMouseWheel)
	f:SetScript("OnHide", f.OnHide)

	if not (f.ScrollBar or scrollBar) then
		f.ScrollBar = CreateScrollBar(f)
		f.ScrollBar:SetFrameLevel(f:GetFrameLevel() + 10)
		f.ScrollBar:UpdateThumbRange()
	end

	if scrollBar then
		f.ScrollBar = scrollBar
	end

	local NoContentAlert = CreateFrame("Frame", nil, f)
	f.NoContentAlert = NoContentAlert
	NoContentAlert:Hide()
	NoContentAlert:SetAllPoints(true)

	local fs1 = NoContentAlert:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	NoContentAlert.AlertText = fs1
	fs1:SetPoint("LEFT", f, "LEFT", 16, 16)
	fs1:SetPoint("RIGHT", f, "RIGHT", -16, 16)
	fs1:SetSpacing(4)
	fs1:SetJustifyH("CENTER")
	fs1:SetText(addon.L["List Is Empty"])
	fs1:SetTextColor(0.5, 0.5, 0.5)

	return f
end
API.CreateScrollView = CreateScrollView

do --ScrollView Basic Content Render
	function ScrollViewMixin:GetScrollTarget()
		return self.scrollTarget
	end

	function ScrollViewMixin:GetOffset()
		return self.offset
	end

	function ScrollViewMixin:SetOffset(offset)
		self.offset = offset
		self.ScrollRef:SetPoint("TOP", self, "TOP", 0, offset)

		if self.scrollable then
			self.ScrollBar:SetValueByRatio(offset / self.range)
		else
			self.ScrollBar:SetValueByRatio(0)
		end
	end

	function ScrollViewMixin:UpdateView(useScrollTarget)
		local top = (useScrollTarget and self.scrollTarget) or self.offset
		local bottom = self.offset + self.viewportSize
		local fromDataIndex
		local toDataIndex

		if self.renderAllObjects then
			fromDataIndex = 1
			toDataIndex = self.numContent or 0
		else
			for dataIndex, v in ipairs(self.content) do
				if not fromDataIndex then
					if v.top >= top or v.bottom >= top then
						fromDataIndex = dataIndex
					end
				end

				if not toDataIndex then
					if (v.top <= bottom and v.bottom >= bottom) or (v.top >= bottom) then
						toDataIndex = dataIndex
						local nextIndex = dataIndex + 1
						v = self.content[nextIndex]
						if v then
							if v.top <= bottom then
								toDataIndex = nextIndex
							end
						end
						break
					end
				end
			end
			toDataIndex = toDataIndex or self.numContent

			for dataIndex, obj in pairs(self.indexedObjects) do
				if dataIndex < fromDataIndex or dataIndex > toDataIndex then
					obj:Release()
					self.indexedObjects[dataIndex] = nil
				end
			end
		end

		local obj
		local contentData

		if fromDataIndex then
			for dataIndex = fromDataIndex, toDataIndex do
				if self.indexedObjects[dataIndex] then
				else
					contentData = self.content[dataIndex]
					obj = self:AcquireObject(contentData.templateKey)
					if obj then
						if contentData.setupFunc then
							contentData.setupFunc(obj)
						end
						obj:SetPoint(
							contentData.point or "TOP",
							self.ScrollRef,
							contentData.relativePoint or "TOP",
							contentData.offsetX or 0,
							-contentData.top
						)
						self.indexedObjects[dataIndex] = obj
					end
				end
			end
		end
	end

	function ScrollViewMixin:OnSizeChanged(forceUpdate)
		--We call this manually
		self.viewportSize = API.Round(self:GetHeight())
		self.ScrollRef:SetWidth(API.Round(self:GetWidth()))
		if forceUpdate then
			self.ScrollBar:UpdateThumbRange()
			self:SetContent(self.content)
			--self:SnapTo(self.offset or 0);
		end
	end

	function ScrollViewMixin:OnMouseWheel(delta)
		if (delta > 0 and self.scrollTarget <= 0) or (delta < 0 and self.scrollTarget >= self.range) then
			return
		end

		local a = IsShiftKeyDown() and 2 or 1
		self:ScrollBy(-self.stepSize * a * delta)
	end

	function ScrollViewMixin:SetStepSize(stepSize)
		self.stepSize = stepSize
	end

	function ScrollViewMixin:SetScrollRange(range)
		if range < 0 then
			range = 0
		end

		self.range = range

		local scrollable = range > 0

		if (not scrollable) and self.smartClipsChildren then
			self:SetClipsChildren(false)
			self:SetScript("OnMouseWheel", nil)
		else
			self:SetClipsChildren(true)
			self:SetScript("OnMouseWheel", self.OnMouseWheel)
		end

		if (not scrollable) and self.scrollable then
			self:ScrollToTop()
		end

		self.scrollable = scrollable
		self.ScrollBar:SetScrollable(self.scrollable)
		self.ScrollBar:SetShown(scrollable or self.alwaysShowScrollBar)
		if scrollable and self.ScrollBar.UpdateVisibleExtentPercentage then
			self.ScrollBar:UpdateVisibleExtentPercentage()
		end

		if self.useBoundaryGradient then
			if scrollable then
				self.BottomGradient:Show()
			else
				self.BottomGradient:Hide()
			end
		end
	end

	function ScrollViewMixin:GetScrollRange()
		return self.range or 0
	end

	function ScrollViewMixin:IsScrollable()
		return self.scrollable
	end

	function ScrollViewMixin:SetContent(content, retainPosition)
		content = content or {}
		self.content = content
		self.numContent = #content

		if self.numContent > 0 then
			local range = content[self.numContent].bottom - self.viewportSize
			if true or range > 0 then
				range = range + self.bottomOvershoot
			end
			self:SetScrollRange(range)
			self.NoContentAlert:Hide()
		else
			self:SetScrollRange(0)
			if self.showNoContentAlert then
				self.NoContentAlert:Show()
			else
				self.NoContentAlert:Hide()
			end
		end

		self:ReleaseAllObjects()

		if retainPosition then
			local offset = self.scrollTarget
			if (not self.allowOvershoot) and offset > self.range then
				offset = self.range
			end
			self.scrollTarget = offset
		else
			self.scrollTarget = 0
		end
		self:SnapToScrollTarget()
	end
end

do --ScrollView ObjectPool
	function ScrollViewMixin:AddTemplate(templateKey, create, onAcquired, onRemoved)
		self.pools[templateKey] = CreateObjectPool(create, onAcquired, onRemoved)
	end

	function ScrollViewMixin:AcquireObject(templateKey)
		return self.pools[templateKey]:Acquire()
	end

	function ScrollViewMixin:ReleaseAllObjects()
		self.indexedObjects = {}
		for templateKey, pool in pairs(self.pools) do
			pool:ReleaseAll()
		end
	end

	function ScrollViewMixin:GetDebugCount()
		local total = 0
		local active = 0
		local unused = 0
		for templateKey, pool in pairs(self.pools) do
			total = total + #pool.objects
			active = active + #pool.activeObjects
			unused = unused + #pool.unusedObjects
		end
		print(total, active, unused)
	end
end

do --ScrollView Smooth Scroll
	function ScrollViewMixin:StopScrolling()
		if self.MouseBlocker then
			self.MouseBlocker:Hide()
		end

		if self.isScrolling or self.isSteadyScrolling then
			self.recycleTimer = 0
			self.isScrolling = nil
			self.isSteadyScrolling = nil
			self:SetScript("OnUpdate", nil)
			self:UpdateView(true)
			self:OnScrollStop()
		end
	end

	function ScrollViewMixin:SnapToScrollTarget()
		self.recycleTimer = 0
		self:SetOffset(self.scrollTarget)
		self.isScrolling = true
		self:StopScrolling()
	end

	function ScrollViewMixin:OnUpdate_Easing(elapsed)
		self.isScrolling = true
		self.offset = DeltaLerp(self.offset, self.scrollTarget, self.blendSpeed, elapsed)

		self.targetDiff = self.offset - self.scrollTarget
		if self.targetDiff < 0 then
			self.targetDiff = -self.targetDiff
		end

		if self.targetDiff < 0.4 then
			self.offset = self.scrollTarget
			self:SnapToScrollTarget()
			return
		elseif self.targetDiff < 2 and self.useMouseBlocker then
			self.MouseBlocker:Hide()
		end

		self.recycleTimer = self.recycleTimer + elapsed
		if self.recycleTimer > 0.033 then
			self.recycleTimer = 0
			self:UpdateView()
		end

		self:SetOffset(self.offset)
	end

	function ScrollViewMixin:OnUpdate_SteadyScroll(elapsed)
		self.isScrolling = true
		self.offset = self.offset + self.scrollSpeed * elapsed

		if self.offset < 0 then
			self.offset = 0
			self.isSteadyScrolling = nil
		elseif self.offset > self.range then
			self.offset = self.range
			self.isSteadyScrolling = nil
		elseif self.scrollSpeed < 4 and self.scrollSpeed > -4 then
			self.isSteadyScrolling = nil
		else
			self.isSteadyScrolling = true
		end

		self.scrollTarget = self.offset

		if not self.isSteadyScrolling then
			self:StopScrolling()
		end

		self.recycleTimer = self.recycleTimer + elapsed
		if self.recycleTimer > 0.033 then
			self.recycleTimer = 0
			self:UpdateView()
		end

		self:SetOffset(self.offset)
	end

	function ScrollViewMixin:SteadyScroll(strengh)
		--For Joystick: strengh -1 ~ +1

		if strengh > 0.8 then
			self.scrollSpeed = 80 + 600 * (strengh - 0.8)
		elseif strengh < -0.8 then
			self.scrollSpeed = -80 + 600 * (strengh + 0.8)
		else
			self.scrollSpeed = 100 * strengh
		end

		if not self.isSteadyScrolling then
			self.recycleTimer = 0
			self:SetScript("OnUpdate", self.OnUpdate_SteadyScroll)
			self:OnScrollStart()
		end
	end

	function ScrollViewMixin:StopSteadyScroll()
		if self.isSteadyScrolling then
			self:StopScrolling()
		end
	end

	function ScrollViewMixin:SnapTo(value)
		--No Easing
		value = Clamp(value, 0, self.range)
		self:SetOffset(value)
		self.scrollTarget = value
		self.isScrolling = true
		self:StopScrolling()
	end

	function ScrollViewMixin:ScrollTo(value)
		--Easing
		value = Clamp(value, 0, self.range)
		self.isSteadyScrolling = nil
		if value ~= self.scrollTarget then
			self.scrollTarget = value
			self.recycleTimer = 0
			self:SetScript("OnUpdate", self.OnUpdate_Easing)
			self:OnScrollStart()
		end
	end

	function ScrollViewMixin:ScrollBy(deltaValue)
		self:ScrollTo(self:GetScrollTarget() + deltaValue)
	end
end

do --ScrollView Scroll Behavior
	function ScrollViewMixin:ScrollToTop()
		self:ScrollTo(0)
	end

	function ScrollViewMixin:ScrollToBottom()
		self:ScrollTo(self.range)
	end

	function ScrollViewMixin:ScrollToRatio(ratio)
		ratio = Clamp(ratio, 0, 1)
		self:ScrollTo(self.range * ratio)
	end

	function ScrollViewMixin:ResetScroll()
		self:SnapTo(0)
	end

	function ScrollViewMixin:SnapToBottom()
		self:SnapTo(self.range)
	end

	function ScrollViewMixin:SnapToRatio(ratio)
		ratio = Clamp(ratio, 0, 1)
		self:SnapTo(self.range * ratio)
	end

	function ScrollViewMixin:ScrollToContent(contentIndex)
		if contentIndex < 1 then
			contentIndex = 1
		end

		if self.content[contentIndex] then
			self:ScrollTo(self.content[contentIndex].top)
		end
	end

	function ScrollViewMixin:SnapToContent(contentIndex)
		if contentIndex < 1 then
			contentIndex = 1
		end

		if contentIndex == 1 then
			self:ResetScroll()
			return
		end

		if self.content[contentIndex] then
			self:SnapTo(self.content[contentIndex].top)
		end
	end

	function ScrollViewMixin:SetBottomOvershoot(bottomOvershoot)
		self.bottomOvershoot = bottomOvershoot
	end

	function ScrollViewMixin:EnableMouseBlocker(state)
		self.useMouseBlocker = state
		if state then
			if not self.MouseBlocker then
				local f = CreateFrame("Frame", nil, self)
				self.MouseBlocker = f
				f:Hide()
				f:SetAllPoints(true)
				f:EnableMouse(true)
				f:EnableMouseMotion(true)
			end
		else
			if self.MouseBlocker then
				self.MouseBlocker:Hide()
			end
		end
	end

	function ScrollViewMixin:SetSmartClipsChildren(state)
		--If true, SetClipsChildren(false)
		--This affects texture rendering
		self.smartClipsChildren = state
	end

	function ScrollViewMixin:SetAllowOvershootAfterRangeChange(state)
		--If the entries are collapsible, the header button's position may change with scroll range
		--If true, the button will retain its position until scroll
		self.allowOvershoot = state
	end

	function ScrollViewMixin:SetAlwaysShowScrollBar(state)
		--If false, hide the scroll bar when it's not scrollable
		self.alwaysShowScrollBar = state
	end

	function ScrollViewMixin:IsAtTop()
		if self.scrollable then
			return self.offset < 0.1
		else
			return true
		end
	end

	function ScrollViewMixin:IsAtBottom()
		if self.scrollable then
			return self.offset > self.range - 0.1
		else
			return true
		end
	end

	function ScrollViewMixin:ResetScrollBarPosition()
		self.ScrollBar:ClearAllPoints()
		self.ScrollBar:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -1)
		self.ScrollBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1)
	end

	function ScrollViewMixin:SetScrollBarOffsetY(top, bottom)
		top = top or -16
		bottom = bottom or 16
		self.ScrollBar:ClearAllPoints()
		self.ScrollBar:SetPoint("TOPRIGHT", self, "TOPRIGHT", -4, top)
		self.ScrollBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, bottom)
	end

	function ScrollViewMixin:UseBoundaryGradient(state)
		self.useBoundaryGradient = state

		if state and not self.BottomGradient then
			local BottomGradient = CreateFrame("Frame", nil, self:GetParent())
			self.BottomGradient = BottomGradient
			BottomGradient:SetSize(224, self.boundaryGradientSize or 40)
			BottomGradient:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 6, -1)
			BottomGradient:SetPoint("BOTTOMRIGHT", self.ScrollBar, "BOTTOMLEFT", -1, -1)
			local tex = BottomGradient:CreateTexture(nil, "OVERLAY")
			tex:SetAllPoints(true)
			local topColor = CreateColor(0.082, 0.047, 0.027, 0)
			local bottomColor = CreateColor(0.082, 0.047, 0.027, 1)
			tex:SetColorTexture(1, 1, 1)
			tex:SetGradient("VERTICAL", bottomColor, topColor)
			BottomGradient:SetFrameLevel(self:GetFrameLevel() + 2)
		end

		if self.BottomGradient then
			self.BottomGradient:SetShown(state)
		end
	end

	function ScrollViewMixin:SetBoundaryGradientSize(size)
		--size(height) is usually (buttonHeight + gap)
		self.boundaryGradientSize = size
		if self.BottomGradient then
			self.BottomGradient:SetHeight(size)
		end
	end

	function ScrollViewMixin:SetShowNoContentAlert(showNoContentAlert)
		self.showNoContentAlert = showNoContentAlert
	end

	function ScrollViewMixin:SetNoContentAlertText(text)
		self.NoContentAlert.AlertText:SetText(text)
	end

	function ScrollViewMixin:SetNoContentAlertTextAlign(align)
		local fs = self.NoContentAlert.AlertText
		local container = self.NoContentAlert
		local padding = 16
		fs:ClearAllPoints()
		if align == "TOP" then
			fs:SetPoint("TOPLEFT", container, "TOPLEFT", padding, -padding)
			fs:SetPoint("TOPRIGHT", container, "TOPRIGHT", -padding, -padding)
			fs:SetJustifyH("LEFT")
		else
			fs:SetPoint("LEFT", container, "LEFT", padding, padding)
			fs:SetPoint("RIGHT", container, "RIGHT", -padding, padding)
			fs:SetJustifyH("CENTER")
		end
	end

	function ScrollViewMixin:MinimizeScrollBar(minimized)
		if self.ScrollBar and self.ScrollBar.SetMinimized then
			self.ScrollBar:SetMinimized(minimized)
		end
	end
end

do --ScrollView Callback
	function ScrollViewMixin:OnHide()
		self:StopScrolling()

		if self.onHideCallback then
			self.onHideCallback()
		end

		if self.ScrollBar then
			self.ScrollBar:StopUpdating()
		end
	end

	function ScrollViewMixin:SetOnHideCallback(onHideCallback)
		self.onHideCallback = onHideCallback
	end

	function ScrollViewMixin:OnScrollStart()
		if self.useMouseBlocker then
			self.MouseBlocker:Show()
			self.MouseBlocker:SetFrameLevel(self:GetFrameLevel() + 4)
		end

		if self.onScrollStartCallback then
			self.onScrollStartCallback()
		end
	end

	function ScrollViewMixin:SetOnScrollStartCallback(onScrollStartCallback)
		self.onScrollStartCallback = onScrollStartCallback
	end

	function ScrollViewMixin:OnScrollStop()
		if self.useMouseBlocker then
			self.MouseBlocker:Hide()
		end

		if self.onScrollStopCallback then
			self.onScrollStopCallback()
		end
	end

	function ScrollViewMixin:SetOnScrollStopCallback(onScrollStopCallback)
		self.onScrollStopCallback = onScrollStopCallback
	end
end

do --ScrollView Content Update
	function ScrollViewMixin:CallObjectMethod(templateKey, method, ...)
		self.pools[templateKey]:CallMethod(method, ...)
	end

	function ScrollViewMixin:CallObjectMethodByPredicate(templateKey, predicate, method, ...)
		self.pools[templateKey]:CallMethodByPredicate(predicate, method, ...)
	end

	function ScrollViewMixin:ProcessActiveObjects(templateKey, processFunc)
		self.pools[templateKey]:ProcessActiveObjects(processFunc)
	end

	function ScrollViewMixin:ReRenderContent()
		self:SetContent(self.content)
	end
end
