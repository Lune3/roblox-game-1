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

-- Handle Private Text Chat switching
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local ChatSwitchEvent = Shared:WaitForChild("ChatSwitchEvent")

ChatSwitchEvent.OnClientEvent:Connect(function(channelName)
    local chatInputBar = TextChatService:FindFirstChild("ChatInputBarConfiguration")
    if chatInputBar then
        local textChannels = TextChatService:WaitForChild("TextChannels")
        -- If switching back to general, the channel is RBXGeneral
        local targetChannel = textChannels:WaitForChild(channelName, 5)
        if targetChannel then
            chatInputBar.TargetTextChannel = targetChannel
            print("Switched chat channel to: " .. channelName)
        end
    end
end)

