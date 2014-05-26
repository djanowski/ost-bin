class Echo
  def call(id)
    Redis.current.set("Echo:result", id)
  end
end
