require('colors')
config = require('./config').config

getStatusStr = (status) ->
	if status is 'success'
		'success'.green 
	else if status is 'pending'
		 'pending'.red 
	else 
		 (status+"").magenta

exports.updateStatus = (params) ->
	status = getStatusStr(params.status)

	sha = params.sha.slice(0,10)
	branch = if params.obj? then params.obj.ref.split('/').pop() else ""
	console.log " * status",(status+"").green+"(#{branch}#".blue+(shar+"").cyan+")".blue


exports.updateStatusDeployment = (params) ->
	status = getStatusStr(params.state)

	console.log " * deploy","->".grey, (params.env+"").underline, status + "(#".blue + (params.ref+"").cyan + ")".blue


exports.listening = ->
	console.log " *".green,"Listen to","3420".green
	console.log " *".grey,"repo ->",config.repo.cyan
	console.log " *".grey,"test results ->",(config.host_build+"/*.html").cyan