githubhook = require('githubhook')
request = require('https').request
spawn = require('child_process').spawn
config = require('./config').config

github = githubhook(logger:console)

github.listen()

repo = "marg51/git"
host_build = "http://git.uto.io"

tests = undefined

# any push made to the repo
github.on 'push', (op,ref,data) ->
# test = (op,ref,data) ->

  # for now, we don't run multiple process
  if tests?
    updateStatus {status: 'error', sha: data.after, message: 'can\'t run tests, already a process'}
    return

  # we set the status as pending while we make tests
  req = updateStatus {status: 'pending', sha: data.after, message: 'Wait for the tests'}, (res) ->
    updateStatusData = ""

    res.on 'data', (chunk) ->
      updateStatusData += chunk
      
    res.on 'end', ->
      # result of the query
      result = JSON.parse(updateStatusData.toString())
      
      # if there is an id, so the update is successful (I guess, actually)
      if result.id?
        # run anything, karma, whatever. The branch and the sha of the new commit is passed
        tests = spawn('./post-update.sh',[ref.split('/').pop(),data.after])

        # when the tests are done
        tests.on 'close', (code) ->
          tests = undefined
          # everything went fine
          if code is 0
            update = updateStatus {status: 'success', sha: data.after}
          else
            update = updateStatus {status: 'failure', sha: data.after, message: "tests failed"}

          # throw the query
          update.end()

        tests.on 'error', ->
          console.log 'spawn.error', arguments

      res.on 'error', ->
        console.log 'res.error', arguments

  req.end()

github.on 'status', (repo, refs, data)->
  if data.status is "success" and data.branches[0].name is 'dev'
    req = addDeployment 'dev', (res) ->
      res.on 'end', (data) ->
        data = JSON.parse(data)
        req2 = updateStatusDeployment {status: 'pending', id: data.id}
        setTimeout( ->
          updateStatusDeployment {status: 'success', id: data.id, message: 'App ready to use'}
        , 1000)
        req2.end()
    req.end()




updateStatus = (params, fn) ->
  # console.log('update',params)

  req = request(
    hostname:'api.github.com'
    method: 'POST'
    path: '/repos/'+repo+'/commits/'+params.sha+'/statuses'
    headers:
      Authorization: 'basic '+config.Authorization
      "User-Agent": "angularjs-ci"
  , fn )

  req.write(JSON.stringify({  "state": params.status,  "target_url": host_build+"/build/"+params.sha+'.html',  "description": params.message || "no infos",  "context": "continuous-integration/angularjs-ci"}));
  
  req.on 'error', ->
    console.error 'err', arguments
  
  # don't forget to call req.end()
  return req


addDeployment = (ref, fn) ->
  # console.log('update',params)

  req = request(
    hostname:'api.github.com'
    method: 'POST'
    path: '/repos/'+repo+'/deployments'
    headers:
      Authorization: 'basic '+config.Authorization
      "User-Agent": "angularjs-ci"
  , fn )

  req.write(JSON.stringify({ ref:ref, auto_merge:false, environment:"staging", description: "Ready to deploy #{ref}", required_contexts:["continuous-integration/angularjs-ci"]} ) )
  
  req.on 'error', ->
    console.error 'err', arguments

updateStatusDeployment = (params, fn) ->
  # console.log('update',params)

  req = request(
    hostname:'api.github.com'
    method: 'POST'
    path: '/repos/'+repo+'/deployments/'+params.id+'/statuses'
    headers:
      Authorization: 'basic '+config.Authorization
      "User-Agent": "angularjs-ci"
  , fn )

  req.write(JSON.stringify({  "state": params.status, "description": params.message || "no infos"}));
  
  req.on 'error', ->
    console.error 'err', arguments
  
  # don't forget to call req.end()
  return req
# test(null, "refs/heads/dev3",{after:"e5cdc91902e0399908d7fa4ff84ff1820da4ac24"})


