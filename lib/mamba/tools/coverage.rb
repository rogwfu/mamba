#require 'plympton'
require 'nokogiri'
require 'yaml'
require 'mongo'
require 'fileutils'

module Mamba
  module Tools
	# Class to generate coverage graphs 
	class Coverage 
	  # Create an instance of the coverage class
	  # @param [String] The name of the disassembly file
	  def initialize(disassemblyFile)
		# Read the disassembly file
		@disassembly = YAML::load(File.open(config['disassembly']))
		@disassembly.disName.chomp!()

		# Read the configuration files
		@mambaConfig = YAML.load_file("configs/Mamba.yml")
		@fuzzerConfig = YAML.load_file("configs/#{@mambaConfig['type']}.yml")

		#if(@mambaConfig['type'] ~= /^Distributed/) then
		# Setup the database connections
		#	database = Mongo::Connection.new(@mambaConfig['server'], @mambaConfig['port']).db(@mambaConfig['uuid'])
		#	@grid = Mongo::Grid.new(database)
		#end

		# Start the matlab files
		@matlabFileSpace = File.open("function_coverage_space.m", "wb")
		@matlabFilePercentage = File.open("function_coverage_percentage.m", "wb")

		return(self)
	  end

	  def calculate_coverage()
		@matlabFileSpace.write(matlab_header())
		@matlabFilePercentage.write(matlab_header())

		@fuzzerConfig["Maximum Generations"].times do |generationNumber|

		end

		@matlabFileSpace.close()
		@matlabFilePercentage.close()
	  end

	  private

	  def matlab_header()
		header = <<HEADER
				lightGray = [0.8 0.8 0.8];

				% Set global properties of the figure
				fh = figure(); % returns the handle to the figure object
				hold on 
HEADER
	  end

	  def matlab_footer_percentage(libDisas, numGens, fitFunc)

		y = $percentageArr.join(",")

		# Thats a hack
		xArr = Array.new()
		numGens.times do |gen|
		  xArr.push(gen)
		end
		x = xArr.join(",")

		footer = <<FOOTER

				X = [#{x}];
				Y=[#{y}];
				line(X, Y, 'Marker','o', 'LineStyle','-', 'LineWidth',1.25);

				% Set Titles
				title({'Percentage Functions Covered' ; 'Function: #{fitFunc}'});
				funcTit = xlabel('Generation');
				set(funcTit, 'FontWeight', 'bold');
				genTit = ylabel('Percentage');
				set(genTit, 'FontWeight', 'bold');
				grid on

				% Work with the axises
				set(gca,'xlim',[0 #{numGens-1}], 'xtick', [0:1:#{numGens-1}])
				set(gca,'ylim',[0 100], 'ytick',[0:10:100])
				set(fh, 'color', 'white'); % sets the color to white
				set(gca,'Color',lightGray);
				set(gca, 'TickDir', 'out'); % set tick marks out
				set(gcf, 'InvertHardCopy', 'off');

				set(gcf, 'PaperUnits', 'inches');
				set(gcf, 'PaperSize', [8.0 9.0]);
				set(gcf, 'PaperPositionMode', 'manual');
				set(gcf, 'PaperPosition', [0 0 8.0 9.0]);

				set(gcf, 'renderer', 'painters');
				print(gcf, '-dpdf', 'function_coverage_percentage.pdf');
FOOTER

	  end

	  def matlab_footer_time_space(libDisas, numGens, fitFunc)
		footer = <<FOOTER
				% Set Titles
				title({'Function Coverage Graph' ; 'Function: #{fitFunc}'});
				funcTit = xlabel('Functions');
				set(funcTit, 'FontWeight', 'bold');
				genTit = ylabel('Generation');
				set(genTit, 'FontWeight', 'bold');
				grid on

				% Work with the axises
				set(gca,'xlim',[0 #{libDisas.funcHash.length()}], 'xtick', [0:250:#{libDisas.funcHash.length()}])
				set(gca,'ylim',[0 #{numGens}], 'ytick',[0:1:#{numGens}])
				set(fh, 'color', 'white'); % sets the color to white
				set(gca,'Color',lightGray);
				set(gca, 'TickDir', 'out'); % set tick marks out
				set(gcf, 'InvertHardCopy', 'off');

				set(gcf, 'PaperUnits', 'inches');
				set(gcf, 'PaperSize', [8.0 9.0]);
				set(gcf, 'PaperPositionMode', 'manual');
				set(gcf, 'PaperPosition', [0 0 8.0 9.0]);

				set(gcf, 'renderer', 'painters');
				print(gcf, '-dpdf', 'function_coverage_space.pdf');

FOOTER
	  end
	end
  end
end
