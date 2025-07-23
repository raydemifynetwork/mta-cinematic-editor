-- client/cinematic_editor.lua (versão atualizada)
CinematicEditor = {}
CinematicEditor.__index = CinematicEditor

-- Configurações globais
CinematicEditor.config = {
    version = "1.0.0",
    debugMode = true,
    maxKeyframes = 100,
    defaultTransitionTime = 2000
}

-- Estados do editor
CinematicEditor.states = {
    NONE = "none",
    EDITING = "editing",
    PLAYING = "playing"
}

function CinematicEditor:new()
    local self = setmetatable({}, CinematicEditor)
    
    self.initialized = false
    self.currentState = CinematicEditor.states.NONE
    self.cameraObject = nil
    self.keyframeSystem = nil
    self.transitionSystem = nil
    self.playbackSystem = nil
    self.guiSystem = nil
    self.isPlaying = false
    
    return self
end


function CinematicEditor:initialize()
    if self.initialized then 
        Utils.debug("Editor já inicializado!")
        return true 
    end
    
    -- Criar sistemas com verificação
    if not self:createCameraObject() then
        Utils.debug("Falha ao criar objeto da câmera!", true)
        return false
    end
    
    self.keyframeSystem = KeyframeSystem:new(self)
    self.transitionSystem = TransitionSystem:new(self)
    self.playbackSystem = PlaybackSystem:new(self)
    
    self.initialized = true
    self.currentState = CinematicEditor.states.EDITING
    
    Utils.debug("Cinematic Editor v" .. self.config.version .. " inicializado com sucesso!")
    
    return true
end


-- client/cinematic_editor.lua

addEventHandler("onClientRender", root, function()
    if self.isPlaying then return end -- Não alterar câmera durante reprodução
    
    if self.cameraObject then
        setCameraTarget(self.cameraObject)
    end
end)

function CinematicEditor:createCameraObject()
    local x, y, z = getElementPosition(localPlayer)
    self.cameraObject = createObject(1337, x, y, z + 5) -- Objeto invisível
    setElementAlpha(self.cameraObject, 0)
    
    -- Fixar câmera no objeto
    setCameraTarget(self.cameraObject)
    
    Utils.debug("Camera object criado na posição: " .. x .. ", " .. y .. ", " .. z)
end

function CinematicEditor:addCurrentPositionAsKeyframe(time, easing)
    if not self.keyframeSystem then 
        Utils.debug("Sistema de keyframes não inicializado!", true)
        return nil 
    end
    
    if not self.cameraObject then 
        Utils.debug("Objeto de câmera não encontrado!", true)
        return nil 
    end
    
    local x, y, z = getElementPosition(self.cameraObject)
    local rx, ry, rz = getElementRotation(self.cameraObject)
    
    local keyframe = self.keyframeSystem:addKeyframe(
        {x, y, z}, 
        {rx, ry, rz}, 
        time or self.config.defaultTransitionTime, 
        easing or "Linear"
    )
    
    -- Atualizar interface se existir
    if self.guiSystem then
        self.guiSystem:updateKeyframeList()
    end
    
    return keyframe
end

function CinematicEditor:removeSelectedKeyframe()
    if not self.keyframeSystem then return false end
    
    local selectedIndex = self.keyframeSystem:getSelectedIndex()
    if not selectedIndex then
        Utils.debug("Nenhum keyframe selecionado!", true)
        return false
    end
    
    local result = self.keyframeSystem:removeKeyframe(selectedIndex)
    
    -- Atualizar interface
    if self.guiSystem then
        self.guiSystem:updateKeyframeList()
        self.guiSystem:clearKeyframeDetails()
    end
    
    return result
end

function CinematicEditor:playCinematic()
    if self.playbackSystem then
        return self.playbackSystem:playFromStart()
    end
    return false
end

function CinematicEditor:pauseCinematic()
    if self.playbackSystem then
        return self.playbackSystem:pause()
    end
    return false
end

function CinematicEditor:resumeCinematic()
    if self.playbackSystem then
        return self.playbackSystem:resume()
    end
    return false
end

function CinematicEditor:stopCinematic()
    if self.playbackSystem then
        self.playbackSystem:stop()
    end
    
    self.currentState = CinematicEditor.states.EDITING
    Utils.debug("Cinematic interrompido")
end

function CinematicEditor:clearAll()
    if self.keyframeSystem then
        self.keyframeSystem:clearAll()
    end
    
    if self.guiSystem then
        self.guiSystem:updateKeyframeList()
        self.guiSystem:clearKeyframeDetails()
    end
    
    Utils.debug("Todos os dados limpos!")
end

-- Getters
function CinematicEditor:getCameraObject()
    return self.cameraObject
end

function CinematicEditor:getKeyframeSystem()
    return self.keyframeSystem
end

function CinematicEditor:getTransitionSystem()
    return self.transitionSystem
end

function CinematicEditor:getPlaybackSystem()
    return self.playbackSystem
end

function CinematicEditor:getCurrentState()
    return self.currentState
end

function CinematicEditor:isPlaying()
    return self.isPlaying
end

-- Funções exportadas
function startCinematicEditor()
    if not CinematicEditor.instance then
        CinematicEditor.instance = CinematicEditor:new()
    end
    return CinematicEditor.instance:initialize()
end

function stopCinematicEditor()
    if CinematicEditor.instance then
        CinematicEditor.instance:stopCinematic()
        Utils.debug("Editor de cinematicas desativado")
    end
end

-- Eventos do MTA - apenas exportar funções
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Apenas garantir que as classes estão disponíveis
    _G.CinematicEditor = CinematicEditor
    Utils.debug("Cinematic Editor carregado - use /cineditor para iniciar")
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    if CinematicEditor.instance then
        CinematicEditor.instance:stopCinematic()
    end
end)

addCommandHandler("cineditor", function()
    if not CinematicEditor.instance then
        CinematicEditor.instance = CinematicEditor:new()
        CinematicEditor.instance:initialize()
    else
        -- Se já existe, apenas mostra a interface
        if CinematicEditor.instance.guiSystem then
            CinematicEditor.instance.guiSystem:toggle()
        else
            -- Recria a interface se necessário
            if GUI then
                CinematicEditor.instance.guiSystem = GUI:new(CinematicEditor.instance)
            end
            if CinematicEditor.instance.guiSystem then
                CinematicEditor.instance.guiSystem:show()
            end
        end
    end
    
    outputChatBox("=== Cinematic Editor v" .. CinematicEditor.config.version .. " ===")
    outputChatBox("Comandos disponíveis:")
    outputChatBox("/addkeyframe [tempo] [easing] - Adicionar keyframe atual")
    outputChatBox("/playcinematic - Reproduzir cinematica")
    outputChatBox("/pausecinematic - Pausar reprodução")
    outputChatBox("/resumecinematic - Retomar reprodução")
    outputChatBox("/stopcinematic - Parar reprodução")
    outputChatBox("/keyframecount - Contar keyframes")
    outputChatBox("/clearcinematic - Limpar tudo")
end)

addCommandHandler("addkeyframe", function(player, cmd, time, easing)
    if CinematicEditor.instance then
        local timeValue = tonumber(time) or CinematicEditor.config.defaultTransitionTime
        local keyframe = CinematicEditor.instance:addCurrentPositionAsKeyframe(timeValue, easing)
        if keyframe then
            outputChatBox("✓ Keyframe adicionado! ID: " .. keyframe.id .. " | Tempo: " .. keyframe.time .. "ms")
        end
    end
end)

addCommandHandler("keyframecount", function()
    if CinematicEditor.instance and CinematicEditor.instance.keyframeSystem then
        local count = CinematicEditor.instance.keyframeSystem:getCount()
        outputChatBox("Total de keyframes: " .. count)
    end
end)

addCommandHandler("clearcinematic", function()
    if CinematicEditor.instance then
        CinematicEditor.instance:clearAll()
        outputChatBox("✓ Todos os dados foram limpos!")
    end
end)

-- Exportar classe globalmente
_G.CinematicEditor = CinematicEditor