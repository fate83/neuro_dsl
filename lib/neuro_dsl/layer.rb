module NeuroDsl
	class Layer
		# Unique name of layer
		attr_reader :name
		
		# :input, :output, :hidden
		attr_reader :type

		# array of neurons
		attr_accessor :neurons

		# last added neuron
		attr_reader :last_neuron

		attr_reader :count

		def initialize name, options = {}
			@name = name
			@type = options[:type] || :hidden
			@neurons = {}
			@count = 0
		end

		def neuron name = "#{@name}_L_#{count}", options = {}
			if name.class == Array
				add_neurons name, options
			else
				add_neuron name, options
			end
		end

		def propagate options = {}
			#Propagation
			@neurons.values.each do |neuron|
				neuron.propagate options
			end
		end

		def learn options = {}
			# Learning
			@neurons.values.each do |neuron|
				neuron.learn options
			end
		end

		def reset
			@neurons.each do |label, neuron|
				neuron.reset
			end
		end

		def to_s
			"#{@type} [#{@name}: #{@neurons.values.join(', ')}]"
		end

		def deep_copy
			layer = Layer.new @name, {:type => @type}
			@neurons.each do |name, neuron|
				layer.neurons[name] = neuron.deep_copy :layer => layer
			end
			layer
		end

		private
			def add_neuron name, options = {}
				options[:type] = @type unless options[:type]
				@last_neuron = Neuron.new name, options
				@neurons[name] = @last_neuron
				@count += 1
			end

			def add_neurons neurons, options = {}
				neurons.each do |n|
					add_neuron n, options
				end
			end
	end
end
