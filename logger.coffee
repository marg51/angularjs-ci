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
	if status is 'success'
		true
	else if status is 'error'
		false
	else 
		null

exports.updateStatus = (params) ->
	status = getStatusStr(params.status)

	sha = params.obj.sha.slice(0,10)
	branch = params.obj.branch

	if getStatus(params.status) is false
		hipchat.notify("[Error] <a href='https://github.com/#{params.obj.repo}/commit/#{params.obj.sha}'><b>#{branch}#</b>#{sha}</a> tests <a href='#{config.host_build}/#{params.obj.repo}/#{sha}.html'>failed</a> (#{branch})")


	console.log " * status",(status+"").green+"(#{branch}#".blue+(sha+"").cyan+")".blue


exports.updateStatusDeployment = (params) ->
	status = getStatusStr(params.status)

	if getStatus(params.status) is false
		hipchat.notify("[Error] <a href='https://github.com/#{params.repo}/commit/#{params.branch}'>#{params.branch}</a> can't be deployed to <a href='#{config.deploy_build}/#{params.branch}.html'>#{params.env}</a>")

	if getStatus(params.status) is true
		hipchat.notify("[Deploy] <a href='https://github.com/#{params.repo}/commit/#{params.branch}'>#{params.branch}</a> deployed to <a href='#{config.deploy_build}/#{params.branch}.html'>#{params.env}</a>","green")

	console.log " * deploy","->".grey, (params.env+"").underline, status + "(#".blue + (params.branch+"").cyan + ")".blue

exports.error = (err) ->
	console.log "[error] ".magenta,err

exports.listening = ->
	console.log " *".green,"Listen to","3420".green
	console.log " *".grey,"test results ->",(config.host_build+"/*.html").cyan