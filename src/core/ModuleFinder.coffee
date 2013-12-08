fs = require 'fs'
path = require 'path'
_ = require 'underscore'
_.str = require 'underscore.string'
file = require 'file'
watch = require 'watch'

moduleFiles = {}
modules = {}

basePath = __dirname+'/../modules'

reloadFileModules = (file) ->
	fileModules = {}

	try
		moduleContainerObject = require file

		for k of moduleContainerObject
			fileModules[k] = new moduleContainerObject[k] if k.indexOf 'Module' isnt -1
	catch e
		console.log "There was a problem while loading #{file}"
		console.error e

	fileModules

loadFile = (file) ->
	file = path.resolve(file)

	moduleFiles[file] = reloadFileModules file
	for moduleName, module of moduleFiles[file]
		modules[moduleName] = module

	console.log "--- Loaded [#{(m.shortName for name, m of moduleFiles[file]).join(', ')}] from #{path.resolve(file)}"

removeFile = (file) ->
	file = path.resolve(file)

	console.log "--- Removing [#{(m.shortName for name, m of moduleFiles[file]).join(', ')}] from #{file}"

	delete require.cache[require.resolve file]
	for moduleName, module of moduleFiles[file]
		delete modules[moduleName]
	delete moduleFiles[file]

file.walkSync basePath, (start, dirs, files) ->
	for f in (files.map (f) -> start+path.sep+f)
		loadFile f

options =
	interval: 2000
	filter: (f, stat) ->
		not (stat.isDirectory() or path.extname(f) in [".coffee"])

watch.createMonitor basePath, options, (monitor) ->
	monitor.on 'created', _.debounce( (f, stat) ->
		# console.log f, "created"
		loadFile f
	, 100)

	monitor.on 'changed', _.debounce( (f, currstat, prevstat) ->
		# console.log f, "changed"
		removeFile f
		loadFile f
	, 100)

	monitor.on 'removed', _.debounce( (f, stat) ->
		# console.log f, "removed"
		removeFile f
	, 100)

exports.ModuleList = modules