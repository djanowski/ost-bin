require "cutest"
require "redis"
require "timeout"

at_exit {
  Process.waitall
}

def wait_for_pid(pid)
  wait_for { !running?(pid) }
end

def wait_for_child(pid)
  Timeout.timeout(5) do
    Process.wait(pid)
  end
end

def wait_for
  Timeout.timeout(5) do
    until value = yield
      sleep 0.1
    end

    return value
  end
end

def running?(pid)
  begin
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end

def read_pid_file(path)
  wait_for { File.exist?(path) && File.size(path) > 0 }

  Integer(File.read(path))
end

def root(path)
  File.expand_path("../#{path}", File.dirname(__FILE__))
end

redis = Redis.connect

prepare do
  redis.flushdb
  Dir["test/workers/**/*.pid"].each { |file| File.delete(file) }
end

test "start" do
  pid = nil

  begin
    redis.flushdb

    pid = spawn("#{root("bin/ost")} start", chdir: "test/workers/echo")

    redis.rpush("ost:Echo", 2)

    value = wait_for { redis.get("Echo:result") }

    assert_equal "2", value
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "daemonizes" do
  pid, detached_pid = nil

  pid_path = "./test/workers/echo/ost.pid"

  begin
    pid = spawn("#{root("bin/ost")} -d start", chdir: "test/workers/echo")

    assert wait_for {
      `ps -p #{pid} -o state`.lines.to_a.last[/(\w+)/, 1] == "Z"
    }

    detached_pid = read_pid_file(pid_path)

    ppid = `ps -p #{detached_pid} -o ppid`.lines.to_a.last[/(\d+)/, 1]

    assert_equal "1", ppid
  ensure
    Process.kill(:INT, pid) if pid
    Process.kill(:INT, detached_pid) if detached_pid
  end

  wait_for_pid(detached_pid)

  assert !File.exist?(pid_path)
end

test "gracefully handles TERM signals" do
  redis.rpush("ost:Slow", 3)

  begin
    spawn("#{root("bin/ost")} -d start", chdir: "test/workers/slow")

    pid = read_pid_file("./test/workers/slow/ost.pid")

    assert wait_for { redis.llen("ost:Slow") == 0 }
  ensure
    Process.kill(:TERM, pid)
  end

  wait_for_pid(pid)

  assert_equal "3", redis.get("slow")
end

test "stop waits for workers to be done" do
  spawn("#{root("bin/ost")} start -d", chdir: "test/workers/slow")

  pid = read_pid_file("./test/workers/slow/ost.pid")

  stopper = spawn("#{root("bin/ost")} stop", chdir: "test/workers/slow")

  # Let the stop command start.
  wait_for { running?(stopper) }

  # Let the stop command end.
  wait_for_child(stopper)

  # Immediately after the stop command exits,
  # ost shouldn't be running and the pid file
  # should be gone.

  assert !running?(pid)
  assert !File.exist?("./test/workers/slow/ost.pid")
end

test "use a specific path for the pid file" do
  pid = nil
  pid_path = "./test/workers/echo/foo.pid"

  begin
    spawn("#{root("bin/ost")} -d start -p foo.pid", chdir: "test/workers/echo")

    pid = read_pid_file(pid_path)

    assert pid
  ensure
    Process.kill(:INT, pid) if pid
  end

  wait_for_pid(pid)

  assert !File.exist?(pid_path)
end

test "load Ostfile" do
  pid = nil

  begin
    redis.flushdb

    pid = spawn("#{root("bin/ost")} start", chdir: "test/workers/echo")

    redis.rpush("ost:Echo", 2)

    value = wait_for { redis.get("Echo:result") }

    assert_equal "2", value
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "redirect stdout and stderr to a log file when daemonizing" do
  pid, detached_pid = nil

  pid_path = "./test/workers/logger/ost.pid"

  log_path = "test/workers/logger/ost.log"

  File.delete(log_path) if File.exist?(log_path)

  begin
    pid = spawn("#{root("bin/ost")} -d start", chdir: "test/workers/logger")

    assert wait_for {
      `ps -p #{pid} -o state`.lines.to_a.last[/(\w+)/, 1] == "Z"
    }

    redis.lpush("ost:Logger", 1)
  ensure
    detached_pid = read_pid_file(pid_path)

    Process.kill(:INT, pid) if pid
    Process.kill(:INT, detached_pid) if detached_pid
  end

  wait_for_pid(detached_pid)

  assert_equal "out: 1\nerr: 1\n", File.read(log_path)
end
