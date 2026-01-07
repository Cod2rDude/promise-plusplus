--!nolint LocalShadow

--[[
	******************************************************************************
	* @file		: .../src/libs/constructor.lua
	* @author	: Cod2rDude
	* @date		: January 7 2026
	* @lastEdit	: January 7 2026 @ 16:35
	* @brief	: Promise constructor.
	* @version	: 0.0.1
	******************************************************************************
	* @attention
	*
	* Copyright © 2026 Axon Corporation.
	* All rights reserved.
	*
	* This software is licensed under terms that can be found in the LICENSE file
	* in the root directory of this software component.
	* If no LICENSE file comes with this software, it is provided AS-IS.
	*
	******************************************************************************
--]]

--// Libs
local types				= require(script.Parent.global.types)

--// Custom Type Definitions/Declerations
type i_promise			= types
type methods			= {
	__index				: methods,
}

export type promise		= typeof(setmetatable({} :: i_promise, {} :: methods))

--// Lib Decleration
local constructor		= {}
constructor.__index		= constructor

--// Lib Functions

--[[
	@params
	*	@param callback : function Callback to process in promise.
	@brief Creates a new promise.
	@returns
	*	@r1 promise Created promise object.
]]
constructor.new			= function()
	
end

return constructor