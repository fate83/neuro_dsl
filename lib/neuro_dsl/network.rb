require 'neuro_dsl/layer'

module NeuroDsl
	class Network

		# storage for feed foorward declarations
		@@feed_forward = {}

		# storage for the last added layer
		@@last_layer = nil

		# layer array
		@@layers = {}
		attr_reader :layers

		# layer count
		@@count = 0
		attr_reader :count

		# axons
		@@axons = []
		attr_reader :axons

		# activation function, possible values: :linear or :logistic
		@@activation_function = :linear
		attr_reader :activation_function

		# init function for the weights
		@@init_function = :random
		attr_reader :init_function
		
		# temperature
		@@temperature = 1.0
		attr_reader :temperature
		
		# name of neural network
		attr_accessor :name

		# input layer
		@@input_layer = nil
		attr_accessor :input_layer

		# output layer
		@@output_layer = nil
		attr_accessor :output_layer

		def self.layer name = "L_#{@count}", options = {}
			@@last_layer = Layer.new(name, options)
			
			if options[:type] == :input
				raise Exception.new("Noooo you cant have more than one input layer!") unless @@input_layer.nil?
				@@input_layer = @@last_layer
			end

			if options[:type] == :output
				raise Exception.new("Noooo you can't have more than one output layer") unless @@output_layer.nil?
				@@output_layer = @@last_layer
			end
			@@layers[name] = @@last_layer

			@@count += 1
			
			if block_given?
				yield @@last_layer
			end
		end

		def self.input_layer name, options = {}, &block
			options[:type] = :input
			layer name, options, &block
		end

		def self.output_layer name, options = {}, &block
			options[:type] = :output
			layer name, options, &block
		end

		def self.neuron options = {}

			if @last_layer.nil?
				raise Error("No layer with id: #{:layer}") if layers[:layer].nil?
				@layers[:layer].add_neuron options
			else
				@last_layer.add_neuron options
			end
		end

		def self.feed_forward layer1_label, layer2_label, options = {}
			@@feed_forward[layer1_label] = [layer2_label, options]
		end

		def initialize name, options = {}
			@count = 0
			@name = name || raise(Error("Network must have a name"))
			@activation_function = options[:activation_function] || :linear
			@init_function = options[:init_function] || @@init_function || :random
			@temperature = options[:temperature] || 1.0
			@layers = {}
			copy_layers
			@last_layer = nil
			connect_layers unless @@feed_forward.empty?
		end

		def connect_layers
			@@feed_forward.each do |source_label, a|
				destination_label = a[0]
				options = a[1]

				unless @layers[source_label].nil?
					connect_layer @layers[source_label], @layers[destination_label], options
				end
			end
		end

		def connect_layer layer1, layer2, options
			neurons01 = layer1.neurons.values
			neurons02 = layer2.neurons.values

			neurons01.each do |n| 
				neurons02.each do |m|
					connect n, m, options
				end
			end		
		end

		def connect source_neuron, destination_neuron, options = {}
			axon = Axon.new source_neuron, destination_neuron, options
			
			destination_neuron.add_input axon
			source_neuron.add_output axon
		end
		
		def copy_layers
			@@layers.each do |name,layer|
				@layers[name] = layer.deep_copy
			end
		end

		def init function, &block
			if block_given?
				random_init &block
			else
				case function
				when :random
					random_init do |axon|
						axon.weight = (rand * 100).round / 100.0
					end
				else
					init :random
				end
			end
		end

		def random_init &block
			@layers.each do |name, layer|
				layer.neurons.each do |name, neuron|
					neuron.weights.each do |axon|
						yield axon
					end
				end
			end
		end


		# Propagation
		#
		def propagate input, options = {}
			input_layers  = @layers.values.select { |l| l.type == :input  }
			output_layers = @layers.values.select { |l| l.type == :output }
			
			if input_layers.size != 1
				raise(Exception.new("A network must have exactly one input layer!"))
			end

			if output_layers.size != 1
				raise(Exception.new("A network must have exactly one output layer!"))
			end

			# initialize input neurons
			input.each do |neuron_label, value|
				# ToDo direct input
				input_layers[0].neurons[neuron_label].state = value
			end

			# propagate recursively
			output_layers[0].propagate options
		end

		# Training
		# 
		def train patterns, options = {}
			# train
			cycles = options[:cycles] || 1000

			patterns.each do |pattern|
				cycles.times do
					if options[:offline]
						train_offline pattern, options
					else
						train_online pattern, options
					end
				end				
			end
		end

		def train_online pattern, options = {}
			puts "\tbefore" if options[:debug]
			puts self if options[:debug]

			propagate pattern.input, options

			puts "\tpropagate" if options[:debug]
			puts self if options[:debug]
			
			learn pattern.output, options
			
			puts "\tlearn" if options[:debug]
			puts self if options[:debug]
			
			reset
			
			puts "\treset" if options[:debug]
			puts self if options[:debug]
#			gets if options[:debug]
		end
		
		def train_offline pattern, options = {}
			raise Error("not implementet yet")
		end

		def learn output, options = {}
			input_layers  = @layers.values.select { |l| l.type == :input  }
			output_layers = @layers.values.select { |l| l.type == :output }

			# set teaching_input for output layer
			output.each do |neuron_label, value|
				neuron = output_layers[0].neurons[neuron_label]
				neuron.set_error(value)
			end

			# learn/backpropagate recursively
			input_layers[0].learn options
		end

		def reset
			@layers.each do |label, layer|
				layer.reset
			end
		end

		def calculate input_pattern, options = {}
			propagate input_pattern.input, options
			output_layers = @layers.values.select { |l| l.type == :output }
			output_layers[0].neurons.values.collect { |n| n.output(options) }
		end

		def to_s
			str = "#{self.class} \"#{@name}\"\n"
			str += "Layer:\n"
			@layers.values.each_with_index do |layer, i|
				str += "#{i}) " + layer.to_s + "\n"
			end
			str += "Axons\n"
			index = 1
			@layers.each do |name, layer|
				layer.neurons.each do |name, neuron|
					neuron.weights.each do |axon|
						str += "#{index}) #{axon}\n"
						index += 1
					end			
				end
			end
			str
		end
	end
end
