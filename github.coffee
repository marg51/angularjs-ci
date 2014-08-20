request = require('https').request
spawn = require('child_process').spawn
config = require('./config').config
logger = require('./logger')
_ = require('lodash')

exports.normalizeData = (type, data) ->
	if type is "status"
		sha: data.sha
		repo: data.name
		status: data.state
		branches: _.pluck(data.branches,'name')
		branch: _.pluck(data.branches,'name').join(', ')
	else if type is "push"
		sha: data.after
		repo: data.repository.full_name
		branch: data.ref.split('/').pop() # refs/heads/dev
		parent: data.before
	else if type is "deploy" 
		id: data.id
		sha: data.deployment.sha
		branch: data.deployment.ref
		env: data.deployment.environment
		repo: data.repository.full_name
		status: data.state



exports.onPush = (op,ref,data) ->
	# test = (op,ref,data) ->

	# branch deleted
	return if data.after is "0000000000000000000000000000000000000000"

	pushData = normalizeData('push',data)

	# we set the status as pending while we make tests
	req = updateStatus( 
		status: 'pending'
		obj: pushData
		message: 'Running tests'
	, (res) ->
		_handleResponse res, (updateStatusData) ->
			# result of the query
			result = JSON.parse(updateStatusData.toString())

			# if there is an id, so the update is successful (I guess, actually)
			if result.id?
				# run anything, karma, whatever. The branch and the sha of the new commit is passed
				tests = spawn("#{config.path}/#{dataPush.repo}/scripts/post-update.sh",[pushData.branch,pushData.sha.slice(0,10), pushData.parent])

				# when the script is done
				tests.on 'close', (code) ->
					# everything went fine
					if code is 0
						update = updateStatus {status: 'success', obj: pushData}
					else
						update = updateStatus {status: 'failure', obj: pushData, message: "tests failed"}

					# throw the query
					update.end()
	)

	req.end()


exports.onStatus = (repo, refs, data)->

	dataStatus = normalizeData('status',data)

	if data.state is "success" and ( dataStatus.branches.indexOf('staging') > -1 or dataStatus.branches.indexOf('master') > -1)
		req = addDeployment dataStatus, (res) ->
			_handleResponse res, (data) ->
				data = JSON.parse(data)

				req2 = updateStatusDeployment {status: 'pending', id: data.id, ref: branch, env:current_env}, (res2) ->
					_handleResponse res2, exports.onDeploy
				req2.end()

		req.end()


exports.onDeploy = (data) ->
	data = JSON.parse(data)
	dataDeploy = normalizeData('deploy', data)

	deploy = spawn("./scripts/deployment.sh",[dataDeploy.branch])
	deploy.on 'close', (code) ->
		if code is 0
			req = updateStatusDeployment {status: 'success', id: dataDeploy.id, message: 'App ready to use',ref: dataDeploy.branch, env:dataDeploy.en}, (res) ->
			spawn("#{config.path}/#{dataPush.repo}/scripts/post-deployment.sh",[dataDeploy.branch,dataDeploy.sha])
		else
			req = updateStatusDeployment {status: 'error', id: dataDeploy.id, message: 'Cannot build or deploy',ref: dataDeploy.branch, env:dataDeploy.env}, (res) ->
			
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

  req = request( _createGithubQuery("/repos/#{params.repo}/commits/#{params.sha}/statuses",'POST'), fn )

  req.write(JSON.stringify(
    "state":        params.status
    "target_url":   "#{config.host_build}/#{params.repo}/#{params.sha.slice(0,10)}.html"
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
  req = request( _createGithubQuery("/repos/#{params.repo}/deployments",'POST'), fn )

  req.write(JSON.stringify(
    "ref":              params.branch
    "auto_merge":       false
    "environment":      params.env
    "description":      "Ready to deploy #{params.branch}"
    "required_contexts":["continuous-integration/angularjs-ci"]
  ))

  # don't forget to call req.end()
  return req

# create a new status for a deployment
# params({state,message,id})
# @params id -> deployment id, from addDeployment()
updateStatusDeployment = (params, fn) ->
  logger.updateStatusDeployment(params)

  req = request( _createGithubQuery("/repos/#{params.repo}/deployments/#{params.id}/statuses", 'POST'), fn)

  req.write(JSON.stringify(
    "state":        params.status
    "description":  params.message || "no infos"
  ))
  
  # don't forget to call req.end()
  return req