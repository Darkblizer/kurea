Module = require('../../core/Module').Module
colors = require 'irc-colors'

class ListModule extends Module
	shortName: "List"
	helpText:
		default: "Lists all the modules this bot has."
	usage:
		default: "list"
	constructor: (moduleManager) ->
		super(moduleManager)

		@addRoute "list", (origin, route) =>
			[bot, user, channel] = [origin.bot, origin.user, origin.channel]
			serverName = bot.conn.opt.server

			moduleManager._getModuleActiveData {server: serverName, channel: channel}, (data) =>
				moduleList = []

				data.forEach (module) ->
					moduleList.push if module.isEnabled then module.name else colors.red module.name

				moduleString = moduleList.join ', '

				@reply origin, "Current modules are: #{moduleString}"

			#list = (module.shortName for name, module of bot.getModules()).join(", ")
			#@reply origin, "Current modules are: #{list}"


exports.ListModule = ListModule