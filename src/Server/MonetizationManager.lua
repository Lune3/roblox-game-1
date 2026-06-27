local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationManager = {}

-- === REPLACE THESE WITH YOUR REAL IDS FROM ROBLOX.COM ===
local PRODUCT_MEGAPHONE = 3606080166
local PRODUCT_VIP_1DAY = 3606849631
-- ========================================================

-- Ensure the Shared folder and Event exist
local Shared = ReplicatedStorage:WaitForChild("Shared")
local MegaphoneEvent = Shared:FindFirstChild("MegaphoneEvent")
if not MegaphoneEvent then
    MegaphoneEvent = Instance.new("RemoteEvent")
    MegaphoneEvent.Name = "MegaphoneEvent"
    MegaphoneEvent.Parent = Shared
end

local SetMegaphoneMessageEvent = Shared:FindFirstChild("SetMegaphoneMessageEvent")
if not SetMegaphoneMessageEvent then
    SetMegaphoneMessageEvent = Instance.new("RemoteEvent")
    SetMegaphoneMessageEvent.Name = "SetMegaphoneMessageEvent"
    SetMegaphoneMessageEvent.Parent = Shared
end

function MonetizationManager.Init()
    -- 1. Check VIP Expiration on Join
    local function onPlayerAdded(player)
        -- Update chat tag status whenever VipExpiration changes
        player:GetAttributeChangedSignal("VipExpiration"):Connect(function()
            local vipExp = player:GetAttribute("VipExpiration") or 0
            if os.time() < vipExp then
                player:SetAttribute("OwnsChatColorPass", true)
            else
                player:SetAttribute("OwnsChatColorPass", false)
            end
        end)
        
        -- Run an initial check in case data loaded before connection
        if player:GetAttribute("VipExpiration") then
            local vipExp = player:GetAttribute("VipExpiration") or 0
            if os.time() < vipExp then
                player:SetAttribute("OwnsChatColorPass", true)
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, player)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)
    
    SetMegaphoneMessageEvent.OnServerEvent:Connect(function(player, message)
        if type(message) == "string" then
            player:SetAttribute("PendingMegaphoneMessage", string.sub(message, 1, 100))
        end
    end)

    -- 2. Handle Developer Product Purchases
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then
            -- Player left before we could process it, tell Roblox to keep it pending
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        if receiptInfo.ProductId == PRODUCT_MEGAPHONE then
            local customMessage = player:GetAttribute("PendingMegaphoneMessage") or "Anyone want to lock in?"
            MegaphoneEvent:FireAllClients(player.Name, customMessage)
            
            print(player.Name .. " successfully purchased a Server Megaphone!")
            return Enum.ProductPurchaseDecision.PurchaseGranted
        elseif receiptInfo.ProductId == PRODUCT_VIP_1DAY then
            -- Add 24 hours (86400 seconds) to their VIP expiration
            local currentExp = player:GetAttribute("VipExpiration") or 0
            local newExp = math.max(os.time(), currentExp) + 86400
            player:SetAttribute("VipExpiration", newExp)
            
            print(player.Name .. " successfully purchased 1-Day VIP!")
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

return MonetizationManager
