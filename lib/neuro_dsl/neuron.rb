# encoding: utf-8
module NeuroDsl
	class Neuron
		# activation function, possible values: :identity
		attr_accessor :activation_function

		# output function, possible values: :identity
		attr_accessor :output_function

		# propagation function
		attr_accessor :propagation_function

		# type: possible values: :input, :output, :hidden
		attr_accessor :type

		# activity state a_i
		attr_writer :state

		# new state after propagation
		attr_accessor :state_new

		# weights to incoming neurons (List of axon references)
		attr_accessor :weights

		# unique name of the neuron
		attr_accessor :name

		# error for backpropagation
		attr_accessor :error

		# axon
		attr_accessor :axons

		# threshold
		attr :threshold

		# temperature
		attr :temperature

		def initialize name, options = {}
			@activation_function = options[:activation_function] || :identity
			@output_function = options[:output_function] || :identity
			@propagation_function = options[:propagation_function] || :propagate
			@type = options[:type] || :hidden
			@state = options[:state] || :initial
			@state_new = options[:state_new] || :initial
			@weights = options[:weights] || []
			@name = name || raise(Error("Neuron must have a name"))
			@error = options[:error] || :initial
			@axons = []
			@threshold = options[:threshold] || 0.5
			@temperature = options[:temperature] || 0.5
 		end

 		def add_input axon
 			@weights << axon
 		end

 		def add_output axon
 			@axons << axon
 		end

		def train

		end

		def propagate options = {}
			return @state if @type == :input
			return @state_new unless @state_new == :initial

			activate(options)

			@state
		end

		def learn options = {}
			puts "#{self} is learning" if options[:debug]
			return @error if @type == :output
			return @error unless @error == :initial

			@error = @axons.inject(0.0) do |sum, axon|
				sum + axon.learn(@state, options)
			end
		end

		def reset
			@state = @state_new
			@state_new = :initial
			@error = :initial

			unless @type == :output
				@axons.each do |axon|
					axon.reset
				end
			end
		end

		def output options = {}
			output_function = options[:output_function] || @output_function
			send output_function, @state
		end

		def input value, options = {}
			activation_function = options[:activation_function] || @activation_function
			@state = send activation_function, value
		end

		def activate options = {}
			activation_function = options[:activation_function] || @activation_function
			@state = send activation_function, net
		end

		def set_input values, options = {}
			
		end

		def set_error teaching_input
			@error = (@state * (1 - @state) * (teaching_input - @state))
			@error = (@error * 100).round / 100.0
		end

		def net options = {}
			retval = @weights.inject(0) do |sum, axon|
				sum + axon.propagate(options)
			end
			retval = (retval * 100).round / 100.0
		end

		def to_s
			"#{@type}: #{@name}: (#{@state} » #{@state_new} | #{@error})"
		end

		def deep_copy options = {}
			neuron = Neuron.new(@name, {
				:type => @type, 
				:state => @state, 
				:state_new => @state_new,
				:activation_function => @activation_function,
				:output_function => @output_function,
				:propagation_function => @propagation_function,
				:error => @error,
				:threshold => @threshold,
				:temperature => @temperature})

			@weights.each do |axon| 
				add_input axon.deep_copy(options)
			end

			neuron
		end

		private

			def identity value
				value > 1.0 ? 1.0 : value < 0.0 ? 0.0 : ((value * 100).round / 100.0)
			end

			def identity_derivation value
				identity value
			end

			def logistic value
				1.0 / (1 + Math.exp( -( value - @threshold ) / @temperature ) )
			end

			def logistic_derivation value
				logistic(value) * (1 - logistic(value))
			end
	end
end
