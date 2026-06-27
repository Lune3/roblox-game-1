local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SetMegaphoneMessageEvent = Shared:WaitForChild("SetMegaphoneMessageEvent")

-- === REPLACE THESE WITH YOUR REAL IDS FROM ROBLOX.COM ===
local PRODUCT_MEGAPHONE = 3606080166
local PRODUCT_VIP_1DAY = 3606849631
-- ========================================================

-- Build the Store UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonetizationUI"
screenGui.Parent = playerGui

local storeFrame = Instance.new("Frame")
storeFrame.Size = UDim2.new(0, 220, 0, 170)
storeFrame.Position = UDim2.new(0, 10, 0.5, -85)
storeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
storeFrame.BackgroundTransparency = 0.5
storeFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = storeFrame

local messageInput = Instance.new("TextBox")
messageInput.Size = UDim2.new(1, -20, 0, 40)
messageInput.Position = UDim2.new(0, 10, 0, 10)
messageInput.PlaceholderText = "Enter shout message..."
messageInput.Text = ""
messageInput.Font = Enum.Font.BuilderSans
messageInput.TextSize = 14
messageInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
messageInput.TextColor3 = Color3.fromRGB(255, 255, 255)
messageInput.ClearTextOnFocus = false
messageInput.Parent = storeFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = messageInput

local errorText = Instance.new("TextLabel")
errorText.Size = UDim2.new(1, -20, 0, 20)
errorText.Position = UDim2.new(0, 10, 0, 50)
errorText.BackgroundTransparency = 1
errorText.Font = Enum.Font.BuilderSansBold
errorText.TextSize = 12
errorText.TextColor3 = Color3.fromRGB(255, 50, 50)
errorText.Text = "enter message to use mega phone"
errorText.Visible = false
errorText.Parent = storeFrame

local megaphoneBtn = Instance.new("TextButton")
megaphoneBtn.Size = UDim2.new(1, -20, 0, 40)
megaphoneBtn.Position = UDim2.new(0, 10, 0, 70)
megaphoneBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
megaphoneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
megaphoneBtn.Font = Enum.Font.BuilderSansBold
megaphoneBtn.TextSize = 14
megaphoneBtn.Text = "📢 Shout (50 R$)"
megaphoneBtn.Parent = storeFrame

local megaCorner = Instance.new("UICorner")
megaCorner.CornerRadius = UDim.new(0, 8)
megaCorner.Parent = megaphoneBtn

local vipBtn = Instance.new("TextButton")
vipBtn.Size = UDim2.new(1, -20, 0, 40)
vipBtn.Position = UDim2.new(0, 10, 0, 120)
vipBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
vipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
vipBtn.Font = Enum.Font.BuilderSansBold
vipBtn.TextSize = 14
vipBtn.Text = "👑 VIP Tag (1 Day)"
vipBtn.Parent = storeFrame

local vipCorner = Instance.new("UICorner")
vipCorner.CornerRadius = UDim.new(0, 8)
vipCorner.Parent = vipBtn

-- Purchasing Logic
megaphoneBtn.MouseButton1Click:Connect(function()
    -- Set the message they want to send based on TextBox input
    local msg = messageInput.Text
    if msg == "" or string.match(msg, "^%s*$") then
        errorText.Visible = true
        task.delay(3, function()
            if errorText then errorText.Visible = false end
        end)
        return
    end
    
    if string.len(msg) > 100 then
        msg = string.sub(msg, 1, 100)
    end
    
    SetMegaphoneMessageEvent:FireServer(msg)
    
    -- Prompt the purchase!
    MarketplaceService:PromptProductPurchase(player, PRODUCT_MEGAPHONE)
end)

-- Clear the text box after a successful purchase
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
    if isPurchased and productId == PRODUCT_MEGAPHONE and userId == player.UserId then
        messageInput.Text = ""
    end
end)

vipBtn.MouseButton1Click:Connect(function()
    -- Prompt Developer Product Purchase!
    MarketplaceService:PromptProductPurchase(player, PRODUCT_VIP_1DAY)
end)
