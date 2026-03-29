local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Cryo Hub",
    LoadingTitle = "Survive LAVA For Cars",
    LoadingSubtitle = "By Lu4ikki",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Cryo Hub",
        FileName = "Cryo Hub"
    }
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Areas = Workspace:FindFirstChild("Areas")
local Events = ReplicatedStorage:FindFirstChild("Events")
local PurchaseSpeed = Events and Events:FindFirstChild("PurchaseSpeed")
local PurchaseCarry = Events and Events:FindFirstChild("PurchaseCarry")

local speedEnabled, jumpEnabled = false, false
local currentSpeed, currentJumpHeight = 16, 50
local autoRebirthEnabled, autoSpeedBuyEnabled, autoCarryBuyEnabled, autoCollectEnabled, autoCarEnabled = false, false, false, false, false
local rebirthConnection, speedBuyConnection, carryBuyConnection, collectConnection, carConnection = nil, nil, nil, nil, nil

-- ========== СПИСОК МАШИН ==========
local AllCars = {
    {ID = "GULF", Name = "Gulf", Selected = false},
    {ID = "SUPRE", Name = "Supre", Selected = false},
    {ID = "BIMMERN2", Name = "BimmerN2", Selected = false},
    {ID = "CURVETT", Name = "Curvett", Selected = false},
    {ID = "TUBOS", Name = "TuboS", Selected = false},
    {ID = "GTI40", Name = "GTI40", Selected = false},
    {ID = "RS3GT", Name = "RS3GT", Selected = false},
    {ID = "AVETEDOR", Name = "Avetedor", Selected = false},
    {ID = "D1", Name = "D1", Selected = false},
    {ID = "ZONDIK", Name = "Zondik", Selected = false},
    {ID = "ZONDIKR", Name = "ZondikR", Selected = false},
    {ID = "W2", Name = "W2", Selected = false},
    {ID = "HURIK", Name = "Hurik", Selected = false},
    {ID = "AGRO", Name = "Agro", Selected = false},
    {ID = "HURIKZ", Name = "HurikZ", Selected = false},
    {ID = "JERGO", Name = "Jergo", Selected = false},
    {ID = "DIVVITI", Name = "Divviti", Selected = false},
    {ID = "TRIBITTI", Name = "Tribitti", Selected = false},
    {ID = "SPALI", Name = "Spali", Selected = false},
    {ID = "STALLIONGT", Name = "StallionGT", Selected = false},
    {ID = "REVOLTO", Name = "Revolto", Selected = false},
    {ID = "BRAVUSG63", Name = "BravusG63", Selected = false},
    {ID = "SPIRETAIL", Name = "Spiretail", Selected = false},
    {ID = "VALKRONPRO", Name = "ValkronPro", Selected = false},
}

local ZonesByRarity = {
    Common = {"Common"}, Rare = {"Rare"}, Epic = {"Epic"},
    Legendary = {"Legendary"}, Mythical = {"Mythical"}, Cosmic = {"Cosmic"},
    Secret = {"Secret"}, Celestial = {"Celestial"}, GOD = {"GOD"}
}

local AllZones = {"Celestial", "Common", "Cosmic", "Epic", "GOD", "Legendary", "Mythical", "Rare", "Secret"}

-- ========== ВСЕ ФУНКЦИИ ==========

local function getPlayerMoney()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local money = leaderstats:FindFirstChild("Money")
        if money then return money.Value end
    end
    return 0
end

local function getCurrentSpeedStat()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local speed = leaderstats:FindFirstChild("Speed")
        if speed then return speed.Value end
    end
    return 0
end

local function removeAllLava()
    if not Areas then return 0 end
    local totalRemoved = 0
    for _, zoneName in ipairs(AllZones) do
        local zone = Areas:FindFirstChild(zoneName)
        if zone then
            local function searchAndRemove(parent)
                for _, child in ipairs(parent:GetChildren()) do
                    if child.Name == "Lava" then
                        pcall(function() child:Destroy(); totalRemoved = totalRemoved + 1 end)
                    elseif #child:GetChildren() > 0 then
                        searchAndRemove(child)
                    end
                end
            end
            searchAndRemove(zone)
        end
        task.wait(0.05)
    end
    return totalRemoved
end

local function getBaseCFrame()
    local plot = Workspace:FindFirstChild("Plot_" .. LocalPlayer.Name)
    if not plot then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name:find(LocalPlayer.Name) and obj.Name:find("Plot") then plot = obj; break end
        end
    end
    if not plot then return nil end
    local tp = plot:FindFirstChild("Spawn") or plot:FindFirstChildWhichIsA("BasePart")
    if tp then return tp.CFrame + Vector3.new(0, 3, 0) end
    return nil
end

local function teleportToBase()
    local baseCF = getBaseCFrame()
    if not baseCF then
        Rayfield:Notify({Title = "Error", Content = "Too Far", Duration = 3})
        return false
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hum = char:FindFirstChild("Humanoid")
        local save = hum and hum.WalkSpeed or 16
        char.HumanoidRootPart.CFrame = baseCF
        task.wait(0.1)
        if hum and speedEnabled then hum.WalkSpeed = save end
        return true
    end
    return false
end

local function teleportToZone(zoneName)
    if not Areas then return false end
    local zone = Areas:FindFirstChild(zoneName)
    if not zone then return false end
    local target = zone:FindFirstChild("Spawn")
    if not target then
        for _, child in ipairs(zone:GetDescendants()) do if child:IsA("BasePart") then target = child; break end end
    end
    if target then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 5, 0)
            return true
        end
    end
    return false
end

local function getRebirthCount()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local rebirths = leaderstats:FindFirstChild("Rebirths")
        if rebirths then return rebirths.Value end
    end
    return 0
end

local function getRebirthRequirement()
    return 50 + (getRebirthCount() * 5)
end

local function doRebirth()
    local requestRebirth = Events and Events:FindFirstChild("RequestRebirth")
    if requestRebirth then requestRebirth:FireServer(); return true end
    return false
end

local function startAutoRebirth()
    if rebirthConnection then rebirthConnection:Disconnect() end
    autoRebirthEnabled = true
    rebirthConnection = RunService.Heartbeat:Connect(function()
        if not autoRebirthEnabled then return end
        if getCurrentSpeedStat() >= getRebirthRequirement() then doRebirth() end
    end)
end

local function stopAutoRebirth()
    autoRebirthEnabled = false
    if rebirthConnection then rebirthConnection:Disconnect(); rebirthConnection = nil end
end

local function buySpeed()
    if PurchaseSpeed then PurchaseSpeed:FireServer(1) end
end

local function startAutoSpeedBuy()
    if speedBuyConnection then speedBuyConnection:Disconnect() end
    autoSpeedBuyEnabled = true
    local lastBuy = 0
    speedBuyConnection = RunService.Heartbeat:Connect(function()
        if not autoSpeedBuyEnabled then return end
        local now = tick()
        if now - lastBuy >= 1 and getPlayerMoney() >= 100 then buySpeed(); lastBuy = now end
    end)
end

local function stopAutoSpeedBuy()
    autoSpeedBuyEnabled = false
    if speedBuyConnection then speedBuyConnection:Disconnect(); speedBuyConnection = nil end
end

local function buyCarry()
    if PurchaseCarry then PurchaseCarry:FireServer() end
end

local function startAutoCarryBuy()
    if carryBuyConnection then carryBuyConnection:Disconnect() end
    autoCarryBuyEnabled = true
    local lastBuy = 0
    carryBuyConnection = RunService.Heartbeat:Connect(function()
        if not autoCarryBuyEnabled then return end
        local now = tick()
        if now - lastBuy >= 1 and getPlayerMoney() >= 500 then buyCarry(); lastBuy = now end
    end)
end

local function stopAutoCarryBuy()
    autoCarryBuyEnabled = false
    if carryBuyConnection then carryBuyConnection:Disconnect(); carryBuyConnection = nil end
end

-- ========== АВТО-СБОР ДЕНЕГ ==========

local modifiedButtons = {}

local function getMyPlot()
    local plot = Workspace:FindFirstChild("Plot_" .. LocalPlayer.Name)
    if not plot then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name:find(LocalPlayer.Name) and (obj.Name:find("Plot") or obj.Name:find("Base")) then return obj end
        end
    end
    return plot
end

local function findAllCollectButtons()
    local plot = getMyPlot()
    if not plot then return {} end
    local buttons = {}
    for _, model in ipairs(plot:GetDescendants()) do
        if model:IsA("Model") and model.Name:find("Collect") then
            local touch = model:FindFirstChild("Touch")
            if touch and touch:IsA("BasePart") then
                table.insert(buttons, {touch = touch, bottom = model:FindFirstChild("Bottom"), offset = math.random() * math.pi * 2})
            end
        end
    end
    return buttons
end

local function modifyButton(btn)
    local touch = btn.touch
    local bottom = btn.bottom
    if not btn.original then btn.original = {tc = touch.CanCollide, tt = touch.Transparency, bc = bottom and bottom.CanCollide, bt = bottom and bottom.Transparency} end
    touch.CanCollide = false; touch.Transparency = 1
    if bottom then bottom.CanCollide = false; bottom.Transparency = 1 end
    return btn
end

local function restoreButton(btn)
    if not btn.original then return end
    local o = btn.original
    if btn.touch and btn.touch.Parent then btn.touch.CanCollide = o.tc; btn.touch.Transparency = o.tt end
    if btn.bottom and btn.bottom.Parent then btn.bottom.CanCollide = o.bc; btn.bottom.Transparency = o.bt end
end

local function startAutoCollect()
    if collectConnection then collectConnection:Disconnect() end
    for _, b in ipairs(modifiedButtons) do restoreButton(b) end
    modifiedButtons = {}
    autoCollectEnabled = true
    for _, b in ipairs(findAllCollectButtons()) do table.insert(modifiedButtons, modifyButton(b)) end
    collectConnection = RunService.Heartbeat:Connect(function()
        if not autoCollectEnabled then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local time, pos = tick(), hrp.Position
        for _, btn in ipairs(modifiedButtons) do
            if not btn.touch or not btn.touch.Parent then continue end
            local angle = time * 10 + btn.offset
            btn.touch.CFrame = CFrame.new(pos.X + math.cos(angle) * 3.5, pos.Y - 2 + math.sin(time * 6 + btn.offset) * 1, pos.Z + math.sin(angle) * 3.5)
            if btn.bottom and btn.bottom.Parent then btn.bottom.CFrame = btn.touch.CFrame end
        end
    end)
    Rayfield:Notify({Title = "Auto Collect Money", Content = "" .. #modifiedButtons .. "", Duration = 1})
end

local function stopAutoCollect()
    autoCollectEnabled = false
    if collectConnection then collectConnection:Disconnect(); collectConnection = nil end
    for _, b in ipairs(modifiedButtons) do restoreButton(b) end
    modifiedButtons = {}
end

-- ========== АВТО-ПОДБОР МАШИН (ТЕЛЕПОРТ К HANDLE → БАЗА) ==========

local selectedCars = {}
local processedCars = {}

local function findSpawnedCars()
    local spawned = Workspace:FindFirstChild("SpawnedItems")
    if not spawned then return {} end
    
    local found = {}
    for _, car in ipairs(spawned:GetChildren()) do
        if processedCars[car] then continue end
        
        local carId = car.Name
        for _, selected in ipairs(selectedCars) do
            if carId == selected.ID or carId:find(selected.ID) then
                -- Ищем Prompt
                for _, obj in ipairs(car:GetDescendants()) do
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and prompt.ActionText == "Pick Up" then
                        table.insert(found, {car = car, prompt = prompt, part = obj})
                        break
                    end
                end
                break
            end
        end
    end
    return found
end

local function collectCarAndReturn(carData)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local car = carData.car
    local prompt = carData.prompt
    
    -- ТЕЛЕПОРТ К HANDLE (PRIMARYPART) МАШИНЫ
    local handle = car.PrimaryPart
    if not handle then
        handle = carData.part
    end
    
    if not handle or not handle.Parent then return false end
    
    local baseCF = getBaseCFrame()
    if not baseCF then return false end
    
    -- 1. Телепорт к Handle машины
    hrp.CFrame = handle.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.3)
    
    -- 2. Подбираем машину
    pcall(function()
        prompt:InputHoldBegin()
        if prompt.HoldDuration > 0 then
            task.wait(prompt.HoldDuration + 0.1)
        end
        prompt:InputHoldEnd()
    end)
    
    processedCars[car] = true
    task.wait(0.2)
    
    -- 3. Возврат на базу
    hrp.CFrame = baseCF
    
    return true
end

local function startAutoCar()
    if carConnection then carConnection:Disconnect() end
    autoCarEnabled = true
    processedCars = {}
    
    carConnection = RunService.Heartbeat:Connect(function()
        if not autoCarEnabled then return end
        
        local cars = findSpawnedCars()
        if #cars == 0 then return end
        
        collectCarAndReturn(cars[1])
        task.wait(1)
    end)
    
    Rayfield:Notify({Title = "err", Content = "err" .. #selectedCars, Duration = 3})
end

local function stopAutoCar()
    autoCarEnabled = false
    if carConnection then carConnection:Disconnect(); carConnection = nil end
    processedCars = {}
    Rayfield:Notify({Title = "err", Content = "", Duration = 2})
end

-- Настройки персонажа
local function setSpeed(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v end
end

local function setJumpHeight(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpHeight = v; hum.UseJumpPower = false end
end

local function resetSpeed() setSpeed(16) end
local function resetJumpHeight() setJumpHeight(50) end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if speedEnabled then setSpeed(currentSpeed) end
    if jumpEnabled then setJumpHeight(currentJumpHeight) end
end)

-- ========== GUI ==========
local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateSection("Auto Farm")
MainTab:CreateToggle({Name = "⚡ Auto Buy Speed", CurrentValue = false, Flag = "AutoSpeedBuy", Callback = function(v) if v then startAutoSpeedBuy() else stopAutoSpeedBuy() end end})
MainTab:CreateToggle({Name = "📦 Auto Buy Carry", CurrentValue = false, Flag = "AutoCarryBuy", Callback = function(v) if v then startAutoCarryBuy() else stopAutoCarryBuy() end end})
MainTab:CreateToggle({Name = "💰 Auto Collect Money", CurrentValue = false, Flag = "AutoCollectOrbit", Callback = function(v) if v then startAutoCollect() else stopAutoCollect() end end})
MainTab:CreateToggle({Name = "🔄 Auto Rebirth", CurrentValue = false, Flag = "AutoRebirth", Callback = function(v) if v then startAutoRebirth() else stopAutoRebirth() end end})
MainTab:CreateSection("Base")
MainTab:CreateButton({Name = "🏠 Teleport to Base", Callback = function() teleportToBase() end})

-- Teleports
local TeleportsTab = Window:CreateTab("Teleports", 4483362458)
local zoneIcons = {Common = "⭐", Rare = "💎", Epic = "⚡", Legendary = "👑", Mythical = "🔮", Cosmic = "🌌", Secret = "❓", Celestial = "✨", GOD = "👑"}
local zoneOrder = {"Common", "Rare", "Epic", "Legendary", "Mythical", "Cosmic", "Secret", "Celestial", "GOD"}

for _, rarity in ipairs(zoneOrder) do
    TeleportsTab:CreateSection(zoneIcons[rarity] .. " " .. rarity:upper())
    for _, zone in ipairs(ZonesByRarity[rarity]) do
        TeleportsTab:CreateButton({Name = "📍 " .. zone, Callback = function() teleportToZone(zone) end})
    end
end

local Misc = Window:CreateTab("Misc", 4483362458)
Misc:CreateSection("Lava Lava")
Misc:CreateButton({Name = "🔥 Destroy Lava", Callback = function() removeAllLava() end})

-- Player
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Speed")
PlayerTab:CreateSlider({Name = "Walk Speed", Range = {0, 100}, Increment = 1, CurrentValue = 16, Flag = "SpeedSlider", Callback = function(v) currentSpeed = v; if speedEnabled then setSpeed(v) end end})
PlayerTab:CreateToggle({Name = "Enable Speed", CurrentValue = false, Flag = "SpeedToggle", Callback = function(v) speedEnabled = v; if v then setSpeed(currentSpeed) else resetSpeed() end end})

PlayerTab:CreateSection("Jump")
PlayerTab:CreateSlider({Name = "Jump Height", Range = {0, 200}, Increment = 1, Suffix = " studs", CurrentValue = 50, Flag = "JumpSlider", Callback = function(v) currentJumpHeight = v; if jumpEnabled then setJumpHeight(v) end end})
PlayerTab:CreateToggle({Name = "Enable Jump", CurrentValue = false, Flag = "JumpToggle", Callback = function(v) jumpEnabled = v; if v then setJumpHeight(currentJumpHeight) else resetJumpHeight() end end})

PlayerTab:CreateSection("Reset")
PlayerTab:CreateButton({Name = "Reset All", Callback = function()
    speedEnabled, jumpEnabled = false, false
    currentSpeed, currentJumpHeight = 16, 50
    resetSpeed(); resetJumpHeight()
    stopAutoRebirth(); stopAutoSpeedBuy(); stopAutoCarryBuy(); stopAutoCollect(); stopAutoCar()
    Rayfield:Notify({Title = "Succefuly", Content = "", Duration = 3})
end})

-- ========== АВТО-МАШИНЫ ==========

local CarsTab = Window:CreateTab("NOT WORKING", 4483362458)

CarsTab:CreateSection("Select Cars to Collect")

for _, car in ipairs(AllCars) do
    CarsTab:CreateToggle({
        Name = car.Name,
        CurrentValue = false,
        Flag = "Car_" .. car.ID,
        Callback = function(val)
            car.Selected = val
            selectedCars = {}
            for _, c in ipairs(AllCars) do if c.Selected then table.insert(selectedCars, c) end end
        end
    })
end

CarsTab:CreateSection("Auto Collect")

CarsTab:CreateToggle({
    Name = "🚗 Auto Collect (Handle → Base)",
    CurrentValue = false,
    Flag = "AutoCarCollect",
    Callback = function(val)
        if val then
            if #selectedCars == 0 then
                Rayfield:Notify({Title = "err", Content = "", Duration = 3})
                return
            end
            startAutoCar()
        else
            stopAutoCar()
        end
    end
})

CarsTab:CreateButton({
    Name = "📋 Check Spawned Cars",
    Callback = function()
        local spawned = Workspace:FindFirstChild("SpawnedItems")
        if not spawned then
            Rayfield:Notify({Title = "err", Content = "", Duration = 3})
            return
        end
        local count = 0
        local names = {}
        for _, obj in ipairs(spawned:GetChildren()) do
            count = count + 1
            table.insert(names, obj.Name)
        end
        Rayfield:Notify({Title = "err", Content = "err " .. count .. " | " .. table.concat(names, ", "), Duration = 5})
    end
})

CarsTab:CreateButton({
    Name = "🔄 Reset Car List",
    Callback = function()
        processedCars = {}
        Rayfield:Notify({Title = "err", Content = "", Duration = 2})
    end
})
