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

-- Movimento da câmera
CinematicEditor.movement = {
    forward = false,
    backward = false,
    left = false,
    right = false,
    up = false,
    down = false
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
    self.originalPlayerState = nil -- Para salvar/restaurar posição do jogador
    
    return self
end

function CinematicEditor:initialize()
    if self.initialized then 
        Utils.debug("Editor já inicializado!")
        -- Se já inicializado, mostrar interface
        if self.guiSystem then
            self.guiSystem:show()
        elseif GUI then
            self.guiSystem = GUI:new(self)
            if self.guiSystem then
                self.guiSystem:show()
            end
        end
        return true 
    end
    
    -- Salvar estado original do jogador antes de fazer qualquer alteração
    self:savePlayerState()
    
    -- Criar câmera e anexar jogador
    if not self:createCameraObject() then
        Utils.debug("Falha ao criar objeto da câmera!", true)
        return false
    end
    
    -- Criar sistemas
    self.keyframeSystem = KeyframeSystem:new(self)
    self.transitionSystem = TransitionSystem:new(self)
    self.playbackSystem = PlaybackSystem:new(self)
    
    self.initialized = true
    self.currentState = CinematicEditor.states.EDITING
    
    Utils.debug("Cinematic Editor v" .. self.config.version .. " inicializado com sucesso!")
    
    -- Criar interface
    if GUI then
        self.guiSystem = GUI:new(self)
        if self.guiSystem then
            self.guiSystem:show()
        end
    end
    
    -- Vincular controles
    self:bindCameraControls()
    
    return true
end

--- Salva a posição, rotação, dimensão e interior originais do jogador
function CinematicEditor:savePlayerState()
    if not self.originalPlayerState then
        local x, y, z = getElementPosition(localPlayer)
        local rx, ry, rz = getElementRotation(localPlayer)
        self.originalPlayerState = {
            position = {x, y, z},
            rotation = {rx, ry, rz},
            dimension = getElementDimension(localPlayer),
            interior = getElementInterior(localPlayer),
            health = getElementHealth(localPlayer),
            armor = getPedArmor(localPlayer)
            -- Adicione outros dados relevantes se necessário
        }
        Utils.debug("Estado original do jogador salvo.")
    end
end

--- Restaura o jogador para sua posição original
function CinematicEditor:restorePlayerState()
    if self.originalPlayerState then
        local pos = self.originalPlayerState.position
        local rot = self.originalPlayerState.rotation
        
        -- Desanexar antes de mover
        if self.cameraObject then
            detachElements(localPlayer, self.cameraObject)
        end
        
        -- Restaurar propriedades
        setElementPosition(localPlayer, pos[1], pos[2], pos[3])
        setElementRotation(localPlayer, rot[1], rot[2], rot[3])
        setElementDimension(localPlayer, self.originalPlayerState.dimension)
        setElementInterior(localPlayer, self.originalPlayerState.interior)
        setElementHealth(localPlayer, self.originalPlayerState.health)
        setPedArmor(localPlayer, self.originalPlayerState.armor)
        setElementAlpha(localPlayer, 255)
        setElementCollisionsEnabled(localPlayer, true)
        setElementFrozen(localPlayer, false)
        
        -- Resetar câmera para o jogador
        setCameraTarget(localPlayer)
        
        Utils.debug("Estado original do jogador restaurado.")
        self.originalPlayerState = nil -- Limpar após restaurar
    end
end

function CinematicEditor:createCameraObject()
    if not self.originalPlayerState then
        Utils.debug("Estado original do jogador não encontrado!", true)
        return false
    end

    local x, y, z = unpack(self.originalPlayerState.position)
    
    -- Criar objeto da câmera na posição original do jogador
    self.cameraObject = createObject(1337, x, y, z + 5)
    
    if not self.cameraObject then
        Utils.debug("Falha ao criar objeto da câmera!", true)
        return false
    end
    
    -- Configurar objeto da câmera
    setElementAlpha(self.cameraObject, 0) -- Invisível
    setElementCollisionsEnabled(self.cameraObject, false) -- Sem colisões
    setElementDimension(self.cameraObject, self.originalPlayerState.dimension)
    setElementInterior(self.cameraObject, self.originalPlayerState.interior)
    
    -- ANEXAR O JOGADOR AO OBJETO (como no seu script antigo)
    setElementAlpha(localPlayer, 0) -- Tornar jogador invisível
    setElementCollisionsEnabled(localPlayer, false) -- Desativar colisões do jogador
    setElementFrozen(localPlayer, true) -- Congelar jogador
    attachElements(localPlayer, self.cameraObject) -- ANEXAR jogador ao objeto
    
    -- FIXAR CÂMERA NO JOGADOR (que está anexado ao objeto)
    setCameraTarget(localPlayer)
    
    Utils.debug("Camera object criado e jogador anexado na posição: " .. x .. ", " .. y .. ", " .. z)
    return true
end

function CinematicEditor:hidePlayer()
    -- Esta lógica agora está incorporada ao createCameraObject
    -- Mantida para compatibilidade
    if self.cameraObject then
        setElementAlpha(localPlayer, 0)
        setElementCollisionsEnabled(localPlayer, false)
        setElementFrozen(localPlayer, true)
        attachElements(localPlayer, self.cameraObject)
        setCameraTarget(localPlayer)
    end
    Utils.debug("Player escondido e anexado")
end

function CinematicEditor:showPlayer()
    -- Esta lógica agora é tratada por restorePlayerState
    -- Mantida para compatibilidade
    self:restorePlayerState()
    Utils.debug("Player mostrado e restaurado")
end

function CinematicEditor:bindCameraControls()
    -- Movimento contínuo
    bindKey("w", "both", function(key, state) 
        CinematicEditor.movement.forward = (state == "down") 
    end)
    bindKey("s", "both", function(key, state) 
        CinematicEditor.movement.backward = (state == "down") 
    end)
    bindKey("a", "both", function(key, state) 
        CinematicEditor.movement.left = (state == "down") 
    end)
    bindKey("d", "both", function(key, state) 
        CinematicEditor.movement.right = (state == "down") 
    end)
    bindKey("space", "both", function(key, state) 
        CinematicEditor.movement.up = (state == "down") 
    end)
    bindKey("lctrl", "both", function(key, state) 
        CinematicEditor.movement.down = (state == "down") 
    end)
    
    -- Movimento contínuo handler
    addEventHandler("onClientRender", root, function()
        if self.currentState == CinematicEditor.states.EDITING then
            local moveX, moveY, moveZ = 0, 0, 0
            
            if CinematicEditor.movement.forward then moveY = moveY + 1 end
            if CinematicEditor.movement.backward then moveY = moveY - 1 end
            if CinematicEditor.movement.left then moveX = moveX - 1 end
            if CinematicEditor.movement.right then moveX = moveX + 1 end
            if CinematicEditor.movement.up then moveZ = moveZ + 1 end
            if CinematicEditor.movement.down then moveZ = moveZ - 1 end
            
            if moveX ~= 0 or moveY ~= 0 or moveZ ~= 0 then
                self:moveCamera(moveX, moveY, moveZ)
            end
        end
    end)
    
    -- Rotação da câmera
    bindKey("left", "down", function() self:rotateCamera(0, 0, 2) end)
    bindKey("right", "down", function() self:rotateCamera(0, 0, -2) end)
    bindKey("up", "down", function() self:rotateCamera(-2, 0, 0) end)
    bindKey("down", "down", function() self:rotateCamera(2, 0, 0) end)
    
    -- Adicionar keyframe rápido
    bindKey("k", "down", function()
        if self.currentState == CinematicEditor.states.EDITING then
            local time = self.config.defaultTransitionTime
            if self.guiSystem and self.guiSystem.elements.timeEdit then
                time = tonumber(guiGetText(self.guiSystem.elements.timeEdit)) or time
            end
            self:addCurrentPositionAsKeyframe(time)
        end
    end)
    
    Utils.debug("Controles de câmera vinculados")
end

function CinematicEditor:moveCamera(x, y, z)
    if not self.cameraObject or self.currentState ~= CinematicEditor.states.EDITING then return end
    
    local moveSpeed = 1.5
    local px, py, pz = getElementPosition(self.cameraObject)
    local rx, ry, rz = getElementRotation(self.cameraObject)
    
    -- Converter movimento local para mundo
    local rad = math.rad(rz)
    local newX = px + (x * math.cos(rad) - y * math.sin(rad)) * moveSpeed
    local newY = py + (x * math.sin(rad) + y * math.cos(rad)) * moveSpeed
    local newZ = pz + z * moveSpeed
    
    -- MOVER O OBJETO DA CÂMERA (o jogador se move junto por estar anexado)
    setElementPosition(self.cameraObject, newX, newY, newZ)
    
    -- A câmera segue o jogador automaticamente por estar anexado!
    
    -- Atualizar interface
    if self.guiSystem then
        self.guiSystem:updateCameraPosition()
    end
end

function CinematicEditor:rotateCamera(rx, ry, rz)
    if not self.cameraObject or self.currentState ~= CinematicEditor.states.EDITING then return end
    
    local currentRx, currentRy, currentRz = getElementRotation(self.cameraObject)
    local newRx = math.max(-89, math.min(89, currentRx + rx)) -- Limitar pitch
    local newRy = currentRy + ry
    local newRz = currentRz + rz
    
    -- ROTACIONAR O OBJETO DA CÂMERA (o jogador rotaciona junto)
    setElementRotation(self.cameraObject, newRx, newRy, newRz)
    
    -- Atualizar interface
    if self.guiSystem then
        self.guiSystem:updateCameraPosition()
    end
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
        -- Esconder interface durante reprodução
        if self.guiSystem then
            self.guiSystem:hide()
        end
        
        self.currentState = CinematicEditor.states.PLAYING
        return self.playbackSystem:playFromStart()
    end
    return false
end

function CinematicEditor:stopCinematic(restorePlayer)
    -- Parâmetro restorePlayer: se true, restaura o jogador ao parar
    local shouldRestore = restorePlayer or false
    
    if self.playbackSystem then
        self.playbackSystem:stop()
    end
    
    self.currentState = CinematicEditor.states.EDITING
    
    -- Mostrar interface
    if self.guiSystem then
        self.guiSystem:show()
    end
    
    -- Restaurar jogador se solicitado
    if shouldRestore then
        self:restorePlayerState()
    else
        -- Garantir que a câmera volte para o objeto
        if self.cameraObject then
            setCameraTarget(localPlayer) -- Camera segue o jogador anexado
        end
    end
    
    Utils.debug("Cinematic interrompido")
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

function CinematicEditor:cleanup()
    -- Mostrar player e restaurar estado original
    self:restorePlayerState()
    Utils.debug("Editor limpo")
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

-- Funções exportadas
function startCinematicEditor()
    if not CinematicEditor.instance then
        CinematicEditor.instance = CinematicEditor:new()
    end
    return CinematicEditor.instance:initialize()
end

function stopCinematicEditor()
    if CinematicEditor.instance then
        CinematicEditor.instance:stopCinematic(true) -- Restaurar jogador ao parar completamente
        Utils.debug("Editor de cinematicas desativado")
    end
end

-- Eventos do MTA
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Apenas garantir que as classes estão disponíveis
    _G.CinematicEditor = CinematicEditor
    Utils.debug("Cinematic Editor carregado - use /cineditor para iniciar")
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    if CinematicEditor.instance then
        CinematicEditor.instance:cleanup()
    end
end)

-- Comandos
addCommandHandler("cineditor", function()
    if not CinematicEditor.instance then
        CinematicEditor.instance = CinematicEditor:new()
    end
    
    if not CinematicEditor.instance.initialized then
        CinematicEditor.instance:initialize()
    else
        -- Se já inicializado, apenas mostrar/alternar interface
        if CinematicEditor.instance.guiSystem then
            CinematicEditor.instance.guiSystem:toggle()
        else
            -- Recriar interface se necessário
            if GUI then
                CinematicEditor.instance.guiSystem = GUI:new(CinematicEditor.instance)
                if CinematicEditor.instance.guiSystem then
                    CinematicEditor.instance.guiSystem:show()
                end
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
    outputChatBox("/exitcinematic - Sair do modo editor e restaurar posição")
end)

-- Comando para sair do modo editor e restaurar posição original
addCommandHandler("exitcinematic", function()
    if CinematicEditor.instance then
        CinematicEditor.instance:stopCinematic(true) -- Restaurar jogador
        outputChatBox("✓ Editor encerrado e posição original restaurada!")
    end
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
    if CinematicEditor.instance then
        CinematicEditor.instance:stopCinematic() -- Não restaura automaticamente
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