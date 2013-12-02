class ModuleManager
	constructor: ->
		@modules = []

	handleMessage: (bot, from, to, message) =>
		match = /^!(.+?)(?:\s+(.+))?$/.exec(message)
		return if match is null

		[command, params] = match[1..2]

		console.log "Handling command #{command} with params '#{params}'"

		for module in @modules
			module.useCommand({ bot: bot, channel: to, user: from, command: command, params: params }) if module.hasCommand(command)

exports.ModuleManager = ModuleManager