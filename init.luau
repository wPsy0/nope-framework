--!strict

local module = {}

function module.doSomething(...: any): ()
    print(...)
end

return module