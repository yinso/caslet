loglet = require 'loglet'
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
uuid = require 'node-uuid'
funclet = require 'funclet'
filelet = require 'filelet'
_ = require 'underscore'

class FSCas
  @initialize: (options, cb) ->
    defaultOpts = 
      baseDir: path.join process.env.HOME, '.caslet'
    options = _.extend {}, defaultOpts, options
    cas = new @ options
    cas.initialize cb
  constructor: (@options) ->
    @pathsDir = path.join @options.baseDir, 'paths'
    @contentsDir = path.join @options.baseDir, 'contents'
    @tempDir = path.join @options.baseDir, 'temp' # for moving the files... 
  initialize: (cb) ->
    funclet
      .each [ @pathsDir, @contentsDir , @tempDir ], (dirPath, next) ->
        filelet.mkdirp dirPath, next
      .catch(cb)
      .done () => cb null, @
  get: (option, cb) ->
    if option.path
      @_getViaPath option.path, cb
    else if option.hash
      @_getViaHash option.hash, cb
    else
      cb {error: 'invalid_argument', args: [ option ]}
  _getViaPath: (pathsPath, cb) ->
    funclet
      .start (next) =>
        normalized = @_pathsFilePath pathsPath
        fs.readFile normalized, 'utf8', next
      .catch(cb)
      .done (data) =>
        parsed = JSON.parse data
        @_getViaHash parsed.hash, cb
  _getViaHash: (hash, cb) ->
    try 
      hashPath = @_hashFilePath hash
      stream = fs.createReadStream hashPath
      cb null, stream
    catch e
      cb e
  store: (instream, cb) ->
    try 
      tempFilePath = @_tempFilePath()
      digest = crypto.createHash 'sha1'
      digest.setEncoding 'hex'
      outstream = fs.createWriteStream tempFilePath
      instream.once 'close', () =>
        try 
          digest.end()
          outstream.end()
          hash = digest.read()
          instream.close()
          outstream.close()
          @_moveTempFile tempFilePath, hash, cb
        catch e
          cb e
      instream.once 'error', cb
      outstream.once 'error', cb
      digest.once 'error', cb
      instream.pipe digest
      instream.pipe outstream
    catch e
      instream.close()
      outstream.close()
      cb e
  storeWithPath: (instream, destPath, cb) ->
    hash = null
    funclet
      .start (next) =>
        @store instream, next
      .then (val, next) =>
        hash = val
        @_storePathMapping hash, destPath, next
      .catch(cb)
      .done () -> 
        cb null, hash
  _storePathMapping: (hash, destPath, cb) ->
    normalizedPath = @_pathsFilePath(destPath)
    result = 
      type: 'fs'
      hash: hash
    filelet.writeFile normalizedPath, JSON.stringify(result, null, 2), 'utf8', cb
  _moveTempFile: (tempFilePath, hash, cb) ->
    try 
      hashPath = @_hashFilePath hash
      filelet.move tempFilePath, hashPath, (err) ->
        if err 
          cb err
        else
          cb null, hash
    catch e
      cb e
  _tempFilePath: () ->
    path.join @tempDir, uuid.v4()
  _pathsFilePath: (filePath) ->
    path.join @pathsDir, filePath
  _hashFilePath: (hash) ->
    parentDir = hash.substring(0, 3)
    fileName = hash.substring(3)
    path.join @contentsDir, parentDir, fileName

module.exports = FSCas
