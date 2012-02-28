require 'ap'
require 'ostruct'
require 'euston'
require 'aggregate_root_samples'

def apr(what, header='')
  puts '', "== #{header} =="
  puts what.inspect
  puts ("="*(header.size + 6)), ''
end
