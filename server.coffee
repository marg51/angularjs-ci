githubhook = require('githubhook')
ci = require('./github')
logger = require('./logger')

# github = githubhook(logger:console)
github = githubhook()

github.listen()

# any push made to the repo
github.on 'push', ci.onPush

github.on 'status', ci.onStatus

logger.listening()

