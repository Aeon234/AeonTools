local _, addon = ...
local L = addon.L

-- ===============
-- === Generic ===
-- ===============
L["AeonTools_Colon"] = "Aeon Tools: "
L["Toggle_EditMode"] = "Toggle Aeon Tools Widgets"
L["Toggle_EditMode_Tooltip"] =
	"Show the following widgets in the Edit Mode:\n\n%s\n\nThis checkbox only controls their visibility in the Edit Mode. It will not enable or disable these modules."
L["Yes"] = "Yes"
L["No"] = "No"
L["Later"] = "Later"
L["Category_Appearance"] = "Appearance"
L["Reload_Warning"] =
	"To finalize changes it's recommended that you reload the UI.\n\nWould you like to reload the UI right now?"
L["FontName"] = "Font"
L["FontSize"] = "Font Size"
L["Color"] = "Color"
L["Modifier_Label"] = "Modifier Key"
L["Horizontal"] = "H"
L["Vertical"] = "V"
L["Reset_Position"] = "Reset To Default Position"
L["Generic_Combat_Error"] = "Cannot change this setting in combat!"
L["Horizontal_Reposition"] = "Move Horizontally"
L["Reposition_Tooltip"] = "Left click and drag to move the window"

-- Modifier Key Options
L["Shift"] = "Shift"
L["Ctrl"] = "Ctrl"
L["Alt"] = "Alt"
L["Shift + Ctrl"] = "Shift + Ctrl"
L["Shift + Alt"] = "Shift + Alt"
L["Ctrl + Alt"] = "Ctrl + Alt"

-- Mouse Button Options
L["Left Click"] = "Left Click"
L["Right Click"] = "Right Click"
L["Middle Click"] = "Middle Click"
L["Mouse Button 4"] = "Mouse Button 4"
L["Mouse Button 5"] = "Mouse Button 5"

-- Raid Marker Names
L["Star"] = "Star"
L["Circle"] = "Circle"
L["Diamond"] = "Diamond"
L["Triangle"] = "Triangle"
L["Moon"] = "Moon"
L["Square"] = "Square"
L["Cross"] = "Cross"
L["Skull"] = "Skull"

-- ===============
-- === Modules ===
-- ===============
-- UIScale
L["UIScale_Title"] = "UI Scale Modification"
L["UIScale_Title_Disabled"] = "|cffb0b0b0UI Scale Modification|r"
L["UIScale_Desc"] =
	"Automatically adjust the UI Scale so it's pixel perfect to your resolution.\n\nAutomatically disabled if ElvUI is enabled."
L["UIScale_Desc_Disabled"] =
	"|cffff2020Automatically disabled since ElvUI is enabled. ElvUI provides its own Scaling Features.|r\n\nAutomatically adjust the UI Scale so it's pixel perfect to your resolution. Will also refresh the layouts of Shadowed Unit Frames and Grid2 if enabled."
L["UIScale_CurrentScale"] = "Current UI Scale: "
L["UIScale_PP_Label"] = "Pixel Perfect Scaling"
L["UIScale_1080_Label"] = "1080p Scaling"
L["UIScale_1440_Label"] = "1440p Scaling"
L["UIScale_4k_Label"] = "4K Scaling"
L["UIScale_Btn_PPTooltip"] = "Sets the UI Scale to the pixel perfect value for your current resolution."
L["UIScale_Btn_Tooltip"] = "Sets the UI Scale to the pixel perfect value for "

-- Escape Menu Scale
L["EMS_Title"] = "Escape Menu Scale"
L["EMS_Desc"] = "Resizes the Escape Menu for better visual clarity."
L["EMS_Slider_Label"] = "Scale"

-- Cooldown Manager Slash Command
L["CDMS_Title"] = "Cooldown Manager Slash"
L["CDMS_Desc"] = "Allows you to open Blizzard's Cooldown Manager using the /cd slash command."

-- Instance Difficulty
L["ID_Title"] = "Instance Difficulty"
L["ID_Desc"] = "Reskin the instance difficulty indicator in text style."
L["ID_Alignment"] = "Alignment"
L["ID_OffsetX"] = "Offset X"
L["ID_OffsetY"] = "Offset Y"
L["ID_Align_Bottom"] = "Bottom"
L["ID_Align_BottomLeft"] = "Bottom Left"
L["ID_Align_BottomRight"] = "Bottom Right"
L["ID_Align_Center"] = "Center"
L["ID_Align_Left"] = "Left"
L["ID_Align_Right"] = "Right"
L["ID_Align_Top"] = "Top"
L["ID_Align_TopLeft"] = "Top Left"
L["ID_Align_TopRight"] = "Top Right"

-- Cursor Ring
L["CR_Title"] = "Cursor Ring"
L["CR_Desc"] =
	"Enables a Circle Indicator around the mouse.\n\nCan always show or only in combat.\nAdditonally, can provide a GCD radial to show the GCD."
L["CR_RingSize"] = "Ring Size"
L["CR_CombatOnly"] = "Show Ring in Combat Only"
L["CR_CenteredDot"] = "Show a dot at the center of the ring"
L["CR_GCDShow"] = "Show GCD Radial"
L["CR_RingColor"] = "Ring Color"
L["CR_RingColorTooltip"] = "Choose the color of the cursor ring."

-- Can't Release
L["CRes_Title"] = "Can't Release Button"
L["CRes_Desc"] = "Create an additonal button you must press before you can press the Release button when dead."
L["CRes_Message"] = "Can't Release"
L["CRes_Popup"] = "Do you want to release your spirit?"

-- Informational Popups
L["IPU_Title"] = "Informational Popups"
L["IPU_Desc"] = "Displays helpful popups for specific ingame events like entering and leaving combat."
L["IPU_DurationLabel"] = "Popup Duration"
L["IPU_DurationTooltip"] = "Set how long each popup should remain on screen in seconds."
L["IPU_PopupTypes"] = "Popup Types"
L["IPU_CombatLabel"] = "In/Out Combat"
L["IPU_CombatTooltip"] = "Display '+Combat' and '-Combat' upon enterering and exiting combat."
L["IPU_CombatColorIn"] = "In Color"
L["IPU_CombatColorOut"] = "Out Color"
L["IPU_MissingPetLabel"] = "Missing Pet"
L["IPU_MissingPetTooltip"] = "Shows when pet is missing while in combat."
L["IPU_PassivePetLabel"] = "Passive Pet"
L["IPU_PassivePetTooltip"] = "Shows when pet is set to passive while in combat."

-- Current Expansion Filter
L["CEF_Title"] = "Current Expansion Filter"
L["CEF_Desc"] = 'Automatically sets the "Current Expansion Only" filter for Auction House and Crafting Orders'

-- Alt Power Bar Status Text
L["AltPower_Title"] = "Alternate Power Bar Status Text"
L["AltPower_Desc"] = "Alternate Power Bar will always show the status text instead of only on hover."

-- Enlarge Objective & Error Text
L["EOT_Title"] = "Enlarge Objective & Error Text"
L["EOT_Desc"] = 'Enlarges in-game objective text and error messages (e.g. "Out of Range") for improved readability.'

-- Extra Action Button Click Through
L["EAB_Title"] = "Extra Action Button Enhanced"
L["EAB_Desc"] =
	"Allows the Extra Action Button and Zone Ability art to be clicked through, preventing them from blocking gameplay interactions.\nAlternatively, can choose to completely hide the art."
L["EAB_HideArt"] = "Remove the textures of the Extra Action Buttons"

-- Focus Shortcut
L["Focus_Title"] = "Focus Mouse Keybind"
L["Focus_Desc"] =
	"Allows you to set target focus using mouse clicks and modifiers.\n\nAdditionally allows to click an empty space to remove focus.\n\nSupported Frames:\nBlizzard\nElvUI\noUF-Based Frames (UUF,Grid2,etc.)"
L["Focus_KeybindHeader"] = "Keybind Settings"
L["Focus_ModifierTooltip"] = "Choose which modifier key to use for setting focus"
L["Focus_ButtonLabel"] = "Mouse Button"
L["Focus_ButtonTooltip"] = "Choose which mouse button to use with the modifier key"
L["Focus_FocusTargetLabel"] = "Focus Target if not Mouseover"
L["Focus_FocusTargetTooltip"] =
	"If player has a target but focus keybind is clicked on an empty space, the target will be focused instead of clearing the focus."
L["Focus_RaidMarkingHeader"] = "Raid Marking"
L["Focus_SetMarkLabel"] = "Auto-Mark Focus"
L["Focus_SetMarkTooltip"] = "Automatically place a raid marker on your focus target when you set focus"
L["Focus_MarkNumberLabel"] = "Raid Marker"
L["Focus_MarkNumberTooltip"] = "Choose which raid marker icon to use (1-8)"
L["Focus_SafeMarkLabel"] = "Safe Marking"
L["Focus_SafeMarkTooltip"] = "Only mark friendly or hostile targets. Prevents marking neutral NPCs."

-- Raid Markers Bar
L["RM_Title"] = "Raid Markers Bar"
L["RM_Desc"] =
	"Creates a modular bar for better ease of access.\nProvides all target and world markers in addition to Ready Check and Pull Timer.\n\nUse /at rm for quick settings."
L["RM_RaidMarkerTooltipLeft"] = "Left Click to mark the target with this mark."
L["RM_RaidMarkerTooltipRight"] = "Right Click to clear the mark on the target."
L["RM_WorldMarkerTooltipLeft"] = "Left Click to place this worldmarker."
L["RM_WorldMarkerTooltipRight"] = "Right Click to clear this worldmarker."
L["RM_WorldMarkerTooltipLeft_Modifier"] = "%s + Left Click to place this worldmarker."
L["RM_WorldMarkerTooltipRight_Modifier"] = "%s + Right Click to clear this worldmarker."
L["RM_RaidMarkerTooltipLeft_Modifier"] = "%s + Left Click to mark the target with this mark."
L["RM_RaidMarkerTooltipRight_Modifier"] = "%s + Right Click to clear the mark on the target."
L["RM_ClearMarks"] = "Click to clear all marks."
L["RM_ClearMarks_Modifier"] = "%s + Click to remove all worldmarkers."
L["RM_ClearWorldMarks"] = "Click to remove all worldmarkers."
L["RM_ClearWorldMarks_Modifier"] = "%s + Click to clear all marks."
L["RM_ReadyCheck"] = "Left Click to ready check."
L["RM_CombatLog"] = "Right click to toggle advanced combat logging."
L["RM_Countdown_Start"] = "Left Click to start countdown."
L["RM_Countdown_Stop"] = "Right click to stop countdown."
L["RM_RaidMarkersLabel"] = "Raid Markers"
L["RM_RaidUtilityLabel"] = "Raid Utility"
L["RM_Options_Tooltip_Label"] = "Tooltip"
L["RM_Options_Tooltip_Tooltip"] = "Show the tooltip when hovering over the buttons."
L["RM_Options_Inverse_Label"] = "Inverse"
L["RM_Options_Inverse_Tooltip"] = "Swap the functionality of normal click and click with modifier keys."
L["RM_Options_Mouseover_Label"] = "Mouseover"
L["RM_Options_Visibility"] = "Visibility"
L["RM_Options_Mouseover_Tooltip"] = "Show the bar only when hovering over it."
L["RM_Options_Orientation"] = "Bar Orientation"
L["RM_Options_BarBackdrop_Label"] = "Bar Backdrop"
L["RM_Options_BarBackdrop_Tooltip"] = "Show a backdrop for the bar"
L["RM_Options_BackdropSpacing_Label"] = "Backdrop Spacing"
L["RM_Options_BackdropSpacing_Tooltip"] = "Spacing between the backdrop and the buttons."
L["RM_Options_ButtonBackdrop_Label"] = "Button Backdrop"
L["RM_Options_ButtonBackdrop_Tooltip"] = "Show a backdrop for each individual button."
L["RM_Options_ButtonSize_Label"] = "Button Size"
L["RM_Options_ButtonSize_Tooltip"] = "Size of the buttons."
L["RM_Options_ButtonSpacing_Label"] = "Button Spacing"
L["RM_Options_ButtonSpacing_Tooltip"] = "Spacing between the buttons."
L["RM_Options_Divider_RC"] = "Ready Check / Countdown"
L["RM_Options_RC_Label"] = "Ready Check / Advance Combat Logging"
L["RM_Options_Countdown_Label"] = "Countdown"
L["RM_Options_Countdown_Tooltip"] = "Trigger a Countdown"
L["RM_Options_CDTime_Label"] = "Countdown Time"
L["RM_Options_CDTime_Tooltip"] = "Countdown time in seconds."

-- World Marker Cycler
L["WMC_Title"] = "World Marker Cycler"
L["WMC_Desc"] =
	"Assign a keybind and cycle through all available world markers wih each click. Placing each marker at your mouse location. By default all world markers are enabled, but you can configure which world markers it should cycle through.\n\nAlternatively, type '/at wm' to access the same menu."
L["WMC_Placer_Label"] = " Placer"
L["WMC_Remover_Label"] = " Remover"
L["WMC_Placer_Tooltip"] = "Keybind that triggers a world marker being placed at your cursor location."
L["WMC_Remover_Tooltip"] = "Keybind that will clear all world markers placed."

-- Flying Path Line
L["FPL_Title"] = "Flying Path Line"
L["FPL_Desc"] = ""
L["FPL_Texture_Circle"] = "Circle Texture"
L["FPL_Texture_Glow"] = "Texture Glow"
L["FPL_Texture_Star"] = "Texture Star"
L["FPL_DotTexture"] = "Dot Texture"
L["FPL_DotSize"] = "Dot Size"
L["FPL_DotSize_Tooltip"] = "Tooltip"
L["FPL_Section_Line"] = "Section Line"
L["FPL_DotAmount"] = "Dot Amount"
L["FPL_DotAmount_Tooltip"] = "Toooltip"
L["FPL_LineSize"] = "Line Size"
L["FPL_LineSize_Tooltip"] = "Tooltip"

-- Prey Bar
L["PB_Title"] = "Prey Progress Bar"
L["PB_Desc"] = "Enhances the Prey Icon with a progress bar that tracks how close you are to slaying your chosen prey."
L["PB_BarOnly"] = "Only Show the Progress Bar"

L[""] = ""
