Ost[File.basename(__FILE__, ".rb")].each do |n|
  sleep(n.to_i)
  Redis.current.set("slow", n)
end
