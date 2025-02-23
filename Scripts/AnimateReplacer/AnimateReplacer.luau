-- Версия и конфигурация
local VERSION = "1.1"
local DEFAULT_CONFIG = {
    animationPack = "Levitation",
    includeToStarterAnimate = false,
    autoRestore = true,
    notifyOnChange = true
}

-- Сервисы
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

-- Локальные переменные
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animate = Character:WaitForChild("Animate")

-- Расширенный список анимаций
local AnimationPacks = {
    ["Levitation"] = {
        climb = { ClimbAnim = "http://www.roblox.com/asset/?id=10921132092" },
        fall = { FallAnim = "http://www.roblox.com/asset/?id=10921136539" },
        idle = {
            Animation1 = "http://www.roblox.com/asset/?id=10921132962",
            Animation2 = "http://www.roblox.com/asset/?id=10921133721"
        },
        jump = { JumpAnim = "http://www.roblox.com/asset/?id=10921137402" },
        run = { RunAnim = "http://www.roblox.com/asset/?id=10921135644" },
        swim = { Swim = "http://www.roblox.com/asset/?id=10921138209" },
        swimidle = { SwimIdle = "http://www.roblox.com/asset/?id=10921139478" },
        walk = { WalkAnim = "http://www.roblox.com/asset/?id=10921140719" }
    },
    ["Stylized Female"] = {
        climb = { ClimbAnim = "http://www.roblox.com/asset/?id=4708184253" },
        fall = { FallAnim = "http://www.roblox.com/asset/?id=4708186162" },
        idle = {
            Animation1 = "http://www.roblox.com/asset/?id=4708191566",
            Animation2 = "http://www.roblox.com/asset/?id=4708192150"
        },
        jump = { JumpAnim = "http://www.roblox.com/asset/?id=4708188025" },
        run = { RunAnim = "http://www.roblox.com/asset/?id=4708192705" },
        swim = { Swim = "http://www.roblox.com/asset/?id=4708189360" },
        swimidle = { SwimIdle = "http://www.roblox.com/asset/?id=4708190607" },
        walk = { WalkAnim = "http://www.roblox.com/asset/?id=4708193840" }
    },
    -- Добавьте новые наборы анимаций здесь
}

-- Утилиты
local Utility = {}

function Utility.IsR15(character)
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    return humanoid and humanoid.RigType == Enum.HumanoidRigType.R15
end

function Utility.Notify(title, message, duration)
    if DEFAULT_CONFIG.notifyOnChange then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 3
        })
    end
end

-- Основной класс AnimationReplacer
local AnimationReplacer = {}
AnimationReplacer.__index = AnimationReplacer

function AnimationReplacer.new(config)
    local self = setmetatable({}, AnimationReplacer)
    self.config = config or DEFAULT_CONFIG
    self.originalAnimations = {}
    self.currentPack = nil
    return self
end

function AnimationReplacer:SaveOriginalAnimations()
    if not Animate then return end
    
    local function saveAnimations(animate)
        local original = {}
        for _, category in pairs(animate:GetChildren()) do
            if category:IsA("Folder") then
                original[category.Name] = {}
                for _, anim in pairs(category:GetChildren()) do
                    if anim:IsA("Animation") then
                        original[category.Name][anim.Name] = anim.AnimationId
                    end
                end
            end
        end
        return original
    end
    
    self.originalAnimations = saveAnimations(Animate)
end

function AnimationReplacer:RestoreOriginalAnimations()
    if not Animate or not self.originalAnimations then return end
    
    for category, animations in pairs(self.originalAnimations) do
        local folder = Animate:FindFirstChild(category)
        if folder then
            for animName, animId in pairs(animations) do
                local anim = folder:FindFirstChild(animName)
                if anim and anim:IsA("Animation") then
                    anim.AnimationId = animId
                end
            end
        end
    end
    
    Utility.Notify("Animations Restored", "Original animations have been restored", 3)
end

function AnimationReplacer:ReplaceAnimations(packName)
    if not AnimationPacks[packName] then
        Utility.Notify("Error", "Animation pack not found: " .. packName, 3)
        return false
    end
    
    local success, error = pcall(function()
        local pack = AnimationPacks[packName]
        Animate.Disabled = true
        
        -- Замена анимаций
        for category, animations in pairs(pack) do
            local folder = Animate:FindFirstChild(category)
            if folder then
                for animName, animId in pairs(animations) do
                    local anim = folder:FindFirstChild(animName)
                    if anim and anim:IsA("Animation") then
                        anim.AnimationId = animId
                    end
                end
            end
        end
        
        -- Обработка StarterAnimate если включено
        if self.config.includeToStarterAnimate then
            local starterAnimate = StarterPlayer.StarterCharacterScripts:FindFirstChild("Animate")
            if starterAnimate then
                for category, animations in pairs(pack) do
                    local folder = starterAnimate:FindFirstChild(category)
                    if folder then
                        for animName, animId in pairs(animations) do
                            local anim = folder:FindFirstChild(animName)
                            if anim and anim:IsA("Animation") then
                                anim.AnimationId = animId
                            end
                        end
                    end
                end
            end
        end
        
        Animate.Disabled = false
        self.currentPack = packName
    end)
    
    if success then
        Utility.Notify("Success", "Animations replaced with " .. packName, 3)
        return true
    else
        Utility.Notify("Error", "Failed to replace animations: " .. error, 3)
        return false
    end
end

-- Инициализация и обработка событий
local function Initialize()
    local animator = AnimationReplacer.new(DEFAULT_CONFIG)
    animator:SaveOriginalAnimations()
    
    -- Обработка смены персонажа
    Player.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter
        Animate = Character:WaitForChild("Animate")
        
        if animator.currentPack then
            animator:ReplaceAnimations(animator.currentPack)
        end
    end)
    
    -- Применение начального набора анимаций
    animator:ReplaceAnimations(DEFAULT_CONFIG.animationPack)
    
    return animator
end

-- Создание UI для управления анимациями (опционально)
local function CreateAnimationUI()
    local ScreenGui = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")
    
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    Frame.Size = UDim2.new(0, 200, 0, 300)
    Frame.Position = UDim2.new(0.85, 0, 0.5, 0)
    Frame.BackgroundTransparency = 0.5
    Frame.Parent = ScreenGui
    
    UIListLayout.Parent = Frame
    
    for packName, _ in pairs(AnimationPacks) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 30)
        button.Text = packName
        button.Parent = Frame
        button.MouseButton1Click:Connect(function()
            animator:ReplaceAnimations(packName)
        end)
    end
end

-- Запуск
local animator = Initialize()
if DEFAULT_CONFIG.showUI then
    CreateAnimationUI()
end

return animator
