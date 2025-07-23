-- client/gui.lua
GUI = {}
GUI.__index = GUI

function GUI:new(editor)
    local self = setmetatable({}, GUI)
    
    self.editor = editor
    self.window = nil
    self.isVisible = false
    self.elements = {}
    
    self:createInterface()
    
    return self
end

function GUI:createInterface()
    -- Janela principal
    self.window = guiCreateWindow(50, 50, 550, 500, "Cinematic Editor v" .. CinematicEditor.config.version, false)
    guiWindowSetSizable(self.window, false)
    guiSetVisible(self.window, false)
    
    -- Painel de abas
    local tabPanel = guiCreateTabPanel(10, 25, 530, 465, false, self.window)
    
    -- Aba de Keyframes
    self:createKeyframeTab(tabPanel)
    
    -- Aba de Controles
    self:createControlTab(tabPanel)
    
    -- Aba de Projeto
    self:createProjectTab(tabPanel)
    
    -- Bind de eventos
    self:bindEvents()
    
    Utils.debug("Interface gráfica criada")
end

function GUI:createKeyframeTab(tabPanel)
    local keyframeTab = guiCreateTab("Keyframes", tabPanel)
    
    -- Lista de keyframes
    self.elements.keyframeList = guiCreateGridList(10, 10, 510, 200, false, keyframeTab)
    guiGridListAddColumn(self.elements.keyframeList, "ID", 0.1)
    guiGridListAddColumn(self.elements.keyframeList, "Tempo (ms)", 0.2)
    guiGridListAddColumn(self.elements.keyframeList, "Posição", 0.4)
    guiGridListAddColumn(self.elements.keyframeList, "Easing", 0.3)
    
    -- Botões de keyframe
    self.elements.btnAddKeyframe = guiCreateButton(10, 220, 110, 30, "➕ Adicionar", false, keyframeTab)
    self.elements.btnRemoveKeyframe = guiCreateButton(130, 220, 110, 30, "🗑 Remover", false, keyframeTab)
    self.elements.btnSelectKeyframe = guiCreateButton(250, 220, 110, 30, "👁 Selecionar", false, keyframeTab)
    self.elements.btnMoveToKeyframe = guiCreateButton(370, 220, 150, 30, "📍 Mover Câmera", false, keyframeTab)
    
    -- Detalhes do keyframe selecionado
    guiCreateLabel(10, 260, 150, 20, "Editar Keyframe Selecionado:", false, keyframeTab)
    
    guiCreateLabel(10, 285, 80, 20, "Tempo (ms):", false, keyframeTab)
    self.elements.timeEdit = guiCreateEdit(10, 305, 100, 25, "2000", false, keyframeTab)
    
    guiCreateLabel(120, 285, 80, 20, "Easing:", false, keyframeTab)
    self.elements.easingCombo = guiCreateComboBox(120, 305, 150, 150, "Linear", false, keyframeTab)
    
    -- Adicionar opções de easing
    local easings = {"Linear", "InQuad", "OutQuad", "InOutQuad", "InCubic", "OutCubic", "InOutCubic", "InQuart", "OutQuart", "InOutQuart"}
    for _, easing in ipairs(easings) do
        guiComboBoxAddItem(self.elements.easingCombo, easing)
    end
    
    self.elements.btnSaveChanges = guiCreateButton(280, 305, 100, 25, "💾 Salvar", false, keyframeTab)
    
    -- Preview de posição
    guiCreateLabel(10, 340, 150, 20, "Posição Atual:", false, keyframeTab)
    self.elements.positionLabel = guiCreateLabel(10, 360, 300, 20, "X: 0.0, Y: 0.0, Z: 0.0", false, keyframeTab)
    self.elements.rotationLabel = guiCreateLabel(10, 380, 300, 20, "RX: 0.0, RY: 0.0, RZ: 0.0", false, keyframeTab)
    
    self.elements.btnUpdatePosition = guiCreateButton(10, 410, 150, 25, "🔄 Atualizar Posição", false, keyframeTab)
end

function GUI:createControlTab(tabPanel)
    local controlTab = guiCreateTab("Controles", tabPanel)
    
    -- Controles de reprodução
    guiCreateLabel(10, 10, 150, 20, "Controles de Reprodução:", false, controlTab)
    
    self.elements.btnPlay = guiCreateButton(10, 35, 80, 30, "▶ Play", false, controlTab)
    self.elements.btnPause = guiCreateButton(100, 35, 80, 30, "⏸ Pausar", false, controlTab)
    self.elements.btnStop = guiCreateButton(190, 35, 80, 30, "⏹ Parar", false, controlTab)
    
    -- Progresso
    guiCreateLabel(10, 80, 100, 20, "Progresso:", false, controlTab)
    self.elements.progressBar = guiCreateProgressBar(10, 100, 300, 20, false, controlTab)
    self.elements.progressLabel = guiCreateLabel(10, 125, 200, 20, "0%", false, controlTab)
    
    -- Status
    self.elements.statusLabel = guiCreateLabel(10, 150, 300, 20, "Status: Aguardando...", false, controlTab)
    
    -- Informações
    local keyframeCount = 0
    if self.editor.keyframeSystem then
        keyframeCount = self.editor.keyframeSystem:getCount()
    end
    self.elements.infoLabel = guiCreateLabel(10, 175, 300, 20, "Keyframes: " .. keyframeCount, false, controlTab)
    
    -- Controles de edição
    guiCreateLabel(10, 210, 150, 20, "Controles de Edição:", false, controlTab)
    
    self.elements.btnClear = guiCreateButton(10, 235, 120, 30, "🗑 Limpar Tudo", false, controlTab)
    self.elements.btnNewProject = guiCreateButton(140, 235, 120, 30, "📄 Novo Projeto", false, controlTab)
    
    -- Ajuda
    guiCreateLabel(10, 280, 400, 20, "⌨️ Comandos Rápidos:", false, controlTab)
    guiCreateLabel(10, 300, 400, 20, "F2 - Mostrar/Esconder editor", false, controlTab)
    guiCreateLabel(10, 320, 400, 20, "K - Adicionar keyframe na posição atual", false, controlTab)
    guiCreateLabel(10, 340, 400, 20, "WASD + Espaço/LCtrl - Mover câmera", false, controlTab)
    guiCreateLabel(10, 360, 400, 20, "Setas - Rotacionar câmera", false, controlTab)
end

function GUI:createProjectTab(tabPanel)
    local projectTab = guiCreateTab("Projeto", tabPanel)
    
    -- Informações do projeto
    guiCreateLabel(10, 10, 150, 20, "Nome do Projeto:", false, projectTab)
    self.elements.projectName = guiCreateEdit(10, 30, 250, 25, "Nova Cinematica", false, projectTab)
    
    -- Botões de projeto
    self.elements.btnSaveProject = guiCreateButton(10, 70, 100, 30, "💾 Salvar", false, projectTab)
    self.elements.btnLoadProject = guiCreateButton(120, 70, 100, 30, "📂 Carregar", false, projectTab)
    self.elements.btnDeleteProject = guiCreateButton(230, 70, 100, 30, "🗑 Deletar", false, projectTab)
    
    -- Lista de projetos salvos
    guiCreateLabel(10, 120, 150, 20, "Projetos Salvos:", false, projectTab)
    self.elements.projectList = guiCreateGridList(10, 140, 300, 150, false, projectTab)
    guiGridListAddColumn(self.elements.projectList, "Nome", 0.6)
    guiGridListAddColumn(self.elements.projectList, "Data", 0.4)
    
    -- Configurações
    guiCreateLabel(10, 300, 150, 20, "Configurações:", false, projectTab)
    
    self.elements.chkAutoSave = guiCreateCheckBox(10, 320, 150, 20, "Salvar automaticamente", false, false, projectTab)
    self.elements.chkShowGrid = guiCreateCheckBox(10, 345, 150, 20, "Mostrar grade", true, false, projectTab)
    
    -- Informações técnicas
    guiCreateLabel(10, 380, 400, 20, "📊 Informações Técnicas:", false, projectTab)
    self.elements.technicalInfo = guiCreateLabel(10, 400, 400, 60, 
        "Versão: " .. CinematicEditor.config.version .. "\n" ..
        "Keyframes: 0\n" ..
        "Estado: " .. (self.editor and self.editor:getCurrentState() or "Desconhecido"),
        false, projectTab)
end

function GUI:bindEvents()
    -- Botões de keyframe
    addEventHandler("onClientGUIClick", self.elements.btnAddKeyframe, 
        function() self:onAddKeyframeClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnRemoveKeyframe, 
        function() self:onRemoveKeyframeClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnSelectKeyframe, 
        function() self:onSelectKeyframeClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnMoveToKeyframe, 
        function() self:onMoveToKeyframeClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnSaveChanges, 
        function() self:onSaveChangesClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnUpdatePosition, 
        function() self:onUpdatePositionClick() end, false)
    
    -- Botões de controle
    addEventHandler("onClientGUIClick", self.elements.btnPlay, 
        function() self:onPlayClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnPause, 
        function() self:onPauseClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnStop, 
        function() self:onStopClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnClear, 
        function() self:onClearClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnNewProject, 
        function() self:onNewProjectClick() end, false)
    
    -- Botões de projeto
    addEventHandler("onClientGUIClick", self.elements.btnSaveProject, 
        function() self:onSaveProjectClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnLoadProject, 
        function() self:onLoadProjectClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnDeleteProject, 
        function() self:onDeleteProjectClick() end, false)
    
    -- Seleção na lista
    addEventHandler("onClientGUIDoubleClick", self.elements.keyframeList, 
        function() self:onKeyframeDoubleClick() end, false)
end

-- Eventos dos botões
function GUI:onAddKeyframeClick()
    if self.editor then
        local time = tonumber(guiGetText(self.elements.timeEdit)) or CinematicEditor.config.defaultTransitionTime
        local easingIndex = guiComboBoxGetSelected(self.elements.easingCombo)
        local easing = guiComboBoxGetItemText(self.elements.easingCombo, easingIndex)
        if easing == "" then easing = "Linear" end
        
        self.editor:addCurrentPositionAsKeyframe(time, easing)
        self:updateCameraPosition()
    end
end

function GUI:onRemoveKeyframeClick()
    if self.editor then
        self.editor:removeSelectedKeyframe()
        self:updateCameraPosition()
    end
end

function GUI:onSelectKeyframeClick()
    local selectedRow = guiGridListGetSelectedItem(self.elements.keyframeList)
    if selectedRow ~= -1 then
        local keyframeId = tonumber(guiGridListGetItemText(self.elements.keyframeList, selectedRow, 1))
        if keyframeId and self.editor.keyframeSystem then
            self.editor.keyframeSystem:selectKeyframe(keyframeId)
            self:loadKeyframeDetails(keyframeId)
        end
    end
end

function GUI:onMoveToKeyframeClick()
    local selectedRow = guiGridListGetSelectedItem(self.elements.keyframeList)
    if selectedRow ~= -1 and self.editor.playbackSystem then
        local keyframeId = tonumber(guiGridListGetItemText(self.elements.keyframeList, selectedRow, 1))
        if keyframeId then
            self.editor.playbackSystem:jumpToKeyframe(keyframeId)
            self:updateCameraPosition()
        end
    end
end

function GUI:onKeyframeDoubleClick()
    self:onMoveToKeyframeClick()
end

function GUI:onSaveChangesClick()
    local selectedRow = guiGridListGetSelectedItem(self.elements.keyframeList)
    if selectedRow ~= -1 and self.editor.keyframeSystem then
        local keyframeId = tonumber(guiGridListGetItemText(self.elements.keyframeList, selectedRow, 1))
        if keyframeId then
            local time = tonumber(guiGetText(self.elements.timeEdit))
            local easingIndex = guiComboBoxGetSelected(self.elements.easingCombo)
            local easing = guiComboBoxGetItemText(self.elements.easingCombo, easingIndex)
            
            if easing == "" then easing = "Linear" end
            
            local keyframes = self.editor.keyframeSystem:getAllKeyframes()
            if keyframes[keyframeId] then
                self.editor.keyframeSystem:updateKeyframe(keyframeId, {
                    time = time,
                    easing = easing
                })
                self:updateKeyframeList()
                Utils.debug("Keyframe " .. keyframeId .. " atualizado!")
            end
        end
    end
end

function GUI:onUpdatePositionClick()
    local selectedRow = guiGridListGetSelectedItem(self.elements.keyframeList)
    if selectedRow ~= -1 and self.editor.keyframeSystem and self.editor.cameraObject then
        local keyframeId = tonumber(guiGridListGetItemText(self.elements.keyframeList, selectedRow, 1))
        if keyframeId then
            local x, y, z = getElementPosition(self.editor.cameraObject)
            local rx, ry, rz = getElementRotation(self.editor.cameraObject)
            
            self.editor.keyframeSystem:updateKeyframe(keyframeId, {
                position = {x, y, z},
                rotation = {rx, ry, rz}
            })
            
            self:updateKeyframeList()
            self:updateCameraPosition()
            Utils.debug("Posição do keyframe " .. keyframeId .. " atualizada!")
        end
    end
end

function GUI:onPlayClick()
    if self.editor then
        self.editor:playCinematic()
    end
end

function GUI:onPauseClick()
    if self.editor then
        self.editor:pauseCinematic()
    end
end

function GUI:onStopClick()
    if self.editor then
        self.editor:stopCinematic()
    end
end

function GUI:onClearClick()
    if self.editor then
        self.editor:clearAll()
        self:updateKeyframeList()
        self:clearKeyframeDetails()
        self:updateStatus()
        self:updateCameraPosition()
    end
end

function GUI:onNewProjectClick()
    if self.editor then
        self.editor:clearAll()
        guiSetText(self.elements.projectName, "Nova Cinematica")
        self:updateKeyframeList()
        self:clearKeyframeDetails()
        self:updateStatus()
        Utils.debug("Novo projeto criado!")
    end
end

function GUI:onSaveProjectClick()
    local projectName = guiGetText(self.elements.projectName)
    if projectName == "" then
        Utils.debug("Digite um nome para o projeto!", true)
        return
    end
    
    Utils.debug("Projeto '" .. projectName .. "' salvo! (simulação)")
    -- Aqui seria implementado o sistema real de salvamento
end

function GUI:onLoadProjectClick()
    Utils.debug("Carregando projeto... (simulação)")
    -- Aqui seria implementado o sistema real de carregamento
end

function GUI:onDeleteProjectClick()
    Utils.debug("Projeto deletado! (simulação)")
end

-- Funções de atualização da interface
function GUI:updateKeyframeList()
    if not self.elements.keyframeList then return end
    
    guiGridListClear(self.elements.keyframeList)
    
    if self.editor.keyframeSystem then
        local keyframes = self.editor.keyframeSystem:getAllKeyframes()
        for i, keyframe in ipairs(keyframes) do
            local row = guiGridListAddRow(self.elements.keyframeList)
            guiGridListSetItemText(self.elements.keyframeList, row, 1, tostring(keyframe.id), false, false)
            guiGridListSetItemText(self.elements.keyframeList, row, 2, tostring(keyframe.time), false, false)
            guiGridListSetItemText(self.elements.keyframeList, row, 3, 
                string.format("%.1f, %.1f, %.1f", keyframe.position[1], keyframe.position[2], keyframe.position[3]), 
                false, false)
            guiGridListSetItemText(self.elements.keyframeList, row, 4, keyframe.easing, false, false)
        end
    end
    
    self:updateStatus()
end

function GUI:loadKeyframeDetails(keyframeId)
    if not self.editor.keyframeSystem then return end
    
    local keyframes = self.editor.keyframeSystem:getAllKeyframes()
    local keyframe = keyframes[keyframeId]
    
    if keyframe then
        guiSetText(self.elements.timeEdit, tostring(keyframe.time))
        
        -- Selecionar easing no combo box
        for i = 0, guiComboBoxGetItemCount(self.elements.easingCombo) - 1 do
            if guiComboBoxGetItemText(self.elements.easingCombo, i) == keyframe.easing then
                guiComboBoxSetSelected(self.elements.easingCombo, i)
                break
            end
        end
    end
end

function GUI:clearKeyframeDetails()
    guiSetText(self.elements.timeEdit, "2000")
    guiComboBoxSetSelected(self.elements.easingCombo, 0)
end

function GUI:updateStatus()
    if not self.elements.statusLabel or not self.elements.infoLabel or not self.elements.progressLabel or not self.elements.progressBar then return end
    
    local status = "Aguardando..."
    local progress = 0
    local totalTime = 0
    local elapsed = 0
    
    if self.editor then
        if self.editor:getCurrentState() == CinematicEditor.states.PLAYING then
            status = "Reproduzindo..."
        elseif self.editor:getCurrentState() == CinematicEditor.states.EDITING then
            status = "Editando"
        end
        
        -- Atualizar progresso se estiver reproduzindo
        if self.editor.playbackSystem and self.editor.playbackSystem:isPlaying() then
            progress = self.editor.playbackSystem:getProgress()
            totalTime = self.editor.playbackSystem:getTotalTime()
            elapsed = self.editor.playbackSystem:getElapsedTime()
        end
    end
    
    guiSetText(self.elements.statusLabel, "Status: " .. status)
    
    local count = 0
    if self.editor.keyframeSystem then
        count = self.editor.keyframeSystem:getCount()
    end
    guiSetText(self.elements.infoLabel, "Keyframes: " .. count)
    
    -- Atualizar barra de progresso
    guiProgressBarSetProgress(self.elements.progressBar, progress * 100)
    guiSetText(self.elements.progressLabel, string.format("%.1f%%", progress * 100))
    
    -- Atualizar informações técnicas
    if self.elements.technicalInfo then
        guiSetText(self.elements.technicalInfo, 
            "Versão: " .. CinematicEditor.config.version .. "\n" ..
            "Keyframes: " .. count .. "\n" ..
            "Estado: " .. (self.editor and self.editor:getCurrentState() or "Desconhecido"))
    end
end

function GUI:updateCameraPosition()
    if not self.editor or not self.editor.cameraObject then return end
    
    if self.elements.positionLabel and self.elements.rotationLabel then
        local x, y, z = getElementPosition(self.editor.cameraObject)
        local rx, ry, rz = getElementRotation(self.editor.cameraObject)
        
        guiSetText(self.elements.positionLabel, string.format("X: %.2f, Y: %.2f, Z: %.2f", x, y, z))
        guiSetText(self.elements.rotationLabel, string.format("RX: %.2f, RY: %.2f, RZ: %.2f", rx, ry, rz))
    end
end

function GUI:show()
    if self.window then
        guiSetVisible(self.window, true)
        showCursor(true)
        self.isVisible = true
        self:updateKeyframeList()
        self:updateStatus()
        self:updateCameraPosition()
        Utils.debug("Interface mostrada")
    end
end

function GUI:hide()
    if self.window then
        guiSetVisible(self.window, false)
        showCursor(false)
        self.isVisible = false
        Utils.debug("Interface escondida")
    end
end

function GUI:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

function GUI:isVisible()
    return self.isVisible
end

-- Exportar para uso global
_G.GUI = GUI

-- Bind de teclas para mostrar/esconder interface e controles de câmera
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Toggle interface
    bindKey("f2", "down", function()
        if CinematicEditor.instance and CinematicEditor.instance.guiSystem then
            CinematicEditor.instance.guiSystem:toggle()
        end
    end)
    
    -- Adicionar keyframe rápido
    bindKey("k", "down", function()
        if CinematicEditor.instance and 
           CinematicEditor.instance:getCurrentState() == CinematicEditor.states.EDITING and
           CinematicEditor.instance.guiSystem then
            local time = CinematicEditor.config.defaultTransitionTime
            if CinematicEditor.instance.guiSystem.elements.timeEdit then
                time = tonumber(guiGetText(CinematicEditor.instance.guiSystem.elements.timeEdit)) or time
            end
            CinematicEditor.instance:addCurrentPositionAsKeyframe(time)
        end
    end)
    
    -- Controles de movimento da câmera (apenas no modo edição)
    local function moveCamera(x, y, z)
        if CinematicEditor.instance and 
           CinematicEditor.instance:getCurrentState() == CinematicEditor.states.EDITING and
           CinematicEditor.instance.cameraObject then
            
            local moveSpeed = 1.0
            local px, py, pz = getElementPosition(CinematicEditor.instance.cameraObject)
            local rx, ry, rz = getElementRotation(CinematicEditor.instance.cameraObject)
            
            -- Converter movimento local para mundo
            local rad = math.rad(rz)
            local newX = px + (x * math.cos(rad) - y * math.sin(rad)) * moveSpeed
            local newY = py + (x * math.sin(rad) + y * math.cos(rad)) * moveSpeed
            local newZ = pz + z * moveSpeed
            
            setElementPosition(CinematicEditor.instance.cameraObject, newX, newY, newZ)
            
            -- Atualizar posição na interface
            if CinematicEditor.instance.guiSystem then
                CinematicEditor.instance.guiSystem:updateCameraPosition()
            end
        end
    end
    
    -- Bind de teclas de movimento
    bindKey("w", "down", function() moveCamera(0, 1, 0) end)
    bindKey("s", "down", function() moveCamera(0, -1, 0) end)
    bindKey("a", "down", function() moveCamera(-1, 0, 0) end)
    bindKey("d", "down", function() moveCamera(1, 0, 0) end)
    bindKey("space", "down", function() moveCamera(0, 0, 1) end)
    bindKey("lctrl", "down", function() moveCamera(0, 0, -1) end)
end)