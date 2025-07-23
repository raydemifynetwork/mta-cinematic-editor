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
    self.window = guiCreateWindow(50, 50, 500, 400, "Cinematic Editor v" .. CinematicEditor.config.version, false)
    guiWindowSetSizable(self.window, false)
    guiSetVisible(self.window, false)
    
    -- Painel de abas
    local tabPanel = guiCreateTabPanel(10, 25, 480, 365, false, self.window)
    
    -- Aba de Keyframes
    self:createKeyframeTab(tabPanel)
    
    -- Aba de Controles
    self:createControlTab(tabPanel)
    
    -- Bind de eventos
    self:bindEvents()
    
    Utils.debug("Interface gráfica criada")
end

function GUI:createKeyframeTab(tabPanel)
    local keyframeTab = guiCreateTab("Keyframes", tabPanel)
    
    -- Lista de keyframes
    self.elements.keyframeList = guiCreateGridList(10, 10, 460, 150, false, keyframeTab)
    guiGridListAddColumn(self.elements.keyframeList, "ID", 0.1)
    guiGridListAddColumn(self.elements.keyframeList, "Tempo (ms)", 0.2)
    guiGridListAddColumn(self.elements.keyframeList, "Posição", 0.4)
    guiGridListAddColumn(self.elements.keyframeList, "Easing", 0.3)
    
    -- Botões de keyframe
    self.elements.btnAddKeyframe = guiCreateButton(10, 170, 100, 30, "Adicionar Keyframe", false, keyframeTab)
    self.elements.btnRemoveKeyframe = guiCreateButton(120, 170, 100, 30, "Remover Keyframe", false, keyframeTab)
    self.elements.btnSelectKeyframe = guiCreateButton(230, 170, 100, 30, "Selecionar", false, keyframeTab)
    
    -- Detalhes do keyframe selecionado
    guiCreateLabel(10, 210, 100, 20, "Editar Keyframe:", false, keyframeTab)
    
    guiCreateLabel(10, 235, 80, 20, "Tempo (ms):", false, keyframeTab)
    self.elements.timeEdit = guiCreateEdit(10, 255, 100, 25, "2000", false, keyframeTab)
    
    guiCreateLabel(120, 235, 80, 20, "Easing:", false, keyframeTab)
    self.elements.easingCombo = guiCreateComboBox(120, 255, 150, 100, "Linear", false, keyframeTab)
    
    -- Adicionar opções de easing
    local easings = {"Linear", "InQuad", "OutQuad", "InOutQuad", "InCubic", "OutCubic", "InOutCubic", "InQuart", "OutQuart", "InOutQuart"}
    for _, easing in ipairs(easings) do
        guiComboBoxAddItem(self.elements.easingCombo, easing)
    end
    
    self.elements.btnSaveChanges = guiCreateButton(280, 255, 100, 25, "Salvar", false, keyframeTab)
end

function GUI:createControlTab(tabPanel)
    local controlTab = guiCreateTab("Controles", tabPanel)
    
    -- Informações do projeto
    guiCreateLabel(10, 10, 150, 20, "Controles do Projeto:", false, controlTab)
    
    self.elements.btnPlay = guiCreateButton(10, 35, 100, 30, "▶ Reproduzir", false, controlTab)
    self.elements.btnStop = guiCreateButton(120, 35, 100, 30, "⏹ Parar", false, controlTab)
    self.elements.btnClear = guiCreateButton(230, 35, 100, 30, "🗑 Limpar Tudo", false, controlTab)
    
    -- Status
    self.elements.statusLabel = guiCreateLabel(10, 80, 300, 20, "Status: Aguardando...", false, controlTab)
    
    -- Informações
    local keyframeCount = 0
    if self.editor.keyframeSystem then
        keyframeCount = self.editor.keyframeSystem:getCount()
    end
    self.elements.infoLabel = guiCreateLabel(10, 110, 300, 20, "Keyframes: " .. keyframeCount, false, controlTab)
    
    -- Ajuda
    guiCreateLabel(10, 150, 400, 20, "Comandos rápidos:", false, controlTab)
    guiCreateLabel(10, 170, 400, 20, "F2 - Mostrar/Esconder editor", false, controlTab)
    guiCreateLabel(10, 190, 400, 20, "K - Adicionar keyframe na posição atual", false, controlTab)
    guiCreateLabel(10, 210, 400, 20, "WASD + Espaço - Mover câmera", false, controlTab)
end

function GUI:bindEvents()
    -- Botões de keyframe
    addEventHandler("onClientGUIClick", self.elements.btnAddKeyframe, 
        function() self:onAddKeyframeClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnRemoveKeyframe, 
        function() self:onRemoveKeyframeClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnSelectKeyframe, 
        function() self:onSelectKeyframeClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnSaveChanges, 
        function() self:onSaveChangesClick() end, false)
    
    -- Botões de controle
    addEventHandler("onClientGUIClick", self.elements.btnPlay, 
        function() self:onPlayClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnStop, 
        function() self:onStopClick() end, false)
    addEventHandler("onClientGUIClick", self.elements.btnClear, 
        function() self:onClearClick() end, false)
    
    -- Seleção na lista
    addEventHandler("onClientGUIDoubleClick", self.elements.keyframeList, 
        function() self:onKeyframeDoubleClick() end, false)
end

function GUI:onAddKeyframeClick()
    if self.editor then
        local time = tonumber(guiGetText(self.elements.timeEdit)) or CinematicEditor.config.defaultTransitionTime
        local easingIndex = guiComboBoxGetSelected(self.elements.easingCombo)
        local easing = guiComboBoxGetItemText(self.elements.easingCombo, easingIndex)
        if easing == "" then easing = "Linear" end
        
        self.editor:addCurrentPositionAsKeyframe(time, easing)
    end
end

function GUI:onRemoveKeyframeClick()
    if self.editor then
        self.editor:removeSelectedKeyframe()
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

function GUI:onKeyframeDoubleClick()
    self:onSelectKeyframeClick()
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

function GUI:onPlayClick()
    if self.editor then
        self.editor:playCinematic()
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
    end
end

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
    if not self.elements.statusLabel or not self.elements.infoLabel then return end
    
    local status = "Aguardando..."
    if self.editor then
        if self.editor:getCurrentState() == CinematicEditor.states.PLAYING then
            status = "Reproduzindo..."
        elseif self.editor:getCurrentState() == CinematicEditor.states.EDITING then
            status = "Editando"
        end
    end
    
    guiSetText(self.elements.statusLabel, "Status: " .. status)
    
    local count = 0
    if self.editor.keyframeSystem then
        count = self.editor.keyframeSystem:getCount()
    end
    guiSetText(self.elements.infoLabel, "Keyframes: " .. count)
end

function GUI:show()
    if self.window then
        guiSetVisible(self.window, true)
        showCursor(true)
        self.isVisible = true
        self:updateKeyframeList()
        self:updateStatus()
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

-- Bind de teclas para mostrar/esconder interface
addEventHandler("onClientResourceStart", resourceRoot, function()
    bindKey("f2", "down", function()
        if CinematicEditor.instance and CinematicEditor.instance.guiSystem then
            CinematicEditor.instance.guiSystem:toggle()
        end
    end)
    
    bindKey("k", "down", function()
        if CinematicEditor.instance and 
           CinematicEditor.instance:getCurrentState() == CinematicEditor.states.EDITING then
            local time = CinematicEditor.config.defaultTransitionTime
            if CinematicEditor.instance.guiSystem then
                time = tonumber(guiGetText(CinematicEditor.instance.guiSystem.elements.timeEdit)) or time
            end
            CinematicEditor.instance:addCurrentPositionAsKeyframe(time)
        end
    end)
end)
