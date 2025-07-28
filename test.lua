-- Utility to stringify errors
local function getErrorMessage(err)
    if type(err) == "string" then
        return err
    elseif type(err) == "table" then
        local parts = {}
        for k, v in pairs(err) do
            local valueStr = type(v) == "table" and getErrorMessage(v) or tostring(v)
            table.insert(parts, tostring(k) .. ": " .. valueStr)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return tostring(err)
    end
end

-- Load Fluent UI library and SaveManager addon
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("ShitassCompScriptConfigV3")

-- Create main window
local Window = Fluent:CreateWindow({
    Title = "shitass comp script v3",
    SubTitle = "made by lonly on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Define tabs
local MainTab = Window:AddTab({ Title = "Main", Icon = "home" })
local QuestTab = Window:AddTab({ Title = "Quests", Icon = "edit" })
local EggSettingsTab = Window:AddTab({ Title = "Egg Settings", Icon = "settings" })
local ConfigTab = Window:AddTab({ Title = "Config", Icon = "folder" })

-- Roblox services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Player references
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Automation state
local taskAutomationEnabled = false
local questToggles = {}

-- Egg data
local eggPositions = {
    ["Common Egg"] = Vector3.new(-83.86, 10.11, 1.57),
    ["Spotted Egg"] = Vector3.new(-93.96, 10.11, 7.41),
    ["Iceshard Egg"] = Vector3.new(-117.06, 10.11, 7.74),
    ["Spikey Egg"] = Vector3.new(-124.58, 10.11, 4.58),
    ["Magma Egg"] = Vector3.new(-133.02, 10.11, -1.55),
    ["Crystal Egg"] = Vector3.new(-140.2, 10.11, -8.36),
    ["Lunar Egg"] = Vector3.new(-143.85, 10.11, -15.93),
    ["Void Egg"] = Vector3.new(-145.91, 10.11, -26.13),
    ["Hell Egg"] = Vector3.new(-145.17, 10.11, -36.78),
    ["Nightmare Egg"] = Vector3.new(-142.35, 10.11, -45.15),
    ["Rainbow Egg"] = Vector3.new(-134.49, 10.11, -52.36),
    ["Mining Egg"] = Vector3.new(-120, 10, -64),
    ["Showman Egg"] = Vector3.new(-130, 10, -60),
    ["Cyber Egg"] = Vector3.new(-95, 10, -63),
    ["Infinity Egg"] = Vector3.new(-99, 9, -26),
    ["Neon Egg"] = Vector3.new(-83, 10, -57)
}
local eggNames = {}
for name in pairs(eggPositions) do table.insert(eggNames, name) end
table.sort(eggNames)

-- Quest definitions
local quests = {
    {ID = "HatchMythic", DisplayName = "Hatch mythic pets", Pattern = "mythic", DefaultEgg = "Mining Egg"},
    {ID = "Hatch200", DisplayName = "Hatch 200 eggs", Pattern = "200", DefaultEgg = "Spikey Egg"}
    {ID = "HatchLegendary", DisplayName = "Hatch legendary pets", Pattern = "legendary", DefaultEgg = "Mining Egg"},
    {ID = "Hatch450", DisplayName = "Hatch 450 eggs", Pattern = "450", DefaultEgg = "Spikey Egg"},
    {ID = "Hatch350", DisplayName = "Hatch 350 eggs", Pattern = "350", DefaultEgg = "Spikey Egg"},
    {ID = "HatchShiny", DisplayName = "Hatch shiny pets", Pattern = "shiny", DefaultEgg = "Mining Egg"},
    {ID = "HatchEpic", DisplayName = "Hatch epic pets", Pattern = "epic", DefaultEgg = "Spikey Egg"},
    {ID = "HatchRare", DisplayName = "Hatch rare pets", Pattern = "rare", DefaultEgg = "Spikey Egg"},
    {ID = "HatchCommon", DisplayName = "Hatch common pets", Pattern = "common", DefaultEgg = "Common Egg"},
    {ID = "HatchUnique", DisplayName = "Hatch unique pets", Pattern = "unique", DefaultEgg = "Spikey Egg"},
    {ID = "Hatch1250", DisplayName = "Hatch 1250 eggs", Pattern = "1250", DefaultEgg = "Spikey Egg"},
    {ID = "Hatch950", DisplayName = "Hatch 950 eggs", Pattern = "950", DefaultEgg = "Spikey Egg"},
}

-- Function to tween to egg
local function tweenToPosition(position)
    local speed = Window.Options.TweenSpeed and Window.Options.TweenSpeed.Value or 30
    local distance = (humanoidRootPart.Position - position).Magnitude
    local time = distance / speed
    return TweenService:Create(humanoidRootPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(position)})
end

-- Hatch egg helper
local function hatchEgg(eggName)
    local pos = eggPositions[eggName]
    if pos then
        local tween = tweenToPosition(pos)
        tween:Play()
        tween.Completed:Wait()
        while (humanoidRootPart.Position - pos).Magnitude > 5 do task.wait(0.1) end
    end
end

-- Main task loop
local function taskManager()
    while taskAutomationEnabled do
        local ok, err = pcall(function()
            local tasksFolder = player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Competitive"):WaitForChild("Frame"):WaitForChild("Content"):WaitForChild("Tasks")
            local templates = {}
            for _, frame in ipairs(tasksFolder:GetChildren()) do
                if frame:IsA("Frame") and frame.Name == "Template" then table.insert(templates, frame) end
            end
            table.sort(templates, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

            local repeatableTasks, protectedSlots = {}, {}
            for index, frame in ipairs(templates) do
                if index == 3 or index == 4 then
                    local content = frame.Content
                    table.insert(repeatableTasks, {frame = frame, title = content.Label.Text, type = content.Type.Text, slot = index})
                end
            end

            local highestAction = nil
            for _, quest in ipairs(quests) do
                if Window.Options["Quest_"..quest.ID].Value then
                    for _, task in ipairs(repeatableTasks) do
                        if task.type == "Repeatable" and task.title:lower():find(quest.Pattern, 1, true) then
                            protectedSlots[task.slot] = true
                            if not highestAction then
                                local matchedEgg
                                for name in pairs(eggPositions) do
                                    if task.title:lower():find(name:lower(), 1, true) then matchedEgg = name; break end
                                end
                                highestAction = {egg = matchedEgg or Window.Options["EggFor_"..quest.ID].Value}
                            end
                        end
                    end
                end
            end

            if highestAction then hatchEgg(highestAction.egg) end

            local rerollRemote = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
            for _, task in ipairs(repeatableTasks) do
                if task.type == "Repeatable" and not protectedSlots[task.slot] then
                    rerollRemote:FireServer("CompetitiveReroll", task.slot)
                    task.wait(0.3)
                end
            end
        end)
        if not ok then warn("[ERROR] Task manager error: ", getErrorMessage(err)) end
        task.wait(0.2)
    end
end

-- Toggle automation
local function startStopAutomation(enabled)
    taskAutomationEnabled = enabled
    getgenv().autoPressE = enabled
    if enabled then
        task.spawn(taskManager)
        task.spawn(function()
            while getgenv().autoPressE do
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait()
            end
        end)
    end
end

-- Helper to refresh UI controls
local function refreshUI(options)
    for name, value in pairs(options) do
        if Window.Options[name] then Window.Options[name]:SetValue(value) end
    end
end

-- Build UI controls
MainTab:AddToggle("AutoTasks", { Title = "Enable Auto Complete", Default = false, Callback = startStopAutomation })
MainTab:AddDropdown("FallbackEgg", { Title = "Fallback Egg", Values = eggNames, Default = "Infinity Egg" })
MainTab:AddSlider("TweenSpeed", { Title = "Character Tween Speed", Min = 16, Max = 60, Default = 30, Rounding = 0 })
for _, quest in ipairs(quests) do
    QuestTab:AddToggle("Quest_"..quest.ID, { Title = quest.DisplayName, Default = false })
    EggSettingsTab:AddDropdown("EggFor_"..quest.ID, { Title = quest.DisplayName, Values = eggNames, Default = quest.DefaultEgg })
end

-- Config Tab
ConfigTab:AddButton({
    Title = "Save Settings",
    Callback = function()
        local ok, err = SaveManager:Save("default")
        Fluent:Notify(ok and { Title = "Success", Content = "Settings saved" } or { Title = "Error", Content = getErrorMessage(err), Duration = 8 })
    end
})
ConfigTab:AddButton({
    Title = "Load Settings",
    Callback = function()
        local ok, data = SaveManager:Load("default")
        if ok and type(data) == "table" then
            for name, val in pairs(data) do if Window.Options[name] then Window.Options[name]:SetValue(val) end end
            Fluent:Notify({ Title = "Success", Content = "Settings loaded & applied" })
        else
            Fluent:Notify({ Title = "Error", Content = getErrorMessage(data), Duration = 8 })
        end
    end
})
ConfigTab:AddButton({
    Title = "Reset Settings",
    Callback = function()
        local defaults = { AutoTasks = false, FallbackEgg = "Infinity Egg", TweenSpeed = 30 }
        for _, quest in ipairs(quests) do defaults["Quest_"..quest.ID] = false; defaults["EggFor_"..quest.ID] = quest.DefaultEgg end
        refreshUI(defaults)
        SaveManager:Save("default")
        Fluent:Notify({ Title = "Success", Content = "Settings reset to defaults" })
    end
})

-- Startup: load and apply saved settings
local ok, data = SaveManager:Load("default")
if ok and type(data) == "table" then
    for name, val in pairs(data) do if Window.Options[name] then Window.Options[name]:SetValue(val) end end
    refreshUI(data)
else
    Fluent:Notify({ Title = "Warning", Content = "Could not load settings: "..tostring(data), Duration = 5 })
end

-- Finalize window
Window:SelectTab(1)
Window:Show()

task.defer(function()
    Fluent:Notify({ Title = "Script Loaded", Content = "Ready!", Duration = 5 })
    if Window.Options.AutoTasks.Value then startStopAutomation(true) end
end)
