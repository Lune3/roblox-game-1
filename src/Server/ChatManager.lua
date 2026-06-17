local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatManager = {}

local activeChannels = {} -- To keep track of channels so we can destroy them
local activeAudioConnections = {} -- To keep track of voice wires

-- Helper to mute/unmute a character's public voice
local function setPublicVoiceVolume(character, volume)
    if not character then return end
    for _, child in ipairs(character:GetDescendants()) do
        if child:IsA("AudioEmitter") then
            child.Volume = volume
        end
    end
end

-- Helper to create a direct voice link
local function CreatePointToPointVoice(playerA, playerB)
    local connections = Instance.new("Folder")
    connections.Name = "PrivateVoice_" .. playerA.Name .. "_" .. playerB.Name
    connections.Parent = script
    
    -- Player A -> Player B
    local inputA = Instance.new("AudioDeviceInput")
    inputA.Player = playerA
    inputA.Parent = connections
    
    local outputB = Instance.new("AudioDeviceOutput")
    outputB.Player = playerB
    outputB.Parent = connections
    
    local wireAtoB = Instance.new("Wire")
    wireAtoB.SourceInstance = inputA
    wireAtoB.TargetInstance = outputB
    wireAtoB.Parent = connections
    
    -- Player B -> Player A
    local inputB = Instance.new("AudioDeviceInput")
    inputB.Player = playerB
    inputB.Parent = connections
    
    local outputA = Instance.new("AudioDeviceOutput")
    outputA.Player = playerA
    outputA.Parent = connections
    
    local wireBtoA = Instance.new("Wire")
    wireBtoA.SourceInstance = inputB
    wireBtoA.TargetInstance = outputA
    wireBtoA.Parent = connections
    
    return connections
end

-- Ensure the RemoteEvent exists
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ChatSwitchEvent = Shared:FindFirstChild("ChatSwitchEvent")
if not ChatSwitchEvent then
    ChatSwitchEvent = Instance.new("RemoteEvent")
    ChatSwitchEvent.Name = "ChatSwitchEvent"
    ChatSwitchEvent.Parent = Shared
end

function ChatManager.CreatePrivateSession(playerA, playerB)
    local textChannels = TextChatService:WaitForChild("TextChannels")
    
    local channelName = "Private_" .. playerA.UserId .. "_" .. playerB.UserId
    local privateChannel = Instance.new("TextChannel")
    privateChannel.Name = channelName
    privateChannel.Parent = textChannels
    
    -- Add the two players
    privateChannel:AddUserAsync(playerA.UserId)
    privateChannel:AddUserAsync(playerB.UserId)
    
    -- Tell both clients to switch to this channel
    ChatSwitchEvent:FireClient(playerA, privateChannel.Name)
    ChatSwitchEvent:FireClient(playerB, privateChannel.Name)
    
    -- Save the reference
    activeChannels[playerA] = privateChannel
    activeChannels[playerB] = privateChannel
    
    -- Mute public voice
    setPublicVoiceVolume(playerA.Character, 0)
    setPublicVoiceVolume(playerB.Character, 0)
    
    -- Create private voice connection
    local audioConnections = CreatePointToPointVoice(playerA, playerB)
    activeAudioConnections[playerA] = audioConnections
    activeAudioConnections[playerB] = audioConnections
end

function ChatManager.EndPrivateSession(playerA, playerB)
    local channel = activeChannels[playerA] or activeChannels[playerB]
    if channel then
        -- Tell clients to switch back to General
        if playerA and playerA.Parent then ChatSwitchEvent:FireClient(playerA, "RBXGeneral") end
        if playerB and playerB.Parent then ChatSwitchEvent:FireClient(playerB, "RBXGeneral") end
        
        channel:Destroy()
        if playerA then activeChannels[playerA] = nil end
        if playerB then activeChannels[playerB] = nil end
    end
    
    -- Handle Voice
    local audioConnections = activeAudioConnections[playerA] or activeAudioConnections[playerB]
    if audioConnections then
        audioConnections:Destroy()
        if playerA then
            activeAudioConnections[playerA] = nil
            setPublicVoiceVolume(playerA.Character, 1)
        end
        if playerB then
            activeAudioConnections[playerB] = nil
            setPublicVoiceVolume(playerB.Character, 1)
        end
    end
end

return ChatManager
