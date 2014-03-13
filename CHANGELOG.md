# (unreleased)

* New `-p` switch to specify the path where PID files should be stored.

* `ost(1)` now accepts commands: `start` and `kill`. For now, `start` is
  implicit, so there is no backwards incompatibility.

# 0.0.3 - 2012-07-05

* Fixed graceful handling of `SIGTERM`.
