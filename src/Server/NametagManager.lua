local Players = game:GetService("Players")

local NametagManager = {}

local function updateNametag(player, character, humanoid)
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local billboard = head:FindFirstChild("CustomNametag")
    
    if player:GetAttribute("OwnsChatColorPass") then
        -- VIP: Hide default nametag and show custom reddish pink one
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        
        if not billboard then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "CustomNametag"
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.AlwaysOnTop = true
            billboard.Adornee = head
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "NameText"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Font = Enum.Font.BuilderSansBold
            textLabel.TextSize = 24
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.TextColor3 = Color3.fromRGB(255, 51, 102) -- Reddish Pink
            textLabel.Parent = billboard
            
            billboard.Parent = head
        end
        
        local textLabel = billboard:FindFirstChild("NameText")
        if textLabel then
            textLabel.Text = "[Rizzler] " .. player.DisplayName
        end
    else
        -- Non-VIP: Show default Roblox nametag and destroy custom one
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        if billboard then
            billboard:Destroy()
        end
    end
end

function NametagManager.Init()
    local function onPlayerAdded(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid", 5)
            
            if humanoid then
                -- Set initial state
                updateNametag(player, character, humanoid)
                
                -- Listen for VIP changes while character is alive
                local connection
                connection = player:GetAttributeChangedSignal("OwnsChatColorPass"):Connect(function()
                    if character.Parent and humanoid.Parent then
                        updateNametag(player, character, humanoid)
                    elseif connection then
                        connection:Disconnect()
                    end
                end)
                
                humanoid.Died:Connect(function()
                    if connection then
                        connection:Disconnect()
                    end
                end)
            end
        end)
    end
    
    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, p)
    end
    Players.PlayerAdded:Connect(onPlayerAdded)
end

return NametagManager
