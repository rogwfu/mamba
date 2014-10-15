# mamba

Description goes here.

## Prerequisites

### Mac OS X (Homebrew)
```
brew install mongodb
```

```
brew install rabbitmq
```

### Ubuntu 14.04

```
wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key|sudo apt-key add -
```
```
apt-get install clang-3.4 clang-3.4-doc libclang-common-3.4-dev libclang-3.4-dev libclang1-3.4 libclang1-3.4-dbg libllvm-3.4-ocaml-dev libllvm3.4 libllvm3.4-dbg lldb-3.4 llvm-3.4 llvm-3.4-dev llvm-3.4-doc llvm-3.4-examples llvm-3.4-runtime clang-modernize-3.4 clang-format-3.4 lldb-3.4-dev
```

## Status
[![Build Status](https://travis-ci.org/rogwfu/mamba.png)](https://travis-ci.org/rogwfu/mamba)
[![Coverage Status](https://coveralls.io/repos/rogwfu/mamba/badge.png)](https://coveralls.io/r/rogwfu/mamba)
[![Dependency Status](https://www.versioneye.com/user/projects/543603aab2a9c5dd3d000092/badge.svg?style=flat)](https://www.versioneye.com/user/projects/543603aab2a9c5dd3d000092)

## Contributing to mamba
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Dependencies
* bundle install
* Install Erlang:
** Option 1: brew install erlang
** Option 2: wget -O erlang.tar.gz "http://www.erlang.org/download/otp_src_R16B01.tar.gz" ; tar xvzf erlang.tar.gz ; cd otp_src_R16B01 ; ./configure ; make ; sudo make install 
 
## Copyright

Copyright (c) 2011 Roger Seagle. See LICENSE.txt for
further details.

