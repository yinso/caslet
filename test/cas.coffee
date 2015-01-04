CAS = require '../src/cas'
loglet = require 'loglet'
fs = require 'fs'
path = require 'path'
funclet = require 'funclet'

cas = null
hash = null 
destPath = 'test/file.coffee'

readAll = (stream, cb) ->
  buffer = []
  stream.setEncoding 'utf8'
  stream.on 'error', cb
  stream.on 'data', (chunk) ->
    buffer.push chunk
  stream.on 'end', () ->
    cb null, buffer.join ''

assertContentEqual = (stream, filePath, cb) ->
  s1 = null
  s2 = null
  funclet
    .start (next) ->
      readAll stream, next
    .then (val, next) ->
      s1 = val
      fs.readFile filePath, 'utf8', next
    .catch(cb)
    .done (val) ->
      s2 = val
      if s1 == s2
        cb null
      else
        cb {error: 'content_not_equal'}

describe 'cas test', () ->
  
  it 'can intiailize', (done) ->
    CAS.initialize {}, (err, val) ->
      if err
        done err
      else
        cas = val
        loglet.log 'cas.config', cas.config
        done null
  
  it 'can store', (done) ->
    try 
      stream = fs.createReadStream __filename
      cas.storeWithPath stream, destPath, (err, val) ->
        if err 
          done err
        else
          hash = val
          done null
    catch e
      done e
  
  it 'can get via hash', (done) ->
    cas.get {hash: hash}, (err, stream) ->
      if err 
        done err
      else
        assertContentEqual stream, __filename, done
  
  it 'can get via path', (done) ->
    cas.get {path: destPath}, (err, stream) ->
      if err 
        done err
      else
        assertContentEqual stream, __filename, done
