--// Variables
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local cooldownTime    = 0.1
local lastDetected    = 0
local triggerConnection
local triggerPart     = "Head"
local aimPart         = "Head"
local aimlockEnabled  = false
local lockedPlayer    = nil
local triggerbotActive= false
local aimSmoothness   = 0.2

-- ESP variables
local espEnabled      = false
local espColor        = Color3.fromRGB(255, 0, 0)  -- Default ESP color: Red
local espHighlights   = {}

local partMap = {
    ["Head"] = {"Head"},
    ["Torso"] = {"Torso","UpperTorso","LowerTorso"},
    ["Root"] = {"HumanoidRootPart"}
}

--// Aimlock Loop
RunService.RenderStepped:Connect(function()
    if aimlockEnabled and lockedPlayer and lockedPlayer.Character and lockedPlayer.Character:FindFirstChild(aimPart) then
        local part       = lockedPlayer.Character[aimPart]
        local targetPos  = part.Position
        local currentPos = Camera.CFrame.Position
        local newLook    = (targetPos - currentPos).Unit
        local currentLook= Camera.CFrame.LookVector
        local lerpedLook = currentLook:Lerp(newLook, aimSmoothness)
        Camera.CFrame     = CFrame.new(currentPos, currentPos + lerpedLook)
    end
end)

--// UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window  = Library.CreateLib("DN HUB: " .. gameName, "BloodTheme")

-- Tabs & Sections
local Tab      = Window:NewTab("Combat")
local Section  = Tab:NewSection("Triggerbot")
local Section2 = Tab:NewSection("Aimlock")
local Tab3     = Window:NewTab("Visuals")
local Section3 = Tab3:NewSection("ESP")

--// Triggerbot Dropdown
Section:NewDropdown("Trigger Area", "Select body area to trigger on", {"Head","Torso","Root"}, function(opt)
    triggerPart = opt
    print("Trigger area set to: " .. triggerPart)
end)

--// Triggerbot Toggle
Section:NewToggle("Triggerbot", "Auto-shoot when aiming at selected part", function(state)
    if state then
        triggerConnection = Mouse.Move:Connect(function()
            local now = tick()
            if now - lastDetected < cooldownTime then return end
            local t = Mouse.Target
            if t and table.find(partMap[triggerPart], t.Name) then
                local mdl = t:FindFirstAncestorOfClass("Model")
                if mdl then
                    local pl = Players:GetPlayerFromCharacter(mdl)
                    if pl and pl ~= LocalPlayer then
                        lastDetected = now
                        mouse1press(); wait(0.05); mouse1release()
                    end
                end
            end
        end)
    else
        if triggerConnection then
            triggerConnection:Disconnect()
            triggerConnection = nil
        end
    end
    print("Triggerbot " .. (state and "enabled" or "disabled"))
end)

--// Triggerbot Keybind
Section:NewKeybind("Triggerbot Key", "Toggle triggerbot with T", Enum.KeyCode.T, function()
    triggerbotActive = not triggerbotActive
    if triggerbotActive then
        if not triggerConnection then
            triggerConnection = Mouse.Move:Connect(function()
                local now = tick()
                if now - lastDetected < cooldownTime then return end
                local t = Mouse.Target
                if t and table.find(partMap[triggerPart], t.Name) then
                    local mdl = t:FindFirstAncestorOfClass("Model")
                    if mdl then
                        local pl = Players:GetPlayerFromCharacter(mdl)
                        if pl and pl ~= LocalPlayer then
                            lastDetected = now
                            mouse1press(); wait(0.05); mouse1release()
                        end
                    end
                end
            end)
        end
    else
        if triggerConnection then
            triggerConnection:Disconnect()
            triggerConnection = nil
        end
    end
    print("Triggerbot " .. (triggerbotActive and "enabled" or "disabled"))
end)

--// Aimlock Dropdown
Section2:NewDropdown("Aim Part", "Select part to aim at", {"Head","Torso","HumanoidRootPart"}, function(opt)
    aimPart = opt
    print("Aim part set to: " .. aimPart)
end)

--// Aimlock Toggle
Section2:NewToggle("Aimlock", "Enable aimlock", function(state)
    aimlockEnabled = state
    if not state then lockedPlayer = nil end
    print("Aimlock " .. (state and "enabled" or "disabled"))
end)

--// Aimlock Keybind
Section2:NewKeybind("Lock Target", "Toggle lock with F", Enum.KeyCode.F, function()
    if not aimlockEnabled then return end
    if lockedPlayer then
        print("Released from " .. lockedPlayer.Name)
        lockedPlayer = nil
        return
    end
    local best, bd = nil, math.huge
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild(aimPart) then
            local p = pl.Character[aimPart]
            local sp, on = Camera:WorldToViewportPoint(p.Position)
            if on then
                local mp = UserInputService:GetMouseLocation()
                local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mp.X, mp.Y)).Magnitude
                if d < bd then
                    best, bd = pl, d
                end
            end
        end
    end
    if best then
        lockedPlayer = best
        print("Locked on " .. best.Name)
    end
end)

--// Aimlock Smoothness
Section2:NewTextBox("Aimlock Smoothness", "0–1 slow→fast", function(txt)
    local n = tonumber(txt)
    if n and n >= 0 and n <= 1 then
        aimSmoothness = n
        print("Smoothness:", n)
    else
        warn("Invalid smoothness")
    end
end)

--// ESP Toggle
Section3:NewToggle("ESP", "Enable player highlights", function(state)
    espEnabled = state
    if state then
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and not espHighlights[pl] then
                local hl = Instance.new("Highlight", pl.Character)
                hl.FillTransparency = 0.5
                hl.OutlineColor = espColor
                espHighlights[pl] = hl
            elseif espHighlights[pl] then
                espHighlights[pl].OutlineColor = espColor
            end
        end
        Players.PlayerAdded:Connect(function(pl)
            pl.CharacterAdded:Connect(function(char)
                if espEnabled then
                    local hl = Instance.new("Highlight", char)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = espColor
                    espHighlights[pl] = hl
                end
            end)
        end)
        Players.PlayerRemoving:Connect(function(pl)
            if espHighlights[pl] then
                espHighlights[pl]:Destroy()
                espHighlights[pl] = nil
            end
        end)
    else
        for pl, hl in pairs(espHighlights) do
            hl:Destroy()
            espHighlights[pl] = nil
        end
    end
    print("ESP " .. (state and "enabled" or "disabled"))
end)

--// ESP Color Picker
Section3:NewColorPicker("ESP Color", "Choose ESP color", espColor, function(c)
    espColor = c
    print("ESP color:", c)
    for _, hl in pairs(espHighlights) do
        hl.OutlineColor = c
    end
end)
