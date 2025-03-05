getgenv().ScriptVersion = "v1.0.9"

loadstring(game:HttpGet("https://raw.githubusercontent.com/YG224586/POP/refs/heads/main/core.lua"))()

local Remotes: Folder & {[string]: RemoteEvent & RemoteFunction} = game:GetService("ReplicatedStorage").Remotes

local Interactions: Folder = workspace:WaitForChild("Interactions")

if not Window then
    return
end

local Tab: Tab = Window:CreateTab("战斗", "swords")

Tab:CreateSection("攻击")

Tab:CreateToggle({
    Name = "⚔ • 杀戮光环",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)        
        while Flags.KillAura.CurrentValue and task.wait() do
            local Closest = GetClosestChild(workspace.Characters:GetChildren(), function(Child)
                if Child == Player.Character then
                    return true
                end
            end)

            if not Closest then
                continue
            end

            Remotes.CharactersDamageRemote:FireServer({Closest})
        end
    end,
})

Tab:CreateToggle({
    Name = "🔥 • 呼吸光环 (需开启呼吸)",
    CurrentValue = false,
    Flag = "BreathAura",
    Callback = function(Value)        
        while Flags.BreathAura.CurrentValue and task.wait() do
            local Closest = GetClosestChild(workspace.Characters:GetChildren(), function(Child)
                if Child == Player.Character then
                    return true
                end
            end)

            if not Closest then
                continue
            end

            Remotes.CharactersDamageRemoteBreath:FireServer({Closest})
        end
    end,
})

local Tab: Tab = Window:CreateTab("消耗", "apple")

Tab:CreateSection("食物/饮品")

Tab:CreateToggle({
    Name = "🍴 • 自动吃最近的食物",
    CurrentValue = false,
    Flag = "Eat",
    Callback = function(Value)        
        while Flags.Eat.CurrentValue and task.wait() do
            local Closest = GetClosestChild(Interactions.Food:GetChildren(), function(Child: PVInstance)
                if not Child:GetChildren()[1] then
                    return true
                end

                local Value = Child:GetAttribute("Value")

                if not Value or Value <= 0 then
                    return true
                end
            end)

            if not Closest then
                continue
            end

            Remotes.Food:FireServer(Closest)
        end
    end,
})

Tab:CreateToggle({
    Name = "💧 • 自动喝最近的湖水",
    CurrentValue = false,
    Flag = "Drink",
    Callback = function(Value)        
        while Flags.Drink.CurrentValue and task.wait() do
            local Closest = GetClosestChild(Interactions.Lakes:GetChildren(), function(Child)
                if Child:GetAttribute("Sickly") then
                    return true
                end
            end)

            if not Closest then
                continue
            end

            Remotes.DrinkRemote:FireServer(Closest)
        end
    end,
})

Tab:CreateSection("疾病")

Tab:CreateToggle({
    Name = "💨 • 自动使用最近的泥堆",
    CurrentValue = false,
    Flag = "Mud",
    Callback = function(Value)
        while Flags.Mud.CurrentValue and task.wait() do
            local Closest = GetClosestChild(Interactions.Mud:GetChildren())

            if not Closest then
                continue
            end

            Remotes.Mud:FireServer(Closest)
            task.wait(1)
        end
    end,
})

Tab:CreateSection("物品")

Tab:CreateToggle({
    Name = "💊 • 自动收集生成的代币",
    CurrentValue = false,
    Flag = "Tokens",
    Callback = function(Value)        
        while Flags.Tokens.CurrentValue and task.wait() do
            local Token: MeshPart? = Interactions.SpawnedTokens:GetChildren()[1]

            if not Token then
                continue
            end

            if Remotes.GetSpawnedTokenRemote:InvokeServer() then
                Token:Destroy()
            end
        end
    end,
})

local ResourceNameMap = {
    ["MossPile"] = "苔藓堆",
    ["MossPileLarge"] = "大苔藓堆",
    ["Log"] = "日志",   
}
local function GetResourcesTable()
    local DroppedResources = {}

    for _, Resource: PVInstance in Interactions.DroppedResources:GetChildren() do
        table.insert(DroppedResources, Resource.Name)
    end

    return DroppedResources
end

local ResourcesDropdown
ResourcesDropdown = Tab:CreateDropdown({
    Name = "💎 • 快速捡起资源",
    Options = GetResourcesTable(),
    CurrentOption = "",
    MultipleOptions = false,
    Callback = function(CurrentOption)
        CurrentOption = CurrentOption[1]

        if CurrentOption == "" then
            return
        end

        local Resource = Interactions.DroppedResources:FindFirstChild(CurrentOption)

        if not Resource then
            return
        end

        Remotes.PickupResource:FireServer(Resource)
        ResourcesDropdown:Set({""})
    end,
})

Tab:CreateButton({
    Name = "🔃 • 刷新下拉菜单",
    Callback = function()
        ResourcesDropdown:Refresh(GetResourcesTable())
    end,
})

local Tab: Tab = Window:CreateTab("传送", "wind")

Tab:CreateSection("传送功能")

Tab:CreateButton({
    Name = "🥚 • 传送到废弃蛋",
    Callback = function()
        local Teleported = false

        local Character = Player.Character

        if not Character then
            return Notify("错误", "你没有角色，请先进入游戏。")
        end

        for _, Egg: Model in Interactions.AbandonedEggs:GetChildren() do
            if not Egg:GetChildren()[1] then
                continue
            end

            Character:PivotTo(Egg:GetPivot())
            Teleported = true
            break
        end

        if not Teleported then
            Notify("失败", "找不到废弃蛋")
        end
    end,
})

local WardenShrines = {}

for _, Shrine: Folder in Interactions["Warden Shrines"]:GetChildren() do
    for _, Tablet: MeshPart in Shrine:GetChildren() do
        table.insert(WardenShrines, Tablet.Name)
    end
end

local TeleportWardenShrine
TeleportWardenShrine = Tab:CreateDropdown({
    Name = "⛩ • 传送到守护者神殿",
    Options = WardenShrines,
    CurrentOption = "",
    MultipleOptions = false,
    Callback = function(CurrentOption)
        CurrentOption = CurrentOption[1]

        if CurrentOption == "" then
            return
        end

        local Tablet: MeshPart = Interactions["Warden Shrines"]:FindFirstChild(CurrentOption, true)

        if not Tablet then
            return Notify("错误", `找不到 '{CurrentOption}' 守护者神殿的石碑。`)
        end

        local Character = Player.Character

        if not Character then
            return
        end

        Character:PivotTo(Tablet:GetPivot() + Tablet:GetPivot().LookVector * 5)
        TeleportWardenShrine:Set({""})
    end,
})

local Tab: Tab = Window:CreateTab("安全", "shield")

Tab:CreateSection("伤害")

Tab:CreateToggle({
    Name = "🌋 • 删除所有熔岩池",
    CurrentValue = false,
    Flag = "DeleteLava",
    Callback = function(Value)        
        if not Value then
            return
        end

        Interactions.LavaPools:ClearAllChildren()
    end,
})

Tab:CreateSection("位置")

Tab:CreateToggle({
    Name = "🛡 • 自动隐藏气味",
    CurrentValue = false,
    Flag = "Scent",
    Callback = function(Value)
        while Flags.Scent.CurrentValue and task.wait() do
            Remotes.HideScent:FireServer()

            task.wait(5)
        end
    end,
})

local Tab: Tab = Window:CreateTab("增强", "arrow-big-up-dash")

Tab:CreateSection("氧气")

local InfiniteNumber = 1e9

local function SetModuleFunctions(Value: boolean, BoostName: string, Module, OriginalFunctions: {[string]: () -> ()})
    if Value then
        for _, FunctionName in {`GetMax{BoostName}`, `Get{BoostName}`} do
            OriginalFunctions[FunctionName] = Module[FunctionName]
            print("设置函数:", FunctionName, "现有函数:", Module[FunctionName])
            Module[FunctionName] = function(Data)
                local PropertyName = FunctionName:gsub("Get", "")

                if Data[PropertyName] then
                    Data[PropertyName] = InfiniteNumber
                end

                return 1e9
            end
        end
    else
        for Name, Function in OriginalFunctions do
            Module[Name] = Function
        end
    end
end

local CanUseModules, OxygenModule = pcall(require, game:GetService("ReplicatedStorage")._replicationFolder.OxygenTracker)

local OxygenFunctions = {}

Tab:CreateToggle({
    Name = ApplyUnsupportedName("🌊 • 无限氧气", CanUseModules),
    CurrentValue = false,
    Flag = "Oxygen",
    Callback = function(Value)
        if not CanUseModules then
            return
        end

        SetModuleFunctions(Value, "Oxygen", OxygenModule, OxygenFunctions)
    end,
})

local _, StaminaModule = pcall(require, game:GetService("ReplicatedStorage")._replicationFolder.StaminaTracker)

local StaminaFunctions = {}

Tab:CreateToggle({
    Name = ApplyUnsupportedName("⚡ • 无限体力", CanUseModules),
    CurrentValue = false,
    Flag = "Stamina",
    Callback = function(Value)
        if not CanUseModules then
            return
        end

        SetModuleFunctions(Value, "Stamina", StaminaModule, StaminaFunctions)
    end,
})

local Tab: Tab = Window:CreateTab("重置", "rotate-ccw")

Tab:CreateSection("自杀")

local Suicide = false
local Toggle
Toggle = Tab:CreateToggle({
    Name = "🩸 • 自杀 (会杀死你的生物)",
    CurrentValue = false,
    Callback = function(Value)
        Suicide = Value

        if Value then
            for i = 5, 1, -1 do
                if not Suicide then
                    Notify("取消", "已取消自杀。")
                    break
                end

                Notify("自杀", `将在 {i} 秒后杀死你的生物，关闭以取消。`)
                task.wait(1)
            end
        end

        while Suicide and task.wait() and Player.Character do
            Remotes.LavaSelfDamage:FireServer()
        end

        if Suicide then
            pcall(Toggle.Set, Toggle, false)
            Suicide = false
            Notify("自杀已禁用", "检测到你的死亡，已禁用自杀。")
        end
    end,
})

getgenv().CreateUniversalTabs()