--[[
	******************************************************************************
	* @file		: .../src/libs/constructor.lua
	* @author	: Cod2rDude
	* @date		: January 7 2026
	* @lastEdit	: January 8 2026 @ 22:30
	* @brief	: Promise constructor.
	* @version	: 0.1.3
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
type methods				= {
	__index					: methods,
	after 					: (self : methods, fullfilled : () -> ()?, rejected : () -> ()?) -> (methods),
	catch 					: (self : methods, reason : types.rejectReason | string, callback : () -> ()) -> (methods),
	finally					: (self : methods, callback : () -> ()) -> (methods),
	catchAll				: (self : methods, callback : () -> ()) -> (methods),
	run						: (self : methods) -> (methods),
	await					: (self : methods) -> (),
}
type i_promise				= types.promise

--// Logs
local callbackIsntFunction	= 0x5
local bothCantBeNonFunction	= 0x6
local reasonMustBeNumOrStr	= 0x7
local expectedMoreFunctions	= 0x8
local errorWhileXpcall		= 0x9

--// Functions
local function xpcallFunction(functionToXpcall : () -> (...any?)) -- useless ah why am i keeping this.
	local success, err = xpcall(functionToXpcall, function(err)
		__log__.new(errorWhileXpcall, {"Reason: "..err, "At promise.constructor.all"})
	end)
end

--// Lib Decleration
local constructor			= {}

--// Lib Types
export type promise			= typeof(setmetatable({} :: i_promise, {} :: typeof(constructor)))

--// Lib Variables
constructor.__index			= constructor

--// Lib Functions
function constructor.is(object : any)
	return type(object) == "table" and getmetatable(object) == constructor
end

function constructor.resolve(self : promise, value : any?)
	if self.state ~= enums.promiseState.pending and self.state ~= enums.promiseState.waiting then return end

	self.state = enums.promiseState.resolved
	self.value = value

	for _, resolveCallback in pairs(self._onResolved) do
		task.defer(resolveCallback, value)
	end
		
	for _, finallyCallback in pairs(self._finally) do
		task.defer(finallyCallback)
	end
end

function constructor.reject(self : promise, reason : types.rejectReason | string)
	if self.state ~= enums.promiseState.pending then return end
	if type(reason) ~= "string" and type(reason) ~= "number" then
		__log__.new(reasonMustBeNumOrStr, {"catch"})
		reason = enums.promiseRejectReason.wrongReason
	end

	self.state = enums.promiseState.rejected
	self.value = reason

	for _, rejectCallback in pairs(self._onRejected) do
		task.defer(rejectCallback, reason)
	end

	if self._catch[reason] then
		for _, catchCallback in pairs(self._catch[reason]) do
			task.defer(catchCallback)
		end
	else
		for _, catchAllCallback in pairs(self._catchAll) do
			task.defer(catchAllCallback, reason)
		end
	end

	for _, finallyCallback in pairs(self._finally) do
		task.defer(finallyCallback)
	end
end

function constructor.execute(self : promise)
	if not self._callback then return end

	local r1  = function(val) constructor.resolve(self, val) end
	local r2  = function(err) constructor.reject(self, err) end

	self.myThread = task.defer(function()
		local success, err = xpcall(function()
			if self._callback then
				self._callback(r1, r2)
			end
		end, debug.traceback)

		if not success then
			constructor.reject(self, err)
		end
	end)
end

--[[
	@params
	*	@param callback : function Callback to process in promise.
	@brief Creates a new promise.
	@returns
	*	@r1 promise Created promise object.
]]
constructor.new				= function(
	callback : (onResolved : (any) -> (), onRejected : (types.rejectReason | string) -> ()) -> (),
	runImmediate : boolean
) : promise?
	if not utils.isFunction(callback) then
		__log__.new(callbackIsntFunction, {})
		return
	end
	
	local data : types.promise	= {
		state 				= enums.promiseState.waiting,
		myThread 			= nil,
		value 				= nil,
		_callback			= callback,
		
		_onResolved 		= {},
		_onRejected 		= {},
		_finally 			= {},
		_catch 				= {},
		_catchAll 			= {}, 
	}

	local self = setmetatable(data, constructor)

	if runImmediate then
		self.state = enums.promiseState.pending
		constructor.execute(self)
	end

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
	local isFunction1 = utils.isFunction(fullfilled)
	local isFunction2 = utils.isFunction(rejected)

	if not isFunction2
	 and not isFunction1
	then
		__log__.new(bothCantBeNonFunction, {})
		return self
	end

	-- necessary?
	if not isFunction1 then
		fullfilled = function(v)
			return v
		end
	end

	if not isFunction2 then
		rejected = function(reason)
			return reason
		end --??????
	end

	return constructor.new(function(resolve, reject)
		local function handleCallback(callback, val)
			if not callback then
				if self.state == enums.promiseState.resolved then resolve(val) else reject(val) end
				return
			end

			local success, result = xpcall(function() 
				return callback(val) 
			end, debug.traceback)

			if success then
				if constructor.is(result) then
					result:after(resolve, reject)
				else
					resolve(result)
				end
			else
				reject(result)
			end
		end

		if self.state == enums.promiseState.resolved then
			handleCallback(fullfilled, self.value)
		elseif self.state == enums.promiseState.rejected then
			handleCallback(rejected, self.value)
		else
			table.insert(self._onResolved, function(val) handleCallback(fullfilled, val) end)
			table.insert(self._onRejected, function(val) handleCallback(rejected, val) end)
		end
	end, true)
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
	if not utils.isFunction(callback) then
		__log__.new(callbackIsntFunction, {"catch"})
		return self
	end

	if type(reason) ~= "string" and type(reason) ~= "number" then
		__log__.new(reasonMustBeNumOrStr, {"catch"})
		return self
	end

	if self.value == reason and self.state == enums.promiseState.rejected then
		task.defer(callback)
		return self
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
	if not utils.isFunction(callback) then
		__log__.new(callbackIsntFunction, {"finally"})
		return self
	end

	if self.state == enums.promiseState.pending or self.state == enums.promiseState.waiting then 
		table.insert(self._finally, callback)
	else
		task.defer(callback)
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
	if not utils.isFunction(callback) then
		__log__.new(callbackIsntFunction, {"catchAll"})
		return self
	end

	if self.state == enums.promiseState.rejected then
		if not self._catch[self.value] then
			task.defer(callback, self.value)
		end
	else
		table.insert(self._catchAll, callback)
	end

	return self
end

--[[
	@brief Yields current thread until promise finishes.
	@returns
	*	@r1 thread
]]
function constructor:await()
	if self.state == enums.promiseState.resolved then
		return true, self.value
	elseif self.state == enums.promiseState.rejected then
		return false, self.value
	end

	local thisThread = coroutine.running()

	self:finally(function()
		task.spawn(thisThread, self.state == enums.promiseState.resolved, self.value)
	end)

	return coroutine.yield()
end

--[[
	@brief Starts executing promise.
	@returns
	*	@r1 promise self
]]
function constructor:run()
	if self.state ~= enums.promiseState.waiting then return self end

	self.state = enums.promiseState.pending
	constructor.execute(self)

	return self
end

--[[
	@params
	*	@param self : promise Promise to be canceled.
	@brief Cancels given promise and puts it in canceled state.
]]
function constructor.cancel(self : promise)
	if self.state ~= enums.promiseState.pending then return end

	self.state = enums.promiseState.canceled

	if self.myThread then
		pcall(task.cancel, self.myThread) 
		self.myThread = nil
	end

	for _, callback : () -> () in pairs(self._finally) do
		if typeof(callback) == "function" then
			task.defer(callback)
		end
	end
end

--[[
	@params
	*	@param self : promise Promise to be cleaned.
	@brief Cleans a promise and puts it in dead state.
]]
function constructor.cleanup(self : promise)
	--[[
		Literally cleans a promise and puts it in dead state
	]]

	constructor.cancel(self)

	self.state = enums.promiseState.dead
	
	table.clear(self._onRejected)
	table.clear(self._onResolved)
	table.clear(self._catch)
	table.clear(self._catchAll)
	table.clear(self._finally)

	self.myThread = nil
	self._callback = nil
end

-- @todo
function constructor.race()
	--[[
		In a given list of promises or functions,
		does something or returns something when one of
		them finishes or resolves.
	]]
end

--[[
	@params
	*	@param list : {[number] : ()->()} Functions to convert to promise.
	@brief Returns a promise object that will only resolve when all of functions in given @param list resolves succesfully too, if one of them fails,
	*		it will reject.
	@returns
	*	@r1 promise A new promise that will resolve when all of promises converted from given functions resolve succesfully.
	@todo:
	*	When resolving return a table of out
	*	Let list contain promises too
]]
function constructor.allFunction(
	list : {[number] : (onResolved : (any) -> (), onRejected : (types.rejectReason | string) -> () | promise) -> (...any?)}
)
	-- please test me i seem like i will fail bro!!!

	local function returnTableWithFunctionsOnly(t : {any?}) : ({()->()?}, number)
		local functionTable = {}
		local count = 0

		for i, v in pairs(t) do
			if typeof(v) == "function" then
				table.insert(functionTable)
				count += 1
			end
		end

		return functionTable, count
	end

	return constructor.new(function(onResolved, onRejected)
		local fixedList, count = returnTableWithFunctionsOnly(list)
		local promises : {promise} = {}
		local promisesCompleted = 0
		local promisesRejected = 0

		if count < 1 then
			-- when failed.
			__log__.new(expectedMoreFunctions, {"Real count: "..tostring(count)})
			onRejected(enums.promiseRejectReason.expectedMoreFunctions)
			return
		end

		for i = 1, #count do
			if promisesRejected > 0 then
				table.clear(promises)
				onRejected(enums.promiseRejectReason.gotRejectionWhileRunning)
				break
			end

			local accessedFunction = fixedList[count]
			local createdPromise = constructor.new(accessedFunction)

			table.insert(promises, createdPromise)

			createdPromise:after(
				function()
					promisesCompleted += 1

					if promisesCompleted == count then
						table.clear(promises)

						onResolved("success")
					end
				end,
				function()
					promisesRejected += 1
				end
			)
		end
	end, true)
end

return constructor