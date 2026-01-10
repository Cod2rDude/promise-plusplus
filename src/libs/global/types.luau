--// Lib Decleration
local types 			= {}

--// Lib Types
export type promiseState= number
export type rejectReason= number

export type promise		=
{
	state 				: promiseState,
	myThread			: thread?,
	value				: any,
	_callback			: (onResolved : (any) -> (), onRejected : (rejectReason | string | {}) -> ()) -> ()?,

	_onResolved			: {(any?)->()},								-- This runs for every resolve.
	_onRejected			: {(reason : number)->()},					-- This runs for every rejection.
	_finally			: {()->()},									-- This runs even if resolved or rejected.
	_catch				: {[rejectReason | string] : {()->()}},		-- This only runs for specific reasons.
	_catchAll			: {(reason : rejectReason | string) -> ()},	-- This runs for every reason.
	_catchUnexpected	: {(reason : rejectReason | string) -> ()}	-- This runs for any reason that didnt exist in self._catch
}

return types