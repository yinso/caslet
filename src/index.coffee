loglet = require 'loglet'
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
uuid = require 'node-uuid'
funclet = require 'funclet'
filelet = require 'filelet'
FSCas = require './cas'

ensureMore = (args, count, usage) ->
  if args.length < count + 1
    loglet.croak usage

run = (argv) ->
  command = argv._[0]
  funclet
    .start (next) ->
      options = 
        baseDir: argv.baseDir or path.join(process.env.HOME, '.caslet')
      FSCas.initialize options, next
    .catch (err) ->
      loglet.croak err
    .done (cas) ->
      switch command
        when 'store'
          ensureMore argv._, 2, "caslet store <file_to_be_stored> <dest_path>"
          runStore2 cas, argv._[1], argv._[2]
        when 'pathget'
          ensureMore argv._, 1, "caslet pathget <dest_path>"
          runGet2 cas, argv._[1]
        when 'hashget'
          ensureMore argv._, 1, "caslet hashget <hash>"
          runhashGet2 cas, argv._[1]
        else
          loglet.croak {error: 'unknown_command', command: command, args: argv}

# cas.init {baseDir: baseDir}
# cas.store stream, destPath, ==> hash
# cas.hashGet hash ==> stream
# cas.get destPath ==> stream
runGet2 = (cas, filePath) ->
  funclet
    .start (next) ->
      cas.get {path: filePath}, next
    .catch (err) ->
      loglet.croak err
    .done (stream) ->
      stream.on 'close', () ->
        stream.close()
      stream.pipe process.stdout

runhashGet2 = (cas, filePath) ->
  funclet
    .start (next) ->
      cas.get {hash: filePath}, next
    .catch (err) ->
      loglet.croak err
    .done (stream) ->
      stream.on 'close', () ->
        stream.close()
      stream.pipe process.stdout

runStore2 = (cas, filePath, destPath) ->
  funclet
    .start (next) ->
      stream = fs.createReadStream filePath
      cas.storeWithPath stream, destPath, next
    .catch (err) ->
      loglet.croak err
    .done (hash) ->
      loglet.log hash

  
module.exports = 
  run: run
  CAS: FSCas

