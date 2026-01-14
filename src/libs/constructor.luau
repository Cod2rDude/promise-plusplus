--[[
	******************************************************************************
	* @file		: .../src/libs/constructor.lua
	* @author	: Cod2rDude
	* @date		: January 13 2026
	* @lastEdit	: January 13 2026 @ 21:31
	* @brief	: Promise constructor.
	* @version	: 0.2.1
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

--[[
	******************************************************************************
	* @notes	:	I'm sick and tired of this sh*t.
	* @motiv	:	You can’t win. It’s pointless to keep fighting. 
	*					Why, Mr. Anderson? Why? Why do you persist?
	* @reworked
	******************************************************************************
]]

--// Services
local runService			= game:GetService("RunService")

--// Libs
local types					= require(script.Parent.global.types)
local enums					= require(script.Parent.global.enums)
local utils					= require(script.Parent.global.utils)
local __log__				= require(script.Parent.Parent.__log__.__log__)

--// Custom Type Definitions/Declerations
type iPromise				= types.promise
type methods				= {
	__index					: methods,
}

type enumObject				= types.enumObject

--// Logs
local callbackIsntFunction	= 0x5
local unknownEnum			= 0x6
local wrongPromiseState		= 0x7
local emptyReasonTuple		= 0x8
local notARejectReason		= 0x9
local promiseError			= 0xA

--// Functions
function doWeKnowThisEnum(enum : enumObject, field : types.enumObject) : boolean
	return field and enum and field[enum.value] and field[field[enum.value]]
	-- Make sure @param field is never types.enumLibrary
end

--// Lib Decleration
local constructor			= {}

--// Lib Types
export type promise			= typeof(setmetatable({} :: iPromise, {} :: typeof(constructor)))

--// Lib Variables
constructor.__index			= constructor -- are you sure this is a variable?

--// Lib Private Functions
function isEmpty(...)
	return select("#", ...) == 0
end

function isEmpty2(t : {})
	return next(t) == nil
end

function is(object : any?) : boolean
	return  type(object) == "table" and object.whoAmI == enums.whoAmI
end

function expectState(self : promise, expectedState : enumObject)
	if self.state == expectedState then
		return true
	end
	__log__.new(wrongPromiseState, "Expected '"..expectedState.name.."', Got: "..self.state.name)
	return false
end

function willSomeoneHandleThis(self : promise)
	return not isEmpty2(self._catch)
		or #self._catchAll > 0
		or #self._catchUnexpected > 0
		or #self._onRejected > 0
end

function isARejectReason(object : any?)
	if not object then return false end
	if typeof(object) == "string" then return true end
	if typeof(object) == "table" then return true end

	return false
end

function _disownChild(self : promise, child)
	if self._children[child] then
		self._children[child] = nil
	end
end

function _adopt(daddy : promise, child : promise)
	child.daddy = daddy
	daddy._children[child] = true
end

function _finalize(self : promise)
	for _, callback in ipairs(self._finally) do
		pcall(callback)
	end

	table.clear(self._catch)
	table.clear(self._catchAll)
	table.clear(self._catchUnexpected)
	table.clear(self._finally)
	table.clear(self._onRejected)
	table.clear(self._onResolved)

	self.traceback = ""
end

function _cancel(self : promise)
	self.state = enums.promiseState.canceled

	if self.myThread then
		pcall(task.cancel, self.myThread)
	end

	self.myThread = nil
	self._executable = nil

	if self._cancellation then
		pcall(self._cancellation)
	end

	for _, eachPromise : promise in pairs(self._children) do
		_cancel(eachPromise)
	end

	if is(self.daddy) then
		_disownChild(self.daddy :: promise, self)
	end

	_finalize(self)
end

function _reject(self : promise, ...)
	if not expectState(self, enums.promiseState.pending) then return end

	local reason : types.rejectReason = enums.promiseRejectReason.noReason
	local remaining = {}

	if not isEmpty(...) then
		local firstItem = select(1, ...)

		if not isARejectReason(firstItem) then
			__log__.new(notARejectReason, {"Expected:", firstItem and typeof(firstItem) or "nil"})
		else
			reason = firstItem
		end

		remaining = table.pack(...)
	else
		__log__.new(emptyReasonTuple, "")
	end

	self.state = enums.promiseState.rejected
	self.value = {
		outcomes = remaining,
		error = reason,
		traceback = self.traceback
	} :: types.promiseResult

	-- What even is this.
	local whatsThis = (typeof(reason) == "table" and reason["name"] and reason["value"]) and "enum" or (
					typeof(reason) == "table" and "table" or "string")

	local errorMessage = reason

	if whatsThis == "enum" then local r = reason :: enumObject; errorMessage = r.name end
	if whatsThis == "table" then local r = reason :: {}; errorMessage = table.concat(r) end

	if not willSomeoneHandleThis(self) then
		coroutine.wrap(function(...) 
			runService.Heartbeat:Wait()

			if willSomeoneHandleThis(self) then return end

			__log__.new(promiseError, 
			{
				"Error Message:",
				errorMessage,
				"Traceback:",
				self.traceback and self.traceback or ""
			})
		end)()
		return
	end

	for _, rejectCallback in ipairs(self._onRejected) do
		task.defer(rejectCallback, reason)
	end

	if whatsThis ~= "table" and self._catch[errorMessage] then
		for i, v : () -> () in pairs(self._catch[errorMessage]) do
			task.defer(v)
		end
	else
		for i, v : (reason : types.rejectReason) -> () in ipairs(self._catchUnexpected) do
			task.defer(v, reason)
		end
	end

	for i, catchAllCallback : (reason : types.rejectReason) -> () in ipairs(self._catchAll) do
		task.defer(catchAllCallback, reason)
	end

	_finalize(self)
end

function _resolve(self : promise, ...)
	if not expectState(self, enums.promiseState.pending) then return end

	if is((...)) then -- if its a promise
		local myPromise = ... :: promise
 
		local newPromise = constructor._after(myPromise, function(...)
			_resolve(self, ...)
		end, function(...)
			_reject(self, ...)
		end) :: promise

		if newPromise.state == enums.promiseState.canceled then
			_cancel(self)
		elseif newPromise.state == enums.promiseState.pending then
			_adopt(newPromise, self)
		end

		return
	end

	self.state = enums.promiseState.resolved
	self.value = {
		outcomes = {...},
		error = nil,
		traceback = self.traceback
	} :: types.promiseResult

	for _, callback in ipairs(self._onResolved) do
		pcall(callback, table.unpack(self.value.outcomes))
	end

	_finalize(self)
end

function _prepareAndExecute(self : promise, executionType : types.enumObject)
	if self.state ~= enums.promiseState.waiting then 
		__log__.new(wrongPromiseState, "Expected '".."waiting', Got: "..self.state.name)
		return 
	end

	if not doWeKnowThisEnum(executionType, enums.executionType) then
		__log__.new(unknownEnum, "Given enum code is '"..tostring(executionType).."'")
		executionType = enums.executionType.immediate
	end

	if not utils.isFunction(self._executable) then
		__log__.new(callbackIsntFunction, "Given type: "..typeof(self._executable))
		self._executable = function(...) return ... end
	end

	local r1 = function(val) _resolve(self, val) end
	local r2 = function(err) _reject(self, err) end
	local r3 = function(callback : () -> ()) 
		if not utils.isFunction(callback) then
			__log__.new(callbackIsntFunction, "From onCancel")
			return
		end

		if self.state == enums.promiseState.canceled then
			pcall(callback)
		else
			self._cancellation = callback
		end
	end

	local isThisDefer = executionType == enums.executionType.defer
	local handler = isThisDefer and task.defer or task.spawn

	self.myThread = handler(function()
		local success, v = xpcall(self._executable :: (...any?) -> (...any?), function(a0) 
			return a0
		end, r1, r2, r3)

		if not success then
			_reject(self, v)
		end
	end)

	self.state = enums.promiseState.pending
end

--// Lib Public Functions

function constructor._run()

end

function constructor._cancel()

end

function constructor._after(self : promise, fullfilled : (...any) -> (), rejected : (types.rejectReason) -> ())
	if self.state == enums.promiseState.canceled then
		local newPromise = constructor._new(self.traceback, function() end, false, self)
		_cancel(self)
		return newPromise
	end

	local function bridge(chainedPromise : promise, callback : (...any) -> () | (types.rejectReason) -> (), ...)
		if not callback then
			if self.state == enums.promiseState.rejected then
				_reject(chainedPromise, ...)
			else
				_resolve(chainedPromise, ...)
			end
			return
		end

		local success, result = pcall(callback, ...)

		if not success then
			_reject(chainedPromise, result)
		else
			_resolve(chainedPromise, result)
		end
	end

	local chainedPromise = constructor._new(self.traceback,
		function(resolve: (any) -> (), reject: (string | types.enumObject | {  }) -> ()) 
		end
	, true, self)

	if self.state == enums.promiseState.resolved then
		bridge(chainedPromise, fullfilled, table.unpack(self.value.outcomes))
	elseif self.state == enums.promiseState.rejected then
		bridge(chainedPromise, rejected, self.value.error)
	else
		table.insert(self._onResolved, function(...)
			bridge(chainedPromise, fullfilled, ...)
		end)
		
		table.insert(self._onRejected, function(...)
			bridge(chainedPromise, rejected, ...)
		end)
	end

	return chainedPromise
end

function constructor.__catch()

end

function constructor.__catchAll()

end

function constructor.__catchUnexpected()

end

function constructor.__finally()

end

function constructor._await()

end

function constructor._awaitAndDo()

end

--// Lib Constructor
function constructor._new(
	traceback : string?,
	executable : (resolve : (any) -> (), reject : (types.rejectReason) -> (), onCancel : (()->())->()) -> (),
	runImmediately : boolean, 
	parent : any?
) : promise
	-- On cancel looks like a face tbh

	if not utils.isFunction(executable) then
		__log__.new(callbackIsntFunction, {})
		return constructor._new(debug.traceback(nil, 3), function() end, false, nil):cancel()
	end

	local data : iPromise	= {
		whoAmI				= enums.whoAmI,

		state 				= enums.promiseState.waiting,
		myThread 			= nil,
		value 				= {
			outcomes		= {},
			error			= enums.promiseRejectReason.noReason,
			traceback		= ""
		},
		traceback			= traceback or debug.traceback(nil, 2),
		daddy				= parent,
		_executable			= executable,
		_children			= setmetatable({}, {__mode = "k"}),
		
		_onResolved 		= {},
		_onRejected 		= {},
		_finally 			= {},
		_catch 				= {},
		_catchAll 			= {},
		_catchUnexpected	= {},
		_cancellation		= nil
	}

	local self = setmetatable(data, constructor)

	if runImmediately then
		 _prepareAndExecute(self, enums.executionType.immediate)
	end

	return self
end

constructor.new 			= function(
	executable : (resolve : (any) -> (), reject : (types.rejectReason) -> ()) -> (),
	runImmediately : boolean
) 
	return constructor._new(nil, executable, runImmediately, nil)
end

--// Lib Metamethods

--// Lib Static Functions

function constructor.race()

end

function constructor.all()

end

return constructor