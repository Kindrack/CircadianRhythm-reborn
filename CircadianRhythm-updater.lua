local addonName = "CircadianRhythm-reborn"

local function crstrsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

local function formatVersion(versionNum)
  local major = math.floor(versionNum / 10000)
  local minor = math.floor((versionNum % 10000) / 100)
  local fix = versionNum % 100
  return major .. "." .. minor .. "." .. fix
end

local major, minor, fix = crstrsplit(".", tostring(GetAddOnMetadata(addonName, "Version")))
fix = fix or 0
local alreadyshown = false
local localversion  = tonumber(major*10000 + minor*100 + fix)
local remoteversion = tonumber(crupdateavailable) or 0
local loginchannels = { "BATTLEGROUND", "RAID", "GUILD", "PARTY" }
local groupchannels = { "BATTLEGROUND", "RAID", "PARTY" }
local partyVersions = {}
local manualPings = {}

local function StripRealmName(fullName)
    if fullName and fullName:find("-") then
        return fullName:match("^([^-]+)")
    end
    return fullName
end

local function UpdatePartyVersionDisplay()
    if UnitName("player") ~= "Bennylava" then
        return
    end

    for i = 1, GetNumPartyMembers() do
        local memberName = UnitName("party" .. i)
        local stripMemberName = StripRealmName(memberName)
        local version = partyVersions[memberName] or partyVersions[stripMemberName]

        if memberName and version then
            local frame = _G["ElvUF_PartyGroup1UnitButton" .. i]
            if not frame then
                frame = _G["PartyMemberFrame" .. i]
            end

            if frame then
                local labelName = "CircadianRhythmVersionLabel" .. i
                local label = _G[labelName]

                local parent = frame.RaisedElementParent or frame

                if not label then
                    label = parent:CreateFontString(labelName, "OVERLAY", "GameFontNormalSmall")
                    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                    label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 15)
                end

                label:SetText("v" .. formatVersion(version))
                label:SetTextColor(1, 0.82, 0)
                label:Show()
            end
        end
    end
end

local function UpdateTargetVersionDisplay()
    if UnitName("player") ~= "Bennylava" then
        return
    end

    if not UnitExists("target") then
        local label = _G["CircadianRhythmVersionLabelTarget"]
        if label then
            label:Hide()
        end
        return
    end

    local targetName = UnitName("target")
    if not targetName then return end

    local stripTargetName = StripRealmName(targetName)
    local version = partyVersions[targetName] or partyVersions[stripTargetName]

    if version then
        local frame = _G["ElvUF_Target"]
        if not frame then
            frame = _G["TargetFrame"]
        end

        if frame then
            local labelName = "CircadianRhythmVersionLabelTarget"
            local label = _G[labelName]

            local parent = frame.RaisedElementParent or frame

            if not label then
                label = parent:CreateFontString(labelName, "OVERLAY", "GameFontNormalSmall")
                label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 15)
            end

            label:SetText("v" .. formatVersion(version))
            label:SetTextColor(1, 0.82, 0)
            label:Show()
        end
    else
        local label = _G["CircadianRhythmVersionLabelTarget"]
        if label then
            label:Hide()
        end
    end
end

local crUpdater = CreateFrame("Frame")
crUpdater:RegisterEvent("CHAT_MSG_ADDON")
crUpdater:RegisterEvent("PLAYER_ENTERING_WORLD")
crUpdater:RegisterEvent("PARTY_MEMBERS_CHANGED")
crUpdater:RegisterEvent("PLAYER_TARGET_CHANGED")
crUpdater:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local arg1, arg2, arg3, arg4 = ...
        if arg1 == "crrb" then
            local v, remoteversion = crstrsplit(":", arg2)
            remoteversion = tonumber(remoteversion)
            if v == "VERSION" and remoteversion then
                local strippedName = StripRealmName(arg4)
                partyVersions[strippedName] = remoteversion
                if remoteversion > localversion then
                    crupdateavailable = remoteversion
                    if not alreadyshown then
                        local currentVer = formatVersion(localversion)
                        local availableVer = formatVersion(remoteversion)
                        print("|cff33ffccCircadianRhythm|r New version available!")
                        print("Current: |cff66ccff" .. currentVer .. "|r -> Available: |cff66ccff" .. availableVer .. "|r")
                        print("|cff66ccffhttps://github.com/Bennylavaa/CircadianRhythm-reborn/releases|r")
                        alreadyshown = true
                    end
                end
            end
            if v == "PING?" then
                if arg3 == "WHISPER" then
                    SendAddonMessage("crrb", "PONG!:"..GetAddOnMetadata(addonName, "Version"), "WHISPER", arg4)
                else
                    for _, chan in ipairs(loginchannels) do
                        SendAddonMessage("crrb", "PONG!:"..GetAddOnMetadata(addonName, "Version"), chan)
                    end
                end
            end
            if v == "PONG!" then
                if UnitName("player") == "Bennylava" then
                    local pongCmd, pongversion = crstrsplit(":", arg2)
                    local pmajor, pminor, pfix = crstrsplit(".", tostring(pongversion))
                    pfix = pfix or 0
                    pongversion = tonumber(pmajor*10000 + pminor*100 + pfix)
                    local strippedName = StripRealmName(arg4)
                    partyVersions[strippedName] = pongversion

                    if manualPings[strippedName] then
                        print("|cffff8000"..arg4.."|r - |cff66ccffv"..formatVersion(pongversion).."|r")
                        manualPings[strippedName] = nil
                    end

                    UpdatePartyVersionDisplay()
                    UpdateTargetVersionDisplay()
                end
            end
        end
    elseif event == "PARTY_MEMBERS_CHANGED" then
        local groupsize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers() > 0 and GetNumPartyMembers() or 0
        if (self.group or 0) < groupsize then
            for _, chan in ipairs(groupchannels) do
                SendAddonMessage("crrb", "VERSION:" .. localversion, chan)
            end
        end
        self.group = groupsize
        UpdatePartyVersionDisplay()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not alreadyshown and localversion < remoteversion then
            local currentVer = formatVersion(localversion)
            local availableVer = formatVersion(remoteversion)
            print("|cff33ffccCircadianRhythm|r New version available!")
            print("Current: |cff66ccff" .. currentVer .. "|r -> Available: |cff66ccff" .. availableVer .. "|r")
            print("|cff66ccffhttps://github.com/Bennylavaa/CircadianRhythm-reborn/releases|r")
            crupdateavailable = localversion
            alreadyshown = true
        end
        for _, chan in ipairs(loginchannels) do
            SendAddonMessage("crrb", "VERSION:" .. localversion, chan)
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if UnitName("player") == "Bennylava" then
            local targetName = UnitName("target")
            if targetName and UnitIsPlayer("target") then
                SendAddonMessage("crrb", "PING?", "WHISPER", targetName)
            end
        end
        UpdateTargetVersionDisplay()
    end
end)

SLASH_CIRCADIANPING1 = "/crping"
SlashCmdList["CIRCADIANPING"] = function(msg)
    if msg == "" then
        print("Usage: /crping PLAYERNAME")
        return
    end
    local strippedName = StripRealmName(msg)
    manualPings[strippedName] = true
    SendAddonMessage("crrb", "PING?", "WHISPER", msg)
end
