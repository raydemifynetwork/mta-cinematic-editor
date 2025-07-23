-- client/playback.lua
PlaybackSystem = {}
PlaybackSystem.__index = PlaybackSystem

function PlaybackSystem:new(editor)
    local self = setmetatable({}, PlaybackSystem)
    
    self.editor = editor
    self.isPlaying = false
    self.isPaused = false
    self.currentKeyframeIndex = 1
    self.currentSegmentTimer = nil
    self.totalTime = 0
    self.elapsedTime = 0
    self.startTime = 0
    
    return self
end

function PlaybackSystem:playFromStart()
    if not self.editor.keyframeSystem then
        Utils.debug("Sistema de keyframes não disponível!", true)
        return false
    end
    
    local keyframes = self.editor.keyframeSystem:getAllKeyframes()
    if #keyframes < 2 then
        Utils.debug("Necessário pelo menos 2 keyframes para reproduzir!", true)
        return false
    end
    
    -- Resetar estado
    self:stop()
    self.isPlaying = true
    self.isPaused = false
    self.currentKeyframeIndex = 1
    self.totalTime = self:calculateTotalTime()
    self.startTime = getTickCount()
    self.elapsedTime = 0
    
    -- Esconder interface
    if self.editor.guiSystem then
        self.editor.guiSystem:hide()
    end
    
    -- Fixar câmera
    if self.editor.cameraObject then
        setCameraTarget(self.editor.cameraObject)
    end
    
    Utils.debug("Reprodução iniciada com " .. #keyframes .. " keyframes")
    self:playNextSegment()
    
    return true
end

function PlaybackSystem:playNextSegment()
    if not self.isPlaying or self.isPaused then return end
    
    local keyframes = self.editor.keyframeSystem:getAllKeyframes()
    if self.currentKeyframeIndex >= #keyframes then
        self:finish()
        return
    end
    
    local currentKeyframe = keyframes[self.currentKeyframeIndex]
    local nextKeyframe = keyframes[self.currentKeyframeIndex + 1]
    
    if not currentKeyframe or not nextKeyframe then
        self:finish()
        return
    end
    
    -- Mover câmera para posição inicial do segmento
    if self.editor.cameraObject then
        setElementPosition(self.editor.cameraObject, 
            currentKeyframe.position[1], 
            currentKeyframe.position[2], 
            currentKeyframe.position[3])
        setElementRotation(self.editor.cameraObject, 
            currentKeyframe.rotation[1], 
            currentKeyframe.rotation[2], 
            currentKeyframe.rotation[3])
    end
    
    -- Iniciar transição
    if self.editor.transitionSystem then
        local onSegmentComplete = function()
            self.currentKeyframeIndex = self.currentKeyframeIndex + 1
            self:playNextSegment()
        end
        
        self.editor.transitionSystem:playTransition(currentKeyframe, nextKeyframe, function(progress)
            if progress >= 1.0 then
                setTimer(onSegmentComplete, 50, 1) -- Pequeno delay entre segmentos
            end
            
            -- Atualizar tempo decorrido
            self.elapsedTime = getTickCount() - self.startTime
        end)
    end
end

function PlaybackSystem:pause()
    if not self.isPlaying or self.isPaused then return false end
    
    self.isPaused = true
    if self.editor.transitionSystem then
        self.editor.transitionSystem:stopCurrentTransition()
    end
    
    Utils.debug("Reprodução pausada")
    return true
end

function PlaybackSystem:resume()
    if not self.isPlaying or not self.isPaused then return false end
    
    self.isPaused = false
    self:playNextSegment()
    
    Utils.debug("Reprodução retomada")
    return true
end

function PlaybackSystem:stop()
    self.isPlaying = false
    self.isPaused = false
    self.currentKeyframeIndex = 1
    self.elapsedTime = 0
    
    if self.currentSegmentTimer then
        killTimer(self.currentSegmentTimer)
        self.currentSegmentTimer = nil
    end
    
    if self.editor.transitionSystem then
        self.editor.transitionSystem:stopCurrentTransition()
    end
    
    -- Mostrar interface novamente
    if self.editor.guiSystem then
        self.editor.guiSystem:show()
    end
    
    Utils.debug("Reprodução interrompida")
end

function PlaybackSystem:finish()
    self.isPlaying = false
    self.isPaused = false
    
    if self.currentSegmentTimer then
        killTimer(self.currentSegmentTimer)
        self.currentSegmentTimer = nil
    end
    
    if self.editor.transitionSystem then
        self.editor.transitionSystem:stopCurrentTransition()
    end
    
    -- Mostrar interface
    if self.editor.guiSystem then
        self.editor.guiSystem:show()
    end
    
    Utils.debug("Reprodução finalizada!")
    outputChatBox("✓ Cinematica concluída!")
end

function PlaybackSystem:jumpToKeyframe(index)
    if not self.editor.keyframeSystem then return false end
    
    local keyframes = self.editor.keyframeSystem:getAllKeyframes()
    if index < 1 or index > #keyframes then
        Utils.debug("Índice de keyframe inválido!", true)
        return false
    end
    
    local keyframe = keyframes[index]
    if not keyframe then return false end
    
    -- Mover câmera para a posição do keyframe
    if self.editor.cameraObject then
        setElementPosition(self.editor.cameraObject, 
            keyframe.position[1], 
            keyframe.position[2], 
            keyframe.position[3])
        setElementRotation(self.editor.cameraObject, 
            keyframe.rotation[1], 
            keyframe.rotation[2], 
            keyframe.rotation[3])
    end
    
    self.currentKeyframeIndex = index
    Utils.debug("Saltado para keyframe " .. index)
    
    return true
end

function PlaybackSystem:calculateTotalTime()
    if not self.editor.keyframeSystem then return 0 end
    
    local totalTime = 0
    local keyframes = self.editor.keyframeSystem:getAllKeyframes()
    
    for i = 1, #keyframes - 1 do
        totalTime = totalTime + keyframes[i + 1].time
    end
    
    return totalTime
end

function PlaybackSystem:getProgress()
    if self.totalTime <= 0 then return 0 end
    return math.min(self.elapsedTime / self.totalTime, 1.0)
end

function PlaybackSystem:getCurrentKeyframeIndex()
    return self.currentKeyframeIndex
end

function PlaybackSystem:getTotalKeyframes()
    if self.editor.keyframeSystem then
        return self.editor.keyframeSystem:getCount()
    end
    return 0
end

function PlaybackSystem:isPlaying()
    return self.isPlaying and not self.isPaused
end

function PlaybackSystem:isPaused()
    return self.isPaused
end

function PlaybackSystem:getElapsedTime()
    return self.elapsedTime
end

function PlaybackSystem:getTotalTime()
    return self.totalTime
end

-- Exportar para uso global
_G.PlaybackSystem = PlaybackSystem

-- Comandos relacionados à reprodução
addCommandHandler("playcinematic", function()
    if CinematicEditor.instance and CinematicEditor.instance.playbackSystem then
        CinematicEditor.instance.playbackSystem:playFromStart()
    end
end)

addCommandHandler("pausecinematic", function()
    if CinematicEditor.instance and CinematicEditor.instance.playbackSystem then
        CinematicEditor.instance.playbackSystem:pause()
    end
end)

addCommandHandler("resumecinematic", function()
    if CinematicEditor.instance and CinematicEditor.instance.playbackSystem then
        CinematicEditor.instance.playbackSystem:resume()
    end
end)

addCommandHandler("stopcinematic", function()
    if CinematicEditor.instance and CinematicEditor.instance.playbackSystem then
        CinematicEditor.instance.playbackSystem:stop()
    end
end)

addCommandHandler("jumpto", function(player, cmd, index)
    if CinematicEditor.instance and CinematicEditor.instance.playbackSystem then
        local keyframeIndex = tonumber(index)
        if keyframeIndex then
            CinematicEditor.instance.playbackSystem:jumpToKeyframe(keyframeIndex)
        end
    end
end)