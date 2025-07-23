-- client/utils.lua
Utils = {}

-- Funções de easing
Utils.Easing = {
    Linear = function(t) return t end,
    
    InQuad = function(t) return t * t end,
    
    OutQuad = function(t) return t * (2 - t) end,
    
    InOutQuad = function(t)
        if t < 0.5 then return 2 * t * t end
        return -1 + (4 - 2 * t) * t
    end,
    
    InCubic = function(t) return t * t * t end,
    
    OutCubic = function(t) 
        t = t - 1
        return t * t * t + 1
    end,
    
    InOutCubic = function(t)
        if t < 0.5 then return 4 * t * t * t end
        t = t - 1
        return 4 * t * t * t + 1
    end,
    
    InQuart = function(t) return t * t * t * t end,
    
    OutQuart = function(t)
        t = t - 1
        return 1 - t * t * t * t
    end,
    
    InOutQuart = function(t)
        if t < 0.5 then return 8 * t * t * t * t end
        t = t - 1
        return 1 - 8 * t * t * t * t
    end
}

-- Obter função de easing
function Utils.getEasingFunction(easingType)
    return Utils.Easing[easingType] or Utils.Easing.Linear
end

-- Interpolação linear
function Utils.lerp(startValue, endValue, progress)
    return startValue + (endValue - startValue) * progress
end

-- Interpolação de vetores 3D
function Utils.lerpVector3(startVec, endVec, progress)
    return {
        Utils.lerp(startVec[1], endVec[1], progress),
        Utils.lerp(startVec[2], endVec[2], progress),
        Utils.lerp(startVec[3], endVec[3], progress)
    }
end

-- Converter tabela para string formatada
function Utils.tableToString(tbl, indent)
    if not indent then indent = 0 end
    local str = ""
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent)
        if type(v) == "table" then
            str = str .. formatting .. k .. ":\n" .. Utils.tableToString(v, indent + 1)
        else
            str = str .. formatting .. k .. ": " .. tostring(v) .. "\n"
        end
    end
    return str
end

-- Debug output
function Utils.debug(message, ...)
    if CinematicEditor and CinematicEditor.config.debugMode then
        local args = {...}
        local msg = "[CinematicEditor] " .. message
        if #args > 0 then
            outputChatBox(msg, 100, 200, 255)
        else
            outputChatBox(msg)
        end
    end
end