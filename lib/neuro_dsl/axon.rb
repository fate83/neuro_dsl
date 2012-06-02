# encoding: utf-8
module NeuroDsl
	class Axon
		# source neuron
		attr :source

		# destination neuron
		attr_reader :destination

		# weight of axon
		attr_accessor :weight

		# new weight after training
		attr_reader :new_weight

		def initialize source, destination, options = {}
			@source = source
			@destination = destination
			@weight = options[:weight] || 0.5
			@new_weight = options[:new_weight] || :initial
		end

		def propagate options = {}
			source.propagate(options) * @weight
		end

		def learn o_pi, options = {}
			puts "#{self} is learning, o_ip is #{o_pi}"
			learn_rate = options[:rate] || 0.1

			error_pj = destination.learn options

			delta_weigth = learn_rate * o_pi * error_pj # * 1.abl. aktivierungsfunktion

			@new_weight = @weight + delta_weigth

			error_pj * @weight
		end

		def reset options = {}
			@weight = @new_weight
			@new_weight = :initial
		end

		def to_s
			"(#{@source.name} => #{@destination.name}: #{@weight} » #{@new_weight})"
		end

		def deep_copy options = {}
			layer = options[:layer] || raise(Error("Cannot locate layer"))
			new_source = layer.neurons[@source.name]
			new_destination = layer.neurons[@destination.name] 
			axon = Axon.new new_source, new_destination, :weight =>  @weight
			axon
		end
	end
end