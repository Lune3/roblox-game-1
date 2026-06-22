local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationManager = {}

-- === REPLACE THESE WITH YOUR REAL IDS FROM ROBLOX.COM ===
local PRODUCT_MEGAPHONE = 3606080166
local GAMEPASS_CHATCOLOR = 1887220269
-- ========================================================

-- Ensure the Shared folder and Event exist
local Shared = ReplicatedStorage:WaitForChild("Shared")
local MegaphoneEvent = Shared:FindFirstChild("MegaphoneEvent")
if not MegaphoneEvent then
    MegaphoneEvent = Instance.new("RemoteEvent")
    MegaphoneEvent.Name = "MegaphoneEvent"
    MegaphoneEvent.Parent = Shared
end

function MonetizationManager.Init()
    -- 1. Check Gamepass Ownership on Join
    local function onPlayerAdded(player)
        local success, hasPass = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_CHATCOLOR)
        end)
        
        if success and hasPass then
            player:SetAttribute("OwnsChatColorPass", true)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, player)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)

    -- 2. Handle Developer Product Purchases
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
        if not player then
            -- Player left before we could process it, tell Roblox to keep it pending
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        if receiptInfo.ProductId == PRODUCT_MEGAPHONE then
            -- The player bought the Megaphone! 
            -- Fire the event to all clients so they show the UI banner.
            -- Note: We read the custom message from an Attribute they set right before buying.
            local customMessage = player:GetAttribute("PendingMegaphoneMessage") or "Anyone want to lock in?"
            MegaphoneEvent:FireAllClients(player.Name, customMessage)
            
            print(player.Name .. " successfully purchased a Server Megaphone!")
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

return MonetizationManager
