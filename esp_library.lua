-- esp.lua

-- fixed skeleton esp, and made the ESP_SETTINGS more organize, but theres still improvement to this esp library I need to fix and do.
-- I also fixed the fps performance a little, but that still needs to be improve still.

--// Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}

local bonesR15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local bonesR6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Left Arm", "Left Leg"},
    {"Torso", "Right Arm"},
    {"Right Arm", "Right Leg"}
}

--// Settings
local ESP_SETTINGS = {
    Box = {
        OutlineColor = Color3.new(0, 0, 0), -- Color of the box outline
        Color = Color3.new(1, 1, 1), -- Color of the box
        Enabled = true, -- Toggle for the box ESP
        Show = true, -- Show/hide the box
        Type = "Corner", -- Type of the box (2D, Corner)
    },
    Name = {
        Color = Color3.new(1, 1, 1), -- Color of the name text
        Show = true -- Show/hide the name
    },
    Health = {
        OutlineColor = Color3.new(0, 0, 0), -- Color of the health bar outline
        HighColor = Color3.new(0, 1, 0), -- Color of the health bar when high
        LowColor = Color3.new(1, 0, 0), -- Color of the health bar when low
        Show = true -- Show/hide the health bar
    },
    Distance = {
        Show = true  -- Show/hide the distance text
    },
    Skeletons = {
        Show = true, -- Show/hide the skeleton ESP
        Color = Color3.new(1, 1, 1) 
    },
    Tracer = {
        Show = true, -- Show/hide the tracer
        Color = Color3.new(1, 1, 1), 
        Thickness = 2, 
        Position = "Bottom" -- Position of the tracer (Top, Middle, Bottom)
    },
    General = {
        CharSize = Vector2.new(4, 6),
        Teamcheck = false, 
        WallCheck = false, 
        Enabled = true  -- Global toggle for the ESP
    }
}

local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local function createEsp(player)
    local esp = {
        boxOutline = create("Square", {
            Color = ESP_SETTINGS.Box.OutlineColor,
            Thickness = 3,
            Filled = false
        }),
        box = create("Square", {
            Color = ESP_SETTINGS.Box.Color,
            Thickness = 1,
            Filled = false
        }),
        name = create("Text", {
            Color = ESP_SETTINGS.Name.Color,
            Outline = true,
            Center = true,
            Size = 13
        }),
        healthOutline = create("Line", {
            Thickness = 3,
            Color = ESP_SETTINGS.Health.OutlineColor
        }),
        health = create("Line", {
            Thickness = 1
        }),
        distance = create("Text", {
            Color = Color3.new(1, 1, 1),
            Size = 12,
            Outline = true,
            Center = true
        }),
        tracer = create("Line", {
            Thickness = ESP_SETTINGS.Tracer.Thickness,
            Color = ESP_SETTINGS.Tracer.Color,
            Transparency = 1
        }),
        boxLines = {},
        skeletonLines = {}
    }

    cache[player] = esp
end

local function isPlayerBehindWall(player)
    local character = player.Character
    if not character then return false end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local ray = Ray.new(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position).Unit * (rootPart.Position - camera.CFrame.Position).Magnitude)
    local hit, _ = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})
    
    return hit and hit:IsA("Part")
end

local function removeEsp(player)
    local esp = cache[player]
    if not esp then return end

    for _, drawing in pairs(esp) do
        if type(drawing) == "table" then
            for _, line in pairs(drawing) do
                line:Remove()
            end
        else
            drawing:Remove()
        end
    end

    cache[player] = nil
end

local function getBones(character)
    if character:FindFirstChild("UpperTorso") then
        return bonesR15
    else
        return bonesR6
    end
end

local function updateEsp()
    local players = Players:GetPlayers()
    for _, player in ipairs(players) do
        if player ~= localPlayer then
            local esp = cache[player]
            if not esp then
                createEsp(player)
                esp = cache[player]
            end
            local character, team = player.Character, player.Team
            if character and (not ESP_SETTINGS.General.Teamcheck or (team and team ~= localPlayer.Team)) then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local head = character:FindFirstChild("Head")
                local humanoid = character:FindFirstChild("Humanoid")
                local isBehindWall = ESP_SETTINGS.General.WallCheck and isPlayerBehindWall(player)
                local shouldShow = not isBehindWall and ESP_SETTINGS.General.Enabled

                if rootPart and head and humanoid and shouldShow then
                    local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                    if onScreen then
                        local hrp2D = camera:WorldToViewportPoint(rootPart.Position)
                        local charSize = (camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0)).Y - camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.6, 0)).Y) / 2
                        local boxSize = Vector2.new(math.floor(charSize * 1.8), math.floor(charSize * 1.9))
                        local boxPosition = Vector2.new(math.floor(hrp2D.X - charSize * 1.8 / 2), math.floor(hrp2D.Y - charSize * 1.6 / 2))

                        -- Name ESP
                        if ESP_SETTINGS.Name.Show then
                            esp.name.Visible = true
                            esp.name.Text = string.lower(player.Name)
                            esp.name.Position = Vector2.new(boxSize.X / 2 + boxPosition.X, boxPosition.Y - 16)
                            esp.name.Color = ESP_SETTINGS.Name.Color
                        else
                            esp.name.Visible = false
                        end

                        -- Box ESP
                        if ESP_SETTINGS.Box.Show then
                            if ESP_SETTINGS.Box.Type == "2D" then
                                esp.boxOutline.Size = boxSize
                                esp.boxOutline.Position = boxPosition
                                esp.box.Size = boxSize
                                esp.box.Position = boxPosition
                                esp.box.Color = ESP_SETTINGS.Box.Color
                                esp.box.Visible = true
                                esp.boxOutline.Visible = true
                                for _, line in ipairs(esp.boxLines) do
                                    line:Remove()
                                end
                            elseif ESP_SETTINGS.Box.Type == "Corner" then
                                local lineW = (boxSize.X / 5)
                                local lineH = (boxSize.Y / 6)
                                local lineT = 1

                                if #esp.boxLines == 0 then
                                    for _ = 1, 16 do
                                        local boxLine = create("Line", {
                                            Thickness = 1,
                                            Color = ESP_SETTINGS.Box.Color,
                                            Transparency = 1
                                        })
                                        table.insert(esp.boxLines, boxLine)
                                    end
                                end

                                local boxLines = esp.boxLines

                                -- corner box lines
                                local lines = {
                                    {boxPosition.X - lineT, boxPosition.Y - lineT, boxPosition.X + lineW, boxPosition.Y - lineT},
                                    {boxPosition.X - lineT, boxPosition.Y - lineT, boxPosition.X - lineT, boxPosition.Y + lineH},
                                    {boxPosition.X + boxSize.X - lineW, boxPosition.Y - lineT, boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT},
                                    {boxPosition.X + boxSize.X + lineT, boxPosition.Y - lineT, boxPosition.X + boxSize.X + lineT, boxPosition.Y + lineH},
                                    {boxPosition.X - lineT, boxPosition.Y + boxSize.Y - lineH, boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT},
                                    {boxPosition.X - lineT, boxPosition.Y + boxSize.Y + lineT, boxPosition.X + lineW, boxPosition.Y + boxSize.Y + lineT},
                                    {boxPosition.X + boxSize.X - lineW, boxPosition.Y + boxSize.Y + lineT, boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT},
                                    {boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y - lineH, boxPosition.X + boxSize.X + lineT, boxPosition.Y + boxSize.Y + lineT}
                                }

                                for i, lineData in ipairs(lines) do
                                    local line = boxLines[i]
                                    line.From = Vector2.new(lineData[1], lineData[2])
                                    line.To = Vector2.new(lineData[3], lineData[4])
                                    line.Visible = true
                                end

                                esp.box.Visible = false
                                esp.boxOutline.Visible = false
                            end
                        else
                            esp.box.Visible = false
                            esp.boxOutline.Visible = false
                            for _, line in ipairs(esp.boxLines) do
                                line:Remove()
                            end
                            esp.boxLines = {}
                        end

                        -- Health ESP
                        if ESP_SETTINGS.Health.Show then
                            esp.healthOutline.Visible = true
                            esp.health.Visible = true
                            local healthPercentage = humanoid.Health / humanoid.MaxHealth
                            esp.healthOutline.From = Vector2.new(boxPosition.X - 6, boxPosition.Y + boxSize.Y)
                            esp.healthOutline.To = Vector2.new(esp.healthOutline.From.X, esp.healthOutline.From.Y - boxSize.Y)
                            esp.health.From = Vector2.new((boxPosition.X - 5), boxPosition.Y + boxSize.Y)
                            esp.health.To = Vector2.new(esp.health.From.X, esp.health.From.Y - healthPercentage * boxSize.Y)
                            esp.health.Color = ESP_SETTINGS.Health.LowColor:Lerp(ESP_SETTINGS.Health.HighColor, healthPercentage)
                        else
                            esp.healthOutline.Visible = false
                            esp.health.Visible = false
                        end

                        -- Distance ESP
                        if ESP_SETTINGS.Distance.Show then
                            local distance = (camera.CFrame.p - rootPart.Position).Magnitude
                            esp.distance.Text = string.format("%.1f studs", distance)
                            esp.distance.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 5)
                            esp.distance.Visible = true
                        else
                            esp.distance.Visible = false
                        end

                        -- Skeleton ESP
                        if ESP_SETTINGS.Skeletons.Show then
                            if #esp.skeletonLines == 0 then
                                local bones = getBones(character)
                                for _, bonePair in ipairs(bones) do
                                    local parentBone, childBone = bonePair[1], bonePair[2]
                                    if character:FindFirstChild(parentBone) and character:FindFirstChild(childBone) then
                                        local skeletonLine = create("Line", {
                                            Thickness = 1,
                                            Color = ESP_SETTINGS.Skeletons.Color,
                                            Transparency = 1
                                        })
                                        table.insert(esp.skeletonLines, {skeletonLine, parentBone, childBone})
                                    end
                                end
                            end

                            for _, lineData in ipairs(esp.skeletonLines) do
                                local skeletonLine = lineData[1]
                                local parentBone, childBone = lineData[2], lineData[3]
                                if character:FindFirstChild(parentBone) and character:FindFirstChild(childBone) then
                                    local parentPosition = camera:WorldToViewportPoint(character[parentBone].Position)
                                    local childPosition = camera:WorldToViewportPoint(character[childBone].Position)
                                    skeletonLine.From = Vector2.new(parentPosition.X, parentPosition.Y)
                                    skeletonLine.To = Vector2.new(childPosition.X, childPosition.Y)
                                    skeletonLine.Color = ESP_SETTINGS.Skeletons.Color
                                    skeletonLine.Visible = true
                                else
                                    skeletonLine:Remove()
                                end
                            end
                        else
                            for _, lineData in ipairs(esp.skeletonLines) do
                                local skeletonLine = lineData[1]
                                skeletonLine:Remove()
                            end
                            esp.skeletonLines = {}
                        end

                        -- Tracer ESP
                        if ESP_SETTINGS.Tracer.Show then
                            local tracerY
                            if ESP_SETTINGS.Tracer.Position == "Top" then
                                tracerY = 0
                            elseif ESP_SETTINGS.Tracer.Position == "Middle" then
                                tracerY = camera.ViewportSize.Y / 2
                            else
                                tracerY = camera.ViewportSize.Y
                            end
                            esp.tracer.Visible = true
                            esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, tracerY)
                            esp.tracer.To = Vector2.new(hrp2D.X, hrp2D.Y)
                        else
                            esp.tracer.Visible = false
                        end
                    else
                        for _, drawing in pairs(esp) do
                            drawing.Visible = false
                        end
                        for _, lineData in ipairs(esp.skeletonLines) do
                            local skeletonLine = lineData[1]
                            skeletonLine:Remove()
                        end
                        esp.skeletonLines = {}
                        for _, line in ipairs(esp.boxLines) do
                            line:Remove()
                        end
                        esp.boxLines = {}
                    end
                else
                    for _, drawing in pairs(esp) do
                        drawing.Visible = false
                    end
                    for _, lineData in ipairs(esp.skeletonLines) do
                        local skeletonLine = lineData[1]
                        skeletonLine:Remove()
                    end
                    esp.skeletonLines = {}
                    for _, line in ipairs(esp.boxLines) do
                        line:Remove()
                    end
                    esp.boxLines = {}
                end
            else
                for _, drawing in pairs(esp) do
                    drawing.Visible = false
                end
                for _, lineData in ipairs(esp.skeletonLines) do
                    local skeletonLine = lineData[1]
                    skeletonLine:Remove()
                end
                esp.skeletonLines = {}
                for _, line in ipairs(esp.boxLines) do
                    line:Remove()
                end
                esp.boxLines = {}
            end
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createEsp(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        createEsp(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end)

RunService.RenderStepped:Connect(updateEsp)
return ESP_SETTINGS
