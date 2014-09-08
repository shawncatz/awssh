# Awssh

Hacky way to handle ssh to AWS servers

- Searches for servers based on AWS tag Name.
- Provides the ability to use single ssh and multiple ssh access.
- Use cssh or csshX (configurable) for mulit-server access
- caches list of servers, to minimize calls to AWS (primarily for speed).

## Installation

Generally, you will install this directly:

    $ gem install awssh

or, add this line to your application's Gemfile:

    gem 'awssh'

And then execute:

    $ bundle

## Requirement

The only requirement of the tool is that the Name tag on the instance maps to the DNS record.
Generally, `awssh` expects that if the name of the instance is `foo.bar`, then it can
connect to the server by appending the domain name as `foo.bar.example.com`.

If you unset the domain name in the config, it will not append it. As such, if your Name
tag maps directly to the DNS name, it will work as well.

In the future, I might add a templated way for handling hostnames, to allow for
more customization in DNS lookup.

## Usage

```
Usage: awssh [options] [search terms]

Search Terms:
  matches against AWS Tag "Name"
  positive check for each entry
    name =~ /term/
  negative check if the term starts with ^
    name !~ /term/

Options:
    -V, --version                    print version
    -i, --init                       initialize config

    -l, --list                       just list servers
    -n, --test                       just output ssh command
    -v, --[no-]verbose               Run verbosely

    -U, --update                     just update the cache
        --no-cache                   disable cache for this run

    -m, --[no-]multi                 connect to multiple servers
    -c, --config                     override config file (default: ~/.awssh)
    -u, --user                       override user setting

```
## Examples
Given a list of servers:
```
web1.staging
app1.staging
web1.production
web2.production
app1.production
app2.production
app3.production
```

Connect to web1.staging
```
awssh web1 staging #=> web1.staging
```

Connect to all staging servers
```
awssh -m staging #=> web1.staging, app1.staging
```

Connect to all production servers, except app3.
The hat `^` negates a match.
```
awssh -m production ^app3 #=> web1.production, web2.production, app1.production, app2.production
```

## Config
```
---
multi: csshX                   # multi ssh program: csshX or cssh
single: ssh                    # ssh program, allows for common configs
region: us-east-1              # ec2 region
user:                          # username to ssh as
key: AWS ACCESS KEY ID         # AWS key
secret: AWS SECRET ACCESS KEY  # AWS secret
domain: example.com            # append domain to server names
cache: "~/.awssh.cache"        # cache file location
expires: 86400                 # cache expiration time (in seconds)
```

## Multi SSH

`csshX` is available on Mac OSX through brew.

`cssh` is available on linux, through apt or yum.

If there are other programs like this, please let me know.

Eventually, I'd like to support the programs with templated commands, to allow
for more advanced usage.

## Caching

Maintains a simple cache with expiration (default: 1 day).
The cache just contains the list of servers' names.
You can disable the cache by setting the cache value to false in the config file.

## Shell Alias

To get around using multiple RVM's and still have access to awssh command

`alias awssh='rvm <rvm version> do awssh'`

When you install awssh into your default ruby, then change to a project ruby,
the awssh gem is no longer available. This allows you to use the awssh gem
from ruby. Just specify the default rvm version in <rvm verison> above.

`alias awssh='rvm 2.1.2 do awssh'`

## Contributing

1. Fork it ( https://github.com/[my-github-username]/awssh/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
