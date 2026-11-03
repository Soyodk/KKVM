local activeDownloads = {}

local function replaceModel(model)
    local dffPath = ("assets/models/%d.dff"):format(model)
    local txdPath = ("assets/models/%d.txd"):format(model)
    local txd = engineLoadTXD(txdPath)
    local dff = engineLoadDFF(dffPath, model)

    if txd then
        engineImportTXD(txd, model)
    end
    if dff then
        engineReplaceModel(dff, model)
    end

    if not txd or not dff then
        outputDebugString(("Owner vehicle model %d failed to load"):format(model), 2)
    end
end

local function loadModelWhenReady(model)
    if activeDownloads[model] then
        return
    end

    local dffPath = ("assets/models/%d.dff"):format(model)
    local txdPath = ("assets/models/%d.txd"):format(model)
    if not fileExists(dffPath) then
        downloadFile(dffPath)
    end
    if not fileExists(txdPath) then
        downloadFile(txdPath)
    end

    activeDownloads[model] = {attempts = 0}
    local timer
    timer = setTimer(function()
        local state = activeDownloads[model]
        if not state then
            killTimer(timer)
            return
        end

        state.attempts = state.attempts + 1
        if fileExists(dffPath) and fileExists(txdPath) then
            replaceModel(model)
            activeDownloads[model] = nil
            killTimer(timer)
        elseif state.attempts >= 120 then
            outputDebugString(("Owner vehicle model %d download timed out"):format(model), 2)
            activeDownloads[model] = nil
            killTimer(timer)
        end
    end, 500, 0)
end

addEvent("kkvm.ownerPerks.applyModels", true)
addEventHandler("kkvm.ownerPerks.applyModels", resourceRoot, function(models)
    if source ~= resourceRoot or type(models) ~= "table" then
        return
    end

    for _, model in ipairs(models) do
        if type(model) == "number" then
            loadModelWhenReady(model)
        end
    end
end)