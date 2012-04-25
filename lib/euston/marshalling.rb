def marshal_dup object
  return nil if object.nil?

  Marshal.load(Marshal.dump object)
end
