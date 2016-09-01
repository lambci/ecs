var fs = require('fs')

var dockerfile = process.argv[2] || 'Dockerfile.test'
var envCopy = Object.assign({}, process.env)

var dockerfileLines
try {
  dockerfileLines = fs.readFileSync(dockerfile, 'utf8').split(/\r?\n/g)
} catch (e) {
  dockerfileLines = []
}

// Remove all variables from process.env that exist in the given Dockerfile
var inEnv = false
dockerfileLines.forEach(function(line) {
  if (!inEnv && !/^ENV\s/.test(line)) {
    inEnv = false
    return
  }
  var pieces = line.trim().split(/\s+/g)
  if (!inEnv) {
    pieces = pieces.slice(1)
  }
  if (pieces[pieces.length - 1] == '\\') {
    inEnv = true
    pieces.pop()
  } else {
    inEnv = false
  }
  if (pieces.length == 2 && !~pieces[0].indexOf('=')) {
    pieces = [pieces.join('=')]
  }
  pieces.forEach(piece => delete envCopy[piece.split('=')[0]])
})

// Also remove variables that don't make sense to pass
delete envCopy.HOME
delete envCopy.HOSTNAME
delete envCopy.PWD
delete envCopy.TERM
delete envCopy.SHELL
delete envCopy.SHLVL
delete envCopy._

console.log(Object.keys(envCopy).join('\n'))
