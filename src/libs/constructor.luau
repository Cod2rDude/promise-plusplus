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
local types					= require(script.Parent.global.types)
local enums					= require(script.Parent.global.enums)
local utils					= require(script.Parent.global.utils)
local __log__				= require(script.Parent.Parent.__log__.__log__)

--// Custom Type Definitions/Declerations
type i_promise				= types.promise
type methods				= {
	__index					: methods,
	after 					: (self : i_promise, fullfilled : () -> ()?, rejected : () -> ()?) -> (methods),
	catch 					: (self : i_promise, reason : types.rejectReason | string, callback : () -> ()) -> (methods),
	finally					: (self : i_promise, callback : () -> ()) -> (methods),
	catchAll				: (self : i_promise, callback : () -> ()) -> (methods),
}

export type promise			= typeof(setmetatable({} :: i_promise, {} :: methods))

--// Logs
local callbackIsntFunction	= 0x5

--// Lib Decleration
local constructor			= {}
constructor.__index			= constructor

--// Lib Functions
function constructor.is(object : any)
	return type(object) == "table" and getmetatable(object) == constructor
end

--[[
	@params
	*	@param callback : function Callback to process in promise.
	@brief Creates a new promise.
	@returns
	*	@r1 promise Created promise object.
]]
constructor.new				= function(
	callback : (onResolved : (any) -> (), onRejected : (types.rejectReason | string) -> ()) -> ()
) : promise
	if not utils.isFunction(callback) then
		__log__.new(callbackIsntFunction, {})
		return
	end
	
	local data : i_promise	= {
		state 				= enums.promiseState.pending,
		myThread 			= nil,
		value 				= nil,
		
		_onResolved 		= {},
		_onRejected 		= {},
		_finally 			= {},
		_catch 				= {},
		_catchAll 			= {}, 
	}

	local self = setmetatable(data, constructor) :: promise

	local function resolve(value : any?)
		if self.state ~= enums.promiseState.pending then return end

		self.state = enums.promiseState.resolved
		self.value = value

		for _, resolveCallback in pairs(self._onResolved) do
			task.spawn(resolveCallback, value)
		end
		
		for _, finallyCallback in pairs(self._finally) do
			task.spawn(finallyCallback)
		end
	end

	local function reject(reason : types.rejectReason | string)
		if self.state ~= enums.promiseState.pending then return end

		self.state = enums.promiseState.rejected
		self.value = reason

		for _, rejectCallback in pairs(self._onRejected) do
			task.spawn(rejectCallback, reason)
		end

		if self._catch[reason] then
			for _, catchCallback in pairs(self._catch[reason]) do
				task.spawn(catchCallback)
			end
		else
			for _, catchAllCallback in pairs(self._catchAll) do
				task.spawn(catchAllCallback, reason)
			end
		end
		
		for _, finallyCallback in pairs(self._finally) do
			task.spawn(finallyCallback)
		end
	end

	self.myThread = task.defer(function()
		local success, err = xpcall(function()
			callback(resolve, reject)
		end, debug.traceback)

		if not success then
			reject(err)
		end
	end)

	return self
end

--[[
	@params
	*	@param fullfilled : (value: any?) -> any? Callback triggered on successful resolution.
	*	@param rejected   : (err: any?) -> any?   Callback triggered on promise failure.
	@brief Chains a new asynchronous operation to the current promise.
	@returns
	*	@r1 promise A new promise instance that follows the state of the callbacks.
	@notes
	*	If a callback returns a promise, the chain "waits" (Unwraps) for that promise.
	*	If no callback is provided for a state, the value/error is "Passed Through."
	*	All callbacks are wrapped in pcall to catch runtime exceptions and trigger rejections.
]]
function constructor:after(fullfilled : () -> ()?, rejected : () -> ()?)
	-- I used ai while writing this function's header^^

	local self : promise = self

	return constructor.new(function(resolve, reject)
		local function handleResolve(value : any?)
			if fullfilled then
				local success, result = pcall(fullfilled, value)

				if success then
					if constructor.is(result) then
						result:after(resolve, reject)
					else
						resolve(result)
					end
				else
					reject(result)
				end
			else
				resolve(value)
			end
		end

		local function handleReject(err : types.rejectReason | string)
			if rejected then
				local success, newValue = pcall(rejected, err)

				if success then
					if constructor.is(newValue) then
						newValue:after(resolve, reject)
					else
						resolve(newValue)
					end
				else
					reject(newValue)
				end
			else
				reject(err)
			end
		end

		if self.state == enums.promiseState.resolved then
			handleResolve(self.value)
		elseif self.state == enums.promiseState.rejected then
			handleReject(self.value)
		else
			table.insert(self._onResolved, handleResolve)
			table.insert(self._onRejected, handleReject)
		end
	end)
end

--[[
	@params
	*	@param reason : string | number Expected reason of rejection.
	*	@param callback : function Function to run when promise gets rejected with expected reason
	@brief Adds an error expectation to promise, only gets called when promise gets rejected with @param reason.
	@returns
	*	@r1 promise self
]]
function constructor:catch(reason : types.rejectReason | string, callback : () -> ())
	local self : promise = self

	if self.value == reason and self.state == enums.promiseState.rejected then
		task.spawn(callback)
		return
	end

	if not self._catch[reason] then
		self._catch[reason] = {}
	end

	table.insert(self._catch[reason], callback)

	return self
end

--[[
	@params
	*	@param callback : function Function to run when promise gets rejected with expected reason
	@brief Adds a callback to promise that runs when either promise is rejected or resolved.
	@returns
	*	@r1 promise self
]]
function constructor:finally(callback : () -> ())
	local self : promise = self

	if self.state == enums.promiseState.pending then 
		table.insert(self._finally, callback)
	else
		task.spawn(callback)
	end

	return self
end

--[[
	@params
	*	@param callback : function Function to run when promise gets rejected with unexpected reason
	@brief Adds an unexpected error function to promise, only gets called when promise gets rejected with a reason that
			does not exist in self._catch.
	@returns
	*	@r1 promise self
]]
function constructor:catchAll(callback : (reason : types.rejectReason | string) -> ())
	local self : promise = self

	if self.state == enums.promiseState.rejected then
		task.spawn(callback, self.value)
	else
		table.insert(self._catchAll, callback)
	end

	return self
end

return constructor