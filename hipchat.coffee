config = require('./config').config
HC = new require('hipchatter')
hipchat = new HC(config.hipchat.token)
exec = require('child_process').exec
parser = require('./parser').parser


notify = (message, color='red') ->
	hipchat.notify(config.hipchat.room_id, {
			message: message
			token: config.hipchat.token
			color: color
			notify: true
	},(err) -> console.log err if err)

exports.notify = notify

options =
	to: (to) ->
		options
	ping: ->
			notify("<b>#{scope.from.name}</b>: pong","gray")
	
	say: (what,to) ->
		if to
			what = "<b>#{to}</b>: "+what
		notify(what+"", "gray")
	getSha: (env) ->
		if !env.match(/^[a-z]+$/i)
			console.log env, "invalid format"
		exec "cd #{config.repo_path} && git symbolic-ref #{env.toUpperCase()}", (err, data) ->
			if err
				console.log err
			else
				console.log data
				notify("Last deployed commit on <b>#{env}</b>: <a href='https://github.com/#{config.repo}/commit/#{data.toString()}'>#{data.toString()}</a>","gray")

	load: (c) ->
		exec "uptime", (err, data) ->
			if err
				console.log err
			else
				console.log data
				notify("#{data.toString()}","gray")

	help: ->
		notify(Object.keys(options).join('<br />'),"gray")

scope = {}

exports.onMessage = (req, res, next) ->
	console.log 'query'
	scope.from = req.params.item.message.from
	parser(req.params.item.message.message.replace(/^!cibot /,''))(scope,options)


# hipchat.webhooks config.hipchat.room_id, (err, hooks) ->
# 	console.log arguments
# 	if err
# 		console.log err
# 	return if !hooks.items
# 	for el in hooks.items
# 		hipchat.delete_webhook(config.hipchat.room_id,el.id, -> createWebhook()) if el.name is "cibot"

# createWebhook = ->
# 	hipchat.create_webhook config.hipchat.room_id,{
# 		url: config.hipchat.webhook
# 		pattern: '^!cibot'
# 		event: "room_message"
# 		name: 'cibot'
# 		token: config.hipchat.token
# 	}, (err) ->
# 		if err
# 			console.log err

# 	createWebhook = ->


