local CompileAndRun = require("@self/src/Runtime/CompileAndRun")

return {
    Run = function(dir: Folder): ()
        local pile = {}
        for _, file in dir:GetChildren() do
            local success, status, resultOrError = CompileAndRun(file)
            if success then
                table.insert(pile, resultOrError)
                continue
            end
            warn(`{status}: {resultOrError}`)
        end
    end
}