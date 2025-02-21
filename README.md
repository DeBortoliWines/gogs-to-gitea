# gogs-to-gitea
A bash script to migrate gogs repositories to gitea via APIs. Note this does orgs and repos only, not users

This is not intended as a user-friendly tool - use at your own risk. I used it once for a migration in 2025, and am not planning on supporting further.

## How to:

1. Copy `env.ex` to `env` and add hostnames/usernames/api keys

2. Update any of the API options in the script that you may want to, eg 
```
        \"issues\": false, \ <- update to true if you want to migrate issues
```

3. Install dependencies:
 - `jq` - [homepage](https://github.com/jqlang/jq)
 - `curl` - [homepage](https://curl.se/)

4. Run it:
```
./migrate_gogs_repos_by_org.sh
```
