local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReleaseLockEvent = Shared:WaitForChild("ReleaseLockEvent")

local ReactionUI = {}

function ReactionUI.Init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Build the UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ReactionMatrixUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local notInterestedBtn = Instance.new("TextButton")
    notInterestedBtn.Name = "NotInterestedButton"
    notInterestedBtn.Size = UDim2.new(0, 200, 0, 50)
    notInterestedBtn.Position = UDim2.new(0.5, -100, 0.8, 0) -- Bottom center
    notInterestedBtn.Text = "Not Interested"
    notInterestedBtn.TextSize = 20
    notInterestedBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    notInterestedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    notInterestedBtn.Visible = false
    notInterestedBtn.Parent = screenGui

    -- Listen for server telling us we are locked or unlocked
    ReleaseLockEvent.OnClientEvent:Connect(function(action, isApproacher)
        if action == "Hide" then
            notInterestedBtn.Visible = false
            ProximityPromptService.Enabled = true
            return
        end

        -- Hide all other players' prompts from our screen while we are in a conversation
        ProximityPromptService.Enabled = false

        if isApproacher then
            notInterestedBtn.Text = "End Conversation"
        else
            notInterestedBtn.Text = "Not Interested"
        end
        notInterestedBtn.Visible = true
    end)

    -- Handle Button Click
    notInterestedBtn.MouseButton1Click:Connect(function()
        notInterestedBtn.Visible = false
        ReleaseLockEvent:FireServer()
    end)
end

return ReactionUI
