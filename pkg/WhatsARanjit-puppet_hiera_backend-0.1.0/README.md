# puppet_hiera_backend

#### Table of Contents

1. [Overview](#overview)
1. [Requirements](#requirements)
1. [Configuration](#configuration)
1. [Usage](#usage)

## Overview

Use Puppet DSL to express Hieradata instead of JSON or YAML.

## Requirements

* Puppet >= 5.x.x

## Configuration

* `/etc/puppetlabs/puppet/hiera.yaml`
  ```yaml
  ---
  version: 5
  defaults:
    datadir: data
  hierarchy:
    - name: Experimental Puppet backend
      data_hash: puppet_data
      path: puppet.pp

  ```

* `/etc/puppetlabs/puppet/data/puppet.pp`

  ```puppet
  {
    'string' => 'foo',
    'array' => [
      'one',
      'two',
      'three',
    ],
    'hash' => {
      'a' => 1,
      'b' => 2,
      'c' => 3,
    }
  }
  ```

  __NOTE__: Hiera data file can only contain literals.  This prevents intrusive 
  Puppet code.  See documentation [here](https://github.com/puppetlabs/puppet/blob/master/lib/puppet/pops/evaluator/literal_evaluator.rb).

## Usage

```shell
[root@master ~]# puppet apply -e 'notice(hiera("string"))'
Notice: Scope(Class[main]): foo
Notice: Compiled catalog for master.puppetlabs.vm in environment production in 0.62 seconds
Notice: Applied catalog in 0.25 seconds
[root@master ~]# puppet apply -e 'notice(hiera("array"))'
Notice: Scope(Class[main]): [one, two, three]
Notice: Compiled catalog for master.puppetlabs.vm in environment production in 0.58 seconds
Notice: Applied catalog in 0.24 seconds
[root@master ~]# puppet apply -e 'notice(hiera("hash"))'
Notice: Scope(Class[main]): {a => 1, b => 2, c => 3}
Notice: Compiled catalog for master.puppetlabs.vm in environment production in 0.65 seconds
Notice: Applied catalog in 0.27 seconds
```
