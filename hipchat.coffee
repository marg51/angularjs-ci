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

options = 
	ping: ->
		exports.notify("<b>#{req.params.item.message.from.name}</b>: pong","gray")
	say: (c,data) ->
		matches = data.matches(/say (.*) to (.*)/)
		if matches?
			exports.notify("<b>#{matches[2]}</b>: #{matches[1]}","gray")
		else 
			exports.notify("#{c.replace(/^say /,'')}","gray")


exports.onMessage = (req, res, next) ->
	console.log 'query'
	matches = parse(req.params.item.message.message)
	console.log 'matches',matches
	if matches and options[matches[1]]?
		options[matches[1]](matches[2],matches)
	else
		exports.notify("Hello <b>#{req.params.item.message.from.name}</b>","gray")

	res.send({status:"ok"})


parse = (message) ->
	matches = message.match(/!cibot ([a-z]+)(.*)/)

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


