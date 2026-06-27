local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReleaseLockEvent = Shared:WaitForChild("ReleaseLockEvent")
local ReactionEvent = Shared:WaitForChild("ReactionEvent")
local Constants = require(Shared:WaitForChild("Constants"))

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
    notInterestedBtn.Size = UDim2.new(0, 220, 0, 55) -- Increased width and height slightly
    notInterestedBtn.AnchorPoint = Vector2.new(0.5, 0)
    notInterestedBtn.Position = UDim2.new(0.5, 0, 0.8, 0) -- Bottom center
    notInterestedBtn.Text = "Not Interested"
    notInterestedBtn.TextSize = 20
    notInterestedBtn.Font = Enum.Font.BuilderSansBold
    notInterestedBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    notInterestedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    notInterestedBtn.Visible = false
    notInterestedBtn.Parent = screenGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = notInterestedBtn

    local btnPadding = Instance.new("UIPadding")
    btnPadding.PaddingTop = UDim.new(0.03, 0)
    btnPadding.PaddingBottom = UDim.new(0.03, 0)
    btnPadding.PaddingLeft = UDim.new(0.03, 0)
    btnPadding.PaddingRight = UDim.new(0.03, 0)
    btnPadding.Parent = notInterestedBtn

    -- Build the 3D UI for the Matrix
    local uiPart = Instance.new("Part")
    uiPart.Name = "ReactionUIPart"
    uiPart.Size = Vector3.new(4.59, 6.885, 0.1) -- Reduced by another 15%
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
    matrixFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    matrixFrame.BackgroundTransparency = 0.2
    matrixFrame.Parent = surfaceGui
    
    local matrixCorner = Instance.new("UICorner")
    matrixCorner.CornerRadius = UDim.new(0, 12)
    matrixCorner.Parent = matrixFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 15)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder -- Forces it to use our specific order instead of alphabetical
    listLayout.Parent = matrixFrame

    -- Re-added the colors so it's beautifully colored from green to red!
    local options = {
        { name = "W Rizz", color = Color3.fromRGB(50, 255, 100) },
        { name = "Smooth", color = Color3.fromRGB(100, 255, 150) },
        { name = "Neutral", color = Color3.fromRGB(220, 220, 220) },
        { name = "Awkward", color = Color3.fromRGB(255, 150, 100) },
        { name = "Cringe", color = Color3.fromRGB(255, 50, 50) }
    }

    local onCooldown = false

    for index, opt in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Name = opt.name .. "Btn"
        btn.LayoutOrder = index -- Explicitly sets the order from top to bottom
        btn.Size = UDim2.new(0.9, 0, 0, 60)
        btn.Text = opt.name
        btn.TextSize = 28
        btn.Font = Enum.Font.BuilderSansBold
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark background
        btn.TextColor3 = opt.color -- Colored text
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        btn.Parent = matrixFrame
        
        btn.MouseButton1Click:Connect(function()
            if onCooldown then return end
            onCooldown = true
            
            -- UI stays visible, but goes on a local cooldown
            ReactionEvent:FireServer(opt.name)
            
            task.delay(Constants.REACTION_COOLDOWN_CLIENT, function()
                onCooldown = false
            end)
        end)
    end

    local renderConnection = nil
    local cameraConnection = nil

    local function show3DUI()
        uiPart.Parent = camera
        surfaceGui.Enabled = true
        
        renderConnection = RunService.RenderStepped:Connect(function()
            -- === MATRIX UI ADJUSTMENT VALUES ===
            -- offsetX: Moves the menu left (negative) or right (positive) on your screen.
            -- offsetY: Moves the menu down (negative) or up (positive) on your screen.
            -- offsetZ: Distance from camera. Keep around -10 so it avoids camera blur!
            -- slantAngle: The 3D rotation tilt of the board in degrees. 
            
            local offsetX = 8
            local offsetY = -1
            local offsetZ = -10
            local slantAngle = 0 -- Degrees it tilts (Removed tilt to make it flat)
            
            -- We add 180 to the angle so the invisible part's front faces the camera
            local rotation = CFrame.Angles(0, math.rad(180 + slantAngle), 0)
            local offsetCFrame = CFrame.new(offsetX, offsetY, offsetZ) * rotation
            
            uiPart.CFrame = camera.CFrame * offsetCFrame
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

    local function lockCamera(isApproacher)
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        camera.CameraType = Enum.CameraType.Scriptable

        cameraConnection = RunService.RenderStepped:Connect(function()
            -- === CAMERA ADJUSTMENT VALUES ===
            -- X_OFFSET: Moves camera left (negative) or right (positive). 
            --           Right now, Approacher is +3 (right shoulder), Target is -3 (left shoulder).
            -- Y_OFFSET: Moves camera up (positive) or down (negative) relative to the player's root.
            -- Z_OFFSET: Moves camera backward (positive) or forward (negative).
            -- LOOK_OFFSET_Y: Moves the focal point (what the camera is staring at) up or down.
            -- LOOK_DISTANCE: How many studs ahead the camera looks to frame the other player.
            
            local xOffset = isApproacher and 5 or -5 
            local yOffset = isApproacher and 2 or 2
            local zOffset = isApproacher and 5 or 8 -- 5 for Approacher, 8 for Target (zoomed out more)
            
            local lookOffsetY = 1.5
            local lookDistance = 8

            -- Calculate the exact position of the camera behind the player
            local camPos = hrp.CFrame * CFrame.new(xOffset, yOffset, zOffset)
            
            -- Calculate the point the camera should look at (roughly at the other player's face)
            local lookAtPos = hrp.Position + (hrp.CFrame.LookVector * lookDistance) + Vector3.new(0, lookOffsetY, 0)

            -- Set the camera to that position and look at the target point
            camera.CFrame = CFrame.lookAt(camPos.Position, lookAtPos)
        end)
    end

    local function unlockCamera()
        if cameraConnection then
            cameraConnection:Disconnect()
            cameraConnection = nil
        end
        camera.CameraType = Enum.CameraType.Custom
    end

    -- Listen for server telling us we are locked or unlocked
    ReleaseLockEvent.OnClientEvent:Connect(function(action, isApproacher)
        if action == "Hide" then
            notInterestedBtn.Visible = false
            hide3DUI()
            unlockCamera()
            ProximityPromptService.Enabled = true
            return
        end

        -- Hide all other players' prompts from our screen while we are in a conversation
        ProximityPromptService.Enabled = false

        if isApproacher then
            notInterestedBtn.Text = "End Conversation"
            notInterestedBtn.Visible = true
            hide3DUI() -- Approacher does NOT see the matrix
            lockCamera(true)
        else
            notInterestedBtn.Text = "Not Interested"
            notInterestedBtn.Visible = true
            show3DUI() -- ONLY Target sees the matrix
            lockCamera(false)
        end
    end)

    -- Handle Button Click
    notInterestedBtn.MouseButton1Click:Connect(function()
        notInterestedBtn.Visible = false
        hide3DUI()
        unlockCamera()
        ReleaseLockEvent:FireServer()
    end)

    -- Listen for server to show floating text
    ReactionEvent.OnClientEvent:Connect(function(targetChar, scoreChange, reactionName)
        -- Hide the floating number from the Target's own screen!
        if player.Character == targetChar then return end
        
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- === FLOATING TEXT TWEAK VALUES ===
        -- START_OFFSET: Where the text spawns relative to the Target's HumanoidRootPart.
        --               Z is positive so it starts BEHIND the target's back.
        -- FLOAT_HEIGHT: How many studs the text rises up.
        -- TWEEN_DURATION: How many seconds the animation takes.
        
        local START_OFFSET = Vector3.new(0, 2, 2) 
        local FLOAT_HEIGHT = 4
        local TWEEN_DURATION = 2.5
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "RizzScoreVFX"
        billboard.Size = UDim2.new(0, 200, 0, 100)
        billboard.StudsOffset = START_OFFSET
        billboard.AlwaysOnTop = true
        billboard.Adornee = hrp
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBlack
        textLabel.TextSize = 50
        
        if scoreChange > 0 then
            textLabel.Text = "+" .. tostring(scoreChange)
            textLabel.TextColor3 = Color3.fromRGB(50, 255, 100) -- Green
        elseif scoreChange < 0 then
            textLabel.Text = tostring(scoreChange)
            textLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
        else
            textLabel.Text = "0"
            textLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray
        end
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 4
        stroke.Parent = textLabel
        
        textLabel.Parent = billboard
        billboard.Parent = playerGui
        
        -- Animation setup
        local floatGoal = {StudsOffset = START_OFFSET + Vector3.new(0, FLOAT_HEIGHT, 0)}
        local fadeGoal = {TextTransparency = 1}
        local strokeFadeGoal = {Transparency = 1}
        
        local floatTween = TweenService:Create(billboard, TweenInfo.new(TWEEN_DURATION, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), floatGoal)
        local fadeTween = TweenService:Create(textLabel, TweenInfo.new(TWEEN_DURATION * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), fadeGoal)
        local strokeFadeTween = TweenService:Create(stroke, TweenInfo.new(TWEEN_DURATION * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), strokeFadeGoal)
        
        floatTween:Play()
        
        -- Wait a bit before fading out so it stays solid for the first half of the animation
        task.delay(TWEEN_DURATION * 0.5, function()
            fadeTween:Play()
            strokeFadeTween:Play()
        end)
        
        -- Clean up
        task.delay(TWEEN_DURATION, function()
            if billboard then billboard:Destroy() end
        end)
    end)
end

return ReactionUI
