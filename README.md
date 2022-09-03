# IntegrateD
Continuous integration and deployment written in D language.

Build: `dub run`

Usage: 
`integrated --github_name <username> --github_repo <reponame> --oauth_token <token> --ci_path "<path>" --ci_script "<script>"` 

You can kill an existing process at start-up by adding the optional command kill_list.
`integrated --github_name <username> --github_repo <reponame> --oauth_token <token> --ci_path "<path>" --ci_script "<script>" --kill_list "process_name"` 