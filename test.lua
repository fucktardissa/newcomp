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
local questToggles = {}
local ConfigToSave = {}

-- Egg positions
local eggPositions = {
    ["Common Egg"]    = Vector3.new(-83.86,10.11,1.57),
    ["Spotted Egg"]   = Vector3.new(-93.96,10.11,7.41),
    ["Iceshard Egg"]  = Vector3.new(-117.06,10.11,7.74),
    ["Spikey Egg"]    = Vector3.new(-124.58,10.11,4.58),
    ["Magma Egg"]     = Vector3.new(-133.02,10.11,-1.55),
    ["Crystal Egg"]   = Vector3.new(-140.2,10.11,-8.36),
    ["Lunar Egg"]     = Vector3.new(-143.85,10.11,-15.93),
    ["Void Egg"]      = Vector3.new(-145.91,10.11,-26.13),
    ["Hell Egg"]      = Vector3.new(-145.17,10.11,-36.78),
    ["Nightmare Egg"] = Vector3.new(-142.35,10.11,-45.15),
    ["Rainbow Egg"]   = Vector3.new(-134.49,10.11,-52.36),
    ["Mining Egg"]    = Vector3.new(-120,10,-64),
    ["Showman Egg"]   = Vector3.new(-130,10,-60),
    ["Cyber Egg"]     = Vector3.new(-95,10,-63),
    ["Infinity Egg"]  = Vector3.new(-99,9,-26),
    ["Neon Egg"]      = Vector3.new(-83,10,-57)
}
local eggNames = {}
for name in pairs(eggPositions) do table.insert(eggNames,name) end
table.sort(eggNames)

-- Quest definitions
local quests = {
    {ID="HatchMythic",   DisplayName="Hatch mythic pets",    Pattern="mythic",    DefaultEgg="Mining Egg"},
    {ID="HatchLegendary", DisplayName="Hatch legendary pets", Pattern="legendary", DefaultEgg="Mining Egg"},
    {ID="HatchShiny",     DisplayName="Hatch shiny pets",     Pattern="shiny",     DefaultEgg="Mining Egg"},
    {ID="HatchEpic",      DisplayName="Hatch epic pets",      Pattern="epic",      DefaultEgg="Spikey Egg"},
    {ID="HatchRare",      DisplayName="Hatch rare pets",      Pattern="rare",      DefaultEgg="Spikey Egg"},
    {ID="HatchCommon",    DisplayName="Hatch common pets",    Pattern="common",    DefaultEgg="Common Egg"},
    {ID="HatchUnique",    DisplayName="Hatch unique pets",    Pattern="unique",    DefaultEgg="Spikey Egg"},
    {ID="Hatch1250",      DisplayName="Hatch 1250 eggs",      Pattern="1250",      DefaultEgg="Spikey Egg"},
    {ID="Hatch950",       DisplayName="Hatch 950 eggs",       Pattern="950",      DefaultEgg="Spikey Egg"},
    {ID="Hatch450",       DisplayName="Hatch 450 eggs",       Pattern="450",      DefaultEgg="Spikey Egg"},
    {ID="Hatch350",       DisplayName="Hatch 350 eggs",       Pattern="350",      DefaultEgg="Spikey Egg"},
    {ID="Hatch200",       DisplayName="Hatch 200 eggs",       Pattern="200",      DefaultEgg="Spikey Egg"}
}

-- Helpers
local function tweenToPosition(position)
    local speed = Window.Options.TweenSpeed.Value or 30
    local time = (humanoidRootPart.Position - position).Magnitude / speed
    return TweenService:Create(humanoidRootPart, TweenInfo.new(time,Enum.EasingStyle.Linear),{CFrame=CFrame.new(position)})
end
local function hatchEgg(eggName)
    local pos=eggPositions[eggName]
    if pos then
        local tw=tweenToPosition(pos);tw:Play();tw.Completed:Wait()
        while (humanoidRootPart.Position-pos).Magnitude>5 do task.wait(0.1) end
    end
end
local function taskManager()
    while taskAutomationEnabled do
        local ok,err=pcall(function()
            local folder=player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Competitive"):WaitForChild("Frame"):WaitForChild("Content"):WaitForChild("Tasks")
            local templ={}
            for _,f in ipairs(folder:GetChildren()) do if f:IsA("Frame") and f.Name=="Template" then table.insert(templ,f) end end
            table.sort(templ,function(a,b)return a.LayoutOrder<b.LayoutOrder end)
            local repeatable={},protected={}
            repeatable,protected={},{}
            for i,f in ipairs(templ) do if i==3 or i==4 then table.insert(repeatable,{title=f.Content.Label.Text,type=f.Content.Type.Text,slot=i}) end end
            local highest
            for _,q in ipairs(quests) do
                local tog=questToggles[q.ID]
                if tog and tog.Value then
                    for _,t in ipairs(repeatable) do
                        if t.type=="Repeatable" and t.title:lower():find(q.Pattern,1,true) then
                            protected[t.slot]=true
                            if not highest then
                                local matchEgg
                                for nm in pairs(eggPositions) do if t.title:lower():find(nm:lower(),1,true) then matchEgg=nm;break end end
                                highest={egg=matchEgg or tog.Value and Window.Options["EggFor_"..q.ID].Value or q.DefaultEgg}
                            end
                        end
                    end
                end
            end
            if highest then hatchEgg(highest.egg) end
            local reroll=ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
            for _,t in ipairs(repeatable) do if t.type=="Repeatable" and not protected[t.slot] then reroll:FireServer("CompetitiveReroll",t.slot);task.wait(0.3) end end
        end)
        if not ok then warn("[ERROR] Task manager error:",getErrorMessage(err)) end
        task.wait(0.2)
    end
end

-- Start/stop automation
local function startStopAutomation(v)
    taskAutomationEnabled=v;getgenv().autoPressE=v
    if v then task.spawn(taskManager);task.spawn(function() while getgenv().autoPressE do VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game);task.wait();VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game);task.wait() end end) end
end

local function refreshUI(options)
    for k,v in pairs(options) do if Window.Options[k] then Window.Options[k]:SetValue(v) end end
end

-- Build UI
-- Main
local autoToggle=MainTab:AddToggle("AutoTasks",{Title="Enable Auto Complete",Default=LoadedOptions.AutoTasks or false,Callback=startStopAutomation})
table.insert(ConfigToSave,"AutoTasks")
MainTab:AddDropdown("FallbackEgg",{Title="Fallback Egg",Values=eggNames,Default=LoadedOptions.FallbackEgg or "Infinity Egg"});table.insert(ConfigToSave,"FallbackEgg")
MainTab:AddSlider("TweenSpeed",{Title="Character Tween Speed",Min=16,Max=60,Default=LoadedOptions.TweenSpeed or 30,Rounding=0});table.insert(ConfigToSave,"TweenSpeed")

-- Quests
QuestTab:AddParagraph({Title="Enable quest categories to complete:"})
for _,q in ipairs(quests) do
    local id="Quest_"..q.ID
    questToggles[q.ID]=QuestTab:AddToggle(id,{Title=q.DisplayName,Default=LoadedOptions[id] or false})
    table.insert(ConfigToSave,id)
end

-- Egg Settings
EggSettingsTab:AddParagraph({Title="Preferred Egg for each quest:"})
for _,q in ipairs(quests) do
    local id="EggFor_"..q.ID
    EggSettingsTab:AddDropdown(id,{Title=q.DisplayName,Values=eggNames,Default=LoadedOptions[id] or q.DefaultEgg})
    table.insert(ConfigToSave,id)
end

-- Config
ConfigTab:AddParagraph({Title="Save / Load Settings"})
ConfigTab:AddButton({Title="Save Settings",Callback=function()
    local settings={}
    for _,k in ipairs(ConfigToSave) do settings[k]=Window.Options[k].Value end
    local ok,err=SaveManager:Save("default")
    Fluent:Notify(ok and {Title="Success",Content="Settings saved"} or {Title="Error",Content=getErrorMessage(err),Duration=8})
end})
ConfigTab:AddButton({Title="Load Settings",Callback=function()
    local ok,data=SaveManager:Load("default")
    if ok and type(data)=="table" then
        refreshUI(data)
        Fluent:Notify({Title="Success",Content="Settings loaded and applied"})
    else
        Fluent:Notify({Title="Error",Content=getErrorMessage(data),Duration=8})
    end
end})
ConfigTab:AddButton({Title="Reset Settings",Callback=function()
    local defaults={AutoTasks=false,FallbackEgg="Infinity Egg",TweenSpeed=30}
    for _,q in ipairs(quests) do defaults["Quest_"..q.ID]=false;defaults["EggFor_"..q.ID]=q.DefaultEgg end
    refreshUI(defaults)
    SaveManager:Save("default")
    Fluent:Notify({Title="Success",Content="Defaults restored",Duration=5})
end})

-- Startup apply
local ok2,data2=SaveManager:Load("default")
if ok2 and type(data2)=="table" then refreshUI(data2) else Fluent:Notify({Title="Warning",Content="Could not load settings: "..tostring(data2),Duration=5}) end

Window:SelectTab(1)
Window:Show()

task.defer(function() Fluent:Notify({Title="Script Loaded",Content="Ready!",Duration=5}) if Window.Options.AutoTasks.Value then startStopAutomation(true) end end)
