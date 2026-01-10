return 
{
	promiseState		= 
	{
		pending			= 1,
		resolved		= 2,
		canceled 		= 3,
		rejected		= 4,
		waiting			= 5,
		dead			= 6
	},
	promiseRejectReason			= {
		timeout					= 1,
		wrongReason				= 2,
		expectedMoreFunctions	= 3,
		gotRejectionWhileRunning= 4,
	},
	emptyValue			= 0x1F
}