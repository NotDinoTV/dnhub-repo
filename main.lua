-- Variables

local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local cooldownTime = 0.1
local lastDetected = 0
local triggerRunning = false

-- Hub

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("DN HUB: ".. gameName, "BloodTheme")
local Tab = Window:NewTab("Combat")
local Section = Tab:NewSection("Combat")

Section:NewToggle("Triggerbot", "Triggers when aiming at chosen part", function(state)
    if state then
        print("Triggerbot enabled")
        triggerRunning = true
        task.spawn(function()
            while triggerRunning do
                local currentTime = tick()
                if currentTime - lastDetected >= cooldownTime then
                    local target = Mouse.Target
                    if target and target.Name == "Head" then
                        local model = target:FindFirstAncestorOfClass("Model")
                        if model then
                            local player = Players:GetPlayerFromCharacter(model)
                            if player and player ~= LocalPlayer then
                                print("Kopf erkannt - Schießen auf: " .. player.Name)
                                lastDetected = currentTime

                                mouse1press()
                                wait(0.05)
                                mouse1release()
                            end
                        end
                    end
                end
                task.wait()
            end
        end)
    else
        print("Triggerbot disabled")
        triggerRunning = false
    end
end)
