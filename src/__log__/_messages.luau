return {
	[0x1] = {
		type = "warning";
		message = {
			[1] = "Logger";
			[2] = "Can not find message in given id. Please check if given index is valid.";
		};
	};
	[0x2] = {
		type = "warning";
		message = {
			[1] = "Logger";
			[2] = "Given message partition is not a string.";
		};
	};
	[0x3] = {
		type = "warning";
		message = {
			[1] = "Logger";
			[2] = "Message is empty.";
		};
	};
	[0x4] = {
		type = "warning";
		message = {
			[1] = "Logger";
			[2] = "While given message is an error, it does not include a level. Did you forget it?";
		};
	};
	[0x5] = {
		type = "warning";
		message = {
			[1] = "Given @param callback is not a function.";
		};
	};
	[0x6] = {
		type = "warning";
		message = {
			[1] = "On :after, @param fullfilled and @param rejected can't be none function at same time.";
		};
	};
	[0x7] = {
		type = "warning";
		message = {
			[1] = "@param reason must be a string or a number.";
		};
	};
}