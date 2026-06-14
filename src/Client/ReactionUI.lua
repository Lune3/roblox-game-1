local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReleaseLockEvent = Shared:WaitForChild("ReleaseLockEvent")

local ReactionUI = {}

function ReactionUI.Init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local camera = workspace.CurrentCamera

    -- Build the 2D UI for the bottom buttons
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

    -- Build the 3D UI for the Matrix
    local uiPart = Instance.new("Part")
    uiPart.Name = "ReactionUIPart"
    uiPart.Size = Vector3.new(6, 9, 0.1) -- Made larger but further away to avoid camera clipping/blur
    uiPart.Anchored = true
    uiPart.CanCollide = false
    uiPart.CanQuery = false
    uiPart.CanTouch = false
    uiPart.CastShadow = false
    uiPart.Transparency = 1 -- Invisible part, we only want the UI

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "ReactionSurfaceGui"
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.CanvasSize = Vector2.new(300, 450)
    surfaceGui.Adornee = uiPart
    surfaceGui.AlwaysOnTop = true -- Renders on top of other 3D objects
    surfaceGui.Enabled = false
    surfaceGui.Parent = playerGui

    -- The Matrix Frame
    local matrixFrame = Instance.new("Frame")
    matrixFrame.Name = "MatrixFrame"
    matrixFrame.Size = UDim2.new(1, 0, 1, 0)
    matrixFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    matrixFrame.BackgroundTransparency = 0.5
    matrixFrame.Parent = surfaceGui
    
    local matrixCorner = Instance.new("UICorner")
    matrixCorner.CornerRadius = UDim.new(0, 12)
    matrixCorner.Parent = matrixFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Parent = matrixFrame

    local options = {
        "W Rizz",
        "Smooth",
        "Neutral",
        "Awkward",
        "Cringe"
    }

    for _, optName in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Name = optName .. "Btn"
        btn.Size = UDim2.new(0.9, 0, 0, 60)
        btn.Text = optName
        btn.TextSize = 28
        btn.Font = Enum.Font.GothamBold
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        btn.Parent = matrixFrame
        
        btn.MouseButton1Click:Connect(function()
            print("Clicked reaction: " .. optName)
        end)
    end

    local renderConnection = nil

    local function show3DUI()
        uiPart.Parent = camera
        surfaceGui.Enabled = true
        -- Update the position every frame so it stays locked to the camera
        renderConnection = RunService.RenderStepped:Connect(function()
            -- Position: 4 studs to the right, 1 stud down, 10 studs forward
            -- Rotation: 180 on Y (to face camera) + 15 degrees for the slant
            local offset = CFrame.new(4, -1, -10) * CFrame.Angles(0, math.rad(180 + 15), 0)
            uiPart.CFrame = camera.CFrame * offset
        end)
    end

    local function hide3DUI()
        uiPart.Parent = nil
        surfaceGui.Enabled = false
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
    end

    -- Listen for server telling us we are locked or unlocked
    ReleaseLockEvent.OnClientEvent:Connect(function(action, isApproacher)
        if action == "Hide" then
            notInterestedBtn.Visible = false
            hide3DUI()
            ProximityPromptService.Enabled = true
            return
        end

        -- Hide all other players' prompts from our screen while we are in a conversation
        ProximityPromptService.Enabled = false

        if isApproacher then
            notInterestedBtn.Text = "End Conversation"
            notInterestedBtn.Visible = true
            hide3DUI() -- Approacher does NOT see the matrix
        else
            notInterestedBtn.Text = "Not Interested"
            notInterestedBtn.Visible = true
            show3DUI() -- ONLY Target sees the matrix
        end
    end)

    -- Handle Button Click
    notInterestedBtn.MouseButton1Click:Connect(function()
        notInterestedBtn.Visible = false
        hide3DUI()
        ReleaseLockEvent:FireServer()
    end)
end

return ReactionUI
