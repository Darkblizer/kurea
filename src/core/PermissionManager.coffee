ModuleDatabase = require('./ModuleDatabase').ModuleDatabase
Q = require 'q'

class PermissionManager
	constructor: () ->
		@db = new ModuleDatabase "internal", "permissions"

	match: (origin, permissionString, callback) ->
		@getPermissions origin, (err, permissionSet) =>
			if err?
				callback err
				return

			console.log "Permission set is:", permissionSet
			callback null, @matchSet(permissionSet, permissionString)

	matchSet: (permissionSet, permissionToMatch) ->
		for permission in permissionSet
			if @matchPermissions(permission, permissionToMatch) then return true

		false

	matchPermissions: (permission, permissionToMatch) ->
		if permission is '*' or permissionToMatch is '*' then return true

		until permissionToMatch is null
			if permissionToMatch is permission then return true

			permissionToMatch = @getParent permissionToMatch

		false

	getParent: (permission) ->
		if (lastDot = permission.lastIndexOf '.') >= 0
			return permission.substring 0, lastDot

		null

	getPermissions: (origin, callback) ->
		origin.bot.userManager.getUsername origin, (err, username) =>
			if err? then callback err
			if not username? then callback new Error("No username was returned")

			else @db.find { username: username.toLowerCase() }, (err, docs) =>
				if err? then callback err
				else
					callback null, docs[0]?.permissions ? []

	addPermission: (targetString, permission, callback) =>
		# Assuming target is nothing but username ATM...
		target = @parseTarget targetString
		console.log target
		if not target.username?
			callback new Error("No username specified")
			return

		@db.update { username: target.username }, { $push: { permissions: permission } }, { upsert: true }, (err, replacedCount, upsert) =>
			if err? then callback err
			else callback null

	parseTarget: (targetString) =>
		target = {}

		regex = ///
			^
				([^.@].*?)?		# username
				(?:\.(.+?))?	# group
				(?:@(.+?))?		# server
			$
		///

		match = regex.exec targetString
		if match?
			console.log "Match fags", match
			[full, target.username, target.group, target.server] = match

		target

	dump: =>
		@db.find {}, (err, docs) =>
			if err? then console.error err.stack
			else
				for doc in docs
					console.log doc

exports.PermissionManager = PermissionManager
