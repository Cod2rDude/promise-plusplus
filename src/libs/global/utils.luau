--// Lib Decleration
local utils		= {}

--// Lib Functions
function utils.isFunction(object : any)
	return object and typeof(object) == "function"
end

return utils