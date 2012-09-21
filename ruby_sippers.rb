require 'test/unit'
require '../lib/ruby_sippers_runner'
require '../lib/ruby_sippers_xml_writer'

class RubySIPPers < Test::Unit::TestCase
  attr_accessor :sipp_runner, :xml_writer
  
  def initialize(options)
    # setting up some environment options
    @init_options = Hash.new
    @init_options[:ssh_user]         = options[:ssh_user]
    @init_options[:ssh_hostname]     = options[:ssh_hostname]
    @init_options[:sipp]             = options[:sipp] || '/site/test-tools/bin/sipp'
    @init_options[:echo_cmd]         = options[:echo_cmd] || 1
    @init_options[:scenarios_location]  = options[:scenarios_location] || "/home/#{@init_options[:ssh_user]}/sipp_scenarios/"
    @init_options[:when]             = options[:when] || nil
    @init_options[:tcpdump]          = options[:tcpdump] || nil
    @init_options[:pcap]             = options[:pcap] || nil
    @init_options[:top]              = options[:top] || nil
    @init_options[:topfile]          = options[:topfile] || nil
    @init_options[:testing]          = options[:testing] || 0
    @init_options[:keep_files]       = options[:keep_files] || 0
    @init_options[:target_host]      = options[:target_host] || 'localhost'
    @init_options[:target_port]      = options[:target_port] || '5060'
    @init_options[:suppress_output]  = options[:suppress_output] || 0 

    @sipp_runner = RubySIPPersRunner.new(@init_options)
    @xml_writer = RubySIPPersXMLWriter.new
  end #initialize 
  
  def basic_calls_from_csv(datafile)
    csv_data = CSV.read(datafile, {:force_quotes => true, :headers => true, :skip_blanks => true}) 
    csv_data.each do |number_collection|
      puts "testing inbound: #{number_collection["inbound_no"]}, outbound: #{number_collection["forward_no"]}, alternative: #{number_collection["alternative"]}"
      xml_array = @xml_writer.generate_calls_from_number(number_collection["inbound_no"])
      run_options = {:fg_xml_file => xml_array[0], :bg_xml_files => xml_array[1]}
      run(run_options)
    end
  end #basic_calls_from_csv
  
  def run(options)   
    # setting run options
    run_options = {}
    run_options[:fg_ip] = options[:fg_ip] || '127.0.1.1:5061'
    run_options[:fg_xml_file] = options[:fg_xml_file]
    run_options[:bg_ips] =  options[:bg_ips] || ['127.0.2.1:5061']
    run_options[:bg_xml_files] = options[:bg_xml_files]
    run_options[:case] = options[:case] || 'Unnamed Case'
    run_options[:count] = options[:count] || 1
    run_options[:limit] = options[:limit] || 1
    run_options[:sipp_options] = options[:sipp_options] || " "
    run_options[:delay]  = options[:delay] || 1000
    run_options[:bg_delay]  = run_options[:delay]
    run_options[:ssh_user] = @init_options[:ssh_user]
    
    # copying files to target host
    system("scp output/#{run_options[:fg_xml_file]} #{@init_options[:ssh_user]}@#{@init_options[:ssh_hostname]}:#{@init_options[:scenarios_location]}")
    run_options[:bg_xml_files]. each do |file|
      system("scp output/#{file} #{@init_options[:ssh_user]}@#{@init_options[:ssh_hostname]}:#{@init_options[:scenarios_location]}")
    end
    
    # kicking off the calls and verifying no errors were raised
    assert_nothing_raised do
      @sipp_runner.run(run_options)
    end
  end
end #RubySIPPers

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
