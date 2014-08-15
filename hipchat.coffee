config = require('./config').config
HC = new require('hipchatter')
hipchat = new HC(config.hipchat.token)


exports.notify = (message, color='red') ->
	if color is "red"
		notify = true
	else 
		notify = false

	hipchat.notify(config.hipchat.room_id, {
		message: message
		token: config.hipchat.token
		color: color
		notify: true
	},(err) -> console.log err if err)


hipchat.webhooks config.hipchat.room_id, (err, hooks) ->
	console.log arguments
	if err
		console.log err
	return if !hooks.items
	for el in hooks.items
		hipchat.delete_webhook(config.hipchat.room_id,el.id, -> createWebhook()) if el.name is "cibot"

createWebhook = ->
	hipchat.create_webhook config.hipchat.room_id,{
		url: config.hipchat.webhook
		pattern: '^!cibot'
		event: "room_message"
		name: 'cibot'
		token: config.hipchat.token
	}, (err) ->
		if err
			console.log err

createWebhook = ->


