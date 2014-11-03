# mamba

Description goes here.

## Status
[![Build Status](https://travis-ci.org/rogwfu/mamba.png)](https://travis-ci.org/rogwfu/mamba)
[![Coverage Status](https://coveralls.io/repos/rogwfu/mamba/badge.png)](https://coveralls.io/r/rogwfu/mamba)
[![Dependency Status](https://www.versioneye.com/user/projects/543603aab2a9c5dd3d000092/badge.svg?style=flat)](https://www.versioneye.com/user/projects/543603aab2a9c5dd3d000092)

## Prerequisites

### Mac OS X (Homebrew)
```
brew install mongodb
```

```
brew install rabbitmq
```

### Ubuntu 14.04

* Install llvm archive signature
```
wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key|sudo apt-key add -
```
* Install llvm package repositories 
```
echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty main" > /etc/apt/sources.list.d/llvm.list
echo "deb-src http://llvm.org/apt/trusty/ llvm-toolchain-trusty main" >> /etc/apt/sources.list.d/llvm.list
echo "# 3.4" >> /etc/apt/sources.list.d/llvm.list
echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" >> /etc/apt/sources.list.d/llvm.list
echo "deb-src http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" >> /etc/apt/sources.list.d/llvm.list
echo "# 3.5" >> /etc/apt/sources.list.d/llvm.list
echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.5 main" >> /etc/apt/sources.list.d/llvm.list
echo "deb-src http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.5 main" >> /etc/apt/sources.list.d/llvm.list
sudo apt-get update
```

* Install llvm 3.4
```
sudo apt-get -y install clang-3.4 clang-3.4-doc libclang-common-3.4-dev libclang-3.4-dev libclang1-3.4 libclang1-3.4-dbg libllvm-3.4-ocaml-dev libllvm3.4 libllvm3.4-dbg lldb-3.4 llvm-3.4 llvm-3.4-dev llvm-3.4-doc llvm-3.4-examples llvm-3.4-runtime clang-modernize-3.4 clang-format-3.4 lldb-3.4-dev
```

* Fix python lldb
```
sudo ln -sf /usr/lib/llvm-3.4/lib/liblldb.so.1  /usr/lib/python2.7/dist-packages/lldb/_lldb.so
```

* Install python dependencies
```
sudo apt-get -y install python-pip
sudo apt-get -y install python-dev
sudo apt-get -y install libevent-dev
sudo apt-get -y install libxml2-dev libxslt-dev python-dev
sudo pip install uwsgi
sudo pip install numpy
sudo pip install lxml
```

# Notes
export PATH="$PATH:$HOME/.mamba"


## Contributing to mamba
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Dependencies

### Ubuntu
* Install lldb
```bash
wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | apt-key add -
echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" >> /etc/apt/llvm.list
echo "deb-src http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" >> /etc/apt/llvm.list
apt-get update
apt-get -y install clang-3.4 clang-3.4-doc libclang-common-3.4-dev libclang-3.4-dev libclang1-3.4 libclang1-3.4-dbg libllvm-3.4-ocaml-dev libllvm3.4 libllvm3.4-dbg lldb-3.4 llvm-3.4 llvm-3.4-dev llvm-3.4-doc llvm-3.4-examples llvm-3.4-runtime clang-modernize-3.4 clang-format-3.4 python-clang-3.4 lldb-3.4-dev
ln -s /usr/bin/lldb-3.4 /usr/local/bin/lldb
```

* Install mongodb
```bash
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
apt-get update
apt-get install -y mongodb-org
```

* Install rabbitmq
```bash
wget -O - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add -
echo 'deb http://www.rabbitmq.com/debian/ testing main' | tee /etc/apt/sources.list.d/rabbitmq.list
apt-get update
apt-get install -y rabbitmq-server
service rabbitmq-server stop
```
### Mac OS X
* bundle install
* Install Erlang:
** Option 1: brew install erlang
** Option 2: wget -O erlang.tar.gz "http://www.erlang.org/download/otp_src_R16B01.tar.gz" ; tar xvzf erlang.tar.gz ; cd otp_src_R16B01 ; ./configure ; make ; sudo make install 

*
## Copyright

Copyright (c) 2011 Roger Seagle. See LICENSE.txt for
further details.

