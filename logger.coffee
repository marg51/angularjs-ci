require('colors')
config = require('./config').config
hipchat = require('./hipchat')

getDate = ->
	x = new Date()
	"[#{x.getHours()}:#{x.getMinutes()}:#{x.getSeconds()}]".grey
	
getStatusStr = (status) ->
	if status is 'success'
		'S'.green 
	else if status is 'pending'
		'P'.red 
	else if status is 'error' or status is 'failure'
		'E'.magenta
	else
		(status+"").magenta

getStatus = (status) ->
	if status is 'success'
		true
	else if status is 'error' || status is 'failure'
		false
	else 
		null

exports.updateStatus = (params) ->
	status = getStatusStr(params.status)

	sha = params.obj.sha.slice(0,10)
	branch = params.obj.branch

	if getStatus(params.status) is false
		hipchat.notify("[Error:#{params.obj.repo}] <a href='https://github.com/#{params.obj.repo}/commit/#{params.obj.sha}'><b>#{branch}#</b>#{sha}</a> tests <a href='#{config.host_build}/#{params.obj.repo}/#{sha}.html'>failed</a>")


	console.log getDate(), status + "(#{branch}#".blue+(sha+"").cyan+")".blue, params.obj.repo.split('/').pop().grey

	if getStatus(params.status) is false
		console.log " *".magenta, "#{config.host_build}/#{params.obj.repo}/#{sha}.html".grey

exports.updateStatusDeployment = (params) ->
	status = getStatusStr(params.status)

	if getStatus(params.status) is false
		hipchat.notify("[Error:#{params.obj.repo}] <a href='https://github.com/#{params.obj.repo}/commit/#{params.obj.branch}'>#{params.obj.branch}</a> can't be deployed to <a href='#{config.deploy_build}/#{params.obj.repo}/#{params.obj.branch}.html'>#{params.obj.env}</a>")

	if getStatus(params.status) is true
		hipchat.notify("[Deploy:#{params.obj.repo}] <a href='https://github.com/#{params.obj.repo}/commit/#{params.obj.sha}'>#{params.obj.branch}</a> deployed to <a href='#{config.deploy_build}/#{params.obj.repo}/#{params.obj.branch}.html'>#{params.obj.env}</a>","green")

	console.log getDate(), status + "(#{params.obj.branch}#".blue + params.obj.sha.slice(0,10).cyan + ")".blue, "->".grey, (params.obj.env+"").underline,  params.obj.repo.split('/').pop().grey

	if getStatus(params.status) is false
		console.log " *".magenta, "#{config.deploy_build}/#{params.obj.repo}/#{sha}.html".grey

exports.error = (err,name) ->
	console.log "[error:#{name}] ".magenta,err

exports.listening = ->
	console.log " *".green,"Listen to","3420".green
	console.log getDate(),"test results ->",(config.host_build+"/*.html").cyan