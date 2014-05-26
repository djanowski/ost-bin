class Slow
  def call(n)
    sleep(n.to_i)
    Redis.current.set("slow", n)
  end
end
