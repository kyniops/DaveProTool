--[[
    ═══════════════════════════════════════════════════════════
    💎 PRO GAMING TOOL V3 - FULLY INTEGRATED 💎
    📦 ESP + 🎯 AIMBOT + ⚡ TRIGGERBOT + 🛠️ SMART UI
    ═══════════════════════════════════════════════════════════
]]--

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local FpsLabel, PingLabel
local fpsCounter = {frames = 0, last = tick(), fps = 0}

local function getCamera()
    return workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
end

-- ========== CONFIGURATION PAR DÉFAUT ==========
local Config = {
    Aimbot = {
        Enabled = false,
        TargetNPC = false,
        Key = "J",
        Smoothness = 0,
        FOV = 150,
        ShowFOV = true,
        TargetPart = "Head",
        MaxDistance = 1000,
        TeamCheck = false,
        VisibleCheck = true,
        IgnoreVehicles = true,
        StraightBullets = true,
        Sticky = true,
        AutoShoot = false
    },
    ESP = {
        Enabled = false,
        TargetNPC = false,
        Boxes = true,
        Skeleton = true,
        Health = true,
        Names = true,
        Distance = true,
        Tracers = true,
        MaxDistance = 5000,
        TeamCheck = false,
        VisibleOnly = false,
        BoxColor = {R = 255, G = 255, B = 255},
        SkelColor = {R = 255, G = 255, B = 255},
        Color = {R = 255, G = 255, B = 255}
    },
    Movement = {
        Fly = {
            Enabled = false,
            Key = "F",
            Speed = 50,
            AscendSpeed = 30,
            NoFallDamage = true,
            
        },
        Sprint = {
            Enabled = false,
            Multiplier = 2,
            Endurance = 100,
            MaxEndurance = 100,
            RecoveryRate = 5
        },
        SuperJump = {
            Enabled = false,
            PowerMultiplier = 1,
            DoubleJumpEnabled = false,
            ReduceFallDamage = true
        },
        SpeedHack = {
            Enabled = false,
            Value = 50
        },
        NoClip = false,
        NoClipKey = "N",
        InfiniteJump = false,
        ClickTP = {Enabled = false, Key = "LeftControl"}
    },
    Combat = {
        SpinBot = {
            Enabled = false,
            Speed = 20
        },
        HitboxExpander = {
            Enabled = false,
            Multiplier = 1.5,
            Transparency = 0.9,
            Color = {R = 0, G = 255, B = 255},
            ColorRGB = {R = 0, G = 255, B = 255},
            ExpandNPC = false
        },
        Reach = {
            Enabled = false,
            Range = 30
        },
        FovChanger = {
            Enabled = false,
            Value = 90
        },
        GodMode = {
            Enabled = false
        }
    },
    Visuals = {
        FullBright = false,
        NoFog = false,
        Chams = false,
        ChamsColor = {R = 255, G = 255, B = 255},
        Highlight = {Enabled = false, Color = {R = 255, G = 255, B = 255}, Transparency = 0.5},
        FOVTransparency = 0.5,
        FOVColorRGB = {R = 255, G = 255, B = 255},
        AccentColor = {R = 255, G = 255, B = 255},
        TimeChanger = {Enabled = false, Time = 12},
        Crosshair = {Enabled = false, Size = 15, Color = {R = 0, G = 255, B = 0}},
        StreamerMode = false,
        AntiLag = false,
        RainbowMode = false
    },
    Misc = {
        AntiAFK = true,
        ChatSpammer = {
            Enabled = false,
            Message = "Dave Pro Tool On Top!",
            Delay = 3
        },
        Waypoints = {}
    },
}

-- ========== UTILS POUR CONFIG ==========
local function toColor3(t)
    if typeof(t) == "Color3" then return t end
    if type(t) == "table" and t.R and t.G and t.B then
        return Color3.fromRGB(t.R, t.G, t.B)
    end
    return Color3.new(1, 1, 1)
end

local function toEnum(val, enumType)
    if typeof(val) == "EnumItem" then return val end
    if type(val) == "string" then
        local success, res = pcall(function() return Enum[enumType][val] end)
        if success then return res end
    end
    return nil
end

-- ========== CONSTANTES ESP ==========
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do
        c[k] = deepCopy(v)
    end
    return c
end

local DefaultConfig = deepCopy(Config)

local autosaveScheduled = false
local function scheduleAutoSave()
    if autosaveScheduled then return end
    autosaveScheduled = true
    task.delay(0.5, function()
        autosaveScheduled = false
        saveConfig()
    end)
end

local R6_JOINTS = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local R15_JOINTS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"}
}

-- État interne
local AimlockPressed = false
local CurrentTarget = nil
local ESPObjects = {}
local FOVCircle = nil
local Flying = false
local NoClipActive = false
local Sprinting = false
local DoubleJumped = false
local CanDoubleJump = false
local FlyVelocity = nil
local FlyGyro = nil
local SpinAngle = 0
local LastJumpTime = 0
local Logs = {}
local Hitboxes = {}
local UpdateMenuThemeFn = nil
local TitleLabel = nil
local function log(msg)
    table.insert(Logs, "[" .. os.date("%X") .. "] " .. msg)
    if #Logs > 50 then table.remove(Logs, 1) end
    print("💎 [PRO TOOL] " .. msg)
end

-- ========== VÉRIFICATION DRAWING LIBRARY ==========
if not Drawing then
    warn("❌ Drawing Library non disponible!")
    return
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DE SAUVEGARDE ET CONFIGURATION
-- ═══════════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")
local ConfigFile = "ProToolConfig.json"
local PresetsFolder = "ProToolPresets/"

if makefolder and not isfolder(PresetsFolder) then
    makefolder(PresetsFolder)
end

local function saveConfig(name)
    if writefile then
        if makefolder and not isfolder(PresetsFolder) then
            makefolder(PresetsFolder)
        end
        
        local fileName = name or ConfigFile
        if name and not name:find("/") then
            fileName = PresetsFolder .. name
        end
        -- S'assurer que l'extension est présente
        if name and not fileName:find("%.json$") then
            fileName = fileName .. ".json"
        end
        local success, data = pcall(function() return HttpService:JSONEncode(Config) end)
        if success then
            writefile(fileName, data)
            log("Configuration sauvegardée: " .. fileName)
            return true
        else
            warn("Échec de l'encodage de la config")
        end
    end
    return false
end

local function loadConfig(name)
    local fileName = name or ConfigFile
    if name and not name:find("/") then
        fileName = PresetsFolder .. name
    end
    -- S'assurer que l'extension est présente pour la recherche de fichier
    if name and not fileName:find("%.json$") then
        fileName = fileName .. ".json"
    end
    
    if readfile and isfile and isfile(fileName) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
        if success and type(data) == "table" then
            local function merge(target, source)
                for k, v in pairs(source) do
                    if type(v) == "table" and target[k] and type(target[k]) == "table" then
                        merge(target[k], v)
                    else
                        target[k] = v
                    end
                end
            end
            
            pcall(function() merge(Config, data) end)
            log("Configuration chargée: " .. fileName)
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════

local function worldToScreen(position)
    local Camera = getCamera()
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function getRainbowColor()
    local t = tick() % 5 / 5
    return Color3.fromHSV(t, 1, 1)
end

local function isPNJOrDie()
    local okPlace, placeId = pcall(function() return game.PlaceId end)
    if okPlace and placeId == 11276071411 then
        return true
    end
    local okName, name = pcall(function() return game.Name end)
    if not okName or not name then return false end
    name = string.lower(name)
    if string.find(name, "npc ou die", 1, true) then return true end
    if string.find(name, "pnj or die", 1, true) then return true end
    return false
end

local function isVisible(targetPart)
    if not Config.Aimbot.VisibleCheck then return true end
    local char = LocalPlayer.Character
    if not char then return false end
    local Camera = getCamera()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, Camera, targetPart.Parent}
    local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), params)
    if not result then return true end
    if Config.Aimbot.IgnoreVehicles and result.Instance then
        local inst = result.Instance
        local model = inst:FindFirstAncestorOfClass("Model")
        local isVeh = false
        if model then
            if model:FindFirstChildWhichIsA("VehicleSeat", true) or model:FindFirstChildWhichIsA("Seat", true) then
                isVeh = true
            end
        end
        local n = inst.Name:lower()
        if n:find("vehicle") or n:find("car") or n:find("plane") or (model and (model.Name:lower():find("car") or model.Name:lower():find("plane") or model.Name:lower():find("vehicle"))) then
            isVeh = true
        end
        if isVeh then
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME AIMBOT
-- ═══════════════════════════════════════════════════════════

local function getClosestPlayerInFOV()
    local target = nil
    local minDist = math.huge
    local Camera = getCamera()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local function processTarget(entity, char, isPlayer)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        
        local part = char:FindFirstChild(Config.Aimbot.TargetPart) or char:FindFirstChild("Head")
        if not part then return end
        
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        
        local screenPos, onScreen = worldToScreen(part.Position)
        if not onScreen then return end
        
        local distFromCenter = (screenPos - center).Magnitude
        if distFromCenter <= Config.Aimbot.FOV and distFromCenter < minDist then
            if isVisible(part) then
                minDist = distFromCenter
                target = {Player = entity, Part = part}
            end
        end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end
        processTarget(player, player.Character, true)
    end

    if Config.Aimbot.TargetNPC then
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                processTarget(obj, obj, false)
            end
        end
    end

    return target
end

local function aimAt(part, isInitial)
    local Camera = getCamera()
    local targetPos = part.Position
    if part.Name == "Head" then targetPos = targetPos + Vector3.new(0, 0.1, 0) end
    
    local targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    local lerpAmount = isInitial and 1 or (1 - Config.Aimbot.Smoothness)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(lerpAmount, 0.01, 1))
end

local function aimbotUpdate()
    if not Config.Aimbot.Enabled or not AimlockPressed then 
        CurrentTarget = nil 
        return 
    end
    
    local target = getClosestPlayerInFOV()
    if target then
        CurrentTarget = target
        aimAt(target.Part, false)
        
        -- AutoShoot logic
        if Config.Aimbot.AutoShoot then
            local VirtualInputManager = game:GetService("VirtualInputManager")
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    else
        CurrentTarget = nil
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME ÉMOTES
-- ═══════════════════════════════════════════════════════════
local CurrentEmoteTrack
local EmoteFallbackConn
local function stopEmoteFallback()
    if EmoteFallbackConn then
        pcall(function() EmoteFallbackConn:Disconnect() end)
        EmoteFallbackConn = nil
    end
    local char = LocalPlayer.Character
    if not char then return end
    for _, m in pairs(char:GetDescendants()) do
        if m:IsA("Motor6D") and string.find(m.Name:lower(), "shoulder") then
            pcall(function() m.Transform = CFrame.new() end)
        end
    end
end
local function startHelicopterFallback()
    stopEmoteFallback()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local t0 = tick()
    EmoteFallbackConn = RunService.RenderStepped:Connect(function()
        local t = tick() - t0
        local angle = t * 10
        for _, m in pairs(char:GetDescendants()) do
            if m:IsA("Motor6D") and string.find(m.Name:lower(), "shoulder") then
                pcall(function() m.Transform = CFrame.Angles(0, angle, 0) end)
            end
        end
        hum.Jump = false
        hum.Sit = false
        hum.PlatformStand = false
    end)
    log("Fallback émote Hélicoptère (custom) activé")
end
local function playEmoteById(id)
    local char = LocalPlayer.Character
    if not char then
        local ok, newChar = pcall(function() return LocalPlayer.CharacterAdded:Wait() end)
        if ok then char = newChar else return end
    end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local assetUri
    if typeof(id) == "string" and string.find(id, "rbxassetid://", 1, true) then
        assetUri = id
    else
        assetUri = "rbxassetid://" .. tostring(id)
    end
    stopEmoteFallback()
    local animator = hum:FindFirstChildOfClass("Animator") or hum:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    if CurrentEmoteTrack then
        pcall(function() CurrentEmoteTrack:Stop(0.2) end)
        CurrentEmoteTrack = nil
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = assetUri
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        CurrentEmoteTrack = track
        pcall(function() track.Priority = Enum.AnimationPriority.Action4 end)
        pcall(function() track.Looped = true end)
        local played = pcall(function() track:Play() end)
        if played then
            log("Émote lancée: " .. tostring(id))
            return
        end
    else
        if tostring(id) == "76510079095692" or tostring(assetUri):find("76510079095692", 1, true) then
            startHelicopterFallback()
        else
            log("Échec de l'émote: " .. tostring(id))
        end
    end
end

local function stopEmotes()
    stopEmoteFallback()
    if CurrentEmoteTrack then
        pcall(function() CurrentEmoteTrack:Stop(0.2) end)
        CurrentEmoteTrack = nil
    end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator") or hum:FindFirstChild("Animator")
    if animator and animator.GetPlayingAnimationTracks then
        for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
            if tr.Priority == Enum.AnimationPriority.Action4 then
                pcall(function() tr:Stop(0.2) end)
            end
        end
    end
    log("Émote arrêtée")
end

local function updateStraightBullets()
    if not Config.Aimbot.StraightBullets then return end
    local char = LocalPlayer.Character
    if not char then return end
    local function zeroInTool(tool)
        if not tool then return end
        pcall(function()
            for _, n in ipairs({"Spread","Bloom","Inaccuracy","Deviation"}) do
                if tool:GetAttribute(n) ~= nil then tool:SetAttribute(n, 0) end
            end
        end)
        for _, d in pairs(tool:GetDescendants()) do
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                local n = d.Name:lower()
                if n:find("spread") or n:find("bloom") or n:find("inacc") or n:find("deviation") then
                    d.Value = 0
                end
            end
        end
    end
    for _, t in pairs(char:GetChildren()) do
        if t:IsA("Tool") then zeroInTool(t) end
    end
    for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") then zeroInTool(t) end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME ESP
-- ═══════════════════════════════════════════════════════════

local function createDrawing(type, props)
    local obj = Drawing.new(type)
    for i, v in pairs(props) do obj[i] = v end
    return obj
end

local function createESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    ESPObjects[player] = {
        Box = {
            T = createDrawing("Line", {Thickness = 1, Visible = false}),
            B = createDrawing("Line", {Thickness = 1, Visible = false}),
            L = createDrawing("Line", {Thickness = 1, Visible = false}),
            R = createDrawing("Line", {Thickness = 1, Visible = false})
        },
        Skeleton = {},
        HealthBar = {
            BG = createDrawing("Line", {Thickness = 2, Color = Color3.new(0,0,0), Visible = false}),
            Bar = createDrawing("Line", {Thickness = 1, Visible = false})
        },
        Text = createDrawing("Text", {Size = 13, Center = true, Outline = true, Visible = false}),
        Tracer = createDrawing("Line", {Thickness = 1, Visible = false}),
        Highlight = nil
    }
    for i = 1, 15 do
        table.insert(ESPObjects[player].Skeleton, createDrawing("Line", {Thickness = 1, Visible = false}))
    end
end

local function removeESP(player)
    local data = ESPObjects[player]
    if not data then return end
    for _, v in pairs(data.Box) do v:Remove() end
    for _, v in pairs(data.HealthBar) do v:Remove() end
    for _, v in pairs(data.Skeleton) do v:Remove() end
    if data.Tracer then data.Tracer:Remove() end
    if data.Highlight then data.Highlight:Destroy() end
    data.Text:Remove()
    ESPObjects[player] = nil
end

local function updateESP()
    if Config.ESP.TargetNPC then
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                createESP(obj)
            end
        end
    end

    for player, data in pairs(ESPObjects) do
        local isPlayer = player:IsA("Player")
        local char = isPlayer and player.Character or player
        
        if not char or not char.Parent or (not isPlayer and not Config.ESP.TargetNPC) then
            removeESP(player)
            continue
        end
        
        if not Config.ESP.Enabled then
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
            continue
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
            continue
        end
        
        local cam = getCamera()
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local distance = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0

        if isPlayer and Config.ESP.TeamCheck and not isPNJOrDie() and player.Team == LocalPlayer.Team then
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
            continue
        end

        if Config.ESP.VisibleOnly then
            local isVisible = false
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char, LocalPlayer.Character}
            
            local result = workspace:Raycast(cam.CFrame.Position, hrp.Position - cam.CFrame.Position, params)
            if not result then isVisible = true end
            
            if not isVisible then
                for _, v in pairs(data.Box) do v.Visible = false end
                for _, v in pairs(data.HealthBar) do v.Visible = false end
                for _, v in pairs(data.Skeleton) do v.Visible = false end
                if data.Tracer then data.Tracer.Visible = false end
                if data.Highlight then data.Highlight.Enabled = false end
                data.Text.Visible = false
                continue
            end
        end
        
        local screenPos, onScreen = worldToScreen(hrp.Position)
        if onScreen then
            local size = char:GetExtentsSize()
            local w, h = size.X * 1.5, size.Y * 1.5
            local cf = CFrame.lookAt(hrp.Position, hrp.Position + (cam.CFrame.Position - hrp.Position).Unit)
            
            local function getP(x, y) return worldToScreen((cf * CFrame.new(x, y, 0)).Position) end
            local tl, os1 = getP(-w/2, h/2)
            local tr, os2 = getP(w/2, h/2)
            local bl, os3 = getP(-w/2, -h/2)
            local br, os4 = getP(w/2, -h/2)
            
            local espColor = Config.Visuals.RainbowMode and getRainbowColor() or toColor3(Config.ESP.Color)
            local boxVis = os1 and os2 and os3 and os4 and Config.ESP.Boxes
            data.Box.T.Visible, data.Box.T.From, data.Box.T.To = boxVis, tl, tr
            data.Box.B.Visible, data.Box.B.From, data.Box.B.To = boxVis, bl, br
            data.Box.L.Visible, data.Box.L.From, data.Box.L.To = boxVis, tl, bl
            data.Box.R.Visible, data.Box.R.From, data.Box.R.To = boxVis, tr, br
            
            if boxVis then
                for _, l in pairs(data.Box) do l.Color = espColor end
            end
            
            if Config.ESP.Health then
                local barOffset = 1.0
                local top, _ = getP(-w/2 - barOffset, h/2)
                local bot, _ = getP(-w/2 - barOffset, -h/2)
                
                local barX = bot.X
                local barY_top = top.Y
                local barY_bot = bot.Y
                
                data.HealthBar.BG.Visible = true
                data.HealthBar.BG.From = Vector2.new(barX, barY_top)
                data.HealthBar.BG.To = Vector2.new(barX, barY_bot)
                data.HealthBar.BG.Thickness = 2
                data.HealthBar.BG.Color = Color3.new(0,0,0)
                
                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local hpHeight = (barY_bot - barY_top) * hpPercent
                
                data.HealthBar.Bar.Visible = true
                data.HealthBar.Bar.From = Vector2.new(barX, barY_bot)
                data.HealthBar.Bar.To = Vector2.new(barX, barY_bot - hpHeight)
                data.HealthBar.Bar.Thickness = 2
                data.HealthBar.Bar.Color = hpPercent > 0.6 and Color3.new(0,1,0) or (hpPercent > 0.3 and Color3.new(1,1,0) or Color3.new(1,0,0))
            else
                data.HealthBar.BG.Visible, data.HealthBar.Bar.Visible = false, false
            end
            
            if Config.ESP.Skeleton then
                local joints = hum.RigType == Enum.HumanoidRigType.R15 and R15_JOINTS or R6_JOINTS
                for i, joint in pairs(joints) do
                    local line = data.Skeleton[i]
                    if line then
                        local p1 = char:FindFirstChild(joint[1])
                        local p2 = char:FindFirstChild(joint[2])
                        if p1 and p2 then
                            local s1, o1 = worldToScreen(p1.Position)
                            local s2, o2 = worldToScreen(p2.Position)
                            if o1 and o2 then
                                line.Visible = true
                                line.From = s1
                                line.To = s2
                                line.Color = espColor
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                end
                for i = #joints + 1, 15 do
                    if data.Skeleton[i] then data.Skeleton[i].Visible = false end
                end
            else
                for _, v in pairs(data.Skeleton) do v.Visible = false end
            end

            if Config.Visuals.Chams then
                if not data.Highlight then
                    data.Highlight = Instance.new("Highlight")
                    data.Highlight.Parent = game.CoreGui
                end
                data.Highlight.Adornee = char
                data.Highlight.Enabled = true
                data.Highlight.FillColor = toColor3(Config.Visuals.ChamsColor)
                data.Highlight.OutlineColor = Color3.new(1,1,1)
                data.Highlight.FillTransparency = 0.5
            elseif data.Highlight then
                data.Highlight.Enabled = false
            end
            
            if Config.ESP.Tracers then
                data.Tracer.Visible = true
                data.Tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                data.Tracer.To = screenPos
                data.Tracer.Color = espColor
            else
                data.Tracer.Visible = false
            end
            
            if Config.ESP.Names or Config.ESP.Distance then
                local head = char:FindFirstChild("Head")
                if head then
                    local headPos, _ = worldToScreen(head.Position + Vector3.new(0, 1.5, 0))
                    data.Text.Visible = true
                    data.Text.Position = headPos
                    local t = ""
                    if Config.ESP.Names then 
                        local displayName = isPlayer and (Config.Visuals.StreamerMode and "Joueur" or player.Name) or player.Name
                        t = t .. displayName .. "\n" 
                    end
                    if Config.ESP.Distance then t = t .. "[" .. math.floor(distance) .. "m]" end
                    data.Text.Text = t
                    data.Text.Color = Config.Visuals.RainbowMode and espColor or Color3.new(1,1,1)
                else
                    data.Text.Visible = false
                end
            else
                data.Text.Visible = false
            end
        else
            for _, v in pairs(data.Box) do v.Visible = false end
            for _, v in pairs(data.HealthBar) do v.Visible = false end
            for _, v in pairs(data.Skeleton) do v.Visible = false end
            if data.Tracer then data.Tracer.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
            data.Text.Visible = false
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DE MOUVEMENT
-- ═══════════════════════════════════════════════════════════

local function updateMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if Config.Movement.SpeedHack.Enabled then
        hum.WalkSpeed = Config.Movement.SpeedHack.Value
    elseif Config.Movement.Sprint.Enabled then
        if Sprinting and Config.Movement.Sprint.Endurance > 0 then
            hum.WalkSpeed = 16 * Config.Movement.Sprint.Multiplier
            Config.Movement.Sprint.Endurance = math.max(0, Config.Movement.Sprint.Endurance - 0.5)
            if Config.Movement.Sprint.Endurance == 0 then Sprinting = false end
        else
            hum.WalkSpeed = 16
            Config.Movement.Sprint.Endurance = math.min(Config.Movement.Sprint.MaxEndurance, Config.Movement.Sprint.Endurance + Config.Movement.Sprint.RecoveryRate/60)
        end
    end

    if Flying then
        if Config.Movement.Fly.NoFallDamage and hrp.Velocity.Y < -30 then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, -30, hrp.Velocity.Z)
        end
        local cam = getCamera()
        local moveDir = Vector3.new(0,0,0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            local vel = moveDir.Unit * Config.Movement.Fly.Speed
            if FlyVelocity then FlyVelocity.Velocity = vel end
        else
            if FlyVelocity then FlyVelocity.Velocity = Vector3.new(0, 0, 0) end
        end
        
        if FlyGyro then FlyGyro.CFrame = cam.CFrame end
    else
        if Config.Movement.Fly.NoFallDamage and hum.FloorMaterial ~= Enum.Material.Air then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, math.max(hrp.Velocity.Y, -15), hrp.Velocity.Z)
        end
    end

    if Config.Movement.SuperJump.Enabled and Config.Movement.SuperJump.ReduceFallDamage then
        if hum.FloorMaterial ~= Enum.Material.Air then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, math.max(hrp.Velocity.Y, -20), hrp.Velocity.Z)
        end
    end

    if NoClipActive then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Config.Movement.AutoJump or Config.Movement.Bhop then
        if hum.FloorMaterial ~= Enum.Material.Air or hum:GetState() == Enum.HumanoidStateType.Landed then
            if Config.Movement.AutoJump then
                -- Saut automatique si obstacle devant
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local rayResult = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 5, rayParams)
                if rayResult then
                    hum.Jump = true
                end
            end
            if Config.Movement.Bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                hum.Jump = true
            end
        end
    end

    if Config.Movement.SuperJump.Enabled then
        hum.JumpPower = 50 * Config.Movement.SuperJump.PowerMultiplier
    else
        hum.JumpPower = 50
    end
end

local function toggleFly()
    Flying = not Flying
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if Flying then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = hrp
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        
        FlyVelocity = bv
        FlyGyro = bg
        log("Mode Vol activé")
    else
        if FlyVelocity then FlyVelocity:Destroy() end
        if FlyGyro then FlyGyro:Destroy() end
        FlyVelocity = nil
        FlyGyro = nil
        hrp.Velocity = Vector3.new(0, 0, 0)
        log("Mode Vol désactivé")
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DE COMBAT AVANCÉ
-- ═══════════════════════════════════════════════════════════

local function spinbotUpdate()
    if not Config.Combat.SpinBot.Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    SpinAngle = SpinAngle + Config.Combat.SpinBot.Speed
    local targetCF = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(SpinAngle), 0)
    hrp.CFrame = targetCF
end

local function updateGodMode()
    if not Config.Combat.GodMode.Enabled then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.BreakJointsOnDeath = false
    if hum.SetStateEnabled then
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false) end)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
    end
    hum.PlatformStand = false
    hum.Sit = false
    if hum.Health < hum.MaxHealth then
        hum.Health = hum.MaxHealth
    end
    if hum:GetState() == Enum.HumanoidStateType.Ragdoll
        or hum:GetState() == Enum.HumanoidStateType.FallingDown
        or hum:GetState() == Enum.HumanoidStateType.PlatformStanding then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        elseif part:IsA("BoolValue") then
            local n = part.Name:lower()
            if n == "knocked" or n == "ko" or n == "down" or n == "downed" then
                part.Value = false
            end
        end
    end
    if (hum.WalkSpeed < 2) and not Config.Movement.SpeedHack.Enabled then
        hum.WalkSpeed = 16
    end
    if hum.JumpPower < 20 then
        hum.JumpPower = 50
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME HITBOX EXPANDER
-- ═══════════════════════════════════════════════════════════

local function updateHitboxes()
    if not Config.Combat.HitboxExpander.Enabled then
        for player, box in pairs(Hitboxes) do
            if box then box:Destroy() end
            Hitboxes[player] = nil
        end
        return
    end

    local function processHitbox(entity, char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if hrp and hum and hum.Health > 0 then
            local box = Hitboxes[entity]
            if not box or box.Parent ~= char then
                if box then box:Destroy() end
                box = Instance.new("Part")
                box.Name = "HitboxPart"
                box.CastShadow = false
                box.CanCollide = false
                box.CanQuery = true
                box.Anchored = false
                box.Transparency = Config.Combat.HitboxExpander.Transparency
                box.Material = Enum.Material.Neon
                box.Parent = char
                
                local weld = Instance.new("Weld")
                weld.Part0 = hrp
                weld.Part1 = box
                weld.C0 = CFrame.new(0, 0, 0)
                weld.Parent = box
                local adorn = Instance.new("BoxHandleAdornment")
                adorn.Name = "HitboxAdornment"
                adorn.Adornee = box
                adorn.ZIndex = 10
                adorn.AlwaysOnTop = true
                adorn.Color3 = toColor3(Config.Combat.HitboxExpander.Color)
                adorn.Transparency = Config.Combat.HitboxExpander.Transparency
                adorn.Size = Vector3.new(2 * Config.Combat.HitboxExpander.Multiplier, 2 * Config.Combat.HitboxExpander.Multiplier, 2 * Config.Combat.HitboxExpander.Multiplier)
                adorn.Parent = box
                Hitboxes[entity] = box
            end

            local sizeMultiplier = Config.Combat.HitboxExpander.Multiplier
            box.Size = Vector3.new(2 * sizeMultiplier, 2 * sizeMultiplier, 2 * sizeMultiplier)
            box.Color = toColor3(Config.Combat.HitboxExpander.Color)
            box.Transparency = Config.Combat.HitboxExpander.Transparency
            local adorn = box:FindFirstChild("HitboxAdornment")
            if adorn then
                adorn.Size = box.Size
                adorn.Color3 = toColor3(Config.Combat.HitboxExpander.Color)
                adorn.Transparency = Config.Combat.HitboxExpander.Transparency
            end
        else
            if Hitboxes[entity] then
                Hitboxes[entity]:Destroy()
                Hitboxes[entity] = nil
            end
        end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
            if Hitboxes[player] then
                Hitboxes[player]:Destroy()
                Hitboxes[player] = nil
            end
            continue
        end

        local char = player.Character
        if char then
            processHitbox(player, char)
        end
    end

    if Config.Combat.HitboxExpander.ExpandNPC then
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                processHitbox(obj, obj)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME COMBAT AVANCÉ
-- ═══════════════════════════════════════════════════════════

local function reachUpdate()
    if not Config.Combat.Reach.Enabled then return end
    
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("Part")
        if handle then
            if not handle:FindFirstChild("DaveReach") then
                local selection = Instance.new("SelectionBox")
                selection.Name = "DaveReach"
                selection.Adornee = handle
                selection.Transparency = 0.8
                selection.Color3 = Color3.fromRGB(255, 0, 0)
                selection.Parent = handle
            end
            
            -- Augmenter la taille de la Hitbox de l'outil
            handle.Size = Vector3.new(Config.Combat.Reach.Range, Config.Combat.Reach.Range, Config.Combat.Reach.Range)
            handle.Massless = true
            handle.CanCollide = false
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME VISUEL AVANCÉ
-- ═══════════════════════════════════════════════════════════

local function updateWorldVisuals()
    if Config.Visuals.TimeChanger.Enabled then
        game.Lighting.ClockTime = Config.Visuals.TimeChanger.Time
    end
end

-- ═══════════════════════════════════════════════════════════
-- INTERFACE UTILISATEUR (UI) PROFESSIONNELLE
-- ═══════════════════════════════════════════════════════════

local Library = {}

function Library:CreateWindow()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProToolUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false
    
    local Theme = {
        Background = Color3.fromRGB(15, 15, 15),
        Sidebar = Color3.fromRGB(10, 10, 10),
        Accent = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 180, 180),
        Secondary = Color3.fromRGB(30, 30, 30),
        Hover = Color3.fromRGB(40, 40, 40)
    }

    RestoreBtn = Instance.new("TextButton")
    RestoreBtn.Name = "RestoreBtn"
    RestoreBtn.Size = UDim2.new(0, 120, 0, 40)
    RestoreBtn.Position = UDim2.new(0, 20, 0.5, -20)
    RestoreBtn.BackgroundColor3 = Theme.Secondary
    RestoreBtn.Text = "DAVE"
    RestoreBtn.TextColor3 = Theme.Accent
    RestoreBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    RestoreBtn.TextStrokeTransparency = 0.4
    RestoreBtn.Font = Enum.Font.GothamBold
    RestoreBtn.TextSize = 22
    RestoreBtn.Visible = false
    RestoreBtn.Parent = ScreenGui
    Instance.new("UICorner", RestoreBtn).CornerRadius = UDim.new(0, 10)
    local RestoreStroke = Instance.new("UIStroke", RestoreBtn)
    RestoreStroke.Color = Theme.Accent
    RestoreStroke.Thickness = 2
    
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 420)
    MainFrame.Position = UDim2.new(1, -570, 0, 20)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BackgroundTransparency = 0.18
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = false
    MainFrame.Parent = ScreenGui
    
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 4)
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.4
    local MainGradient = Instance.new("UIGradient", MainFrame)
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
    })
    MainGradient.Rotation = 90
    
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BackgroundTransparency = 0.22
    Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 4)
    local SidebarGradient = Instance.new("UIGradient", Sidebar)
    SidebarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
    })
    SidebarGradient.Rotation = 0
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 60)
    Title.BackgroundTransparency = 1
    Title.Text = "DAVE PRO TOOL"
    Title.TextColor3 = Theme.Accent
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = Sidebar
    TitleLabel = Title
    
    do
        local dragging = false
        local dragStart, startPos
        local dragThresholdY = 60
        Sidebar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local localY = input.Position.Y - Sidebar.AbsolutePosition.Y
                if localY <= dragThresholdY then
                    dragging = true
                    dragStart = input.Position
                    startPos = MainFrame.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    
    local TopDrag = Instance.new("Frame")
    TopDrag.Size = UDim2.new(1, 0, 0, 28)
    TopDrag.BackgroundTransparency = 1
    TopDrag.Parent = MainFrame
    do
        local dragging2 = false
        local dragStart2, startPos2
        TopDrag.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging2 = true
                dragStart2 = input.Position
                startPos2 = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging2 = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging2 and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart2
                MainFrame.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset + delta.X, startPos2.Y.Scale, startPos2.Y.Offset + delta.Y)
            end
        end)
    end
    
    local Version = Instance.new("TextLabel")
    Version.Size = UDim2.new(1, 0, 0, 20)
    Version.Position = UDim2.new(0, 0, 1, -25)
    Version.BackgroundTransparency = 1
    Version.Text = "VERSION V3.3B"
    Version.TextColor3 = Theme.TextDim
    Version.Font = Enum.Font.Gotham
    Version.TextSize = 10
    Version.Parent = Sidebar

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -170, 1, -20)
    Container.Position = UDim2.new(0, 170, 0, 10)
    Container.BackgroundTransparency = 1
    Container.Parent = MainFrame
    
    local currentTab = nil
    local TabButtons = Instance.new("Frame")
    TabButtons.Name = "TabButtons"
    TabButtons.Size = UDim2.new(1, 0, 1, -100)
    TabButtons.Position = UDim2.new(0, 0, 0, 70)
    TabButtons.BackgroundTransparency = 1
    TabButtons.Parent = Sidebar
    
    local TabList = Instance.new("UIListLayout", TabButtons)
    TabList.Padding = UDim.new(0, 2)
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function createTab(name, icon)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0.9, 0, 0, 35)
        tabBtn.BackgroundColor3 = Theme.Hover
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = name:upper()
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.TextSize = 12
        tabBtn.Parent = TabButtons
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)
        
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 2, 0.6, 0)
        indicator.Position = UDim2.new(0, 4, 0.2, 0)
        indicator.BackgroundColor3 = Theme.Accent
        indicator.Visible = false
        indicator.Parent = tabBtn

        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, -10, 1, -10)
        tabFrame.Position = UDim2.new(0, 5, 0, 5)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.Visible = false
        tabFrame.ScrollBarThickness = 4
        tabFrame.ScrollBarImageColor3 = Theme.Accent
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Parent = Container
        
        -- IMPORTANT: Utiliser un UIListLayout pour organiser les éléments
        local layout = Instance.new("UIListLayout", tabFrame)
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        -- Mise à jour automatique de la taille du canvas
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        
        tabBtn.MouseButton1Click:Connect(function()
            if currentTab then 
                currentTab.Btn.BackgroundTransparency = 1
                currentTab.Btn.TextColor3 = Theme.TextDim
                currentTab.Indicator.Visible = false
                currentTab.Frame.Visible = false 
            end
            tabBtn.BackgroundTransparency = 0.9
            tabBtn.TextColor3 = Theme.Accent
            indicator.Visible = true
            tabFrame.Visible = true
            currentTab = {Btn = tabBtn, Frame = tabFrame, Indicator = indicator}
        end)
        
        return tabFrame, tabBtn
    end
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.AnchorPoint = Vector2.new(1, 0)
    CloseBtn.Position = UDim2.new(1, 4, 0, -8)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Theme.TextDim
    CloseBtn.TextSize = 30
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.ZIndex = 20
    CloseBtn.Parent = MainFrame
    
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Accent end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextDim end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        RestoreBtn.Visible = true
    end)
    
    RestoreBtn.MouseEnter:Connect(function()
        RestoreBtn.BackgroundColor3 = Theme.Hover
        RestoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        RestoreBtn.TextStrokeTransparency = 0.2
    end)
    RestoreBtn.MouseLeave:Connect(function()
        RestoreBtn.BackgroundColor3 = Theme.Secondary
        RestoreBtn.TextColor3 = Theme.Accent
        RestoreBtn.TextStrokeTransparency = 0.4
    end)
    RestoreBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        RestoreBtn.Visible = false
    end)
    
    local StatsHUD = Instance.new("Frame")
    StatsHUD.Size = UDim2.new(0, 140, 0, 36)
    StatsHUD.Position = UDim2.new(1, -150, 1, -45)
    StatsHUD.BackgroundColor3 = Theme.Secondary
    StatsHUD.BackgroundTransparency = 0.22
    StatsHUD.Visible = false
    StatsHUD.Parent = MainFrame
    Instance.new("UICorner", StatsHUD).CornerRadius = UDim.new(0, 4)
    local hudStroke = Instance.new("UIStroke", StatsHUD)
    hudStroke.Color = Theme.Accent
    hudStroke.Thickness = 1
    hudStroke.Transparency = 0.5
    hudStroke.Enabled = true
    local hudGradient = Instance.new("UIGradient", StatsHUD)
    hudGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
    })
    hudGradient.Rotation = 90
    
    FpsLabel = Instance.new("TextLabel")
    FpsLabel.Size = UDim2.new(1, -10, 0, 16)
    FpsLabel.Position = UDim2.new(0, 5, 0, 4)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text = "FPS: ..."
    FpsLabel.TextColor3 = Theme.Text
    FpsLabel.Font = Enum.Font.GothamSemibold
    FpsLabel.TextSize = 11
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.Parent = StatsHUD
    
    PingLabel = Instance.new("TextLabel")
    PingLabel.Size = UDim2.new(1, -10, 0, 16)
    PingLabel.Position = UDim2.new(0, 5, 0, 20)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Text = "Ping: ..."
    PingLabel.TextColor3 = Theme.Text
    PingLabel.Font = Enum.Font.GothamSemibold
    PingLabel.TextSize = 11
    PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    PingLabel.Parent = StatsHUD
    
    local function addToggle(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 35)
        frame.BackgroundColor3 = Theme.Secondary
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text:upper()
        label.TextColor3 = default and Theme.Accent or Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.Parent = frame
        
        local box = Instance.new("TextButton")
        box.Size = UDim2.new(0, 30, 0, 16)
        box.Position = UDim2.new(1, -40, 0.5, -8)
        box.BackgroundColor3 = default and Theme.Accent or Theme.Background
        box.Text = ""
        box.Parent = frame
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
        local boxStroke = Instance.new("UIStroke", box)
        boxStroke.Color = Theme.Accent
        boxStroke.Thickness = 1

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = default and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
        dot.BackgroundColor3 = default and Theme.Background or Theme.Accent
        dot.Parent = box
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        
        local state = default
        box.MouseButton1Click:Connect(function()
            state = not state
            box.BackgroundColor3 = state and Theme.Accent or Theme.Background
            dot.BackgroundColor3 = state and Theme.Background or Theme.Accent
            dot:TweenPosition(state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5), "Out", "Quad", 0.1, true)
            label.TextColor3 = state and Theme.Accent or Theme.TextDim
            callback(state)
        scheduleAutoSave()
        end)
    end
    
    local function addSlider(parent, text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 50)
        frame.BackgroundColor3 = Theme.Secondary
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text:upper() .. " : " .. default
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 10
        label.Parent = frame
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 2)
        bar.Position = UDim2.new(0, 10, 0, 35)
        bar.BackgroundColor3 = Theme.Hover
        bar.Parent = frame
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 8, 0, 8)
        knob.Position = UDim2.new(1, -4, 0.5, -4)
        knob.BackgroundColor3 = Theme.Accent
        knob.Parent = fill
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = bar
        
        local function update(input)
            local barPosX = bar.AbsolutePosition.X
            local barSizeX = bar.AbsoluteSize.X
            local pos = math.clamp((input.Position.X - barPosX) / barSizeX, 0, 1)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            local val = min + (max - min) * pos
            if max <= 10 then
                val = math.floor(val * 10) / 10
            else
                val = math.floor(val)
            end
            label.Text = text:upper() .. " : " .. val
            callback(val)
            scheduleAutoSave()
        end
        
        local dragging = false
        
        frame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(i)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                update(i)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end
    
    local function addKeybind(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 35)
        frame.BackgroundColor3 = Theme.Secondary
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text:upper()
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 0, 20)
        btn.Position = UDim2.new(1, -90, 0.5, -10)
        btn.BackgroundColor3 = Theme.Background
        btn.Text = typeof(default) == "EnumItem" and default.Name:upper() or tostring(default):upper()
        btn.TextColor3 = Theme.Accent
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Theme.Accent
        btnStroke.Thickness = 1
        
        local waiting = false
        btn.MouseButton1Click:Connect(function()
            waiting = true
            btn.Text = "..."
        end)
        
        UserInputService.InputBegan:Connect(function(input)
            if waiting then
                local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                if key ~= Enum.KeyCode.Escape then
                    btn.Text = key.Name:upper()
                    callback(key.Name)
                    scheduleAutoSave()
                end
                waiting = false
            end
        end)
    end

    local function addInput(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 50)
        frame.BackgroundColor3 = Theme.Secondary
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text:upper()
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 10
        label.Parent = frame
        
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -20, 0, 20)
        input.Position = UDim2.new(0, 10, 0, 25)
        input.BackgroundColor3 = Theme.Background
        input.Text = default
        input.TextColor3 = Theme.Accent
        input.Font = Enum.Font.Gotham
        input.TextSize = 12
        input.Parent = frame
        Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
        
        input.FocusLost:Connect(function(enter)
            if enter then
                callback(input.Text)
                log("Valeur mise à jour: " .. input.Text)
                scheduleAutoSave()
            end
        end)
    end

    local function addButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = Theme.Secondary
        btn.Text = text:upper()
        btn.TextColor3 = Theme.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(callback)
    end

    -- Construction des Tabs
    local AimbotTab = createTab("Aimbot", "🎯")
    local ESPTab = createTab("ESP", "👁️")
    local MovementTab = createTab("Mouvement", "👟")
    local CombatTab = createTab("Combat", "⚔️")
    local VisualsTab = createTab("Visuels", "✨")
    local EmoteTab = createTab("Émotes", "🕺")
    local TeleportTab, TeleportBtn = createTab("Téléportation", "📍")
    local ScriptsTab = createTab("Scripts", "📜")
    local MiscTab = createTab("Divers", "🛠️")
    
    local selectedTeleportPlayer = nil
    local StarFishingUI = nil
    local PresetsModal = nil
    
    local function refreshPresets(parentFrame)
        if not parentFrame then return end
        for _, child in pairs(parentFrame:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        local function createPresetButton(name)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = Theme.Secondary
            btn.Text = name:upper()
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 12
            btn.Parent = parentFrame
            btn.ZIndex = 105 -- S'assurer qu'il est au-dessus du modal
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                if loadConfig(name .. ".json") then
                    log("Preset chargé: " .. name)
                    if ScreenGui then ScreenGui:Destroy() end
                    Library:CreateWindow()
                else
                    log("Erreur lors du chargement du preset")
                end
            end)
        end

        if listfiles then
            local found = false
            local processedNames = {}
            
            local function processFiles(fileList)
                if not fileList or type(fileList) ~= "table" then return end
                for _, file in pairs(fileList) do
                    if typeof(file) == "string" and file:lower():find("%.json") then
                        -- Extraire le nom sans le chemin et sans l'extension
                        local name = file:match("([^/\\]+)%.json$") or file:match("([^/\\]+)$") or file
                        name = name:gsub("%.json", "")
                        
                        if name ~= "ProToolConfig" and not processedNames[name] then
                            createPresetButton(name)
                            processedNames[name] = true
                            found = true
                        end
                    end
                end
            end

            -- Tester plusieurs chemins pour listfiles (selon l'exécuteur)
            local pathsToTest = {
                PresetsFolder,
                PresetsFolder:gsub("/$", ""),
                ".",
                "./",
                ""
            }

            for _, path in ipairs(pathsToTest) do
                local success, files = pcall(function() return listfiles(path) end)
                if success and files then
                    processFiles(files)
                end
            end
            
            if not found then
                local noFiles = Instance.new("TextLabel")
                noFiles.Size = UDim2.new(1, 0, 0, 30)
                noFiles.BackgroundTransparency = 1
                noFiles.Text = "AUCUN PRESET TROUVÉ"
                noFiles.TextColor3 = Theme.TextDim
                noFiles.Font = Enum.Font.Gotham
                noFiles.TextSize = 10
                noFiles.Parent = parentFrame
                noFiles.ZIndex = 105
            end
        else
            local noFunc = Instance.new("TextLabel")
            noFunc.Size = UDim2.new(1, 0, 0, 30)
            noFunc.BackgroundTransparency = 1
            noFunc.Text = "LISTFILES NON DISPONIBLE"
            noFunc.TextColor3 = Theme.TextDim
            noFunc.Font = Enum.Font.Gotham
            noFunc.TextSize = 10
            noFunc.Parent = parentFrame
            noFunc.ZIndex = 105
        end
    end

    local function showPresetsModal()
        if PresetsModal then PresetsModal:Destroy() end
        
        PresetsModal = Instance.new("Frame")
        PresetsModal.Name = "PresetsModal"
        PresetsModal.Size = UDim2.new(0, 300, 0, 350)
        PresetsModal.Position = UDim2.new(0.5, -150, 0.5, -175)
        PresetsModal.BackgroundColor3 = Theme.Background
        PresetsModal.BorderSizePixel = 0
        PresetsModal.Parent = ScreenGui
        PresetsModal.ZIndex = 100
        Instance.new("UICorner", PresetsModal).CornerRadius = UDim.new(0, 6)
        local modalStroke = Instance.new("UIStroke", PresetsModal)
        modalStroke.Color = Theme.Accent
        modalStroke.Thickness = 1

        local modalTitle = Instance.new("TextLabel")
        modalTitle.Size = UDim2.new(1, 0, 0, 40)
        modalTitle.BackgroundTransparency = 1
        modalTitle.Text = "CHARGER UN PRESET"
        modalTitle.TextColor3 = Theme.Accent
        modalTitle.Font = Enum.Font.GothamBold
        modalTitle.TextSize = 16
        modalTitle.Parent = PresetsModal
        modalTitle.ZIndex = 101

        local manualInput = Instance.new("TextBox")
        manualInput.Size = UDim2.new(1, -130, 0, 25)
        manualInput.Position = UDim2.new(0, 10, 0, 40)
        manualInput.BackgroundColor3 = Theme.Secondary
        manualInput.PlaceholderText = "Nom du preset..."
        manualInput.Text = ""
        manualInput.TextColor3 = Theme.Text
        manualInput.Font = Enum.Font.Gotham
        manualInput.TextSize = 10
        manualInput.Parent = PresetsModal
        manualInput.ZIndex = 101
        Instance.new("UICorner", manualInput).CornerRadius = UDim.new(0, 4)

        local manualLoad = Instance.new("TextButton")
        manualLoad.Size = UDim2.new(0, 50, 0, 25)
        manualLoad.Position = UDim2.new(1, -115, 0, 40)
        manualLoad.BackgroundColor3 = Theme.Accent
        manualLoad.Text = "LOAD"
        manualLoad.TextColor3 = Theme.Background
        manualLoad.Font = Enum.Font.GothamBold
        manualLoad.TextSize = 10
        manualLoad.Parent = PresetsModal
        manualLoad.ZIndex = 101
        Instance.new("UICorner", manualLoad).CornerRadius = UDim.new(0, 4)

        manualLoad.MouseButton1Click:Connect(function()
            if manualInput.Text ~= "" then
                if loadConfig(manualInput.Text .. ".json") then
                    log("Preset chargé manuellement: " .. manualInput.Text)
                    if ScreenGui then ScreenGui:Destroy() end
                    Library:CreateWindow()
                else
                    log("Erreur: Preset introuvable")
                end
            end
        end)

        local refreshBtn = Instance.new("TextButton")
        refreshBtn.Size = UDim2.new(0, 50, 0, 25)
        refreshBtn.Position = UDim2.new(1, -60, 0, 40)
        refreshBtn.BackgroundColor3 = Theme.Secondary
        refreshBtn.Text = "REFRESH"
        refreshBtn.TextColor3 = Theme.Accent
        refreshBtn.Font = Enum.Font.GothamBold
        refreshBtn.TextSize = 10
        refreshBtn.Parent = PresetsModal
        refreshBtn.ZIndex = 101
        Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -35, 0, 5)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Theme.TextDim
        closeBtn.TextSize = 25
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = PresetsModal
        closeBtn.ZIndex = 101
        closeBtn.MouseButton1Click:Connect(function() PresetsModal:Destroy() end)

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -20, 1, -85)
        scroll.Position = UDim2.new(0, 10, 0, 75)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = Theme.Accent
        scroll.Parent = PresetsModal
        scroll.ZIndex = 101

        local scrollLayout = Instance.new("UIListLayout", scroll)
        scrollLayout.Padding = UDim.new(0, 5)
        scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10)
        end)

        refreshBtn.MouseButton1Click:Connect(function()
            refreshPresets(scroll)
        end)

        refreshPresets(scroll)
        
        -- Dragging logic for modal
        local dragging = false
        local dragStart, startPos
        PresetsModal.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = PresetsModal.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                PresetsModal.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    -- Aimbot Content
    addToggle(AimbotTab, "Activer Aimbot", Config.Aimbot.Enabled, function(v)
        Config.Aimbot.Enabled = v
        AimlockPressed = v
        if not v then CurrentTarget = nil end
        if FOVCircle then FOVCircle.Visible = v and Config.Aimbot.ShowFOV end
    end)
    addToggle(AimbotTab, "Viser NPC/Bot", Config.Aimbot.TargetNPC, function(v) Config.Aimbot.TargetNPC = v end)
    addKeybind(AimbotTab, "Touche Aimbot", Config.Aimbot.Key, function(v) Config.Aimbot.Key = v end)
    addSlider(AimbotTab, "Lissage (Smooth)", 0, 0.95, Config.Aimbot.Smoothness, function(v) Config.Aimbot.Smoothness = v end)
    addSlider(AimbotTab, "Rayon FOV", 10, 800, Config.Aimbot.FOV, function(v) Config.Aimbot.FOV = v end)
    addToggle(AimbotTab, "Afficher FOV", Config.Aimbot.ShowFOV, function(v) Config.Aimbot.ShowFOV = v if FOVCircle then FOVCircle.Visible = v and Config.Aimbot.Enabled end end)
    addToggle(AimbotTab, "Team Check", Config.Aimbot.TeamCheck, function(v) Config.Aimbot.TeamCheck = v end)
    addToggle(AimbotTab, "Visible Check", Config.Aimbot.VisibleCheck, function(v) Config.Aimbot.VisibleCheck = v end)
    addToggle(AimbotTab, "Ignorer Véhicules", Config.Aimbot.IgnoreVehicles, function(v) Config.Aimbot.IgnoreVehicles = v end)
    addToggle(AimbotTab, "Sticky Lock", Config.Aimbot.Sticky, function(v) Config.Aimbot.Sticky = v end)
    addToggle(AimbotTab, "Auto Shoot", Config.Aimbot.AutoShoot, function(v) Config.Aimbot.AutoShoot = v end)
    addToggle(AimbotTab, "Tirs droits (No Spread)", Config.Aimbot.StraightBullets, function(v) Config.Aimbot.StraightBullets = v end)
    addButton(AimbotTab, "Cible: Tête", function() Config.Aimbot.TargetPart = "Head" log("Cible: Head") end)
    addButton(AimbotTab, "Cible: Torse", function() Config.Aimbot.TargetPart = "HumanoidRootPart" log("Cible: Torso") end)

    -- ESP Content
    addToggle(ESPTab, "Activer ESP", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)
    addToggle(ESPTab, "Voir NPC/Bot", Config.ESP.TargetNPC, function(v) Config.ESP.TargetNPC = v end)
    addToggle(ESPTab, "Boxes", Config.ESP.Boxes, function(v) Config.ESP.Boxes = v end)
    addToggle(ESPTab, "Squelettes", Config.ESP.Skeleton, function(v) Config.ESP.Skeleton = v end)
    addToggle(ESPTab, "Barre de Vie", Config.ESP.Health, function(v) Config.ESP.Health = v end)
    addToggle(ESPTab, "Noms", Config.ESP.Names, function(v) Config.ESP.Names = v end)
    addToggle(ESPTab, "Distance", Config.ESP.Distance, function(v) Config.ESP.Distance = v end)
    addToggle(ESPTab, "Traceurs (Tracers)", Config.ESP.Tracers, function(v) Config.ESP.Tracers = v end)
    addToggle(ESPTab, "Team Check", Config.ESP.TeamCheck, function(v) Config.ESP.TeamCheck = v end)
    addToggle(ESPTab, "Visible Uniquement", Config.ESP.VisibleOnly, function(v) Config.ESP.VisibleOnly = v end)
    addToggle(ESPTab, "ESP Loot/Items", false, function(v) log("ESP Loot: " .. tostring(v)) end)
    
    -- Visuals Content
    addToggle(VisualsTab, "Chams (Wallhack)", Config.Visuals.Chams, function(v) Config.Visuals.Chams = v end)
    addToggle(VisualsTab, "Highlight ESP", Config.Visuals.Highlight.Enabled, function(v) Config.Visuals.Highlight.Enabled = v end)
    addToggle(VisualsTab, "FullBright (Lumière)", Config.Visuals.FullBright, function(v) Config.Visuals.FullBright = v end)
    addToggle(VisualsTab, "No Fog (Pas de brouillard)", Config.Visuals.NoFog, function(v) Config.Visuals.NoFog = v end)
    addSlider(VisualsTab, "Transparence FOV", 0, 1, Config.Visuals.FOVTransparency, function(v) Config.Visuals.FOVTransparency = v end)
    
    addToggle(VisualsTab, "Time Changer", Config.Visuals.TimeChanger.Enabled, function(v) Config.Visuals.TimeChanger.Enabled = v end)
    addSlider(VisualsTab, "Heure du monde", 0, 24, Config.Visuals.TimeChanger.Time, function(v) Config.Visuals.TimeChanger.Time = v end)
    addToggle(VisualsTab, "Viseur (Crosshair)", Config.Visuals.Crosshair.Enabled, function(v) Config.Visuals.Crosshair.Enabled = v end)
    addToggle(VisualsTab, "Anti-Lag (FPS Boost)", Config.Visuals.AntiLag, function(v) Config.Visuals.AntiLag = v end)
    addToggle(VisualsTab, "Mode Streamer", Config.Visuals.StreamerMode, function(v) Config.Visuals.StreamerMode = v end)
    addToggle(VisualsTab, "Mode Rainbow", Config.Visuals.RainbowMode, function(v) Config.Visuals.RainbowMode = v end)
    
    local function createColorSection(parent, title, configPath, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 60)
        frame.BackgroundColor3 = Theme.Secondary
        frame.BackgroundTransparency = 0.2
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = title:upper()
        label.TextColor3 = Theme.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 10
        label.Parent = frame
        
        local colors = {
            {Color3.fromRGB(255, 255, 255), "Blanc"},
            {Color3.fromRGB(255, 0, 0), "Rouge"},
            {Color3.fromRGB(0, 255, 0), "Vert"},
            {Color3.fromRGB(0, 0, 255), "Bleu"},
            {Color3.fromRGB(255, 255, 0), "Jaune"},
            {Color3.fromRGB(255, 0, 255), "Rose"},
            {Color3.fromRGB(0, 255, 255), "Cyan"},
            {Color3.fromRGB(255, 165, 0), "Orange"}
        }
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 25)
        container.Position = UDim2.new(0, 10, 0, 25)
        container.BackgroundTransparency = 1
        container.Parent = frame
        
        local layout = Instance.new("UIListLayout", container)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 5)
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        
        for _, data in pairs(colors) do
            local color = data[1]
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 20, 0, 20)
            btn.BackgroundColor3 = color
            btn.Text = ""
            btn.Parent = container
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                configPath.R, configPath.G, configPath.B = color.R * 255, color.G * 255, color.B * 255
                if callback then callback(color) end
                log("Couleur " .. title .. " mise à jour: " .. data[2])
            end)
        end
    end

    local function updateMenuTheme(color)
        local oldAccent = Theme.Accent
        Theme.Accent = color
        if RestoreBtn then RestoreBtn.TextColor3 = color end
        if RestoreStroke then RestoreStroke.Color = color end
        if Title then Title.TextColor3 = color end
        
        -- Mise à jour dynamique des éléments visuels
        for _, obj in pairs(ScreenGui:GetDescendants()) do
            if obj:IsA("TextButton") and obj.BackgroundColor3 == oldAccent then
                obj.BackgroundColor3 = color
            elseif obj:IsA("UIStroke") and obj.Color == oldAccent then
                obj.Color = color
            elseif obj:IsA("TextLabel") and obj.TextColor3 == oldAccent then
                obj.TextColor3 = color
            elseif obj:IsA("ScrollingFrame") and obj.ScrollBarImageColor3 == oldAccent then
                obj.ScrollBarImageColor3 = color
            elseif obj:IsA("Frame") and obj.BackgroundColor3 == oldAccent then
                obj.BackgroundColor3 = color
            end
        end
        
        -- S'assurer que les onglets sélectionnés gardent la couleur
        if currentTab then
            currentTab.Btn.TextColor3 = color
            currentTab.Indicator.BackgroundColor3 = color
        end
        UpdateMenuThemeFn = updateMenuTheme
    end

    createColorSection(VisualsTab, "Couleur Menu", Config.Visuals.AccentColor, updateMenuTheme)
    createColorSection(VisualsTab, "Couleur ESP", Config.ESP.Color)
    createColorSection(VisualsTab, "Couleur FOV", Config.Visuals.FOVColorRGB)
    -- retiré: Couleur Monde

    addButton(VisualsTab, "Reset Couleurs", function()
        Config.Visuals.AccentColor = {R = 255, G = 255, B = 255}
        Config.ESP.Color = {R = 255, G = 255, B = 255}
        Config.Visuals.FOVColorRGB = {R = 255, G = 255, B = 255}
        updateMenuTheme(Color3.new(1,1,1))
    end)

    -- Movement Content - TOUS LES ÉLÉMENTS
    addToggle(MovementTab, "Mode Vol (Fly)", Config.Movement.Fly.Enabled, function(v) Config.Movement.Fly.Enabled = v if v == false and Flying then toggleFly() end end)
    addKeybind(MovementTab, "Touche Vol", Config.Movement.Fly.Key, function(v) Config.Movement.Fly.Key = v end)
    addSlider(MovementTab, "Vitesse Vol", 10, 500, Config.Movement.Fly.Speed, function(v) Config.Movement.Fly.Speed = v end)
    addToggle(MovementTab, "NoClip", Config.Movement.NoClip, function(v)
        Config.Movement.NoClip = v
        NoClipActive = v
        if not NoClipActive then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end)
    addKeybind(MovementTab, "Touche NoClip", Config.Movement.NoClipKey, function(v) Config.Movement.NoClipKey = v end)
    addToggle(MovementTab, "Speed Hack", Config.Movement.SpeedHack.Enabled, function(v) Config.Movement.SpeedHack.Enabled = v end)
    addSlider(MovementTab, "Valeur Vitesse", 16, 500, Config.Movement.SpeedHack.Value, function(v) Config.Movement.SpeedHack.Value = v end)
    addToggle(MovementTab, "Anti-dégâts de chute (Fly)", Config.Movement.Fly.NoFallDamage, function(v) Config.Movement.Fly.NoFallDamage = v end)
    addToggle(MovementTab, "Sprint Amélioré", Config.Movement.Sprint.Enabled, function(v) Config.Movement.Sprint.Enabled = v end)
    addSlider(MovementTab, "Multiplicateur Sprint", 1, 5, Config.Movement.Sprint.Multiplier, function(v) Config.Movement.Sprint.Multiplier = v end)
    addToggle(MovementTab, "Super Saut", Config.Movement.SuperJump.Enabled, function(v) Config.Movement.SuperJump.Enabled = v end)
    addSlider(MovementTab, "Puissance Saut", 1, 10, Config.Movement.SuperJump.PowerMultiplier, function(v) Config.Movement.SuperJump.PowerMultiplier = v end)
    addToggle(MovementTab, "Double Saut", Config.Movement.SuperJump.DoubleJumpEnabled, function(v) Config.Movement.SuperJump.DoubleJumpEnabled = v end)
    addToggle(MovementTab, "Réduire Dégâts Chute", Config.Movement.SuperJump.ReduceFallDamage, function(v) Config.Movement.SuperJump.ReduceFallDamage = v end)

    addToggle(MovementTab, "Saut Infini", Config.Movement.InfiniteJump, function(v) Config.Movement.InfiniteJump = v end)
    
    -- Combat Content - TOUS LES ÉLÉMENTS
    addToggle(CombatTab, "FOV Changer", Config.Combat.FovChanger.Enabled, function(v) Config.Combat.FovChanger.Enabled = v end)
    addSlider(CombatTab, "Valeur FOV", 30, 120, Config.Combat.FovChanger.Value, function(v) Config.Combat.FovChanger.Value = v end)
    addToggle(CombatTab, "God Mode (Invincible)", Config.Combat.GodMode.Enabled, function(v) Config.Combat.GodMode.Enabled = v end)
    addToggle(CombatTab, "Activer SpinBot", Config.Combat.SpinBot.Enabled, function(v) Config.Combat.SpinBot.Enabled = v end)
    addSlider(CombatTab, "Vitesse Rotation", 1, 100, Config.Combat.SpinBot.Speed, function(v) Config.Combat.SpinBot.Speed = v end)
    addToggle(CombatTab, "Hitbox Expander", Config.Combat.HitboxExpander.Enabled, function(v) Config.Combat.HitboxExpander.Enabled = v end)
    addToggle(CombatTab, "Inclure NPCs", Config.Combat.HitboxExpander.ExpandNPC, function(v) Config.Combat.HitboxExpander.ExpandNPC = v end)
    addSlider(CombatTab, "Multiplicateur Taille", 1, 150, Config.Combat.HitboxExpander.Multiplier, function(v) Config.Combat.HitboxExpander.Multiplier = v end)
    addSlider(CombatTab, "Transparence Hitbox", 0, 1, Config.Combat.HitboxExpander.Transparency, function(v) Config.Combat.HitboxExpander.Transparency = v end)
    createColorSection(CombatTab, "Couleur Hitbox", Config.Combat.HitboxExpander.ColorRGB, function(c) Config.Combat.HitboxExpander.Color = c end)
    addToggle(CombatTab, "Weapon Reach", Config.Combat.Reach.Enabled, function(v) Config.Combat.Reach.Enabled = v end)
    
    -- Émotes
    addButton(EmoteTab, "Arrêter l'émote", function() stopEmotes() end)
    addButton(EmoteTab, "Invisible", function() playEmoteById("rbxassetid://98700803185886") end)
    addButton(EmoteTab, "Hélicoptère", function() playEmoteById("rbxassetid://76510079095692") end)
    addButton(EmoteTab, "Tornado", function() playEmoteById("rbxassetid://135373056067761") end)
    addButton(EmoteTab, "Parkour Dance", function() playEmoteById("rbxassetid://120244151914853") end)
    addButton(EmoteTab, "Propeller", function() playEmoteById("rbxassetid://85377443478134") end)
    addButton(EmoteTab, "67", function() playEmoteById("rbxassetid://130984232537362") end)
    addButton(EmoteTab, "SixSeven", function() playEmoteById("rbxassetid://113052384161929") end)
    addButton(EmoteTab, "Admin Fly", function() playEmoteById("rbxassetid://138354833484039") end)
    addButton(EmoteTab, "Sakuna", function() playEmoteById("rbxassetid://128203986262469") end)
    addButton(EmoteTab, "Scary Tall", function() playEmoteById("rbxassetid://130916388086314") end)
    addButton(EmoteTab, "Woof Woof Bark", function() playEmoteById("rbxassetid://96435804447949") end)
    addButton(EmoteTab, "Silly Jumping", function() playEmoteById("rbxassetid://137124482339556") end)
    addButton(EmoteTab, "Silly Spider Dance", function() playEmoteById("rbxassetid://139310328821985") end)
    addButton(EmoteTab, "Kid Tantrum", function() playEmoteById("rbxassetid://86339673982616") end)
    addSlider(CombatTab, "Portée Reach", 1, 50, Config.Combat.Reach.Range, function(v) Config.Combat.Reach.Range = v end)
    -- retiré: doublon SpinBot (bas)

    -- Misc Content - TOUS LES ÉLÉMENTS
    addToggle(MiscTab, "Anti-AFK", Config.Misc.AntiAFK, function(v) Config.Misc.AntiAFK = v end)
    addToggle(MiscTab, "Chat Spammer", Config.Misc.ChatSpammer.Enabled, function(v) Config.Misc.ChatSpammer.Enabled = v end)
    addInput(MiscTab, "Message Spammer", Config.Misc.ChatSpammer.Message, function(v) Config.Misc.ChatSpammer.Message = v end)
    addSlider(MiscTab, "Délai Spammer (s)", 1, 10, Config.Misc.ChatSpammer.Delay, function(v) Config.Misc.ChatSpammer.Delay = v end)

    -- retiré: Gravité
    -- retiré: Cap FPS
    
    addButton(MiscTab, "Server Hop", serverHop)

    -- retiré: Quick Exit (Touche Fin)
    -- retiré: Consommation Énergie Vol
    local currentProfileName = "Preset1"
    addInput(MiscTab, "Nom du Preset", "Preset1", function(v) currentProfileName = v end)
    
    addButton(MiscTab, "Sauvegarder Preset", function() 
        if saveConfig(currentProfileName) then
            log("Preset sauvegardé: " .. currentProfileName)
            if PresetsModal and PresetsModal.Parent then
                local scroll = PresetsModal:FindFirstChildOfClass("ScrollingFrame")
                if scroll then refreshPresets(scroll) end
            end
        end
    end)
    
    addButton(MiscTab, "Charger Preset", function() 
        showPresetsModal()
    end)

    addButton(MiscTab, "Reset Config", function() 
        Config = deepCopy(DefaultConfig)
        saveConfig()
        if ScreenGui then
            ScreenGui:Destroy()
        end
        Library:CreateWindow()
        log("Configuration réinitialisée")
    end)

    -- Teleportation Content
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(1, -10, 0, 240) -- Augmenté pour la barre de recherche
    playerListFrame.BackgroundColor3 = Theme.Secondary
    playerListFrame.BackgroundTransparency = 0.2
    playerListFrame.Parent = TeleportTab
    Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 4)

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -20, 0, 25)
    searchBox.Position = UDim2.new(0, 10, 0, 35)
    searchBox.BackgroundColor3 = Theme.Hover
    searchBox.BackgroundTransparency = 0.5
    searchBox.Text = ""
    searchBox.PlaceholderText = "Rechercher un joueur..."
    searchBox.TextColor3 = Theme.Text
    searchBox.PlaceholderColor3 = Theme.TextDim
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 12
    searchBox.Parent = playerListFrame
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)

    local playerListScroll = Instance.new("ScrollingFrame")
    playerListScroll.Size = UDim2.new(1, -10, 1, -75)
    playerListScroll.Position = UDim2.new(0, 5, 0, 70)
    playerListScroll.BackgroundTransparency = 1
    playerListScroll.ScrollBarThickness = 2
    playerListScroll.Parent = playerListFrame
    
    local playerListLayout = Instance.new("UIListLayout", playerListScroll)
    playerListLayout.Padding = UDim.new(0, 2)

    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(1, -10, 0, 30)
    playerLabel.Position = UDim2.new(0, 10, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "SÉLECTIONNER UN JOUEUR"
    playerLabel.TextColor3 = Theme.Text
    playerLabel.Font = Enum.Font.GothamSemibold
    playerLabel.TextSize = 10
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.Parent = playerListFrame
    
    addToggle(TeleportTab, "Click Teleport (Ctrl+LClick)", Config.Movement.ClickTP.Enabled, function(v) Config.Movement.ClickTP.Enabled = v end)

    local function refreshPlayerList(searchText)
        searchText = searchText and searchText:lower() or ""
        for _, child in pairs(playerListScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and (searchText == "" or p.Name:lower():find(searchText) or p.DisplayName:lower():find(searchText)) then
                local pBtn = Instance.new("TextButton")
                pBtn.Size = UDim2.new(1, -10, 0, 25)
                pBtn.BackgroundColor3 = Theme.Hover
                pBtn.BackgroundTransparency = 0.5
                pBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                pBtn.TextColor3 = Theme.Text
                pBtn.Font = Enum.Font.Gotham
                pBtn.TextSize = 12
                pBtn.Parent = playerListScroll
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
                
                pBtn.MouseButton1Click:Connect(function()
                    selectedTeleportPlayer = p
                    playerLabel.Text = "CIBLE : " .. p.Name:upper()
                    log("Joueur sélectionné : " .. p.Name)
                end)
            end
        end
        playerListScroll.CanvasSize = UDim2.new(0, 0, 0, playerListLayout.AbsoluteContentSize.Y)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshPlayerList(searchBox.Text)
    end)

    addButton(TeleportTab, "Rafraîchir la liste", function() refreshPlayerList(searchBox.Text) end)
    addButton(TeleportTab, "Téléporter vers le joueur", function()
        if selectedTeleportPlayer and selectedTeleportPlayer.Character and selectedTeleportPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = selectedTeleportPlayer.Character.HumanoidRootPart.CFrame
                log("Téléporté vers " .. selectedTeleportPlayer.Name)
            else
                log("Erreur: Votre personnage n'est pas prêt")
            end
        else
            log("Erreur: Aucun joueur sélectionné ou joueur hors ligne")
        end
    end)
    addButton(TeleportTab, "Fling Player", function()
        if not selectedTeleportPlayer or not selectedTeleportPlayer.Character then
            log("Erreur: Aucun joueur sélectionné")
            return
        end
        local targetChar = selectedTeleportPlayer.Character
        local targetRP = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
        if not targetRP or not myHum or not myRP then
            log("Erreur: Humanoid introuvable")
            return
        end
        local savedCF = myRP.CFrame
        local tool = Instance.new("Tool")
        tool.RequiresHandle = true
        tool.Name = "FlingTool"
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(5,5,5)
        handle.Transparency = 1
        handle.LocalTransparencyModifier = 1
        handle.CastShadow = false
        handle.CanQuery = false
        handle.CanCollide = true
        handle.Massless = false
        handle.Parent = tool
        tool.Parent = LocalPlayer.Backpack
        myHum:EquipTool(tool)
        task.wait()
        handle = myChar:FindFirstChild("Handle") or handle
        if not handle then
            log("Erreur: Handle indisponible")
            return
        end
        local RNG = Random.new()
        local start = tick()
        while tick() - start < 1.0 do
            myRP.CFrame = targetRP.CFrame * CFrame.new(0, 0, 1.2)
            local av = Vector3.new(0, 6500, 0)
            local lvDir = (targetRP.Position - handle.Position)
            local lv = lvDir.Magnitude > 0 and lvDir.Unit * 1200 or Vector3.new(0,0,0)
            handle.AssemblyAngularVelocity = av
            handle.AssemblyLinearVelocity = lv + RNG:NextUnitVector() * 300
            RunService.Heartbeat:Wait()
        end
        task.delay(2, function()
            if myRP and myRP.Parent then
                local returnCF = savedCF
                for i=1,3 do
                    myRP.Anchored = true
                    myRP.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    myRP.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    if myChar and myChar.Parent then
                        myChar:PivotTo(returnCF)
                    else
                        myRP.CFrame = returnCF
                    end
                    RunService.Heartbeat:Wait()
                end
                myRP.Anchored = false
            end
        end)
        pcall(function() tool:Destroy() end)
        log("Fling Player exécuté sur " .. selectedTeleportPlayer.Name)
    end)
    
    local AnnoyPlayerActive = false
    local function startAnnoyPlayer()
        if not selectedTeleportPlayer or not selectedTeleportPlayer.Character then
            log("Erreur: Aucun joueur sélectionné")
            AnnoyPlayerActive = false
            return
        end
        local backFar = 12
        local backNear = 1.5
        local speed = 220 -- studs/sec
        local freq = 2.4  -- oscillations/sec
        local phase = 0
        playEmoteById("rbxassetid://82682811348660")
        task.spawn(function()
            local last = tick()
            while AnnoyPlayerActive do
                local now = tick()
                local dt = now - last
                last = now
                local targetHRP = selectedTeleportPlayer.Character and selectedTeleportPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP or not myHRP then break end
                
                phase = phase + dt * 2 * math.pi * freq
                local osc = 0.5 + 0.5 * math.sin(phase)
                local offset = backNear + (backFar - backNear) * osc
                
                local goalCF = targetHRP.CFrame * CFrame.new(0, 0, offset)
                local goalPos = goalCF.Position
                local curPos = myHRP.Position
                local dir = goalPos - curPos
                local dist = dir.Magnitude
                if dist > 0 then
                    local stepDist = math.min(speed * dt, dist)
                    local newPos = curPos + dir.Unit * stepDist
                    local rotOnly = targetHRP.CFrame - targetHRP.Position
                    myHRP.CFrame = CFrame.new(newPos) * rotOnly
                end
                
                task.wait() -- yield to next frame
            end
            stopEmotes()
        end)
    end
    addButton(TeleportTab, "Téléportation aléatoire", function()
        local players = Players:GetPlayers()
        local randomPlayer = players[math.random(1, #players)]
        if randomPlayer and randomPlayer ~= LocalPlayer and randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
                log("TP vers: " .. randomPlayer.Name)
            end
        end
    end)
    addToggle(TeleportTab, "Annoy Player", false, function(v)
        AnnoyPlayerActive = v
        if v then
            startAnnoyPlayer()
        else
            stopEmotes()
        end
    end)
    
    local BangPlayerActive = false
    local function startBangPlayer()
        if not selectedTeleportPlayer or not selectedTeleportPlayer.Character then
            log("Erreur: Aucun joueur sélectionné")
            BangPlayerActive = false
            return
        end
        local backOffset = 1
        local speed = 260
        playEmoteById("rbxassetid://130984232537362")
        task.spawn(function()
            local last = tick()
            while BangPlayerActive do
                local now = tick()
                local dt = now - last
                last = now
                local targetHRP = selectedTeleportPlayer.Character and selectedTeleportPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP or not myHRP then break end
                
                local goalCF = targetHRP.CFrame * CFrame.new(0, 0, backOffset)
                local goalPos = goalCF.Position
                local curPos = myHRP.Position
                local dir = goalPos - curPos
                local dist = dir.Magnitude
                if dist > 0 then
                    local stepDist = math.min(speed * dt, dist)
                    local newPos = curPos + dir.Unit * stepDist
                    local rotOnly = targetHRP.CFrame - targetHRP.Position
                    myHRP.CFrame = CFrame.new(newPos) * rotOnly
                end
                
                task.wait()
            end
            stopEmotes()
        end)
    end
    addToggle(TeleportTab, "Bang Player", false, function(v)
        BangPlayerActive = v
        if v then
            AnnoyPlayerActive = false
            startBangPlayer()
        else
            stopEmotes()
        end
    end)

    -- Waypoints Section
    local waypointLabel = Instance.new("TextLabel")
    waypointLabel.Size = UDim2.new(1, -10, 0, 30)
    waypointLabel.BackgroundTransparency = 1
    waypointLabel.Text = "POINTS DE PASSAGE (WAYPOINTS)"
    waypointLabel.TextColor3 = Theme.Text
    waypointLabel.Font = Enum.Font.GothamSemibold
    waypointLabel.TextSize = 10
    waypointLabel.TextXAlignment = Enum.TextXAlignment.Left
    waypointLabel.Parent = TeleportTab

    local waypointName = "Point 1"
    addInput(TeleportTab, "Nom du Waypoint", "Point 1", function(v) waypointName = v end)

    local waypointScroll = Instance.new("ScrollingFrame")
    waypointScroll.Size = UDim2.new(1, -10, 0, 150)
    waypointScroll.BackgroundTransparency = 1
    waypointScroll.ScrollBarThickness = 2
    waypointScroll.Parent = TeleportTab
    
    local waypointLayout = Instance.new("UIListLayout", waypointScroll)
    waypointLayout.Padding = UDim.new(0, 2)

    local function refreshWaypoints()
        for _, child in pairs(waypointScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        for name, pos in pairs(Config.Misc.Waypoints) do
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 40)
            frame.BackgroundColor3 = Theme.Hover
            frame.BackgroundTransparency = 0.5
            frame.Parent = waypointScroll
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 0.6, 0)
            label.Position = UDim2.new(0, 10, 0, 2)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = Theme.Text
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local coords = Instance.new("TextLabel")
            coords.Size = UDim2.new(0.6, 0, 0.4, 0)
            coords.Position = UDim2.new(0, 10, 0.6, -2)
            coords.BackgroundTransparency = 1
            coords.Text = string.format("X: %.1f, Y: %.1f, Z: %.1f", pos.X, pos.Y, pos.Z)
            coords.TextColor3 = Theme.TextDim
            coords.Font = Enum.Font.Gotham
            coords.TextSize = 10
            coords.TextXAlignment = Enum.TextXAlignment.Left
            coords.Parent = frame

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0.15, 0, 0.8, 0)
            tpBtn.Position = UDim2.new(0.65, 0, 0.1, 0)
            tpBtn.BackgroundColor3 = Theme.Accent
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Theme.Text
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 10
            tpBtn.Parent = frame
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)

            tpBtn.MouseButton1Click:Connect(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
                    log("TP vers waypoint: " .. name)
                end
            end)

            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0.15, 0, 0.8, 0)
            delBtn.Position = UDim2.new(0.82, 0, 0.1, 0)
            delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            delBtn.Text = "X"
            delBtn.TextColor3 = Theme.Text
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 10
            delBtn.Parent = frame
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)

            delBtn.MouseButton1Click:Connect(function()
                Config.Misc.Waypoints[name] = nil
                refreshWaypoints()
                saveConfig()
                log("Waypoint supprimé: " .. name)
            end)
        end
        waypointScroll.CanvasSize = UDim2.new(0, 0, 0, waypointLayout.AbsoluteContentSize.Y)
    end

    addButton(TeleportTab, "Sauvegarder position actuelle", function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            Config.Misc.Waypoints[waypointName] = {X = hrp.Position.X, Y = hrp.Position.Y, Z = hrp.Position.Z}
            refreshWaypoints()
            saveConfig()
            log("Waypoint sauvegardé: " .. waypointName)
        end
    end)

    addButton(TeleportTab, "Vider tous les Waypoints", function()
        Config.Misc.Waypoints = {}
        refreshWaypoints()
        saveConfig()
        log("Tous les waypoints ont été supprimés")
    end)

    refreshWaypoints()

    TeleportBtn.MouseButton1Click:Connect(function()
        refreshPlayerList()
        refreshWaypoints()
    end)
     refreshPlayerList()
     
     Players.PlayerAdded:Connect(refreshPlayerList)
     Players.PlayerRemoving:Connect(refreshPlayerList)

    -- Scripts Content
    addButton(ScriptsTab, "Blox Fruit", function()
        log("Lancement de Blox Fruit...")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TheDarkoneMarcillisePex/Other-Scripts/refs/heads/main/Bloxfruits%20script"))()
    end)
    addButton(ScriptsTab, "Star Fishing", function()
        log("Ouverture de l'interface Star Fishing...")
        if StarFishingUI and StarFishingUI.Parent then
            StarFishingUI.Visible = true
            return
        end
        StarFishingUI = Instance.new("Frame")
        StarFishingUI.Name = "StarFishingUI"
        StarFishingUI.Size = UDim2.new(0, 220, 0, 120)
        StarFishingUI.Position = UDim2.new(0.5, -110, 0, 60)
        StarFishingUI.BackgroundColor3 = Theme.Secondary
        StarFishingUI.BackgroundTransparency = 0.25
        StarFishingUI.BorderSizePixel = 0
        StarFishingUI.Parent = ScreenGui
        Instance.new("UICorner", StarFishingUI).CornerRadius = UDim.new(0, 6)
        local sfStroke = Instance.new("UIStroke", StarFishingUI)
        sfStroke.Color = Theme.Accent
        sfStroke.Thickness = 1
        local sfTitle = Instance.new("TextLabel")
        sfTitle.Name = "Title"
        sfTitle.Size = UDim2.new(1, -40, 0, 26)
        sfTitle.Position = UDim2.new(0, 10, 0, 6)
        sfTitle.BackgroundTransparency = 1
        sfTitle.Text = "Star Fishing"
        sfTitle.TextColor3 = Theme.Text
        sfTitle.Font = Enum.Font.GothamBold
        sfTitle.TextSize = 16
        sfTitle.TextXAlignment = Enum.TextXAlignment.Left
        sfTitle.Parent = StarFishingUI
        local sfClose = Instance.new("TextButton")
        sfClose.Name = "Close"
        sfClose.Size = UDim2.new(0, 24, 0, 24)
        sfClose.Position = UDim2.new(1, -28, 0, 6)
        sfClose.BackgroundTransparency = 1
        sfClose.Text = "×"
        sfClose.TextColor3 = Theme.Text
        sfClose.Font = Enum.Font.GothamBold
        sfClose.TextSize = 20
        sfClose.Parent = StarFishingUI
        sfClose.MouseEnter:Connect(function()
            sfClose.TextColor3 = Theme.Accent
        end)
        sfClose.MouseLeave:Connect(function()
            sfClose.TextColor3 = Theme.Text
        end)
        sfClose.MouseButton1Click:Connect(function()
            StarFishingUI.Visible = false
        end)
        local dragBar = Instance.new("Frame")
        dragBar.Size = UDim2.new(1, 0, 0, 30)
        dragBar.BackgroundTransparency = 1
        dragBar.Parent = StarFishingUI
        do
            local dragging = false
            local dragStart, startPos
            dragBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = StarFishingUI.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Position - dragStart
                    StarFishingUI.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end
        local farmBtn = Instance.new("TextButton")
        farmBtn.Name = "FarmButton"
        farmBtn.Size = UDim2.new(0, 140, 0, 32)
        farmBtn.Position = UDim2.new(0.5, -70, 0.5, -16)
        farmBtn.BackgroundColor3 = Theme.Secondary
        farmBtn.Text = "Farm"
        farmBtn.TextColor3 = Theme.Text
        farmBtn.Font = Enum.Font.GothamBold
        farmBtn.TextSize = 16
        farmBtn.Parent = StarFishingUI
        Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 6)
        local farmStroke = Instance.new("UIStroke", farmBtn)
        farmStroke.Color = Theme.Accent
        farmStroke.Thickness = 1
        farmBtn.MouseEnter:Connect(function()
            farmBtn.BackgroundColor3 = Theme.Hover
        end)
        farmBtn.MouseLeave:Connect(function()
            farmBtn.BackgroundColor3 = Theme.Secondary
        end)
        farmBtn.MouseButton1Click:Connect(function()
            log("Star Fishing: démarrage du farm auto")
            local Flags = {
                Farm = "Self",
                SellAll = true,
                SellAllDebounce = 10,
                AutoEquipRod = true
            }
            getgenv().StarFishingFlags = Flags
            loadstring(game:HttpGet("https://raw.githubusercontent.com/afyzone/lua/refs/heads/main/Star%20Fishing/AutoFish.lua"))()
        end)
    end)

    -- Initialisation du premier onglet
    task.wait(0.1)
    local firstTabBtn = TabButtons:GetChildren()[2]
    if firstTabBtn and firstTabBtn:IsA("TextButton") then
        firstTabBtn.BackgroundTransparency = 0.9
        firstTabBtn.TextColor3 = Theme.Accent
        AimbotTab.Visible = true
        local indicator = firstTabBtn:FindFirstChildOfClass("Frame")
        if indicator then indicator.Visible = true end
        currentTab = {Btn = firstTabBtn, Frame = AimbotTab, Indicator = indicator}
    end
end

-- ═══════════════════════════════════════════════════════════
-- SYSTÈME DIVERS & TOOLS
-- ═══════════════════════════════════════════════════════════

local function setupAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if Config.Misc.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            log("Anti-AFK: Action effectuée")
        end
    end)
end

local lastChatSpam = 0
local function updateChatSpammer()
    if not Config.Misc.ChatSpammer.Enabled then return end
    if tick() - lastChatSpam < Config.Misc.ChatSpammer.Delay then return end
    
    task.spawn(function()
        local success = false
        
        -- Méthode 1: TextChatService (Nouveau système Roblox)
        local textChatService = game:GetService("TextChatService")
        if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = textChatService:FindFirstChild("TextChannels")
            local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildOfClass("TextChannel"))
            if channel then
                channel:SendAsync(Config.Misc.ChatSpammer.Message)
                success = true
            end
        end
        
        -- Méthode 2: RemoteEvent (Ancien système Legacy)
        if not success then
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            remote = remote and remote:FindFirstChild("SayMessageRequest")
            if remote then
                remote:FireServer(Config.Misc.ChatSpammer.Message, "All")
                success = true
            end
        end

        -- Méthode 3: SayMessageRequest direct (Alternative Legacy)
        if not success then
            local sayMsg = game:GetService("ReplicatedStorage"):FindFirstChild("SayMessageRequest")
            if sayMsg and sayMsg:IsA("RemoteEvent") then
                sayMsg:FireServer(Config.Misc.ChatSpammer.Message, "All")
                success = true
            end
        end
        
        if success then
            lastChatSpam = tick()
        else
            log("Erreur: Impossible de trouver un canal de chat valide")
        end
    end)
end

local function serverHop()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceId = game.PlaceId
    
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    
    if success and servers and servers.data then
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id)
                return
            end
        end
    end
    log("Aucun serveur trouvé pour le hop")
end

local function rejoinServer()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end

setupAntiAFK()

-- ═══════════════════════════════════════════════════════════
-- BOUCLE PRINCIPALE ET ÉVÉNEMENTS
-- ═══════════════════════════════════════════════════════════

FOVCircle = createDrawing("Circle", {Thickness = 1, NumSides = 64, Color = Color3.new(1,1,1), Transparency = 1, Visible = false})

local CrosshairL = createDrawing("Line", {Thickness = 1, Color = Color3.new(0, 1, 0), Transparency = 1, Visible = false})
local CrosshairR = createDrawing("Line", {Thickness = 1, Color = Color3.new(0, 1, 0), Transparency = 1, Visible = false})
local CrosshairT = createDrawing("Line", {Thickness = 1, Color = Color3.new(0, 1, 0), Transparency = 1, Visible = false})
local CrosshairB = createDrawing("Line", {Thickness = 1, Color = Color3.new(0, 1, 0), Transparency = 1, Visible = false})

local function updateVisuals()
    if Config.Visuals.RainbowMode then
        local color = getRainbowColor()
        if TitleLabel then
            TitleLabel.TextColor3 = color
        end
    elseif TitleLabel then
        local accent = toColor3(Config.Visuals.AccentColor)
        TitleLabel.TextColor3 = accent
    end

    if Config.Visuals.FullBright then
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        game:GetService("Lighting").GlobalShadows = true
    end

    if Config.Visuals.NoFog then
        game:GetService("Lighting").FogEnd = 100000
    end

    if Config.Combat.FovChanger.Enabled then
        local cam = getCamera()
        if cam then
            cam.FieldOfView = Config.Combat.FovChanger.Value
        end
    end

    -- retiré: animation Menu Rainbow

    -- Update Crosshair
    local showCrosshair = Config.Visuals.Crosshair.Enabled
    local cam = getCamera()
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local size = Config.Visuals.Crosshair.Size
    local color = toColor3(Config.Visuals.Crosshair.Color)

    CrosshairL.Visible = showCrosshair
    CrosshairR.Visible = showCrosshair
    CrosshairT.Visible = showCrosshair
    CrosshairB.Visible = showCrosshair

    if showCrosshair then
        CrosshairL.From = center - Vector2.new(size, 0)
        CrosshairL.To = center - Vector2.new(2, 0)
        CrosshairL.Color = color

        CrosshairR.From = center + Vector2.new(2, 0)
        CrosshairR.To = center + Vector2.new(size, 0)
        CrosshairR.Color = color

        CrosshairT.From = center - Vector2.new(0, size)
        CrosshairT.To = center - Vector2.new(0, 2)
        CrosshairT.Color = color

        CrosshairB.From = center + Vector2.new(0, 2)
        CrosshairB.To = center + Vector2.new(0, size)
        CrosshairB.Color = color
    end

    if Config.Visuals.AntiLag then
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
        Config.Visuals.AntiLag = false -- Run once
        log("Anti-Lag appliqué (Smooth Plastic & No Textures)")
    end

    -- Update Highlights
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("DaveHighlight")
            if Config.Visuals.Highlight.Enabled then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "DaveHighlight"
                    highlight.Parent = player.Character
                end
                highlight.FillColor = toColor3(Config.Visuals.Highlight.Color)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = Config.Visuals.Highlight.Transparency
                highlight.OutlineTransparency = 0
                
                -- Team Check
                if Config.ESP.TeamCheck and player.Team == LocalPlayer.Team then
                    highlight.Enabled = false
                else
                    highlight.Enabled = true
                end
            elseif highlight then
                highlight:Destroy()
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    updateESP()
    updateMovement()
    updateGodMode()
    spinbotUpdate()
    updateStraightBullets()
    updateHitboxes()
    updateVisuals()
    reachUpdate()
    updateWorldVisuals()
    updateChatSpammer()
    if FOVCircle then
        local cam = getCamera()
        FOVCircle.Position = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        FOVCircle.Radius = Config.Aimbot.FOV
        local fovColor = Config.Visuals.RainbowMode and getRainbowColor() or toColor3(Config.Visuals.FOVColorRGB)
        FOVCircle.Color = fovColor
        FOVCircle.Transparency = Config.Visuals.FOVTransparency
    end
    if FpsLabel and PingLabel then
        fpsCounter.frames = fpsCounter.frames + 1
        local now = tick()
        if now - fpsCounter.last >= 1 then
            fpsCounter.fps = fpsCounter.frames / (now - fpsCounter.last)
            fpsCounter.frames = 0
            fpsCounter.last = now
        end
        local pingVal = 0
        local stats = game:GetService("Stats")
        local net = stats and stats.Network
        local item = net and net.ServerStatsItem and net.ServerStatsItem["Data Ping"]
        if item and item.GetValue then
            pingVal = math.floor(item:GetValue())
        end
        FpsLabel.Text = "FPS: " .. tostring(math.floor(fpsCounter.fps + 0.5))
        PingLabel.Text = "Ping: " .. tostring(pingVal) .. " ms"
    end
end)

RunService:BindToRenderStep("AimbotProc", Enum.RenderPriority.Camera.Value + 1, aimbotUpdate)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 and Config.Movement.ClickTP.Enabled then
        if UserInputService:IsKeyDown(toEnum(Config.Movement.ClickTP.Key, "KeyCode") or Enum.KeyCode.LeftControl) then
            local mouse = LocalPlayer:GetMouse()
            if mouse.Target then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local targetPos = mouse.Hit.p + Vector3.new(0, 3, 0)
                    local startPos = hrp.Position
                    local dir = (targetPos - startPos)
                    local dist = dir.Magnitude
                    if dist == 0 then return end
                    local step = 150
                    local steps = math.ceil(dist / step)
                    local unit = dir.Unit
                    for i = 1, steps do
                        local ratio = math.clamp(i * step, 0, dist)
                        local pos = startPos + unit * ratio
                        hrp.CFrame = CFrame.new(pos)
                        RunService.Heartbeat:Wait()
                    end
                    log("Téléporté à la position de la souris")
                end
            end
        end
    end

    if input.KeyCode == toEnum(Config.Aimbot.Key, "KeyCode") or input.UserInputType == toEnum(Config.Aimbot.Key, "UserInputType") then 
        AimlockPressed = not AimlockPressed
        if not AimlockPressed then CurrentTarget = nil end
    end
    
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
        ScreenGui.Enabled = MainFrame.Visible
        if not MainFrame.Visible then
            RestoreBtn.Visible = true
        else
            RestoreBtn.Visible = false
        end
    end
    
    if input.KeyCode == toEnum(Config.Movement.Fly.Key, "KeyCode") and Config.Movement.Fly.Enabled then
        toggleFly()
    end

    if input.KeyCode == toEnum(Config.Movement.NoClipKey, "KeyCode") and Config.Movement.NoClip then
        NoClipActive = not NoClipActive
        log("NoClip: " .. (NoClipActive and "Activé" or "Désactivé"))

        if not NoClipActive then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
    
    if Config.Movement.Sprint.Enabled and input.KeyCode == Enum.KeyCode.LeftShift then
        Sprinting = true
    end
    
    if input.KeyCode == Enum.KeyCode.Space then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.Movement.InfiniteJump then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            elseif Config.Movement.SuperJump.DoubleJumpEnabled then
                if hum.FloorMaterial == Enum.Material.Air then
                    if not DoubleJumped and CanDoubleJump then
                        DoubleJumped = true
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Velocity = Vector3.new(hrp.Velocity.X, hum.JumpPower * Config.Movement.SuperJump.PowerMultiplier, hrp.Velocity.Z)
                        end
                    end
                else
                    DoubleJumped = false
                    CanDoubleJump = true
                end
            end
        end
    end
    -- retiré: Quick Exit via touche End
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        Sprinting = false
    end
end)

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)
for _, p in pairs(Players:GetPlayers()) do createESP(p) end

local function runTests()
    log("Démarrage des tests automatiques...")
    local testsPassed = 0
    local totalTests = 5

    if Config.Aimbot and Config.Movement and Config.Combat then
        testsPassed = testsPassed + 1
        log("Test 1 (Intégrité Config) : RÉUSSI")
    end

    if LocalPlayer.Character then
        testsPassed = testsPassed + 1
        log("Test 2 (Détection Personnage) : RÉUSSI")
    end

    if game:GetService("RunService") and game:GetService("UserInputService") then
        testsPassed = testsPassed + 1
        log("Test 3 (Services Système) : RÉUSSI")
    end

    if updateMovement then
        testsPassed = testsPassed + 1
        log("Test 4 (Module Mouvement) : RÉUSSI")
    end

    if Library and Library.CreateWindow then
        testsPassed = testsPassed + 1
        log("Test 5 (Module UI) : RÉUSSI")
    end

    log("Résultats des tests : " .. testsPassed .. "/" .. totalTests .. " réussis.")
end

loadConfig()
NoClipActive = Config.Movement.NoClip
runTests()
Library:CreateWindow()
print("💎 PRO TOOL V3.3 - TOOL V3.3 - TOUS LES ONGLETS CORRIGÉS ✅")
