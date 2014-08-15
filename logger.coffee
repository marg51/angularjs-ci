require('colors')
config = require('./config').config
hipchat = require('./hipchat')

getStatusStr = (status) ->
	if status is 'success'
		'success'.green 
	else if status is 'pending'
		 'pending'.red 
	else 
		 (status+"").magenta

getStatus = (status) ->
	return false
	if status is 'success'
		true
	else if status is 'error'
		false
	else 
		null

exports.updateStatus = (params) ->
	status = getStatusStr(params.status)

	sha = params.sha.slice(0,10)
	branch = params.branch.split('/').pop()

	if getStatus(params.status) is false
		hipchat.notify("[Error] <a href='https://github.com/#{config.repo}/commit/#{params.sha}>#{branch}##{sha}</a> tests <a href='#{config.host_build}/#{sha}.html>failed</a>")


	console.log " * status",(status+"").green+"(#{branch}#".blue+(sha+"").cyan+")".blue


exports.updateStatusDeployment = (params) ->
	status = getStatusStr(params.state)

	if getStatus(params.status) is false
		hipchat.notify("[Error] <a href='https://github.com/#{config.repo}/commit/#{params.ref}>#{params.ref}</a> can't be deployed to <a href='#{config.deploy_build}/#{params.ref}.html>#{params.env}</a>")


	console.log " * deploy","->".grey, (params.env+"").underline, status + "(#".blue + (params.ref+"").cyan + ")".blue


exports.listening = ->
	console.log " *".green,"Listen to","3420".green
	console.log " *".grey,"repo ->",config.repo.cyan
	console.log " *".grey,"test results ->",(config.host_build+"/*.html").cyan