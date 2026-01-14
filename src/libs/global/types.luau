--// Lib Decleration
local types 				= {}

--// Lib Types
export type enumObject		= {value : number, name : string}

export type promiseState	= enumObject
export type rejectReason	= string | {} | enumObject

export type promise			=
{
	whoAmI					: enumObject,

	state 					: promiseState,
	myThread				: thread?,
	value					: promiseResult,
	traceback				: string?,
	daddy					: any?,
	_children				: typeof(setmetatable({}, {__mode = "k"})),
	_executable				: (resolve : (any) -> (), reject : (rejectReason) -> (), onCancel : (()->())->()) -> ()?,

	_onResolved				: {(any?)->()},								-- This runs for every resolve.
	_onRejected				: {(reason : number)->()},					-- This runs for every rejection.
	_finally				: {()->()},									-- This runs even if resolved or rejected.
	_catch					: {[rejectReason] : {()->()}},		-- This only runs for specific reasons.
	_catchAll				: {(reason : rejectReason) -> ()},	-- This runs for every reason.
	_catchUnexpected		: {(reason : rejectReason) -> ()},	-- This runs for any reason that didnt exist in self._catch
	_cancellation			: () -> (...any?)?
}

export type promiseResult	= 
{
	outcomes				: {any},
	error 					: rejectReason,
	traceback				: typeof(debug.traceback())
}

return types