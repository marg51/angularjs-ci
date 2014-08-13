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

	console.log " * status",(status+"").green+"(#".blue+(params.sha.slice(0,10)+"").cyan+")".blue


exports.updateStatusDeployment = (params) ->
	status = getStatusStr(params.status)

	console.log " * deploy","->".grey, (params.env+"").underline, status + "(#".blue + (params.ref+"").cyan + ")".blue


exports.listening = ->
	console.log " *".green,"Listen to","3420".green
	console.log " *".grey,"repo ->",config.repo.cyan
	console.log " *".grey,"test results ->",(config.host_build+"/*.html").cyan