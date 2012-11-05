require "cutest"
require "redis"

at_exit {
  Process.waitall
}

def wait_for_pid(pid)
  running = true

  while running
    begin
      Process.kill(0, pid)
    rescue Errno::ESRCH
      running = false
    end
  end
end

def root(path)
  File.expand_path("../#{path}", File.dirname(__FILE__))
end

redis = Redis.connect

test "daemon, implicit start" do
  r, w = IO.pipe
  pid = nil

  begin
    redis.flushdb

    pid = spawn("#{root("bin/ost")} echo", out: w, chdir: "test")

    redis.rpush("ost:echo", 1)

    assert_equal "1\n", r.gets
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "daemon, explicit start" do
  r, w = IO.pipe
  pid = nil

  begin
    redis.flushdb

    pid = spawn("#{root("bin/ost")} start echo", out: w, chdir: "test")

    redis.rpush("ost:echo", 2)

    assert_equal "2\n", r.gets
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "daemonizes" do
  r, w = IO.pipe
  pid, detached_pid = nil

  redis.flushdb

  begin
    pid = spawn("#{root("bin/ost")} -d echo", out: w, chdir: "test")

    sleep 1

    state = `ps -p #{pid} -o state`.lines.to_a.last[/(\w+)/, 1]

    assert_equal "Z", state

    pid_path = "./test/workers/echo.pid"

    assert File.exist?(pid_path)

    detached_pid = File.read(pid_path).to_i

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
  r, w = IO.pipe
  pid, detached_pid = nil

  redis.flushdb

  pid_path = "./test/workers/slow.pid"

  begin
    redis.rpush("ost:slow", 5)

    pid = spawn("#{root("bin/ost")} -d slow", out: w, chdir: "test")

    until File.exist?(pid_path)
      sleep 0.5
    end

    detached_pid = File.read(pid_path).to_i

    Process.kill(:TERM, detached_pid)
  ensure
    Process.kill(:INT, pid)
  end

  wait_for_pid(detached_pid)

  assert_equal "5", redis.get("slow")
end

test "stops worker from command line action" do
  r, w = IO.pipe
  pid, detached_pid = nil

  redis.flushdb

  pid_path = "./test/workers/killme.pid"

  pid = spawn("#{root("bin/ost")} start -d killme", out: w, err: w, chdir: "test")

  sleep 1

  until File.exist?(pid_path)
    sleep 0.5
  end

  detached_pid = File.read(pid_path).to_i

  spawn("#{root("bin/ost")} kill killme", chdir: "test")

  wait_for_pid(detached_pid)

  assert_equal "YES", redis.get("killme")
end
