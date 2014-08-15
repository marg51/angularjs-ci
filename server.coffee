githubhook = require('githubhook')
ci = require('./github')
logger = require('./logger')
restify = require('restify')
http = require('http')
config = require('./config').config
hipchat = require('./hipchat')

# github = githubhook(logger:console)
github = githubhook()

github.listen()

# any push made to the repo
github.on 'push', ci.onPush
github.on 'status', ci.onStatus


server = restify.createServer
	name:'Hipchat '
	version: '0.0.1'

server.use restify.acceptParser(server.acceptable)
server.use restify.queryParser()
server.use restify.bodyParser()
		
server.get 'hipchat/message', (req, res, next) ->
	console.log req.params

server.listen 3421
logger.listening()




