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

-- === MEGAPHONE UI ===
local MegaphoneEvent = Shared:WaitForChild("MegaphoneEvent")

-- Create the UI ScreenGui for the Megaphone
local playerGui = localPlayer:WaitForChild("PlayerGui")
local megaphoneGui = Instance.new("ScreenGui")
megaphoneGui.Name = "MegaphoneGui"
megaphoneGui.Parent = playerGui

local megaphoneBanner = Instance.new("Frame")
megaphoneBanner.Size = UDim2.new(1, 0, 0, 80)
megaphoneBanner.Position = UDim2.new(0, 0, -0.2, 0) -- Hidden above screen
megaphoneBanner.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
megaphoneBanner.BackgroundTransparency = 0.2
megaphoneBanner.BorderSizePixel = 0
megaphoneBanner.Parent = megaphoneGui

local megaphoneText = Instance.new("TextLabel")
megaphoneText.Size = UDim2.new(1, 0, 1, 0)
megaphoneText.BackgroundTransparency = 1
megaphoneText.Font = Enum.Font.GothamBold
megaphoneText.TextSize = 24
megaphoneText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
megaphoneText.Text = ""
megaphoneText.Parent = megaphoneBanner

local TweenService = game:GetService("TweenService")

MegaphoneEvent.OnClientEvent:Connect(function(playerName, message)
    megaphoneText.Text = "📢 " .. playerName .. " shouts: " .. message
    
    -- Slide down
    local tweenDown = TweenService:Create(megaphoneBanner, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
    tweenDown:Play()
    
    -- Wait 5 seconds, then slide up
    task.delay(5, function()
        local tweenUp = TweenService:Create(megaphoneBanner, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, -0.2, 0)})
        tweenUp:Play()
    end)
end)

-- === CUSTOM CHAT COLORS (VIP) ===
TextChatService.OnIncomingMessage = function(message)
    local props = Instance.new("TextChatMessageProperties")
    
    if message.TextSource then
        local player = Players:GetPlayerByUserId(message.TextSource.UserId)
        if player and player:GetAttribute("OwnsChatColorPass") then
            -- Add VIP tag and make their prefix Gold!
            props.PrefixText = "<font color='#FFD700'><b>[VIP]</b></font> " .. message.PrefixText
        end
    end
    
    return props
end

-- === COOLDOWN NOTIFICATION UI ===
local CooldownNotifyEvent = Shared:WaitForChild("CooldownNotifyEvent")

local cooldownNotifyGui = Instance.new("ScreenGui")
cooldownNotifyGui.Name = "CooldownNotifyGui"
cooldownNotifyGui.Parent = playerGui

local cooldownNotifyText = Instance.new("TextLabel")
cooldownNotifyText.Size = UDim2.new(1, 0, 0, 50)
cooldownNotifyText.Position = UDim2.new(0, 0, 0, -50) -- Hidden above screen
cooldownNotifyText.BackgroundTransparency = 1
cooldownNotifyText.Font = Enum.Font.BuilderSansBold
cooldownNotifyText.TextSize = 28
cooldownNotifyText.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
cooldownNotifyText.TextStrokeTransparency = 0
cooldownNotifyText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
cooldownNotifyText.Text = ""
cooldownNotifyText.Parent = cooldownNotifyGui

local notifyTweenUp, notifyTweenDown
local currentNotifyThread = nil

CooldownNotifyEvent.OnClientEvent:Connect(function(message)
    cooldownNotifyText.Text = message
    
    if notifyTweenUp then notifyTweenUp:Cancel() end
    if notifyTweenDown then notifyTweenDown:Cancel() end
    if currentNotifyThread then task.cancel(currentNotifyThread) end
    
    -- Slide down (smooth quart curve)
    notifyTweenDown = TweenService:Create(cooldownNotifyText, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 50)})
    notifyTweenDown:Play()
    
    -- Wait 3 seconds, then slide up off screen
    currentNotifyThread = task.delay(3, function()
        notifyTweenUp = TweenService:Create(cooldownNotifyText, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, 0, -100)})
        notifyTweenUp:Play()
    end)
end)
