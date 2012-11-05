Ost[File.basename(__FILE__, ".rb")].each do |id|
  puts id
end

Redis.current.set("killme", "YES")
