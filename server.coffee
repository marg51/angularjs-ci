githubhook = require('githubhook')
request = require('https').request
spawn = require('child_process').spawn
config = require('./config').config
colors = require('colors')

# github = githubhook(logger:console)
github = githubhook()

github.listen()

hasDebug = false
debug = -> if hasDebug then console.log.apply(console.log,arguments)

repo = config.repo
host_build = config.host_build

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
          if code is 0
            update = updateStatus {status: 'success', sha: data.after}
          else
            update = updateStatus {status: 'failure', sha: data.after, message: "tests failed"}

          # throw the query
          update.end()

        tests.stdout.on 'data', (data) ->
            debug 'stdout data',data.toString()
        tests.on 'error', ->
          debug 'spawn.error', arguments

      res.on 'error', ->
        debug 'res.error', arguments

  req.end()

github.on 'status', (repo, refs, data)->
  if data.state is "success" and ( data.branches[0].name is 'dev' or data.branches[0].name is 'master' )
    branch = data.branches[0].name
    current_env= 'staging'
    req = addDeployment {ref:branch, env: current_env}, (res) ->
      data = ''
      res.on 'data', (chunk) ->
        data+=chunk

      res.on 'end', ->
        data = JSON.parse(data)
        debug 'status success on branch',data

        req2 = updateStatusDeployment {state: 'pending', id: data.id,ref: branch, env:current_env}, (res2) ->
          data2 = ''
          res2.on 'data', (chunk) ->
            data2+=chunk

          res2.on 'end', ->
            data2 = JSON.parse(data2)
            debug "pending", data2

            deploy = spawn("./deployment.sh",[branch])
            deploy.stdout.on 'data', (c) -> debug 'deployment', c.toString()
            deploy.on 'close', (code) ->
              debug 'deploy code',code
              if code is 0
                req3 = updateStatusDeployment {state: 'success', id: data.id, message: 'App ready to use',ref: branch, env:current_env}, (res2) ->
                  data2 = ''
                  res2.on 'data', (chunk) ->
                    data2+=chunk

                  res2.on 'end', ->
                    data2 = JSON.parse(data2)
                    debug "deploy", data2
              else
                req3 = updateStatusDeployment {state: 'error', id: data.id, message: 'Cannot build or deploy',ref: branch, env:current_env}, (res2) ->
              req3.end()
              

              
        req2.end()
    req.end()




updateStatus = (params, fn) ->
  status = if params.status is 'success' then 'success'.green else if params.status is 'pending' then 'pending'.red else 'error'.magenta
  console.log " * status",(status+"").green+"(#".blue+(params.sha.slice(0,7)+"").cyan+")".blue

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
    debug 'err', arguments
  
  # don't forget to call req.end()
  return req


addDeployment = (params, fn) ->
  req = request(
    hostname:'api.github.com'
    method: 'POST'
    path: '/repos/'+repo+'/deployments'
    headers:
      Authorization: 'basic '+config.Authorization
      "User-Agent": "angularjs-ci"
      "Accept": "application/vnd.github.cannonball-preview+json"
  , fn )

  req.write(JSON.stringify({ ref:params.ref, auto_merge:false, environment:params.env, description: "Ready to deploy #{params.ref}", required_contexts:["continuous-integration/angularjs-ci"]} ) )
  
  req.on 'error', ->
    debug 'err', arguments

updateStatusDeployment = (params, fn) ->
  status = if params.state is 'success' then 'success'.green else if params.state is 'pending' then 'pending'.red else (params.state+"").magenta
  console.log " * deploy","->".grey,(params.env+"").underline,status+"(#".blue+(params.ref+"").cyan+")".blue

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
    debug 'err', arguments
  
  # don't forget to call req.end()
  return req
# test(null, "refs/heads/dev3",{after:"e5cdc91902e0399908d7fa4ff84ff1820da4ac24"})


console.log " *".green,"Listen to","3420".green
console.log " *".grey,"repo ->",repo.cyan
console.log " *".grey,"test results ->",(host_build+"/*.html").cyan

