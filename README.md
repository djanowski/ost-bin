ost(1)
======

Lets you define and run [Ost][ost] workers.


Usage
-----

Assuming a simple worker:

    class Mailer
      def call(item)
        puts "Emailing #{item}..."

        # Actually do it.
      end
    end

Declare it in a file named `Ostfile` at the root of your project:

    require "app"

    Ost.run(Mailer)

From the command line:

    $ ost start

Enqueue some items and see it running:

    $ redis-cli lpush ost:Mailer foo bar baz

Once you're up and running, deploy your workers using `-d` for daemonization:

    $ ost start -d

You can stop the worker pool by issuing the `stop` command:

    $ ost stop

This will wait for all workers to exit gracefully.

For more information, run:

    $ ost -h


Design notes
------------

`ost(1)` assumes that your workers perform a fair amount of I/O (probably one
of the most common reasons to send jobs to the background). We will optimize
`ost(1)` for this use case.

Currently, `ost(1)` runs multiple threads per worker. However, we may `fork(2)`
if we find that's better for multiple-core utilization under MRI.


See also
--------

[Ost::Worker][ost-worker].


Support
-------

Since we may use `fork(2)`, `ost(1)` only supports MRI for now.

[ost]: https://github.com/soveran/ost
[ost-worker]: https://github.com/djanowski/ost-worker
