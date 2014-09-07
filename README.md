# Awssh

Hacky way to handle ssh to AWS servers

- Searches for servers based on AWS tag Name.
- Provides the ability to use single ssh and multiple ssh access.
- Multiple can use cssh or csshX (configurable)

## Installation

Add this line to your application's Gemfile:

    gem 'awssh'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install awssh

## Usage

```
Usage: awssh [options] [search terms]

Search Terms:
  matches against AWS Tag "Name"
  positive check for each entry
    name =~ /term/
  negative check if the term starts with ^
    name !~ /term/ if term[0] == "^"

Options:
    -n, --test                       just output ssh command
    -v, --[no-]verbose               Run verbosely
    -V, --version                    print version
    -c, --config                     config file (default: ~/.awssh)
    -m, --[no-]multi                 connect to multiple servers
    -i, --init                       initialize config
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/awssh/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
