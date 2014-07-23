class Logger
  def call(id)
    $stdout.puts("out: #{id}")
    $stderr.puts("err: #{id}")
  end
end
