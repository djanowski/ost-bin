# 0.1.1 - 2014-07-23

* When daemonized, all output is now redirected to a file. It's `ost.log` by
  default, but you can specify a different path via `-l`.

# 0.1.0 - 2014-05-26

* Moved to a threaded model.

* Added `Ostfile` to specify which workers you want to run.

* New `-p` switch to specify the path where the PID file should be stored.

* `ost(1)` now accepts `start` and `stop` commands.

# 0.0.3 - 2012-07-05

* Fixed graceful handling of `SIGTERM`.
