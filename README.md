# CASlet - a Simple Content Addressable Storage System

`caslet` is a simple content storage system that allows you to store files uniquely (i.e. the same file will be stored only once).

## Install

    npm install -g caslet

## Usage

Command Line Usage

    # to store files into the storage system.
    $ caslet store /file/to/be/stored destination/file/path
    ==> a sha1 hash will be returned.
    
    # get the file by destination/file/path
    $ caslet get destination/file/path target/file/path
    
    # get the file by hash
    $ caslet gethash hash target/file/path

By default, `caslet` will hold its content at `$HOME/.caslet` directory. To change the particular directory, pass in `-b|--baseDir a/different/directory` as part of the command line call. 

    $ caslet -b ./assets store /file/to/be/stored destination/file/path
    $ caslet -b ./assets pathget destination/flie/path target/file/path
    $ caslet -b ./assets hashget hash target/file/path

# API

    var CAS = require('caslet');
    CAS.initialize({baseDir: './assets'}, function(err, cas) {
      cas.store(...);
      cas.storeWithPath(...);
      cas.get(...);
    });

## `CAS.initialize(options, function(err, cas) { ... })`

Create the CAS object with CAS initialize - this is where we pass in the initialization parameters. 

### Option 

The following are the values of the option object

- `baseDir`: the root directory of the CAS repo. Defaults to `$HOME/.caslet` if not passed in.

The returned `cas` object have the following functions:

## `cas.store(filePath, function(err, hash) { ... })`

This call stores the file located at `filePath` to `destPath`, and returns its sha1 hash through the callback. 

## `cas.storeWithPath(filePath, destPath, function(err, hash) { ... })`

This wraps around `cas.store` with an addition of `destPath` that can be also be used for retrieving the file.

## `cas.get(options, function (err, stream) { ... })`

Get the content as a stream.

Options is a JSON object with either `hash` (the hash returned) or `path` (the path supplied to `cas.storeWithPath`). 

