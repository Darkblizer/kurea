Module = require('../../core/Module').Module

class EchoModule extends Module
	shortName: "Echo"
	helpText:
		default: "I'll say whatever you want me to say. USAGE: !echo [target] [message]"

	constructor: ->
		super()

		@addRoute "echo :target *", (origin, route) =>
			origin.bot.say route.params.target, route.splats[0]

exports.EchoModule = EchoModule