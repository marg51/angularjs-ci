githubhook = require('githubhook')
request = require('https').request
spawn = require('child_process').spawn
config = require('./config').config

github = githubhook(logger:console)

github.listen()

repo = "wearemop/customer-service"
host_build = "http://integration.mopp.com/build/cs"

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
        tests = spawn('./post-update.sh',[ref.split('/').pop(),data.after.slice(0,10)])

        # when the tests are done
        tests.on 'close', (code) ->
          tests = undefined
          # everything went fine
          console.log code
          if code is 0
            update = updateStatus {status: 'success', sha: data.after}
          else
            update = updateStatus {status: 'failure', sha: data.after, message: "tests failed"}

          # throw the query
          update.end()

        tests.stdout.on 'data', (data) ->
            console.log 'stdout data',data.toString()
        tests.on 'error', ->
          console.log 'spawn.error', arguments

      res.on 'error', ->
        console.log 'res.error', arguments

  req.end()

github.on 'status', (repo, refs, data)->
  if data.state is "success" and ( data.branches[0].name is 'dev' or data.branches[0].name is 'master' )
    branch = data.branches[0].name
    req = addDeployment branch, (res) ->
      data = ''
      res.on 'data', (chunk) ->
        data+=chunk

      res.on 'end', ->
        data = JSON.parse(data)
        console.log 'status success on branch',data

        req2 = updateStatusDeployment {state: 'pending', id: data.id}, (res2) ->
          data2 = ''
          res2.on 'data', (chunk) ->
            data2+=chunk

          res2.on 'end', ->
            data2 = JSON.parse(data2)
            console.log "pending", data2

            deploy = spawn("./deployment.sh",[branch])
            deploy.stdout.on 'data', (c) -> console.log 'deployment', c.toString()
            deploy.on 'close', (code) ->
              console.log 'deploy code',code
              if code is 0
                req3 = updateStatusDeployment {state: 'success', id: data.id, message: 'App ready to use'}, (res2) ->
                  data2 = ''
                  res2.on 'data', (chunk) ->
                    data2+=chunk

                  res2.on 'end', ->
                    data2 = JSON.parse(data2)
                    console.log "deploy", data2
              else
                req3 = updateStatusDeployment {status: 'error', id: data.id, message: 'Cannot build or deploy'}, (res2) ->
              req3.end()
              

              
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
      "Accept": "application/vnd.github.cannonball-preview+json"
  , fn )

  req.write(JSON.stringify({  "state": params.status,  "target_url": host_build+"/"+params.sha.slice(0,10)+'.html',  "description": params.message || "no infos",  "context": "continuous-integration/angularjs-ci"}));
  
  req.on 'error', ->
    console.error 'err', arguments
  
  # don't forget to call req.end()
  return req


addDeployment = (ref, fn) ->
  console.log('addDeployment',ref)

  req = request(
    hostname:'api.github.com'
    method: 'POST'
    path: '/repos/'+repo+'/deployments'
    headers:
      Authorization: 'basic '+config.Authorization
      "User-Agent": "angularjs-ci"
      "Accept": "application/vnd.github.cannonball-preview+json"
  , fn )

  req.write(JSON.stringify({ ref:ref, auto_merge:false, environment:"staging", description: "Ready to deploy #{ref}", required_contexts:["continuous-integration/angularjs-ci"]} ) )
  
  req.on 'error', ->
    console.error 'err', arguments

updateStatusDeployment = (params, fn) ->
  console.log('updateStatusDeployment',params)

  req = request(
    hostname:'api.github.com'
    method: 'POST'
    path: '/repos/'+repo+'/deployments/'+params.id+'/statuses'
    headers:
      Authorization: 'basic '+config.Authorization
      "User-Agent": "angularjs-ci"
      "Accept": "application/vnd.github.cannonball-preview+json"
  , fn )

  req.write(JSON.stringify({  "state": params.state, "description": params.message || "no infos"}));
  
  req.on 'error', ->
    console.error 'err', arguments
  
  # don't forget to call req.end()
  return req
# test(null, "refs/heads/dev3",{after:"e5cdc91902e0399908d7fa4ff84ff1820da4ac24"})


