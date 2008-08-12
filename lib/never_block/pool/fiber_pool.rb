# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2008 eSpace, Inc.
# License::   Distributes under the same terms as Ruby
#
#	A pool of initialized fibers
#	It does not grow in size or create transient fibers
#	It will queue code blocks when needed (if all its fibers are busy)
#
# This class is particulary useful when you use the fibers 
# to connect to evented back ends. It also does not generate
# transient objects and thus saves memory.
# 
# Example:
# fiber_pool = NeverBlock::Pool::FiberPool.new(150)
# 
# loop do
#   fiber_pool.spawn do
#     #fiber body goes here 
#   end
# end

require 'fiber'

module NeverBlock
  module Pool
	  class FiberPool
		  attr_accessor :fibers

		  # Prepare a list of fibers 
		  # that are able to run different
		  # blocks of code every time
		  # once a fiber is done with its block
		  # it attempts to fetch another one
		  # from the queue. 
		  def initialize(count = 50)
			  @fibers,@queue = [],[]
			  count.times do |i| 
				  fiber = Fiber.new do |block|
					  loop do
						  block.call
						  unless @queue.empty?
							  block = @queue.shift
						  else
							  block = Fiber.yield @fibers << Fiber.current
						  end
					  end
				  end
				  fiber[:evented] = true
				  @fibers << fiber
			  end 
		  end

		  # If there is an available fiber
		  # use it, otherwise, leave it to linger in a queue
		  def spawn(&block)
			  if fiber = @fibers.shift
				  fiber.resume(block)
			  else
				  @queue << block
			  end
			  self # we are keen on hiding our queue 
		  end
	  end
	end
end