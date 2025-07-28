--4
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "shitass comp script v3",
    SubTitle = "made by lonly on discord",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Let SaveManager handle the initial load and option tracking, but we will override the manual save/load.
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("ShitassCompScriptConfigV3")
local LoadedOptions = SaveManager:Load() or {}
local ConfigToSave = {}

local MainTab = Window:AddTab({ Title = "Main", Icon = "home" })
local QuestTab = Window:AddTab({ Title = "Quests", Icon = "edit" })
local EggSettingsTab = Window:AddTab({ Title = "Egg Settings", Icon = "settings" })
local ConfigTab = Window:AddTab({ Title = "Config", Icon = "folder" })

local tweenService = game:GetService("TweenService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local httpService = game:GetService("HttpService") -- NEW: For reliable saving/loading

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local taskAutomationEnabled = false

local questToggles = {}

-- ... (all the egg and quest data remains the same) ...
local eggPositions = {["Common Egg"]=Vector3.new(-83.86,10.11,1.57),["Spotted Egg"]=Vector3.new(-93.96,10.11,7.41),["Iceshard Egg"]=Vector3.new(-117.06,10.11,7.74),["Spikey Egg"]=Vector3.new(-124.58,10.11,4.58),["Magma Egg"]=Vector3.new(-133.02,10.11,-1.55),["Crystal Egg"]=Vector3.new(-140.2,10.11,-8.36),["Lunar Egg"]=Vector3.new(-143.85,10.11,-15.93),["Void Egg"]=Vector3.new(-145.91,10.11,-26.13),["Hell Egg"]=Vector3.new(-145.17,10.11,-36.78),["Nightmare Egg"]=Vector3.new(-142.35,10.11,-45.15),["Rainbow Egg"]=Vector3.new(-134.49,10.11,-52.36),["Mining Egg"]=Vector3.new(-120,10,-64),["Showman Egg"]=Vector3.new(-130,10,-60),["Cyber Egg"]=Vector3.new(-95,10,-63),["Infinity Egg"]=Vector3.new(-99,9,-26),["Neon Egg"]=Vector3.new(-83,10,-57)}
local eggNames = {} for n in pairs(eggPositions) do table.insert(eggNames, n) end table.sort(eggNames)
local quests = {{ID="HatchMythic",DisplayName="Hatch mythic pets",Pattern="mythic",DefaultEgg="Mining Egg"},{ID="HatchLegendary",DisplayName="Hatch legendary pets",Pattern="legendary",DefaultEgg="Mining Egg"},{ID="HatchShiny",DisplayName="Hatch shiny pets",Pattern="shiny",DefaultEgg="Mining Egg"},{ID="HatchEpic",DisplayName="Hatch epic pets",Pattern="epic",DefaultEgg="Spikey Egg"},{ID="HatchRare",DisplayName="Hatch rare pets",Pattern="rare",DefaultEgg="Spikey Egg"},{ID="HatchCommon",DisplayName="Hatch common pets",Pattern="common",DefaultEgg="Common Egg"},{ID="HatchUnique",DisplayName="Hatch unique pets",Pattern="unique",DefaultEgg="Spikey Egg"},{ID="Hatch1250",DisplayName="Hatch 1250 eggs",Pattern="1250",DefaultEgg="Spikey Egg"},{ID="Hatch950",DisplayName="Hatch 950 eggs",Pattern="950",DefaultEgg="Spikey Egg"},{ID="Hatch450",DisplayName="Hatch 450 eggs",Pattern="450",DefaultEgg="Spikey Egg"},{ID="Hatch350",DisplayName="Hatch 350 eggs",Pattern="350",DefaultEgg="Spikey Egg"},{ID="Hatch200",DisplayName="Hatch 200 eggs",Pattern="200",DefaultEgg="Spikey Egg"}}


-- ... (all the functions like tweenToPosition, hatchEgg, taskManager remain the same) ...
local function tweenToPosition(position) local speed = Window.Options.TweenSpeed.Value or 30 local dist = (humanoidRootPart.Position - position).Magnitude local time = dist / speed local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear) local tween = tweenService:Create(humanoidRootPart, tweenInfo, { CFrame = CFrame.new(position) }) tween:Play() return tween end
local function hatchEgg(eggName) local pos = eggPositions[eggName] if pos then local tween = tweenToPosition(pos) tween.Completed:Wait() while (humanoidRootPart.Position - pos).Magnitude > 5 do task.wait(0.1) end end end
local function taskManager() while taskAutomationEnabled do local success, err = pcall(function() local tasksFolder = player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Competitive"):WaitForChild("Frame"):WaitForChild("Content"):WaitForChild("Tasks") local templates = {} for _, f in ipairs(tasksFolder:GetChildren()) do if f:IsA("Frame") and f.Name == "Template" then table.insert(templates, f) end end table.sort(templates, function(a, b) return a.LayoutOrder < b.LayoutOrder end) local repeatableTasks = {} for index, frame in ipairs(templates) do if index == 3 or index == 4 then local content = frame:FindFirstChild("Content") local titleLabel = content and content:FindFirstChild("Label") local typeLabel = content and content:FindFirstChild("Type") if titleLabel and typeLabel then table.insert(repeatableTasks, {frame = frame,title = titleLabel.Text,type = typeLabel.Text,slot = index}) end end end local highestPriorityAction = nil local protectedSlots = {} for _, questData in ipairs(quests) do local toggle = questToggles[questData.ID] if toggle and toggle.Value then for _, task in ipairs(repeatableTasks) do local lowerTitle = task.title:lower():gsub("%s+", " ") if task.type == "Repeatable" and lowerTitle:find(questData.Pattern, 1, true) then if not protectedSlots[task.slot] then protectedSlots[task.slot] = true end if not highestPriorityAction then local matchedEgg = nil for eggName in pairs(eggPositions) do if lowerTitle:find(eggName:lower():gsub(" egg", ""), 1, true) then matchedEgg = eggName break end end local selectedOption = Window.Options["EggFor_"..questData.ID] local fallbackEgg = (selectedOption and selectedOption.Value) or questData.DefaultEgg local eggToHatch = matchedEgg or fallbackEgg highestPriorityAction = { egg = eggToHatch, title = task.title } end end end end end if highestPriorityAction then hatchEgg(highestPriorityAction.egg) end local rerollRemote = replicatedStorage.Shared.Framework.Network.Remote.RemoteEvent for _, task in ipairs(repeatableTasks) do if task.type == "Repeatable" and not protectedSlots[task.slot] then rerollRemote:FireServer("CompetitiveReroll", task.slot) task.wait(0.3) end end end) if not success then warn("[ERROR] Task manager error:", err) end task.wait(0.2) end end


-- Function to refresh the UI with the latest loaded settings
local function refreshUI(options)
    for optionName, optionValue in pairs(options) do
        if Window.Options[optionName] then
            Window.Options[optionName]:SetValue(optionValue)
        end
    end
end

-- ... (all the UI elements in MainTab, QuestTab, EggSettingsTab remain the same) ...
local autoTasksToggle=MainTab:AddToggle("AutoTasks",{Title="Enable Auto Complete",Default=LoadedOptions.AutoTasks or false,Callback=function(v) taskAutomationEnabled=v getgenv().autoPressE=v if v then task.spawn(taskManager) task.spawn(function() while getgenv().autoPressE do VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game) task.wait() VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game) task.wait() end end) end end}) table.insert(ConfigToSave,"AutoTasks")
MainTab:AddDropdown("FallbackEgg",{Title="Fallback Egg",Values=eggNames,Default=LoadedOptions.FallbackEgg or "Infinity Egg"}) table.insert(ConfigToSave,"FallbackEgg")
MainTab:AddSlider("TweenSpeed",{Title="Character Tween Speed",Min=16,Max=60,Default=LoadedOptions.TweenSpeed or 30,Rounding=0}) table.insert(ConfigToSave,"TweenSpeed")
QuestTab:AddParagraph({Title="Enable quest categories to complete:"}) for _,q in ipairs(quests) do local optionId="Quest_"..q.ID local toggle=QuestTab:AddToggle(optionId,{Title=q.DisplayName,Default=LoadedOptions[optionId] or false}) questToggles[q.ID]=toggle table.insert(ConfigToSave,optionId) end
EggSettingsTab:AddParagraph({Title="Preferred Egg for each quest:"}) for _,q in ipairs(quests) do local optionId="EggFor_"..q.ID EggSettingsTab:AddDropdown(optionId,{Title=q.DisplayName,Values=eggNames,Default=LoadedOptions[optionId] or q.DefaultEgg}) table.insert(ConfigToSave,optionId) end

----------------------------------------------------
--- NEW AND IMPROVED SAVE/LOAD LOGIC BELOW ---
----------------------------------------------------

local FOLDER_NAME = "ShitassCompScriptConfigV3"
local FILE_NAME = "settings.json" -- We will save to a json file.

ConfigTab:AddParagraph({ Title = "Manually save or load your settings." })

ConfigTab:AddButton({
    Title = "Save Settings",
    Callback = function()
        local settings = {}
        -- Gather all current settings from the UI
        for _, key in ipairs(ConfigToSave) do
            if Window.Options[key] then
                settings[key] = Window.Options[key].Value
            end
        end

        -- Convert to JSON and save using the reliable writefile
        local success, result = pcall(function()
            local json_data = httpService:JSONEncode(settings)
            writefile(FOLDER_NAME .. "/" .. FILE_NAME, json_data)
        end)

        if success then
            Fluent:Notify({ Title = "Success", Content = "Settings saved to " .. FILE_NAME })
        else
            Fluent:Notify({ Title = "Error", Content = "Failed to save settings. Error: " .. tostring(result) })
        end
    end
})

ConfigTab:AddButton({
    Title = "Load Settings",
    Callback = function()
        local file_path = FOLDER_NAME .. "/" .. FILE_NAME
        
        -- Check if the file exists first
        if not isfile(file_path) then
            Fluent:Notify({ Title = "Error", Content = "No settings file found. Please save first." })
            return
        end

        -- Load, decode, and apply the settings
        local success, result = pcall(function()
            local json_data = readfile(file_path)
            local loaded_settings = httpService:JSONDecode(json_data)
            refreshUI(loaded_settings)
        end)

        if success then
            Fluent:Notify({ Title = "Success", Content = "Settings have been loaded." })
        else
            Fluent:Notify({ Title = "Error", Content = "Failed to load settings. Error: " .. tostring(result) })
        end
    end
})

-- Let SaveManager build the list of options to track, which we use in our custom save function.
SaveManager:BuildConfig(ConfigToSave)
Window:SelectTab(1)

if autoTasksToggle.Value then
    autoTasksToggle:SetValue(true)
end

Fluent:Notify({
    Title = "Script Loaded",
    Content = "dm me if any problems",
    Duration = 8
})
