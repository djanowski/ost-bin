Ost[File.basename(__FILE__, ".rb")].each do |id|
  Redis.current.set("echo:result", id)
end
