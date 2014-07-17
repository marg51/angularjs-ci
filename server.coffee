githubhook = require('githubhook')
request = require('https').request
spawn = require('child_process').spawn
config = require('config')

github = githubhook(logger:console)

github.listen()

repo = "marg51/git"
host_build = "http://git.uto.io"


# any push made to the repo
github.on 'push', (op,ref,data) ->
  # we set the status as pending while we make tests

  req = updateStatus 'pending', data.after, (res) ->
    updateStatusData = ""

    res.on 'data', (chunk) ->
      updateStatusData += chunk
      
    res.on 'end', ->
      # result of the query
      result = JSON.parse(updateStatusData.toString())
      
      # if there is an id, so the update is successful (I guess, actually)
      if result.id?
        # run anything, karma, whatever. The branch and the sha of the new commit is passed
        tests = spawn('post-update.sh',[ref.split('/').pop(),data.after])

        # when the tests are done
        tests.on 'close', (code) ->
          # everything went fine
          if code is 0
            update = updateStatus 'success', data.after
          else
            update = updateStatus 'failure', data.after

          # throw the query
          update.end()

        tests.on 'error', ->
          console.log 'spawn.error', arguments

      res.on 'error', ->
        console.log 'res.error', arguments

  req.end()


console.log('go')

updateStatus = (status, sha, fn) ->
  console.log('update',sha,status)

  req = request(
    hostname:'api.github.com'
    method: 'POST'
    path: '/repos/'+repo+'/commits/'+sha+'/statuses'
    headers:
      Authorization: 'basic '+config.Authorization
      "User-Agent": "angularjs-ci"
  , fn )

  req.write(JSON.stringify({  "state": status,  "target_url": build_host+"/build/"+sha+'.html',  "description": "no infos right now",  "context": "continuous-integration/mopp"}));
  
  req.on 'error', ->
    console.error 'err', arguments
  
  # don't forget to call req.end()
  return req


