request = require('https').request
spawn = require('child_process').spawn
config = require('./config').config
logger = require('./logger')


tests = undefined

exports.onPush = (op,ref,data) ->
	# test = (op,ref,data) ->

	# for now, we don't run multiple process
	if typeof tests is "undefined"
		updateStatus 
			status: 'error'
			sha: data.after
			message: 'can\'t run tests, already a process'
		return

	# we set the status as pending while we make tests
	req = updateStatus( 
		status: 'pending'
		sha: data.after
		message: 'Wait for the tests'
	, (res) ->
		_handleResponse res, (updateStatusData) ->
			# result of the query
			result = JSON.parse(updateStatusData.toString())

			# if there is an id, so the update is successful (I guess, actually)
			if result.id?
				# run anything, karma, whatever. The branch and the sha of the new commit is passed
				tests = spawn('./post-update.sh',[ref.split('/').pop(),data.after.slice(0,10)])

				# when the tests are done
				tests.on 'close', (code) ->
					tests = undefined

					# everything went fine
					if code is 0
						update = updateStatus {status: 'success', sha: data.after, obj: data}
					else
						update = updateStatus {status: 'failure', sha: data.after, obj: data, message: "tests failed"}

					# throw the query
					update.end()
	)

	req.end()


exports.onStatus = (repo, refs, data)->
	if data.state is "success" and ( data.branches[0].name is 'dev' or data.branches[0].name is 'master' )
		branch = data.branches[0].name
		current_env= 'staging'
		req = addDeployment {ref:branch, env: current_env}, (res) ->
			_handleResponse res, (data) ->
				data = JSON.parse(data)

				req2 = updateStatusDeployment {state: 'pending', id: data.id,ref: branch, env:current_env}, (res2) ->
					_handleResponse res2, (data2) ->
						data2 = JSON.parse(data2)

						deploy = spawn("./deployment.sh",[branch])
						deploy.on 'close', (code) ->
							if code is 0
								req3 = updateStatusDeployment {state: 'success', id: data.id, message: 'App ready to use',ref: branch, env:current_env}, (res2) ->
							else
								req3 = updateStatusDeployment {state: 'error', id: data.id, message: 'Cannot build or deploy',ref: branch, env:current_env}, (res2) ->
								
							req3.end()
				req2.end()

		req.end()


_handleResponse = (res, fn) ->
	data = ''
	res.on 'data', (chunk) ->
		data+=chunk

	res.on 'end', -> 
		fn(data)


_createGithubQuery = (path, method='GET') ->
  hostname:'api.github.com'
  method: method
  path: path
  headers:
    Authorization: 'basic '+config.Authorization
    "User-Agent": "angularjs-ci"
    "Accept": "application/vnd.github.cannonball-preview+json"

# Update the status (success|pending|error) of a commit
# params({sha,status,message})
updateStatus = (params, fn) ->
  logger.updateStatus(params)

  req = request( _createGithubQuery('/repos/'+config.repo+'/commits/'+params.sha+'/statuses','POST'), fn )

  req.write(JSON.stringify(
    "state":        params.status
    "target_url":   config.host_build+"/"+params.sha.slice(0,10)+'.html'
    "description":  params.message || "no infos"
    "context":      "continuous-integration/angularjs-ci"
  ));
  
  # don't forget to call req.end()
  return req


# Create an empty new deployment
# params({ref,env})
# @params ref: branch or sha to be deployed
# @params env: staging|prod|whatever
addDeployment = (params, fn) ->
  req = request( _createGithubQuery('/repos/'+config.repo+'/deployments','POST'), fn )

  req.write(JSON.stringify(
    "ref":              params.ref
    "auto_merge":       false
    "environment":      params.env
    "description":      "Ready to deploy #{params.ref}"
    "required_contexts":["continuous-integration/angularjs-ci"]
  ))

  # don't forget to call req.end()
  return req

# create a new status for a deployment
# params({state,message,id})
# @params id -> deployment id, from addDeployment()
updateStatusDeployment = (params, fn) ->
  logger.updateStatusDeployment(params)

  req = request( _createGithubQuery('/repos/'+config.repo+'/deployments/'+params.id+'/statuses', 'POST'), fn)

  req.write(JSON.stringify(
    "state":        params.state
    "description":  params.message || "no infos"
  ))
  
  # don't forget to call req.end()
  return req