local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local LocalPlayer = Players.LocalPlayer

-- Load Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local window = Fluent:CreateWindow({
    Title = "Enchant Reroller",
    SubTitle = "by FluentUI",
    Size = UDim2.new(0, 450, 0, 600), -- Use UDim2.new, not fromOffset
    Theme = "Dark",
    Acrylic = true
})


local tab = window:AddTab({Title = "Main", Icon = "settings"})
local opts = Fluent.Options

-- Search + selection list
local filterBox = tab:AddTextbox("filter", {Title = "Search Pet Name", Placeholder = "Type to filter..."}):OnChanged(function(txt)
    updateList(txt)
end)

local dropdown = tab:AddScrollingFrame("petList", {Title = "Pets", Size = UDim2.new(1, 0, 0, 200)})
dropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y

local selected = {}
local petButtons = {}

function updateList(filter)
    dropdown:Clear()  -- assuming such method exists
    for _, btn in ipairs(petButtons) do btn:Destroy() end
    petButtons = {}

    local pets = LocalData:Get().Pets or {}
    for _, pet in ipairs(pets) do
        local name = pet.Name or pet.name or "Unknown"
        if filter == "" or name:lower():find(filter:lower()) then
            local btn = dropdown:AddButton(pet.Id, {Title = name .. " ["..pet.Id.."]"})
            petButtons[#petButtons+1] = btn
            btn:OnClick(function()
                if selected[pet.Id] then
                    selected[pet.Id] = nil
                    btn:SetState(false)
                else
                    selected[pet.Id] = true
                    btn:SetState(true)
                end
            end)
        end
    end
end

-- Enchant inputs
local enchantBox = tab:AddTextbox("enchant", {Title = "Enchant Name", Placeholder = "Enter enchant ID"})
local levelBox = tab:AddTextbox("level", {Title = "Enchant Level", Placeholder = "Enter level"})
local statusLabel = tab:AddLabel("status", {Title = "Status", Content = "Waiting..."})

-- Action buttons
tab:AddButton("start", {
    Title = "Start",
    Description = "Begin reroll loop",
    Callback = function()
        startReroll()
    end
})

tab:AddButton("stop", {
    Title = "Stop",
    Description = "Stop rerolling",
    Callback = function()
        rerolling = false
        statusLabel:SetContent("⏹️ Reroll stopped.")
    end
})

-- Core reroll logic (same as before)
local rerolling = false
local rerollQueue = {}

local function hasDesiredEnchant(pet, id, lvl)
    for _, e in ipairs(pet.Enchants or {}) do
        if e.Id == id and e.Level == tonumber(lvl) then return true end
    end
    return false
end

local function enqueueRerolls(enchant, lvl)
    rerollQueue = {}
    for _, pet in pairs(LocalData:Get().Pets or {}) do
        if selected[pet.Id] and not hasDesiredEnchant(pet, enchant, lvl) then
            table.insert(rerollQueue, pet.Id)
        end
    end
end

function startReroll()
    if next(selected) == nil then
        statusLabel:SetContent("⚠️ Select at least one pet.")
        return
    end
    local enchantId = enchantBox:GetValue():lower()
    local lvl = tonumber(levelBox:GetValue())
    if enchantId == "" or not lvl then
        statusLabel:SetContent("⚠️ Enter valid enchant and level.")
        return
    end
    rerolling = true
    statusLabel:SetContent("⏳ Starting reroll...")
    enqueueRerolls(enchantId, lvl)

    coroutine.wrap(function()
        while rerolling and #rerollQueue > 0 do
            local petId = table.remove(rerollQueue, 1)
            while rerolling do
                local pet
                for _, p in ipairs(LocalData:Get().Pets or {}) do
                    if p.Id == petId then pet = p; break end
                end
                if pet and not hasDesiredEnchant(pet, enchantId, lvl) then
                    RemoteFunction:InvokeServer("RerollEnchants", petId, "Gems")
                    statusLabel:SetContent("🔁 Rerolling "..(pet.Name or petId))
                else
                    statusLabel:SetContent("✅ "..(pet and pet.Name or petId).." has desired enchant.")
                    break
                end
                task.wait(0.3)
            end
            enqueueRerolls(enchantId, lvl)
            task.wait(0.5)
        end

        statusLabel:SetContent("✅ All selected pets have desired enchant. Monitoring...")
        while rerolling do
            for _, pet in ipairs(LocalData:Get().Pets or {}) do
                if selected[pet.Id] and not hasDesiredEnchant(pet, enchantId, lvl) then
                    table.insert(rerollQueue, pet.Id)
                    statusLabel:SetContent("⚠️ "..(pet.Name or pet.Id).." lost desired enchant. Re-queuing...")
                end
            end
            while rerolling and #rerollQueue > 0 do
                local petId = table.remove(rerollQueue,1)
                repeat
                    local curr = nil
                    for _, p in ipairs(LocalData:Get().Pets or {}) do
                        if p.Id == petId then curr = p; break end
                    end
                    if curr and not hasDesiredEnchant(curr, enchantId, lvl) then
                        RemoteFunction:InvokeServer("RerollEnchants", petId, "Gems")
                        statusLabel:SetContent("🔁 Rerolling "..(curr.Name or petId))
                        task.wait(0.3)
                    else
                        statusLabel:SetContent("✅ "..(curr and curr.Name or petId).." is good.")
                        break
                    end
                until not rerolling
            end
            task.wait(2)
        end

        statusLabel:SetContent("⏹️ Reroll stopped.")
    end)()
end

updateList("")  -- initial populate
