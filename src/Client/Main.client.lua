local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("Aura Simulator Client Started")

-- Function to hide our own prompt so we only see other people's prompts
local function HideOwnPrompt(character)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    local prompt = hrp:WaitForChild("ApproachPrompt", 5)
    if prompt then
        -- Force it off now
        prompt.Enabled = false
        -- If the server tries to turn it back on, force it off again!
        prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
            if prompt.Enabled then
                prompt.Enabled = false
            end
        end)
    end
end

-- Run when we spawn
localPlayer.CharacterAdded:Connect(HideOwnPrompt)

-- Run if we already spawned before the script loaded
if localPlayer.Character then
    HideOwnPrompt(localPlayer.Character)
end

local ReactionUI = require(script.Parent:WaitForChild("ReactionUI"))
ReactionUI.Init()

local SettingsUI = require(script.Parent:WaitForChild("SettingsUI"))
SettingsUI.Init()

