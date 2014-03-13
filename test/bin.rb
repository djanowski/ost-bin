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

def read_pid_file(path)
  until File.exist?(path) && File.size(path) > 0
    sleep 0.05
  end

  Integer(File.read(path))
end

def root(path)
  File.expand_path("../#{path}", File.dirname(__FILE__))
end

redis = Redis.connect

prepare do
  redis.flushdb
  Dir["test/workers/*.pid"].each { |file| File.delete(file) }
end

test "daemon, implicit start" do
  pid = nil

  begin
    redis.flushdb

    pid = spawn("#{root("bin/ost")} echo", chdir: "test")

    redis.rpush("ost:echo", 1)

    until value = redis.get("echo:result"); end

    assert_equal "1", value
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "daemon, explicit start" do
  pid = nil

  begin
    redis.flushdb

    pid = spawn("#{root("bin/ost")} start echo", chdir: "test")

    redis.rpush("ost:echo", 2)

    until value = redis.get("echo:result"); end

    assert_equal "2", value
  ensure
    Process.kill(:INT, pid) if pid
  end
end

test "daemonizes" do
  pid, detached_pid = nil

  pid_path = "./test/workers/echo.pid"

  begin
    pid = spawn("#{root("bin/ost")} -d echo", chdir: "test")

    sleep 1

    state = `ps -p #{pid} -o state`.lines.to_a.last[/(\w+)/, 1]

    assert_equal "Z", state

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
  redis.rpush("ost:slow", 3)

  begin
    spawn("#{root("bin/ost")} -d slow", chdir: "test")

    pid = read_pid_file("./test/workers/slow.pid")

    until redis.llen("ost:slow") == 0; end
  ensure
    Process.kill(:TERM, pid)
  end

  wait_for_pid(pid)

  assert_equal "3", redis.get("slow")
end

test "stops worker from command line action" do
  spawn("#{root("bin/ost")} start -d killme", chdir: "test")

  pid = read_pid_file("./test/workers/killme.pid")

  spawn("#{root("bin/ost")} kill killme", chdir: "test")

  wait_for_pid(pid)

  assert_equal "YES", redis.get("killme")
end

test "use a different dir for pids" do
  pid = nil
  pid_path = "./test/tmp/echo.pid"

  begin
    spawn("#{root("bin/ost")} -d echo -p tmp", chdir: "test")

    pid = read_pid_file(pid_path)

    assert pid
  ensure
    Process.kill(:INT, pid) if pid
  end

  wait_for_pid(pid)

  assert !File.exist?(pid_path)
end
