ost(1)
======

Just an experiment for running daemonized Ost workers.

Usage
-----

Assuming a simple worker:

    require "app"

    Ost[:stuff].each do |item|
      # process item
    end

Place the worker at `./workers/stuff.rb` and then:

    $ ost stuff

That should load the worker in the foreground.

You can daemonize the process by passing the `-d` flag:

    $ ost -d stuff

If you daemonize, a file containing the daemonized process ID is written
to `./workers/stuff.pid`.

Support
-------

For now, this experiment is only tested on MRI 1.9.2+.
