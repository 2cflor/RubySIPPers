require '../ruby_sippers'
require 'test/unit'

class RubySippersTestcase < Test::Unit::TestCase
  
  def test_a_test_case
    # set some environment options
    # :ssh_hostname - the host where you want to run SIPp
    # :ssh_user - this user needs to have ssh keys set up with the targethost
    # see more options in ruby_sippers_runner.rb
    init_options = {
      :ssh_hostname => 'yourtargethost.com',
      :ssh_user => 'yourusername' 
    }
    
    # initialize a RubySIPPers object
    # makes available the objects: ruby_sippers.xml_writer and ruby_sippers.sipp_runner
    ruby_sippers = RubySIPPers.new(init_options)
    
    # define call specifications
    # the direction of the '>' specifies the direction of the request
    # this describes the actions, but also the expectations on the receiving end
    conversation = {
      :case => 'conversation_1',
      :callee_number => '2061234567',
      :caller_number => '4151234567',
      :caller_name => 'Engelbert Humperdink',
      :roles => [
        {:name => 'Engelbert', :ip => '127.0.1.1', :descr => 'Caller'},
        {:name => 'Barry', :ip => '127.0.2.1', :descr => 'Callee'},
        ],
      :sequence  => [
        {'Engelbert > invite > Barry' => { :retrans => 0.5, :crlf => "true" }},
        {'Engelbert < 100    < Barry' => { :optional => "true" }},
        {'Engelbert < 180           ' => { :retrans => 0.5, :optional => "true" }},
        {'Engelbert < 200    < Barry' => { :rtd => "true"}},
        {'Engelbert > ack    > Barry' => { :optional => "true", :rtd => "true", :crlf => "true"}},
        {'Engelbert : pause         ' => { :pause => 15.0 }},
        {'Engelbert > bye    > Barry' => { :retrans => 0.5}},
        {'Engelbert < 200    < Barry' => { :crlf => "true" }},
        {'Barry : pause         '     => { :pause => 4.0 }}
        ]
       }     
    
     # have the XML file created and written locally into ./output  
     file_array = ruby_sippers.xml_writer.make_sipp_xml(conversation)
     
     # setting options about SIPp XML files
     run_options = {}
     run_options[:fg_xml_file] = file_array[0]
     run_options[:bg_xml_files] = [file_array[1]]
     
     # start call, which:
     # - copies XMLs over to the targethost
     # - starts the background process(es)
     # - starts the foreground process
     # - verifies that foreground process didn't report any problems
     ruby_sippers.run(run_options)
  end
end

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
