# scripts

### post-update.sh

> called after a push

- args: `(branch, sha, old_sha)`
- branch: -> branch pushed
- sha: -> last commit of the push
- old_sha: -> sha of the branch before push

### deploy.sh

- args: `(branch, env)`
- branch: branch pushed (usually staging or master)
- env: environment to deploy to (stage or production, based on branch name)

### post-deploy.sh

- args: `(branch, sha)`
- branch: branch deployed
- sha: sha deployed

# install

```bash
npm install

cp config.coffee.sample config.coffee

# edit config.coffee

coffee server.coffee
```

