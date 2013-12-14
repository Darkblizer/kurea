EventEmitter = require('events').EventEmitter
_ = require 'underscore'
_.str = require 'underscore.string'
Database = require 'nedb'
color = require 'irc-colors'
Q = require 'q'

BotEvents = require('./Bot').events

class ModuleManager extends EventEmitter

	moduleActiveSettings: new Database { autoload: true, filename: 'data/bot-core/module-settings.kdb' }

	constructor: (@botManager) ->
		@botListeners = []
		@modules = require('./ModuleFinder').buildModuleList @

	findModuleByNameAndAliases: (name) =>

		name = name.toLowerCase()

		possibleModule = null

		for moduleName,module of @modules

			break if possibleModule isnt null

			compareNames = [module.shortName.toLowerCase()]

			for alias of module.usage when alias isnt 'default'
				compareNames.push alias.toLowerCase()

			possibleModule = module if -1 isnt compareNames.indexOf name

		possibleModule

	isModuleActive: (module, server, channel) =>
		deferred = Q.defer()

		@moduleActiveSettings.find { name: module.shortName, server: server, channel: channel }, (err, data) ->
			#I would rather do this somewhere at startup, but...
			if module.shortName is 'Toggle' or (data isnt [] and data.length is 1 and data[0].isEnabled)
				deferred.resolve(true)
			else
				deferred.reject(false)

		deferred.promise

	_getModuleActiveData: (search, callback) ->
		@moduleActiveSettings.find search, (err, docs) ->
			callback docs

	getModuleActiveData: (module, server, channel, callback) =>
		return if module is null

		@_getModuleActiveData { name: module.shortName, server: server, channel: channel }, callback

	enableAllModules: (server, channel) =>
		for moduleName,module of @modules
			@enableModule module,server,channel

	disableAllModules: (server, channel) =>
		for moduleName,module of @modules
			@disable module,server,channel

	enableModule: (module, server, channel) =>

		@moduleActiveSettings.update { name: module.shortName, server: server, channel: channel },
									{ $set: { isEnabled: true } },
									{ upsert: true }

		"Module #{color.bold module.shortName} is now #{color.bold 'enabled'} in #{channel}."

	disableModule: (module, server, channel) =>

		@moduleActiveSettings.update { name: module.shortName, server: server, channel: channel },
									{ $set: { isEnabled: false } },
									{ upsert: true }

		"Module #{color.bold module.shortName} is now #{color.bold 'disabled'} in #{channel}."

	handleMessage: (bot, from, to, message) =>

		matchRegex = /^(?:([^\s]+)[,:]\s+)?(.+)$/
		match = matchRegex.exec message
		return if not match?

		[full, targetNick, commandPart] = match
		return if targetNick? and targetNick isnt bot.getNick()
		# console.log "targetNick: #{targetNick}; commandPart: #{commandPart}
		
		serverName = bot.conn.opt.server
		isChannel = 0 is to.indexOf "#"

		for moduleName, module of @modules
			if not targetNick?
				# console.log "Has prefix '#{module.commandPrefix}'?", (_.str.startsWith commandPart, module.commandPrefix)
				continue if not _.str.startsWith commandPart, module.commandPrefix

				command = commandPart.substring module.commandPrefix.length

			else command = commandPart

			routeToMatch = module.router.match command.split('%').join('%25') # Router doesn't like %'s
			if routeToMatch?
				origin =
					bot: bot
					user: from
					channel: if to is bot.getNick() then undefined else to
					isPM: to is bot.getNick()

				#I have no idea what this is needed to make matching work...
				#sigh.
				routeVariable = routeToMatch

				@isModuleActive(module, serverName, to).then ->
					try
						routeVariable.fn origin, routeVariable
					catch e
						console.error "Your module is bad and you should feel bad:"
						console.error e.stack



	addListener: (event, listener) ->
		@on event, listener

	on: (event, listener) ->
		if event in BotEvents
			for bot in @botManager.bots
				do (bot) =>
					listenerWrapper = (args...) =>
						try
							listener bot, args...
						catch e
							console.error "Error in module bot listener"
							console.error e.stack
					bot.conn.on event, listenerWrapper
					@botListeners.push
						event: event
						listener: listener
						wrapper: listenerWrapper
						bot: bot

		else
			super(event, listener)

	once: (event, listener) ->
		if event in BotEvents
			self = @
			for bot in @botManager.bots
				do (bot) =>
					listenerWrapper = (args...) ->
						try
							for e, index in botListeners when e.listenerWrapper is listenerWrapper
								self.botListeners.splice index, 1
							listener bot, args...
						catch e
							console.error "Error in module bot listener"
							console.error e.stack
					bot.conn.once event, listenerWrapper
					@botListeners.push
						event: event
						listener: listener
						wrapper: listenerWrapper
						bot: bot
		else
			super(event, listener)

	removeListener: (event, listener) ->
		if event in BotEvents
			for index in [@botListeners.length - 1..0]
				e = @botListeners[index]
				if e.event is event and e.listener is listener
					e.bot.conn.removeListener(event, e.wrapper)
					@botListeners.splice index, 1
		else
			super(event, listener)

	removeAllListeners: (event) ->
		super(event)
		for listener in @botListeners[event]
			removeListener(event, listener)

	listeners: (event) ->
		listeners = super(event)
		if @botListeners[event]?
			for listener in @botListeners[event]
				listeners.push listener
		listeners

exports.ModuleManager = ModuleManager