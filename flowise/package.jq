  ( [ .[].name
    , "husky" ]
  | add )
  as $ignore
| ( [ .[].dependencies ]
  | add
  | with_entries(select(.key as $k | $ignore | index($k) == null)) )
  as $deps
| ( [ .[].devDependencies ]
  | add
  | with_entries(select(.key as $k | $ignore | index($k) == null)) )
  as $devDeps
| .[]
  # find root packages.json
| select(.workspaces | length > 0)
| .dependencies = $deps
| .devDependencies = $devDeps
  # remove husky, which needs .git
| .scripts.postinstall = null
| .scripts.build |= . + " --cache-dir .unused-turbo-cache --no-daemon --no-cache"
  # https://github.com/FlowiseAI/Flowise/issues/556
| .devDependencies.turbo = "1.10"
