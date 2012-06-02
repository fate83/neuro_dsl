module NeuroDsl
	class Pattern

		# Lists of input and output values
		attr_accessor :input, :output

		def initialize input, output
			@input  = input
			@output = output
		end

		def to_s
			@input.values.join(" ")
		end
	end
end	