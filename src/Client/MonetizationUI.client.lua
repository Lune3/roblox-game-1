local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === REPLACE THESE WITH YOUR REAL IDS FROM ROBLOX.COM ===
local PRODUCT_MEGAPHONE = 3606080166
local GAMEPASS_CHATCOLOR = 1887220269
-- ========================================================

-- Build the Store UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonetizationUI"
screenGui.Parent = playerGui

local storeFrame = Instance.new("Frame")
storeFrame.Size = UDim2.new(0, 160, 0, 120)
storeFrame.Position = UDim2.new(0, 10, 0.5, -60)
storeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
storeFrame.BackgroundTransparency = 0.5
storeFrame.Parent = screenGui

local megaphoneBtn = Instance.new("TextButton")
megaphoneBtn.Size = UDim2.new(1, -10, 0, 45)
megaphoneBtn.Position = UDim2.new(0, 5, 0, 5)
megaphoneBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
megaphoneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
megaphoneBtn.Font = Enum.Font.GothamBold
megaphoneBtn.TextSize = 14
megaphoneBtn.Text = "📢 Shout (50 R$)"
megaphoneBtn.Parent = storeFrame

local vipBtn = Instance.new("TextButton")
vipBtn.Size = UDim2.new(1, -10, 0, 45)
vipBtn.Position = UDim2.new(0, 5, 0, 60)
vipBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
vipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
vipBtn.Font = Enum.Font.GothamBold
vipBtn.TextSize = 14
vipBtn.Text = "👑 VIP Tag"
vipBtn.Parent = storeFrame

-- Purchasing Logic
megaphoneBtn.MouseButton1Click:Connect(function()
    -- Set the message they want to send (In the future, we can add a TextBox for them to type this)
    player:SetAttribute("PendingMegaphoneMessage", "TESTING THE MEGAPHONE YESSIR!")
    
    -- Prompt the purchase!
    MarketplaceService:PromptProductPurchase(player, PRODUCT_MEGAPHONE)
end)

vipBtn.MouseButton1Click:Connect(function()
    -- Prompt Gamepass Purchase!
    MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_CHATCOLOR)
end)
