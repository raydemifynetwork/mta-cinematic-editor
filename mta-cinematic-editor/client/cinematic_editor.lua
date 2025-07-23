-- client/cinematic_editor.lua
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
    self.guiSystem = nil
    self.isPlaying = false
    
    return self
end

function CinematicEditor:initialize()
    if self.initialized then 
        Utils.debug("Editor já inicializado!")
        return true 
    end
    
    -- Criar sistemas
    self:createCameraObject()
    self.keyframeSystem = KeyframeSystem:new(self)
    self.transitionSystem = TransitionSystem:new(self)
    
    self.initialized = true
    self.currentState = CinematicEditor.states.EDITING
    
    Utils.debug("Cinematic Editor v" .. self.config.version .. " inicializado com sucesso!")
    
    -- Criar interface
    if GUI then
        self.guiSystem = GUI:new(self)
    end
    
    return true
end

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
    if not self.keyframeSystem or not self.transitionSystem then
        Utils.debug("Sistemas não inicializados!", true)
        return false
    end
    
    local keyframes = self.keyframeSystem:getAllKeyframes()
    if #keyframes < 2 then
        Utils.debug("Necessário pelo menos 2 keyframes para reproduzir!", true)
        return false
    end
    
    self.currentState = CinematicEditor.states.PLAYING
    self.isPlaying = true
    
    -- Esconder interface durante a reprodução
    if self.guiSystem then
        self.guiSystem:hide()
    end
    
    Utils.debug("Iniciando reprodução de cinematic com " .. #keyframes .. " keyframes")
    self:playNextSegment(1)
    
    return true
end

function CinematicEditor:playNextSegment(index)
    if not self.isPlaying or not self.keyframeSystem or not self.transitionSystem then
        return
    end
    
    local keyframes = self.keyframeSystem:getAllKeyframes()
    if index >= #keyframes then
        self:stopCinematic()
        return
    end
    
    local currentKeyframe = keyframes[index]
    local nextKeyframe = keyframes[index + 1]
    
    if not currentKeyframe or not nextKeyframe then
        self:stopCinematic()
        return
    end
    
    -- Callback para quando a transição terminar
    local onTransitionComplete = function()
        self:playNextSegment(index + 1)
    end
    
    -- Iniciar transição
    self.transitionSystem:playTransition(currentKeyframe, nextKeyframe, function(progress)
        if progress >= 1.0 then
            setTimer(onTransitionComplete, 100, 1)
        end
    end)
end

function CinematicEditor:stopCinematic()
    self.isPlaying = false
    self.currentState = CinematicEditor.states.EDITING
    
    if self.transitionSystem then
        self.transitionSystem:stopCurrentTransition()
    end
    
    -- Mostrar interface novamente
    if self.guiSystem then
        self.guiSystem:show()
    end
    
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

function CinematicEditor:getCameraObject()
    return self.cameraObject
end

function CinematicEditor:getKeyframeSystem()
    return self.keyframeSystem
end

function CinematicEditor:getTransitionSystem()
    return self.transitionSystem
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

-- Eventos do MTA
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Carregar dependências primeiro
    if Utils and KeyframeSystem and TransitionSystem then
        startCinematicEditor()
    else
        outputChatBox("[CinematicEditor] Erro ao carregar dependências!", 255, 100, 100)
    end
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    if CinematicEditor.instance then
        CinematicEditor.instance:stopCinematic()
    end
end)

-- Comandos de teste
addCommandHandler("cineditor", function()
    outputChatBox("=== Cinematic Editor v" .. CinematicEditor.config.version .. " ===")
    outputChatBox("Comandos disponíveis:")
    outputChatBox("/addkeyframe [tempo] [easing] - Adicionar keyframe atual")
    outputChatBox("/playcinematic - Reproduzir cinematica")
    outputChatBox("/stopcinematic - Parar reprodução")
    outputChatBox("/keyframecount - Contar keyframes")
    outputChatChat("/clearcinematic - Limpar tudo")
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

addCommandHandler("playcinematic", function()
    if CinematicEditor.instance then
        CinematicEditor.instance:playCinematic()
    end
end)

addCommandHandler("stopcinematic", function()
    if CinematicEditor.instance then
        CinematicEditor.instance:stopCinematic()
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
