local addonName = "CircadianRhythm-reborn"

local function DefaultSettings()
    return {
        showGameTimeOnHover = true,
        showButton = true,
        buttonLocked = false,
        buttonPosition = { point = "CENTER", x = 0, y = 0 },
        showClockText = true,
        clockTimeSource = "realm",
        clockPosition = "LEFT",
        clockShowSeconds = false,
        clockMilitaryTime = false,
        clockBackground = "BLIZZARD",
        clockFreePosition = { point = "CENTER", x = 0, y = 60 },
        hideMinimapClock = false,
        clockFont = "GameFontNormal",
        clockFontColor = { r = 1, g = 1, b = 1 },
        clockSpacing = 8,
    }
end

local function ApplyDefaults(tbl)
    for k, v in pairs(tbl) do
        if tbl[k] == nil then
            tbl[k] = v
        end
    end
    return tbl
end

local settings
if CircadianRhythmSettings then
    settings = ApplyDefaults(CircadianRhythmSettings)
else
    settings = DefaultSettings()
end

local function SaveSettings()
    CircadianRhythmSettings = settings
end

local button = CreateFrame("Button", "MyGameTimeButton", UIParent)
button:SetSize(40, 40)
button:SetPoint("CENTER", 0, 0)
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForClicks("AnyUp")

local texture = button:CreateTexture(nil, "BACKGROUND")
texture:SetAllPoints(button)

local function SavePosition()
    local point, _, _, x, y = button:GetPoint()
    if point then
        settings.buttonPosition = { point = point, x = x or 0, y = y or 0 }
        SaveSettings()
    end
end

local function RestorePosition()
    if settings.buttonPosition and settings.buttonPosition.point then
        button:ClearAllPoints()
        button:SetPoint(settings.buttonPosition.point, UIParent, settings.buttonPosition.point,
                       settings.buttonPosition.x or 0, settings.buttonPosition.y or 0)
    else
        button:ClearAllPoints()
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function UpdateLockVisual()
    button:SetMovable(not settings.buttonLocked)
    button:EnableMouse(true)
end

local function UpdateMinimapClockVisibility()
    if not TimeManagerClockButton then return end

    if settings.hideMinimapClock then
        TimeManagerClockButton:Hide()
    else
        TimeManagerClockButton:Show()
    end
end

if TimeManagerClockButton then
    TimeManagerClockButton:HookScript("OnShow", function(self)
        if settings.hideMinimapClock then
            self:Hide()
        end
    end)
end

local EPOCH_SUNRISE_HOUR = 6
local EPOCH_SUNSET_HOUR = 20
local EPOCH_CYCLE_SECONDS = 4 * 60 * 60
local EPOCH_DAY_SECONDS = 24 * 60 * 60

local function GetEpochPhaseLabel(hour)
    if hour == 0 then
        return "Midnight"
    elseif hour < EPOCH_SUNRISE_HOUR then
        return "Late Night"
    elseif hour < 12 then
        return "Morning"
    elseif hour == 12 then
        return "Noon"
    elseif hour < 17 then
        return "Afternoon"
    elseif hour < EPOCH_SUNSET_HOUR then
        return "Evening"
    else
        return "Night"
    end
end

local function GetEpochTimeOfDay()
    local _, hour, minute = GameTime_GetGameTime(true)
    if not hour then return nil end
    local isDay = hour >= EPOCH_SUNRISE_HOUR and hour < EPOCH_SUNSET_HOUR
    local phase = GetEpochPhaseLabel(hour)
    return hour, minute, isDay, phase
end

local function GetEpochCountdown(hour, minute, isDay)
    local nowSec = hour * 3600 + minute * 60
    local targetSec, untilLabel
    if isDay then
        targetSec, untilLabel = EPOCH_SUNSET_HOUR * 3600, "Nightfall in:"
    elseif hour < EPOCH_SUNRISE_HOUR then
        targetSec, untilLabel = EPOCH_SUNRISE_HOUR * 3600, "Daybreak in:"
    else
        targetSec, untilLabel = (24 + EPOCH_SUNRISE_HOUR) * 3600, "Daybreak in:"
    end

    local realRemain = (targetSec - nowSec) * EPOCH_CYCLE_SECONDS / EPOCH_DAY_SECONDS
    local rh, rm = floor(realRemain / 3600), floor(mod(realRemain, 3600) / 60)
    local remainStr
    if rh > 0 then
        remainStr = format("%dh %02dm", rh, rm)
    elseif rm > 0 then
        remainStr = format("%dm", rm)
    else
        remainStr = format("%ds", floor(mod(realRemain, 60)))
    end

    return untilLabel, remainStr
end

local function UpdateGameTimeTexture()
    local hour, _, isDay = GetEpochTimeOfDay()
    if hour then
        local texturePath
        if isDay then
            texturePath = "Interface\\AddOns\\" .. addonName .. "\\images\\day"
        else
            texturePath = "Interface\\AddOns\\" .. addonName .. "\\images\\night"
        end

        texture:SetTexture(texturePath)
    end
end

local clockFrame = CreateFrame("Button", "MyGameTimeClockFrame", UIParent)
clockFrame:SetSize(90, 20)
clockFrame:EnableMouse(true)
clockFrame:SetMovable(true)
clockFrame:RegisterForDrag("LeftButton")

local clockText = clockFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
clockText:SetPoint("CENTER", clockFrame, "CENTER", 0, 0)

local CLOCK_BACKDROP_BLIZZARD = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local CLOCK_BACKDROP_ELVUI = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function UpdateClockBackground()
    if settings.clockBackground == "BLIZZARD" then
        clockFrame:SetBackdrop(CLOCK_BACKDROP_BLIZZARD)
        clockFrame:SetBackdropColor(0, 0, 0, 0.8)
        clockFrame:SetBackdropBorderColor(1, 1, 1, 1)
    elseif settings.clockBackground == "ELVUI" then
        clockFrame:SetBackdrop(CLOCK_BACKDROP_ELVUI)
        clockFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
        clockFrame:SetBackdropBorderColor(0, 0, 0, 1)
    else
        clockFrame:SetBackdrop(nil)
    end
end

local function UpdateClockFontAppearance()
    clockText:SetFontObject(settings.clockFont or "GameFontNormal")
    local c = settings.clockFontColor or { r = 1, g = 1, b = 1 }
    clockText:SetTextColor(c.r, c.g, c.b)
end

local function UpdateClockPosition()
    clockFrame:ClearAllPoints()
    local spacing = settings.clockSpacing or 8
    if settings.clockPosition == "FREE" then
        local pos = settings.clockFreePosition or { point = "CENTER", x = 0, y = 60 }
        clockFrame:SetPoint(pos.point, UIParent, pos.point, pos.x or 0, pos.y or 0)
    elseif settings.clockPosition == "RIGHT" then
        clockFrame:SetPoint("LEFT", button, "RIGHT", spacing, 0)
    elseif settings.clockPosition == "TOP" then
        clockFrame:SetPoint("BOTTOM", button, "TOP", 0, spacing)
    elseif settings.clockPosition == "BOTTOM" then
        clockFrame:SetPoint("TOP", button, "BOTTOM", 0, -spacing)
    else
        clockFrame:SetPoint("RIGHT", button, "LEFT", -spacing, 0)
    end
end

clockFrame:RegisterForClicks("AnyUp")

local clockIsDragging = false

clockFrame:SetScript("OnDragStart", function(self)
    if settings.clockPosition == "FREE" and not settings.buttonLocked then
        clockIsDragging = true
        self:StartMoving()
    end
end)

clockFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if settings.clockPosition == "FREE" then
        local point, _, _, x, y = self:GetPoint()
        settings.clockFreePosition = { point = point, x = x or 0, y = y or 0 }
        SaveSettings()
    end
end)

clockFrame:SetScript("OnClick", function(self, clickButton)
    if clockIsDragging then
        clockIsDragging = false
        return
    end

    if clickButton == "LeftButton" then
        if not TimeManagerFrame then
            LoadAddOn("Blizzard_TimeManager")
        end

        if TimeManagerFrame then
            if TimeManagerFrame:IsShown() then
                TimeManagerFrame:Hide()
            else
                TimeManagerFrame:Show()
            end
        end
    end
end)

local lastRealmMinute, realmMinuteChangedAt = nil, 0

local function GetInterpolatedRealmSeconds(minute)
    if minute ~= lastRealmMinute then
        lastRealmMinute = minute
        realmMinuteChangedAt = GetTime()
    end
    local sec = floor(GetTime() - realmMinuteChangedAt)
    if sec > 59 then sec = 59 end
    if sec < 0 then sec = 0 end
    return sec
end

local function FormatClockTime(hour, minute, second)
    if settings.clockMilitaryTime then
        if settings.clockShowSeconds then
            return format("%02d:%02d:%02d", hour, minute, second)
        else
            return format("%02d:%02d", hour, minute)
        end
    else
        local displayHour = hour % 12
        if displayHour == 0 then displayHour = 12 end
        local ampm = (hour >= 12) and "PM" or "AM"
        if settings.clockShowSeconds then
            return format("%d:%02d:%02d %s", displayHour, minute, second, ampm)
        else
            return format("%d:%02d %s", displayHour, minute, ampm)
        end
    end
end

local function UpdateClockText()
    if not settings.showClockText then
        clockFrame:Hide()
        return
    end

    local hour, minute, second
    if settings.clockTimeSource == "local" then
        local d = date("*t")
        hour, minute, second = d.hour, d.min, d.sec
    else
        hour, minute = GetEpochTimeOfDay()
        if not hour then return end
        second = GetInterpolatedRealmSeconds(minute)
    end

    clockFrame:Show()
    clockText:SetText(FormatClockTime(hour, minute, second))
    clockFrame:SetSize(clockText:GetStringWidth() + 16, clockText:GetStringHeight() + 8)
end

local function OnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 1 then
        UpdateGameTimeTexture()
        UpdateClockText()
        self.elapsed = 0
    end
end

local tickerFrame = CreateFrame("Frame")
tickerFrame:SetScript("OnUpdate", OnUpdate)

local function OnEnter(self)
    if not settings.showGameTimeOnHover then return end

    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTime_UpdateTooltip()
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

local isDragging = false
local mouseDownTime = 0

local function OnMouseDown(self, buttonClick)
    if buttonClick == "LeftButton" and not settings.buttonLocked then
        isDragging = false
        mouseDownTime = GetTime()
        self:StartMoving()
    end
end

local function OnMouseUp(self, buttonClick)
    if buttonClick == "LeftButton" and not settings.buttonLocked then
        self:StopMovingOrSizing()

        local holdTime = GetTime() - mouseDownTime
        if holdTime > 0.15 then
            isDragging = true
        else
            isDragging = false
        end

        SavePosition()
    end
end

local function OnClick(self, clickButton)
    if clickButton == "LeftButton" and isDragging then
        isDragging = false
        return
    end

    if clickButton == "LeftButton" then
        ToggleCalendar()
    elseif clickButton == "RightButton" then
        SavePosition()
        settings.buttonLocked = not settings.buttonLocked
        SaveSettings()
        UpdateLockVisual()
    end
end

function GameTime_UpdateTooltip()
    GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)

    local hour, minute, isDay, phase = GetEpochTimeOfDay()

    if hour then
        local pr, pg, pb
        if isDay then
            pr, pg, pb = 1.0, 0.82, 0.0
        else
            pr, pg, pb = 0.4, 0.55, 1.0
        end

        GameTooltip:AddDoubleLine(
            "Time of day:",
            phase,
            NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
            pr, pg, pb
        )

        local untilLabel, remainStr = GetEpochCountdown(hour, minute, isDay)
        GameTooltip:AddDoubleLine(
            untilLabel,
            remainStr,
            NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
            HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b
        )
    end

    GameTooltip:AddDoubleLine(
        TIMEMANAGER_TOOLTIP_REALMTIME,
        GameTime_GetGameTime(true),
        NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
        HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b
    )

    GameTooltip:AddDoubleLine(
        TIMEMANAGER_TOOLTIP_LOCALTIME,
        GameTime_GetLocalTime(true),
        NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b,
        HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b
    )
end

local function SetDropDownValue(dropDown, options, value)
    UIDropDownMenu_SetSelectedValue(dropDown, value)
    for _, opt in ipairs(options) do
        if opt.value == value then
            UIDropDownMenu_SetText(dropDown, opt.text)
            break
        end
    end
end

local optionsPanel = CreateFrame("Frame", addonName .. "OptionsPanel", UIParent)
optionsPanel.name = addonName
InterfaceOptions_AddCategory(optionsPanel)

local titleText = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 16, -16)
titleText:SetText("CircadianRhythm")

local subtitleText = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitleText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -6)
subtitleText:SetText("Shows Epoch day/night time, with an optional clock display.")

local headerDivider = optionsPanel:CreateTexture(nil, "ARTWORK")
headerDivider:SetHeight(1)
headerDivider:SetPoint("TOPLEFT", subtitleText, "BOTTOMLEFT", 0, -12)
headerDivider:SetPoint("RIGHT", optionsPanel, "RIGHT", -16, 0)
headerDivider:SetTexture(1, 1, 1, 0.15)

local generalHeader = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
generalHeader:SetPoint("TOPLEFT", headerDivider, "BOTTOMLEFT", 0, -14)
generalHeader:SetText("General")
generalHeader:SetTextColor(1, 0.82, 0)

local hoverCheckbox = CreateFrame("CheckButton", addonName .. "ShowHoverCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
hoverCheckbox:SetPoint("TOPLEFT", generalHeader, "BOTTOMLEFT", 0, -6)

local hoverLabel = hoverCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hoverLabel:SetPoint("LEFT", hoverCheckbox, "RIGHT", 4, 0)
hoverLabel:SetText("Show Game Time on Hover")

hoverCheckbox:SetChecked(settings.showGameTimeOnHover)
hoverCheckbox:SetScript("OnClick", function(self)
    settings.showGameTimeOnHover = self:GetChecked()
    SaveSettings()
end)

local buttonCheckbox = CreateFrame("CheckButton", addonName .. "ShowButtonCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
buttonCheckbox:SetPoint("TOPLEFT", hoverCheckbox, "BOTTOMLEFT", 0, -8)

local buttonLabel = buttonCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
buttonLabel:SetPoint("LEFT", buttonCheckbox, "RIGHT", 4, 0)
buttonLabel:SetText("Show Game Time Graphic")

buttonCheckbox:SetChecked(settings.showButton)
buttonCheckbox:SetScript("OnClick", function(self)
    settings.showButton = self:GetChecked()
    SaveSettings()
    if settings.showButton then
        button:Show()
    else
        button:Hide()
    end
end)

local lockCheckbox = CreateFrame("CheckButton", addonName .. "ButtonLockedCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
lockCheckbox:SetPoint("TOPLEFT", buttonCheckbox, "BOTTOMLEFT", 0, -8)

local lockLabel = lockCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lockLabel:SetPoint("LEFT", lockCheckbox, "RIGHT", 4, 0)
lockLabel:SetText("Lock Button Position")

lockCheckbox:SetChecked(settings.buttonLocked)
lockCheckbox:SetScript("OnClick", function(self)
    settings.buttonLocked = self:GetChecked()
    SaveSettings()
    UpdateLockVisual()
end)

local minimapClockCheckbox = CreateFrame("CheckButton", addonName .. "HideMinimapClockCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
minimapClockCheckbox:SetPoint("TOPLEFT", lockCheckbox, "BOTTOMLEFT", 0, -8)

local minimapClockLabel = minimapClockCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
minimapClockLabel:SetPoint("LEFT", minimapClockCheckbox, "RIGHT", 4, 0)
minimapClockLabel:SetText("Hide Default Minimap Clock")

minimapClockCheckbox:SetChecked(settings.hideMinimapClock)
minimapClockCheckbox:SetScript("OnClick", function(self)
    settings.hideMinimapClock = self:GetChecked()
    SaveSettings()
    UpdateMinimapClockVisibility()
end)

local clockHeader = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
clockHeader:SetPoint("TOPLEFT", minimapClockCheckbox, "BOTTOMLEFT", 0, -14)
clockHeader:SetText("Clock")
clockHeader:SetTextColor(1, 0.82, 0)

local clockTextCheckbox = CreateFrame("CheckButton", addonName .. "ShowClockTextCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
clockTextCheckbox:SetPoint("TOPLEFT", clockHeader, "BOTTOMLEFT", 0, -6)

local clockTextLabel = clockTextCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
clockTextLabel:SetPoint("LEFT", clockTextCheckbox, "RIGHT", 4, 0)
clockTextLabel:SetText("Show Clock Text")

clockTextCheckbox:SetChecked(settings.showClockText)
clockTextCheckbox:SetScript("OnClick", function(self)
    settings.showClockText = self:GetChecked()
    SaveSettings()
    UpdateClockText()
end)

local secondsCheckbox = CreateFrame("CheckButton", addonName .. "ShowSecondsCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
secondsCheckbox:SetPoint("TOPLEFT", clockTextCheckbox, "BOTTOMLEFT", 0, -4)

local secondsLabel = secondsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
secondsLabel:SetPoint("LEFT", secondsCheckbox, "RIGHT", 4, 0)
secondsLabel:SetText("Show Seconds")

secondsCheckbox:SetChecked(settings.clockShowSeconds)
secondsCheckbox:SetScript("OnClick", function(self)
    settings.clockShowSeconds = self:GetChecked()
    SaveSettings()
    UpdateClockText()
end)

local militaryCheckbox = CreateFrame("CheckButton", addonName .. "MilitaryTimeCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
militaryCheckbox:SetPoint("TOPLEFT", secondsCheckbox, "BOTTOMLEFT", 0, -4)

local militaryLabel = militaryCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
militaryLabel:SetPoint("LEFT", militaryCheckbox, "RIGHT", 4, 0)
militaryLabel:SetText("Use Military Time")

militaryCheckbox:SetChecked(settings.clockMilitaryTime)
militaryCheckbox:SetScript("OnClick", function(self)
    settings.clockMilitaryTime = self:GetChecked()
    SaveSettings()
    UpdateClockText()
end)

local appearanceHeader = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
appearanceHeader:SetPoint("TOPLEFT", headerDivider, "BOTTOMLEFT", 240, -14)
appearanceHeader:SetText("Appearance")
appearanceHeader:SetTextColor(1, 0.82, 0)

local timeSourceLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timeSourceLabel:SetPoint("TOPLEFT", appearanceHeader, "BOTTOMLEFT", 0, -10)
timeSourceLabel:SetText("Time Source")

local timeSourceDropDown = CreateFrame("Frame", addonName .. "TimeSourceDropDown", optionsPanel, "UIDropDownMenuTemplate")
timeSourceDropDown:SetPoint("TOPLEFT", timeSourceLabel, "BOTTOMLEFT", -16, -2)
UIDropDownMenu_SetWidth(timeSourceDropDown, 100)

local TIME_SOURCE_OPTIONS = { { text = "Realm Time", value = "realm" }, { text = "Local Time", value = "local" } }

local function TimeSourceDropDown_OnClick(self)
    settings.clockTimeSource = self.value
    SetDropDownValue(timeSourceDropDown, TIME_SOURCE_OPTIONS, self.value)
    SaveSettings()
    UpdateClockText()
end

local function TimeSourceDropDown_Initialize()
    local info = UIDropDownMenu_CreateInfo()
    for _, opt in ipairs(TIME_SOURCE_OPTIONS) do
        info.text = opt.text
        info.value = opt.value
        info.func = TimeSourceDropDown_OnClick
        info.checked = (settings.clockTimeSource == opt.value)
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(timeSourceDropDown, TimeSourceDropDown_Initialize)
SetDropDownValue(timeSourceDropDown, TIME_SOURCE_OPTIONS, settings.clockTimeSource)

local positionLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
positionLabel:SetPoint("TOPLEFT", timeSourceDropDown, "BOTTOMLEFT", 16, -6)
positionLabel:SetText("Position")

local positionDropDown = CreateFrame("Frame", addonName .. "PositionDropDown", optionsPanel, "UIDropDownMenuTemplate")
positionDropDown:SetPoint("TOPLEFT", positionLabel, "BOTTOMLEFT", -16, -2)
UIDropDownMenu_SetWidth(positionDropDown, 100)

local POSITION_OPTIONS = {
    { text = "Left", value = "LEFT" },
    { text = "Right", value = "RIGHT" },
    { text = "Above", value = "TOP" },
    { text = "Below", value = "BOTTOM" },
    { text = "Free (Drag to Position)", value = "FREE" },
}

local function PositionDropDown_OnClick(self)
    settings.clockPosition = self.value
    SetDropDownValue(positionDropDown, POSITION_OPTIONS, self.value)
    SaveSettings()
    UpdateClockPosition()
end

local function PositionDropDown_Initialize()
    local info = UIDropDownMenu_CreateInfo()
    for _, opt in ipairs(POSITION_OPTIONS) do
        info.text = opt.text
        info.value = opt.value
        info.func = PositionDropDown_OnClick
        info.checked = (settings.clockPosition == opt.value)
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(positionDropDown, PositionDropDown_Initialize)
SetDropDownValue(positionDropDown, POSITION_OPTIONS, settings.clockPosition)

local spacingSlider = CreateFrame("Slider", addonName .. "SpacingSlider", optionsPanel, "OptionsSliderTemplate")
spacingSlider:SetPoint("TOPLEFT", positionDropDown, "BOTTOMLEFT", 20, -18)
spacingSlider:SetWidth(100)
spacingSlider:SetMinMaxValues(0, 40)
spacingSlider:SetValueStep(1)
_G[spacingSlider:GetName() .. "Low"]:SetText("0")
_G[spacingSlider:GetName() .. "High"]:SetText("40")
_G[spacingSlider:GetName() .. "Text"]:SetText("Spacing: " .. (settings.clockSpacing or 8))
spacingSlider:SetValue(settings.clockSpacing or 8)
spacingSlider:SetScript("OnValueChanged", function(self, value)
    value = floor(value + 0.5)
    settings.clockSpacing = value
    SaveSettings()
    _G[self:GetName() .. "Text"]:SetText("Spacing: " .. value)
    UpdateClockPosition()
end)

local backgroundLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
backgroundLabel:SetPoint("TOPLEFT", spacingSlider, "BOTTOMLEFT", -4, -12)
backgroundLabel:SetText("Background")

local backgroundDropDown = CreateFrame("Frame", addonName .. "BackgroundDropDown", optionsPanel, "UIDropDownMenuTemplate")
backgroundDropDown:SetPoint("TOPLEFT", backgroundLabel, "BOTTOMLEFT", -16, -2)
UIDropDownMenu_SetWidth(backgroundDropDown, 100)

local BACKGROUND_OPTIONS = {
    { text = "None", value = "NONE" },
    { text = "Blizzard", value = "BLIZZARD" },
    { text = "ElvUI", value = "ELVUI" },
}

local function BackgroundDropDown_OnClick(self)
    settings.clockBackground = self.value
    SetDropDownValue(backgroundDropDown, BACKGROUND_OPTIONS, self.value)
    SaveSettings()
    UpdateClockBackground()
end

local function BackgroundDropDown_Initialize()
    local info = UIDropDownMenu_CreateInfo()
    for _, opt in ipairs(BACKGROUND_OPTIONS) do
        info.text = opt.text
        info.value = opt.value
        info.func = BackgroundDropDown_OnClick
        info.checked = (settings.clockBackground == opt.value)
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(backgroundDropDown, BackgroundDropDown_Initialize)
SetDropDownValue(backgroundDropDown, BACKGROUND_OPTIONS, settings.clockBackground)

local fontLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fontLabel:SetPoint("TOPLEFT", backgroundDropDown, "BOTTOMLEFT", 16, -6)
fontLabel:SetText("Font Style")

local fontDropDown = CreateFrame("Frame", addonName .. "FontDropDown", optionsPanel, "UIDropDownMenuTemplate")
fontDropDown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -16, -2)
UIDropDownMenu_SetWidth(fontDropDown, 100)

local FONT_OPTIONS = {
    { text = "Normal", value = "GameFontNormal" },
    { text = "Normal Large", value = "GameFontNormalLarge" },
    { text = "Highlight", value = "GameFontHighlight" },
    { text = "Highlight Large", value = "GameFontHighlightLarge" },
    { text = "Huge", value = "GameFontNormalHuge" },
    { text = "Number Font", value = "NumberFontNormal" },
}

local function FontDropDown_OnClick(self)
    settings.clockFont = self.value
    SetDropDownValue(fontDropDown, FONT_OPTIONS, self.value)
    SaveSettings()
    UpdateClockFontAppearance()
end

local function FontDropDown_Initialize()
    local info = UIDropDownMenu_CreateInfo()
    for _, opt in ipairs(FONT_OPTIONS) do
        info.text = opt.text
        info.value = opt.value
        info.func = FontDropDown_OnClick
        info.checked = (settings.clockFont == opt.value)
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(fontDropDown, FontDropDown_Initialize)
SetDropDownValue(fontDropDown, FONT_OPTIONS, settings.clockFont)

local colorLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colorLabel:SetPoint("TOPLEFT", fontDropDown, "BOTTOMLEFT", 16, -8)
colorLabel:SetText("Font Color")

local colorSwatch = CreateFrame("Button", addonName .. "ColorSwatch", optionsPanel)
colorSwatch:SetSize(18, 18)
colorSwatch:SetPoint("LEFT", colorLabel, "RIGHT", 8, 0)

local colorSwatchBorder = colorSwatch:CreateTexture(nil, "BACKGROUND")
colorSwatchBorder:SetAllPoints(colorSwatch)
colorSwatchBorder:SetTexture(0, 0, 0, 1)

local colorSwatchTexture = colorSwatch:CreateTexture(nil, "ARTWORK")
colorSwatchTexture:SetPoint("TOPLEFT", colorSwatch, "TOPLEFT", 1, -1)
colorSwatchTexture:SetPoint("BOTTOMRIGHT", colorSwatch, "BOTTOMRIGHT", -1, 1)
colorSwatchTexture:SetTexture("Interface\\Buttons\\WHITE8x8")

local function RefreshColorSwatchPreview()
    local c = settings.clockFontColor or { r = 1, g = 1, b = 1 }
    colorSwatchTexture:SetVertexColor(c.r, c.g, c.b)
end

RefreshColorSwatchPreview()

local function OnClockColorChanged()
    local r, g, b = ColorPickerFrame:GetColorRGB()
    settings.clockFontColor = { r = r, g = g, b = b }
    SaveSettings()
    UpdateClockFontAppearance()
    RefreshColorSwatchPreview()
end

colorSwatch:SetScript("OnClick", function()
    local previousColor = settings.clockFontColor or { r = 1, g = 1, b = 1 }
    ColorPickerFrame.func = OnClockColorChanged
    ColorPickerFrame.opacityFunc = nil
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.cancelFunc = function()
        settings.clockFontColor = previousColor
        SaveSettings()
        UpdateClockFontAppearance()
        RefreshColorSwatchPreview()
    end
    ColorPickerFrame:SetColorRGB(previousColor.r, previousColor.g, previousColor.b)
    ColorPickerFrame:Show()
end)

local helpIcon = CreateFrame("Button", addonName .. "HelpIcon", optionsPanel)
helpIcon:SetSize(20, 20)
helpIcon:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -16, -16)

local helpIconTexture = helpIcon:CreateTexture(nil, "ARTWORK")
helpIconTexture:SetAllPoints(helpIcon)
helpIconTexture:SetTexture("Interface\\FriendsFrame\\InformationIcon")

helpIcon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Instructions", 1, 0.82, 0, 1, true)
    GameTooltip:AddLine("Left-click the button to open Calendar", 1, 1, 1, true)
    GameTooltip:AddLine("Right-click the button to toggle lock/unlock", 1, 1, 1, true)
    GameTooltip:AddLine("Drag the button to move it (when unlocked)", 1, 1, 1, true)
    GameTooltip:AddLine("Left-click the clock text to open/close the Time Manager panel", 1, 1, 1, true)
    GameTooltip:AddLine("When Clock Position is set to Free, drag the clock text to move it", 1, 1, 1, true)
    GameTooltip:Show()
end)

helpIcon:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

button:RegisterEvent("ADDON_LOADED")

button:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == addonName then
        if CircadianRhythmSettings then
            settings = ApplyDefaults(CircadianRhythmSettings)
        else
            settings = DefaultSettings()
        end

        SaveSettings()

        hoverCheckbox:SetChecked(settings.showGameTimeOnHover)
        buttonCheckbox:SetChecked(settings.showButton)
        lockCheckbox:SetChecked(settings.buttonLocked)
        clockTextCheckbox:SetChecked(settings.showClockText)
        secondsCheckbox:SetChecked(settings.clockShowSeconds)
        militaryCheckbox:SetChecked(settings.clockMilitaryTime)
        minimapClockCheckbox:SetChecked(settings.hideMinimapClock)
        SetDropDownValue(timeSourceDropDown, TIME_SOURCE_OPTIONS, settings.clockTimeSource)
        SetDropDownValue(positionDropDown, POSITION_OPTIONS, settings.clockPosition)
        SetDropDownValue(backgroundDropDown, BACKGROUND_OPTIONS, settings.clockBackground)
        SetDropDownValue(fontDropDown, FONT_OPTIONS, settings.clockFont)
        RefreshColorSwatchPreview()
        spacingSlider:SetValue(settings.clockSpacing)
        _G[spacingSlider:GetName() .. "Text"]:SetText("Spacing: " .. settings.clockSpacing)

        self:SetScript("OnEnter", OnEnter)
        self:SetScript("OnLeave", OnLeave)
        self:SetScript("OnMouseDown", OnMouseDown)
        self:SetScript("OnMouseUp", OnMouseUp)
        self:SetScript("OnClick", OnClick)

        clockFrame:SetScript("OnEnter", OnEnter)
        clockFrame:SetScript("OnLeave", OnLeave)

        if settings.showButton then
            button:Show()
            RestorePosition()
        else
            button:Hide()
        end

        UpdateLockVisual()

        UpdateGameTimeTexture()
        UpdateClockBackground()
        UpdateClockFontAppearance()
        UpdateClockPosition()
        UpdateClockText()
        UpdateMinimapClockVisibility()
    end
end)

