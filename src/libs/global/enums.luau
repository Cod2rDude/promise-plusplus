--// Libs
local types						= require(script.Parent.types)

--// Custom Type Definitions
export type enumObject			= types.enumObject

--// Lib
return {
	promiseState				= 
	{
		pending					= {name = "pending", value = 1} :: enumObject,
		resolved				= {name = "resolved", value = 2} :: enumObject,
		canceled 				= {name = "canceled", value = 3} :: enumObject,
		rejected				= {name = "rejected", value = 4} :: enumObject,
		waiting					= {name = "waiting", value = 5} :: enumObject,

		[1]						= "pending",
		[2]						= "resolved",
		[3]						= "canceled",
		[4]						= "rejected",
		[5]						= "waiting",
	},
	promiseRejectReason			= 
	{
		noReason 				= {name = "noReason", value = 1} :: enumObject,
		unknown					= {name = "unknown", value = 2} :: enumObject,

		[1]						= "noReason",
		[2]						= "unknown",
	},
	executionType				= 
	{
		defer					= {name = "defer", value = 1} :: enumObject,
		immediate				= {name = "immediate", value = 2} :: enumObject,

		[1]						= "defer",
		[2]						= "immediate"
	},

	whoAmI						= {name = "whoAmI", value = 0x45}, -- yeah i know i know.

	[1]							= "whoAmI"
}