config = require('./config').config
HC = new require('hipchatter')
hipchat = new HC(config.hipchat.token)
exec = require('child_node').exec


notify = (message, color='red') ->
	hipchat.notify(config.hipchat.room_id, {
			message: message
			token: config.hipchat.token
			color: color
			notify: true
	},(err) -> console.log err if err)

exports.notify = notify

options =
	ping: (a,b,message) ->
			notify("<b>#{message.from.name}</b>: pong","gray")
	say: (c,data) ->
			say = data[0].match(/say (.*) to (.*)/)
			console.log say
			if say?
					notify("<b>#{say[2]}</b>: #{say[1]}","gray")
			else
					notify(c.replace(/^say /,''),"gray")
	sha: (c) ->
		if !c.match(/^[a-z]+$/i)
			console.log c, "invalid format"
			return
		exec "cd #{config.repo_path} && git symbolic-ref #{c.toUpperCase()}", (err, data) ->
			if err
				console.log err
			else
				console.log data
				notify("Last deployed commit on <b>#{c}</b>: #{data.toString()}","gray")


exports.onMessage = (req, res, next) ->
	console.log 'query'
	matches = parse(req.params.item.message.message)
	if matches and matches[1]? and options[matches[1]]?
			options[matches[1]](matches[2],matches,req.params.item.message)
	else
			notify("Hello <b>#{req.params.item.message.from.name}</b>","gray")

	res.send({status:"ok"})


parse = (message) ->
		matches = message.match(/!cibot ([a-z]+) ?(.*)/)

		return matches


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


