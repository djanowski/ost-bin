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

test "daemon" do
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
