local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print("Aura Simulator Client Started")

-- Function to hide our own prompt so we only see other people's prompts
local function HideOwnPrompt(character)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    local prompt = hrp:WaitForChild("ApproachPrompt", 5)
    if prompt then
        -- This only disables it on OUR screen, other players can still see it!
        prompt.Enabled = false
    end
end

-- Run when we spawn
localPlayer.CharacterAdded:Connect(HideOwnPrompt)

-- Run if we already spawned before the script loaded
if localPlayer.Character then
    HideOwnPrompt(localPlayer.Character)
end

