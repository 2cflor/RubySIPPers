$:.unshift File.join(File.expand_path(File.dirname(__FILE__)),'..')

require 'ruby_sippers_client.rb'

# initialize a RubySIPPersClient object
ruby_sippers = RubySIPPersClient.new({:host => "freeway.sea.marchex.com", :port => 4567})

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

# make the call 
ruby_sippers.delete_logs
ruby_sippers.retrieve_logs
ruby_sippers.call(:conversation => conversation)

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
