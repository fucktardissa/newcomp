-- Utility to stringify errorsasdasd
local function getErrorMessage(err)
    if type(err) == "string" then return err
    elseif type(err) == "table" then
        local parts = {}
        for k, v in pairs(err) do
            local valueStr = type(v) == "table" and getErrorMessage(v) or tostring(v)
            table.insert(parts, tostring(k) .. ": " .. valueStr)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else return tostring(err) end
end

-- Load libraries
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("ShitassCompScriptConfigV3")

-- Load saved options
local LoadedOptions = {}
local okLoad, loadedData = SaveManager:Load("default")
if okLoad and type(loadedData) == "table" then
    for k, v in pairs(loadedData) do LoadedOptions[k] = v end
end

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

-- Tabs
local MainTab        = Window:AddTab({ Title = "Main", Icon = "home" })
local QuestTab       = Window:AddTab({ Title = "Quests", Icon = "edit" })
local EggSettingsTab = Window:AddTab({ Title = "Egg Settings", Icon = "settings" })
local ConfigTab      = Window:AddTab({ Title = "Config", Icon = "folder" })

-- Services & refs
local TweenService        = game:GetService("TweenService")
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- State
local taskAutomationEnabled = false
local activeQuests = {}
local ConfigToSave = {}

-- Egg data
local eggPositions = {
    ["Common Egg"]    = Vector3.new(-83.86, 10.11, 1.57),
    ["Spotted Egg"]   = Vector3.new(-93.96, 10.11, 7.41),
    ["Iceshard Egg"]  = Vector3.new(-117.06, 10.11, 7.74),
    ["Spikey Egg"]    = Vector3.new(-124.58, 10.11, 4.58),
    ["Magma Egg"]     = Vector3.new(-133.02, 10.11, -1.55),
    ["Crystal Egg"]   = Vector3.new(-140.2, 10.11, -8.36),
    ["Lunar Egg"]     = Vector3.new(-143.85, 10.11, -15.93),
    ["Void Egg"]      = Vector3.new(-145.91, 10.11, -26.13),
    ["Hell Egg"]      = Vector3.new(-145.17, 10.11, -36.78),
    ["Nightmare Egg"] = Vector3.new(-142.35, 10.11, -45.15),
    ["Rainbow Egg"]   = Vector3.new(-134.49, 10.11, -52.36),
    ["Mining Egg"]    = Vector3.new(-120, 10, -64),
    ["Showman Egg"]   = Vector3.new(-130, 10, -60),
    ["Cyber Egg"]     = Vector3.new(-95, 10, -63),
    ["Infinity Egg"]  = Vector3.new(-99, 9, -26),
    ["Neon Egg"]      = Vector3.new(-83, 10, -57)
}
local eggNames = {}
for name in pairs(eggPositions) do table.insert(eggNames, name) end
table.sort(eggNames)

-- Quest definitions
local quests = {
    {ID="HatchMythic",   DisplayName="Hatch mythic pets",    Pattern="mythic"},
    {ID="HatchLegendary", DisplayName="Hatch legendary pets", Pattern="legendary"},
    {ID="HatchEpic",      DisplayName="Hatch epic pets",      Pattern="epic"}
}

-- Hatch amount options
local hatchAmounts = {"1250","950","450","350","200"}

-- Helpers
local function tweenToPosition(pos)
    local speed = Window.Options.TweenSpeed.Value or 30
    local time = (humanoidRootPart.Position - pos).Magnitude / speed
    return TweenService:Create(humanoidRootPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
end

local function hatchEgg(name)
    local pos = eggPositions[name]
    if pos then
        local tw = tweenToPosition(pos)
        tw:Play(); tw.Completed:Wait()
        while (humanoidRootPart.Position - pos).Magnitude > 5 do task.wait(0.1) end
    end
end

local function taskManager()
    while taskAutomationEnabled do
        local success, err = pcall(function()
            local folder = player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Competitive"):WaitForChild("Frame"):WaitForChild("Content"):WaitForChild("Tasks")
            local templates = {}
            for _, f in ipairs(folder:GetChildren()) do
                if f:IsA("Frame") and f.Name == "Template" then table.insert(templates, f) end
            end
            table.sort(templates, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

            local repeatable, protectedSlots = {}, {}
            for i, f in ipairs(templates) do
                if i == 3 or i == 4 then
                    table.insert(repeatable, {title = f.Content.Label.Text, type = f.Content.Type.Text, slot = i})
                end
            end

            local highest
            for _, q in ipairs(quests) do
                if table.find(activeQuests, q.ID) then
                    for _, t in ipairs(repeatable) do
                        if t.type == "Repeatable" and t.title:lower():find(q.Pattern, 1, true) then
                            protectedSlots[t.slot] = true
                            if not highest then
                                local megg
                                for nm in pairs(eggPositions) do
                                    if t.title:lower():find(nm:lower(), 1, true) then megg = nm; break end
                                end
                                highest = {egg = megg or Window.Options.FallbackEgg.Value}
                            end
                        end
                    end
                end
            end

            if highest then hatchEgg(highest.egg) end

            local reroll = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
            for _, t in ipairs(repeatable) do
                if t.type == "Repeatable" and not protectedSlots[t.slot] then
                    reroll:FireServer("CompetitiveReroll", t.slot)
                    task.wait(0.3)
                end
            end
        end)
        if not success then warn("[ERROR] TaskManager:", getErrorMessage(err)) end
        task.wait(0.2)
    end
end

-- Start/stop automation
local function startStopAutomation(on)
    taskAutomationEnabled = on; getgenv().autoPressE = on
    if on then
        task.spawn(taskManager)
        task.spawn(function()
            while getgenv().autoPressE do
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait()
            end
        end)
    end
end

local function refreshUI(opts)
    for k, v in pairs(opts) do
        if Window.Options[k] then Window.Options[k]:SetValue(v) end
    end
end

-- Build UI: Main

table.insert(ConfigToSave, "AutoTasks")
MainTab:AddToggle("AutoTasks", {Title = "Enable Auto Complete", Default = LoadedOptions.AutoTasks or false, Callback = startStopAutomation})

table.insert(ConfigToSave, "FallbackEgg")
MainTab:AddDropdown("FallbackEgg", {Title = "Fallback Egg", Values = eggNames, Default = LoadedOptions.FallbackEgg or eggNames[1]})

table.insert(ConfigToSave, "TweenSpeed")
MainTab:AddSlider("TweenSpeed", {Title = "Character Tween Speed", Min = 16, Max = 60, Default = LoadedOptions.TweenSpeed or 30, Rounding = 0})

table.insert(ConfigToSave, "HatchAmount")
MainTab:AddDropdown("HatchAmount", {Title = "Number of eggs to hatch", Values = hatchAmounts, Default = LoadedOptions.HatchAmount or hatchAmounts[1]})

-- Quest checklist
local labels, defaults = {}, {}
for _, q in ipairs(quests) do
    table.insert(labels, q.DisplayName)
    if LoadedOptions.ActiveQuests and table.find(LoadedOptions.ActiveQuests, q.ID) then
        table.insert(defaults, q.DisplayName)
    end
end
QuestTab:AddList("ActiveQuests", {
    Title = "Enable quest categories:",
    Values = labels,
    Default = defaults,
    Multi = true,
    Callback = function(sel)
        activeQuests = {}
        for _, lbl in ipairs(sel) do
            for _, q in ipairs(quests) do
                if q.DisplayName == lbl then table.insert(activeQuests, q.ID) end
            end
        end
    end
})

-- EggSettingsTab: per-quest fallback eggs
EggSettingsTab:AddParagraph({Title = "Preferred Egg for each quest:"})
for _, q in ipairs(quests) do
    local id = "EggFor_" .. q.ID
    table.insert(ConfigToSave, id)
    EggSettingsTab:AddDropdown(id, {Title = q.DisplayName, Values = eggNames, Default = LoadedOptions[id] or eggPositions[1] and eggNames[1]})
end

-- ConfigTab
ConfigTab:AddParagraph({Title = "Save / Load Settings"})
ConfigTab:AddButton({
    Title = "Save Settings",
    Callback = function()
        local s = {}
        for _, key in ipairs(ConfigToSave) do s[key] = Window.Options[key].Value end
        s.ActiveQuests = activeQuests
        s.HatchAmount = Window.Options.HatchAmount.Value
        local ok, err = SaveManager:Save("default")
        Fluent:Notify(ok and {Title = "Success", Content = "Settings saved"} or {Title = "Error", Content = getErrorMessage(err), Duration = 8})
    end
})
ConfigTab:AddButton({
    Title = "Load Settings",
    Callback = function()
        local ok, data = SaveManager:Load("default")
        if ok and type(data) == "table" then
            refreshUI(data)
            -- restore checklist
            local sel = {}
            for _, q in ipairs(quests) do
                if data.ActiveQuests and table.find(data.ActiveQuests, q.ID) then
                    table.insert(sel, q.DisplayName)
                end
            end
            Window.Options.ActiveQuests:SetValue(sel)
            Fluent:Notify({Title = "Success", Content = "Settings loaded"})
        else
            Fluent:Notify({Title = "Error", Content = getErrorMessage(data), Duration = 8})
        end
    end
})
ConfigTab:AddButton({
    Title = "Reset Settings",
    Callback = function()
        local defaults = { AutoTasks = false, FallbackEgg = eggNames[1], TweenSpeed = 30, HatchAmount = hatchAmounts[1] }
        defaults.ActiveQuests = {}
        for _, q in ipairs(quests) do defaults["EggFor_"..q.ID] = eggNames[1] end
        refreshUI(defaults)
        Window.Options.ActiveQuests:SetValue({})
        SaveManager:Save("default")
        Fluent:Notify({Title = "Success", Content = "Defaults restored", Duration = 5})
    end
})

-- Startup apply
local ok2, d2 = SaveManager:Load("default")
if ok2 and type(d2) == "table" then
    refreshUI(d2)
    local sel = {}
    for _, q in ipairs(quests) do
        if d2.ActiveQuests and table.find(d2.ActiveQuests, q.ID) then
            table.insert(sel, q.DisplayName)
        end
    end
    Window.Options.ActiveQuests:SetValue(sel)
else
    Fluent:Notify({Title = "Warning", Content = "Could not load settings: "..tostring(d2), Duration = 5})
end

Window:SelectTab(1)
Window:Show()

task.defer(function()
    Fluent:Notify({Title = "Script Loaded", Content = "Ready!", Duration = 5})
    if Window.Options.AutoTasks.Value then startStopAutomation(true) end
end)
-- Utility to stringify errors
local function getErrorMessage(err)
    if type(err) == "string" then return err
    elseif type(err) == "table" then
        local parts = {}
        for k, v in pairs(err) do
            local valueStr = type(v) == "table" and getErrorMessage(v) or tostring(v)
            table.insert(parts, tostring(k) .. ": " .. valueStr)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else return tostring(err) end
end

-- Load libraries
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("ShitassCompScriptConfigV3")

-- Load saved options
local LoadedOptions = {}
local okLoad, loadedData = SaveManager:Load("default")
if okLoad and type(loadedData) == "table" then
    for k, v in pairs(loadedData) do LoadedOptions[k] = v end
end

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

-- Tabs
local MainTab        = Window:AddTab({ Title = "Main", Icon = "home" })
local QuestTab       = Window:AddTab({ Title = "Quests", Icon = "edit" })
local EggSettingsTab = Window:AddTab({ Title = "Egg Settings", Icon = "settings" })
local ConfigTab      = Window:AddTab({ Title = "Config", Icon = "folder" })

-- Services & refs
local TweenService        = game:GetService("TweenService")
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- State
local taskAutomationEnabled = false
local activeQuests = {}
local ConfigToSave = {}

-- Egg data
local eggPositions = {
    ["Common Egg"]    = Vector3.new(-83.86, 10.11, 1.57),
    ["Spotted Egg"]   = Vector3.new(-93.96, 10.11, 7.41),
    ["Iceshard Egg"]  = Vector3.new(-117.06, 10.11, 7.74),
    ["Spikey Egg"]    = Vector3.new(-124.58, 10.11, 4.58),
    ["Magma Egg"]     = Vector3.new(-133.02, 10.11, -1.55),
    ["Crystal Egg"]   = Vector3.new(-140.2, 10.11, -8.36),
    ["Lunar Egg"]     = Vector3.new(-143.85, 10.11, -15.93),
    ["Void Egg"]      = Vector3.new(-145.91, 10.11, -26.13),
    ["Hell Egg"]      = Vector3.new(-145.17, 10.11, -36.78),
    ["Nightmare Egg"] = Vector3.new(-142.35, 10.11, -45.15),
    ["Rainbow Egg"]   = Vector3.new(-134.49, 10.11, -52.36),
    ["Mining Egg"]    = Vector3.new(-120, 10, -64),
    ["Showman Egg"]   = Vector3.new(-130, 10, -60),
    ["Cyber Egg"]     = Vector3.new(-95, 10, -63),
    ["Infinity Egg"]  = Vector3.new(-99, 9, -26),
    ["Neon Egg"]      = Vector3.new(-83, 10, -57)
}
local eggNames = {}
for name in pairs(eggPositions) do table.insert(eggNames, name) end
table.sort(eggNames)

-- Quest definitions
local quests = {
    {ID="HatchMythic",   DisplayName="Hatch mythic pets",    Pattern="mythic"},
    {ID="HatchLegendary", DisplayName="Hatch legendary pets", Pattern="legendary"},
    {ID="HatchEpic",      DisplayName="Hatch epic pets",      Pattern="epic"}
}

-- Hatch amount options
local hatchAmounts = {"1250","950","450","350","200"}

-- Helpers
local function tweenToPosition(pos)
    local speed = Window.Options.TweenSpeed.Value or 30
    local time = (humanoidRootPart.Position - pos).Magnitude / speed
    return TweenService:Create(humanoidRootPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
end

local function hatchEgg(name)
    local pos = eggPositions[name]
    if pos then
        local tw = tweenToPosition(pos)
        tw:Play(); tw.Completed:Wait()
        while (humanoidRootPart.Position - pos).Magnitude > 5 do task.wait(0.1) end
    end
end

local function taskManager()
    while taskAutomationEnabled do
        local success, err = pcall(function()
            local folder = player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Competitive"):WaitForChild("Frame"):WaitForChild("Content"):WaitForChild("Tasks")
            local templates = {}
            for _, f in ipairs(folder:GetChildren()) do
                if f:IsA("Frame") and f.Name == "Template" then table.insert(templates, f) end
            end
            table.sort(templates, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

            local repeatable, protectedSlots = {}, {}
            for i, f in ipairs(templates) do
                if i == 3 or i == 4 then
                    table.insert(repeatable, {title = f.Content.Label.Text, type = f.Content.Type.Text, slot = i})
                end
            end

            local highest
            for _, q in ipairs(quests) do
                if table.find(activeQuests, q.ID) then
                    for _, t in ipairs(repeatable) do
                        if t.type == "Repeatable" and t.title:lower():find(q.Pattern, 1, true) then
                            protectedSlots[t.slot] = true
                            if not highest then
                                local megg
                                for nm in pairs(eggPositions) do
                                    if t.title:lower():find(nm:lower(), 1, true) then megg = nm; break end
                                end
                                highest = {egg = megg or Window.Options.FallbackEgg.Value}
                            end
                        end
                    end
                end
            end

            if highest then hatchEgg(highest.egg) end

            local reroll = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
            for _, t in ipairs(repeatable) do
                if t.type == "Repeatable" and not protectedSlots[t.slot] then
                    reroll:FireServer("CompetitiveReroll", t.slot)
                    task.wait(0.3)
                end
            end
        end)
        if not success then warn("[ERROR] TaskManager:", getErrorMessage(err)) end
        task.wait(0.2)
    end
end

-- Start/stop automation
local function startStopAutomation(on)
    taskAutomationEnabled = on; getgenv().autoPressE = on
    if on then
        task.spawn(taskManager)
        task.spawn(function()
            while getgenv().autoPressE do
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                task.wait()
            end
        end)
    end
end

local function refreshUI(opts)
    for k, v in pairs(opts) do
        if Window.Options[k] then Window.Options[k]:SetValue(v) end
    end
end

-- Build UI: Main

table.insert(ConfigToSave, "AutoTasks")
MainTab:AddToggle("AutoTasks", {Title = "Enable Auto Complete", Default = LoadedOptions.AutoTasks or false, Callback = startStopAutomation})

table.insert(ConfigToSave, "FallbackEgg")
MainTab:AddDropdown("FallbackEgg", {Title = "Fallback Egg", Values = eggNames, Default = LoadedOptions.FallbackEgg or eggNames[1]})

table.insert(ConfigToSave, "TweenSpeed")
MainTab:AddSlider("TweenSpeed", {Title = "Character Tween Speed", Min = 16, Max = 60, Default = LoadedOptions.TweenSpeed or 30, Rounding = 0})

table.insert(ConfigToSave, "HatchAmount")
MainTab:AddDropdown("HatchAmount", {Title = "Number of eggs to hatch", Values = hatchAmounts, Default = LoadedOptions.HatchAmount or hatchAmounts[1]})

-- Quest checklist
local labels, defaults = {}, {}
for _, q in ipairs(quests) do
    table.insert(labels, q.DisplayName)
    if LoadedOptions.ActiveQuests and table.find(LoadedOptions.ActiveQuests, q.ID) then
        table.insert(defaults, q.DisplayName)
    end
end
QuestTab:AddList("ActiveQuests", {
    Title = "Enable quest categories:",
    Values = labels,
    Default = defaults,
    Multi = true,
    Callback = function(sel)
        activeQuests = {}
        for _, lbl in ipairs(sel) do
            for _, q in ipairs(quests) do
                if q.DisplayName == lbl then table.insert(activeQuests, q.ID) end
            end
        end
    end
})

-- EggSettingsTab: per-quest fallback eggs
EggSettingsTab:AddParagraph({Title = "Preferred Egg for each quest:"})
for _, q in ipairs(quests) do
    local id = "EggFor_" .. q.ID
    table.insert(ConfigToSave, id)
    EggSettingsTab:AddDropdown(id, {Title = q.DisplayName, Values = eggNames, Default = LoadedOptions[id] or eggPositions[1] and eggNames[1]})
end

-- ConfigTab
ConfigTab:AddParagraph({Title = "Save / Load Settings"})
ConfigTab:AddButton({
    Title = "Save Settings",
    Callback = function()
        local s = {}
        for _, key in ipairs(ConfigToSave) do s[key] = Window.Options[key].Value end
        s.ActiveQuests = activeQuests
        s.HatchAmount = Window.Options.HatchAmount.Value
        local ok, err = SaveManager:Save("default")
        Fluent:Notify(ok and {Title = "Success", Content = "Settings saved"} or {Title = "Error", Content = getErrorMessage(err), Duration = 8})
    end
})
ConfigTab:AddButton({
    Title = "Load Settings",
    Callback = function()
        local ok, data = SaveManager:Load("default")
        if ok and type(data) == "table" then
            refreshUI(data)
            -- restore checklist
            local sel = {}
            for _, q in ipairs(quests) do
                if data.ActiveQuests and table.find(data.ActiveQuests, q.ID) then
                    table.insert(sel, q.DisplayName)
                end
            end
            Window.Options.ActiveQuests:SetValue(sel)
            Fluent:Notify({Title = "Success", Content = "Settings loaded"})
        else
            Fluent:Notify({Title = "Error", Content = getErrorMessage(data), Duration = 8})
        end
    end
})
ConfigTab:AddButton({
    Title = "Reset Settings",
    Callback = function()
        local defaults = { AutoTasks = false, FallbackEgg = eggNames[1], TweenSpeed = 30, HatchAmount = hatchAmounts[1] }
        defaults.ActiveQuests = {}
        for _, q in ipairs(quests) do defaults["EggFor_"..q.ID] = eggNames[1] end
        refreshUI(defaults)
        Window.Options.ActiveQuests:SetValue({})
        SaveManager:Save("default")
        Fluent:Notify({Title = "Success", Content = "Defaults restored", Duration = 5})
    end
})

-- Startup apply
local ok2, d2 = SaveManager:Load("default")
if ok2 and type(d2) == "table" then
    refreshUI(d2)
    local sel = {}
    for _, q in ipairs(quests) do
        if d2.ActiveQuests and table.find(d2.ActiveQuests, q.ID) then
            table.insert(sel, q.DisplayName)
        end
    end
    Window.Options.ActiveQuests:SetValue(sel)
else
    Fluent:Notify({Title = "Warning", Content = "Could not load settings: "..tostring(d2), Duration = 5})
end

Window:SelectTab(1)
Window:Show()

task.defer(function()
    Fluent:Notify({Title = "Script Loaded", Content = "Ready!", Duration = 5})
    if Window.Options.AutoTasks.Value then startStopAutomation(true) end
end)
