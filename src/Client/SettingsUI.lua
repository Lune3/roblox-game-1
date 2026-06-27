local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UpdateSettingsEvent = Shared:WaitForChild("UpdateSettingsEvent")

local SettingsUI = {}

function SettingsUI.Init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SettingsUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Settings Button (Top Right)
    local openBtn = Instance.new("TextButton")
    openBtn.Name = "OpenSettingsBtn"
    openBtn.Size = UDim2.new(0, 100, 0, 40)
    openBtn.AnchorPoint = Vector2.new(1, 1)
    openBtn.Position = UDim2.new(1, -20, 1, -20)
    openBtn.Text = "Settings"
    openBtn.TextSize = 18
    openBtn.Font = Enum.Font.BuilderSans
    openBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    openBtn.Parent = screenGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = openBtn

    -- Settings Panel
    local panel = Instance.new("Frame")
    panel.Name = "SettingsPanel"
    panel.Size = UDim2.new(0, 320, 0, 200)
    panel.Position = UDim2.new(0.5, -160, 0.5, -100)
    panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    panel.Visible = false
    panel.Parent = screenGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = panel

    local panelPadding = Instance.new("UIPadding")
    panelPadding.PaddingTop = UDim.new(0.04, 0)
    panelPadding.PaddingBottom = UDim.new(0.04, 0)
    panelPadding.PaddingLeft = UDim.new(0.04, 0)
    panelPadding.PaddingRight = UDim.new(0.04, 0)
    panelPadding.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "Game Settings"
    title.TextSize = 20
    title.Font = Enum.Font.BuilderSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Parent = panel

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.new(0, 10, 0, 50)
    label.Text = "Approach Cooldown (Seconds):"
    label.TextSize = 16
    label.Font = Enum.Font.BuilderSans
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = panel

    local inputField = Instance.new("TextBox")
    inputField.Size = UDim2.new(1, -20, 0, 40)
    inputField.Position = UDim2.new(0, 10, 0, 80)
    inputField.Text = tostring(player:GetAttribute("ApproachCooldown") or 10)
    inputField.TextSize = 18
    inputField.Font = Enum.Font.BuilderSans
    inputField.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    inputField.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputField.ClearTextOnFocus = false
    inputField.Parent = panel

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputField

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(1, -20, 0, 40)
    applyBtn.Position = UDim2.new(0, 10, 0, 135)
    applyBtn.Text = "Apply & Close"
    applyBtn.TextSize = 18
    applyBtn.Font = Enum.Font.BuilderSansBold
    applyBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Parent = panel 

    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 6)
    applyCorner.Parent = applyBtn

    openBtn.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
        inputField.Text = tostring(player:GetAttribute("ApproachCooldown") or 10)
    end)

    applyBtn.MouseButton1Click:Connect(function()
        local seconds = tonumber(inputField.Text)
        if seconds then
            UpdateSettingsEvent:FireServer(seconds)
            panel.Visible = false
        else
            inputField.Text = "Invalid Number!"
        end
    end)
end

return SettingsUI
