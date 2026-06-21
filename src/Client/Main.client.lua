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
            -- Retry loop: It takes a moment for the server to replicate the TextSource permissions to the client.
            -- If we set it too early, Roblox ignores it.
            task.spawn(function()
                local retries = 0
                while chatInputBar.TargetTextChannel ~= targetChannel and retries < 10 do
                    chatInputBar.TargetTextChannel = targetChannel
                    if chatInputBar.TargetTextChannel ~= targetChannel then
                        task.wait(0.2)
                    end
                    retries = retries + 1
                end
                if chatInputBar.TargetTextChannel == targetChannel then
                    print("Successfully switched chat channel to: " .. channelName)
                end
            end)
        end
    end
end)

