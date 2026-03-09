local _, addon = ...
local L = addon.L
local API = addon.API

local GK = CreateFrame("Frame")

local function CreateDragonflightNineSlice(parent, size)
	local pieces = {}

	local CORNER_SIZE = size * 0.385 --100
	local EDGE_THICKNESS = CORNER_SIZE * 0.18 --18

	-- Corners
	pieces.TopLeft = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.TopLeft:SetAtlas("Dragonflight-NineSlice-CornerTopLeft")
	pieces.TopLeft:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.TopLeft:SetPoint("TOPLEFT")

	pieces.TopRight = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.TopRight:SetAtlas("Dragonflight-NineSlice-CornerTopRight")
	pieces.TopRight:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.TopRight:SetPoint("TOPRIGHT")

	pieces.BottomLeft = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.BottomLeft:SetAtlas("Dragonflight-NineSlice-CornerBottomLeft")
	pieces.BottomLeft:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.BottomLeft:SetPoint("BOTTOMLEFT")

	pieces.BottomRight = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.BottomRight:SetAtlas("Dragonflight-NineSlice-CornerBottomRight")
	pieces.BottomRight:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.BottomRight:SetPoint("BOTTOMRIGHT")

	-- Top edge
	pieces.Top = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Top:SetAtlas("_Dragonflight-Nineslice-EdgeTop")
	pieces.Top:SetHeight(EDGE_THICKNESS)
	pieces.Top:SetPoint("TOPLEFT", pieces.TopLeft, "TOPRIGHT", 0, 0)
	pieces.Top:SetPoint("TOPRIGHT", pieces.TopRight, "TOPLEFT", 0, 0)

	-- Bottom edge
	pieces.Bottom = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Bottom:SetAtlas("_Dragonflight-Nineslice-EdgeBottom")
	pieces.Bottom:SetHeight(EDGE_THICKNESS)
	pieces.Bottom:SetPoint("BOTTOMLEFT", pieces.BottomLeft, "BOTTOMRIGHT", 0, 0)
	pieces.Bottom:SetPoint("BOTTOMRIGHT", pieces.BottomRight, "BOTTOMLEFT", 0, 0)

	-- Left edge (rotate top edge)
	pieces.Left = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Left:SetAtlas("!Dragonflight-NineSlice-EdgeLeft")
	pieces.Left:SetWidth(EDGE_THICKNESS)
	pieces.Left:SetPoint("TOPLEFT", pieces.TopLeft, "BOTTOMLEFT", 0, 0)
	pieces.Left:SetPoint("BOTTOMLEFT", pieces.BottomLeft, "TOPLEFT", 0, 0)

	-- Right edge
	pieces.Right = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Right:SetAtlas("!Dragonflight-NineSlice-EdgeRight")
	pieces.Right:SetWidth(EDGE_THICKNESS)
	pieces.Right:SetPoint("TOPRIGHT", pieces.TopRight, "BOTTOMRIGHT", 0, 0)
	pieces.Right:SetPoint("BOTTOMRIGHT", pieces.BottomRight, "TOPRIGHT", 0, 0)

	return pieces
end

local function CreateGenericMetal2NineSlice(parent, size)
	local pieces = {}

	local CORNER_SIZE = size * (0.2285714286 * 1.5)
	local EDGE_THICKNESS = CORNER_SIZE

	-- Corners
	pieces.TopLeft = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.TopLeft:SetAtlas("GenericMetal2-NineSlice-CornerTopLeft")
	pieces.TopLeft:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.TopLeft:SetPoint("TOPLEFT")

	pieces.TopRight = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.TopRight:SetAtlas("GenericMetal2-NineSlice-CornerTopRight")
	pieces.TopRight:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.TopRight:SetPoint("TOPRIGHT")

	pieces.BottomLeft = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.BottomLeft:SetAtlas("GenericMetal2-NineSlice-CornerBottomLeft")
	pieces.BottomLeft:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.BottomLeft:SetPoint("BOTTOMLEFT")

	pieces.BottomRight = parent:CreateTexture(nil, "ARTWORK", nil, 7)
	pieces.BottomRight:SetAtlas("GenericMetal2-NineSlice-CornerBottomRight")
	pieces.BottomRight:SetSize(CORNER_SIZE, CORNER_SIZE)
	pieces.BottomRight:SetPoint("BOTTOMRIGHT")

	-- Top edge
	pieces.Top = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Top:SetAtlas("_GenericMetal2-NineSlice-EdgeTop")
	pieces.Top:SetHeight(EDGE_THICKNESS)
	pieces.Top:SetPoint("TOPLEFT", pieces.TopLeft, "TOPRIGHT", 0, 0)
	pieces.Top:SetPoint("TOPRIGHT", pieces.TopRight, "TOPLEFT", 0, 0)

	-- Bottom edge
	pieces.Bottom = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Bottom:SetAtlas("_GenericMetal2-NineSlice-EdgeBottom")
	pieces.Bottom:SetHeight(EDGE_THICKNESS)
	pieces.Bottom:SetPoint("BOTTOMLEFT", pieces.BottomLeft, "BOTTOMRIGHT", 0, 0)
	pieces.Bottom:SetPoint("BOTTOMRIGHT", pieces.BottomRight, "BOTTOMLEFT", 0, 0)

	-- Left edge (rotate top edge)
	pieces.Left = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Left:SetAtlas("!GenericMetal2-NineSlice-EdgeLeft")
	pieces.Left:SetWidth(EDGE_THICKNESS)
	pieces.Left:SetPoint("TOPLEFT", pieces.TopLeft, "BOTTOMLEFT", 0, 0)
	pieces.Left:SetPoint("BOTTOMLEFT", pieces.BottomLeft, "TOPLEFT", 0, 0)

	-- Right edge
	pieces.Right = parent:CreateTexture(nil, "ARTWORK", nil, 6)
	pieces.Right:SetAtlas("!GenericMetal2-NineSlice-EdgeRight")
	pieces.Right:SetWidth(EDGE_THICKNESS)
	pieces.Right:SetPoint("TOPRIGHT", pieces.TopRight, "BOTTOMRIGHT", 0, 0)
	pieces.Right:SetPoint("BOTTOMRIGHT", pieces.BottomRight, "TOPRIGHT", 0, 0)

	return pieces
end

-- "GenericMetal2-NineSlice-CornerBottomLeft"
-- "GenericMetal2-NineSlice-CornerBottomRight"
-- "GenericMetal2-NineSlice-CornerTopLeft"
-- "GenericMetal2-NineSlice-CornerTopRight"
-- "_GenericMetal2-NineSlice-EdgeBottom"
-- "_GenericMetal2-NineSlice-EdgeTop"

local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local entries = {
	{ texture = 5899326, player = "Thalorin", class = "PALADIN", dungeon = "Halls of Atonement", level = 12 },
	{ texture = 5899327, player = "Mirellia", class = "MAGE", dungeon = "Mists of Tirna Scithe", level = 18 },
	{ texture = 5899328, player = "Korvax", class = "DEMONHUNTER", dungeon = "The Necrotic Wake", level = 7 },
	{ texture = 5899329, player = "Seraphyne", class = "PRIEST", dungeon = "Plaguefall", level = 15 },
	{ texture = 5899330, player = "Draxen", class = "WARRIOR", dungeon = "Spires of Ascension", level = 20 },
}

local parent = CreateFrame("Frame", nil, UIParent)
parent:SetPoint("CENTER", -100, 100)
parent:SetSize(400, 400)
-- parent:SetSize(1200, 1400)
parent.bg = parent:CreateTexture(nil, "BACKGROUND")
parent.bg:SetColorTexture(1, 1, 1, 0)
parent.bg:SetAllPoints(parent)

local ICON_SIZE = 80
local GAP = 10

for i, data in ipairs(entries) do
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(ICON_SIZE, ICON_SIZE)
	f:SetPoint("TOP", parent, "TOP", 0, -((i - 1) * (ICON_SIZE + GAP)))

	-- f.border = CreateGenericMetal2NineSlice(f, ICON_SIZE)

	local iconSize = ICON_SIZE * 0.86

	f.tex = f:CreateTexture(nil, "ARTWORK", nil, 1)
	f.tex:SetSize(iconSize, iconSize)
	f.tex:SetPoint("CENTER")
	f.tex:SetTexture(data.texture)

	-- f.mask = f:CreateMaskTexture()
	-- f.mask:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/Octagonal_Button",
	--     "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	-- f.mask:SetAllPoints(f.tex)
	-- f.tex:AddMaskTexture(f.mask)

	f.levelText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.levelText:SetPoint("CENTER")
	f.levelText:SetFont(addon.Expressway, 30, "OUTLINE")
	f.levelText:SetTextColor(1, 1, 1)
	f.levelText:SetText("+" .. data.level)

	f.playerText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.playerText:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, -10)
	f.playerText:SetFont(addon.Expressway, 24, "OUTLINE")

	local classColor = RAID_CLASS_COLORS[data.class] or { r = 1, g = 1, b = 1 }
	f.playerText:SetTextColor(classColor.r, classColor.g, classColor.b)
	f.playerText:SetText(data.player)

	f.dungeonText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.dungeonText:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 4, 0)
	f.dungeonText:SetFont(addon.Expressway, 20, "OUTLINE")
	f.dungeonText:SetTextColor(1, 1, 1)
	f.dungeonText:SetText(data.dungeon)
end
