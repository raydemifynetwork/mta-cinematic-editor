-- client/keyframes.lua
KeyframeSystem = {}
KeyframeSystem.__index = KeyframeSystem

function KeyframeSystem:new(editor)
    local self = setmetatable({}, KeyframeSystem)
    
    self.editor = editor
    self.keyframes = {}
    self.selectedKeyframe = nil
    self.maxKeyframes = 100
    
    return self
end

function KeyframeSystem:addKeyframe(position, rotation, time, easing)
    if #self.keyframes >= self.maxKeyframes then
        Utils.debug("Limite máximo de keyframes atingido!", true)
        return nil
    end
    
    local keyframe = {
        id = #self.keyframes + 1,
        time = time or 2000,
        position = {position[1], position[2], position[3]},
        rotation = {rotation[1], rotation[2], rotation[3]},
        easing = easing or "Linear",
        timestamp = getTickCount()
    }
    
    table.insert(self.keyframes, keyframe)
    Utils.debug("Keyframe adicionado! ID: " .. keyframe.id)
    
    return keyframe
end

function KeyframeSystem:removeKeyframe(index)
    if not index or index > #self.keyframes or index < 1 then
        Utils.debug("Índice de keyframe inválido!", true)
        return false
    end
    
    table.remove(self.keyframes, index)
    
    -- Reindexar keyframes
    for i = index, #self.keyframes do
        self.keyframes[i].id = i
    end
    
    -- Ajustar keyframe selecionado
    if self.selectedKeyframe and self.selectedKeyframe >= index then
        if self.selectedKeyframe == index then
            self.selectedKeyframe = nil
        else
            self.selectedKeyframe = self.selectedKeyframe - 1
        end
    end
    
    Utils.debug("Keyframe removido!")
    return true
end

function KeyframeSystem:getKeyframe(index)
    return self.keyframes[index]
end

function KeyframeSystem:getAllKeyframes()
    return self.keyframes
end

function KeyframeSystem:clearAll()
    self.keyframes = {}
    self.selectedKeyframe = nil
    Utils.debug("Todos os keyframes foram limpos!")
end

function KeyframeSystem:getCount()
    return #self.keyframes
end

function KeyframeSystem:selectKeyframe(index)
    if index and index <= #self.keyframes and index >= 1 then
        self.selectedKeyframe = index
        Utils.debug("Keyframe " .. index .. " selecionado")
        return true
    end
    return false
end

function KeyframeSystem:getSelectedKeyframe()
    if self.selectedKeyframe then
        return self.keyframes[self.selectedKeyframe]
    end
    return nil
end

function KeyframeSystem:getSelectedIndex()
    return self.selectedKeyframe
end

function KeyframeSystem:updateKeyframe(index, data)
    if not index or index > #self.keyframes or index < 1 then
        return false
    end
    
    local keyframe = self.keyframes[index]
    if not keyframe then return false end
    
    -- Atualizar dados fornecidos
    if data.time then keyframe.time = data.time end
    if data.position then keyframe.position = data.position end
    if data.rotation then keyframe.rotation = data.rotation end
    if data.easing then keyframe.easing = data.easing end
    
    Utils.debug("Keyframe " .. index .. " atualizado!")
    return true
end

-- Interpolação entre keyframes
function KeyframeSystem:interpolate(startKeyframe, endKeyframe, progress)
    local easingFunc = Utils.getEasingFunction(endKeyframe.easing)
    local easedProgress = easingFunc(progress)
    
    local interpolatedPos = Utils.lerpVector3(
        startKeyframe.position, 
        endKeyframe.position, 
        easedProgress
    )
    
    local interpolatedRot = Utils.lerpVector3(
        startKeyframe.rotation, 
        endKeyframe.rotation, 
        easedProgress
    )
    
    return {
        position = interpolatedPos,
        rotation = interpolatedRot
    }
end

-- Exportar para uso global
_G.KeyframeSystem = KeyframeSystem