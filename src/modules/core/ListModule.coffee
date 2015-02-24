module.exports = (Module) ->
	colors = require 'irc-colors'
	_ = require 'lodash'
	
	class ListModule extends Module
		shortName: "List"
		helpText:
			default: "Lists all the modules this bot has."
		usage:
			default: "list"
		constructor: (moduleManager) ->
			super(moduleManager)
	
			@addRoute "list", (origin) =>
				[bot, channel] = [origin.bot, origin.channel]
				serverName = bot.conn.opt.server

				fullExistingModuleList = []
				for nodeModuleName, kureaModules of moduleManager.modules
					for moduleName, module of kureaModules
						fullExistingModuleList.push module.shortName

				if !_.contains origin.channel, "#"
					return @reply origin, "While some modules may not work correctly in PM, here is the list:
						#{(_.sortBy fullExistingModuleList, _.identity).join ', '}"

				moduleManager._getModuleActiveData {server: serverName, channel: channel}, (data) =>
					moduleList = []

					fullExistingModuleList.forEach (module) ->
						moduleList.push if (_.findWhere data, {name: module, isEnabled: false}) or (not _.findWhere data, {name: module}) then colors.red module else module
	
					@reply origin, "Current modules are: #{(_.sortBy moduleList, _.identity).join ', '}"
	
	ListModule