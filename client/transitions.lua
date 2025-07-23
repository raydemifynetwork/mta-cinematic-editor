-- client/transitions.lua
TransitionSystem = {}
TransitionSystem.__index = TransitionSystem

function TransitionSystem:new(editor)
    local self = setmetatable({}, TransitionSystem)
    
    self.editor = editor
    self.isPlaying = false
    self.currentTransition = nil
    self.transitionTimer = nil
    
    return self
end

function TransitionSystem:playTransition(startKeyframe, endKeyframe, callback)
    if not startKeyframe or not endKeyframe then
        Utils.debug("Keyframes inválidos para transição!", true)
        return false
    end
    
    if self.isPlaying then
        self:stopCurrentTransition()
    end
    
    self.isPlaying = true
    local startTime = getTickCount()
    local duration = endKeyframe.time
    
    local transitionFunction = function()
        if not self.isPlaying then return end
        
        local elapsed = getTickCount() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Interpolar posição e rotação
        local interpolated = self.editor.keyframeSystem:interpolate(
            startKeyframe, 
            endKeyframe, 
            progress
        )
        
        -- Aplicar à câmera
        if self.editor.cameraObject then
            setElementPosition(
                self.editor.cameraObject, 
                interpolated.position[1], 
                interpolated.position[2], 
                interpolated.position[3]
            )
            setElementRotation(
                self.editor.cameraObject, 
                interpolated.rotation[1], 
                interpolated.rotation[2], 
                interpolated.rotation[3]
            )
        end
        
        -- Callback para cada frame
        if callback then
            callback(progress, interpolated)
        end
        
        -- Verificar se terminou
        if progress >= 1 then
            self.isPlaying = false
            if self.transitionTimer then
                killTimer(self.transitionTimer)
                self.transitionTimer = nil
            end
            
            -- Callback final
            if callback then
                callback(1.0, interpolated)
            end
        end
    end
    
    -- Iniciar transição (~60 FPS)
    self.transitionTimer = setTimer(transitionFunction, 16, 0)
    Utils.debug("Transição iniciada: " .. startKeyframe.id .. " -> " .. endKeyframe.id)
    
    return true
end

function TransitionSystem:stopCurrentTransition()
    self.isPlaying = false
    if self.transitionTimer then
        killTimer(self.transitionTimer)
        self.transitionTimer = nil
    end
    Utils.debug("Transição interrompida")
end

function TransitionSystem:isPlaying()
    return self.isPlaying
end

-- Exportar para uso global
_G.TransitionSystem = TransitionSystem