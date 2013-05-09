$:.unshift File.join(File.expand_path(File.dirname(__FILE__)),'..','lib')

require 'ruby_sippers_client.rb'
require 'socket'

def ip(target)
  Socket::getaddrinfo(target, 'www', nil, Socket::SOCK_STREAM)[0][3]
end 

sippers_server_host = "automation1.qa.marchex.com"

# initialize a RubySIPPersClient object
ruby_sippers = RubySIPPersClient.new({:host => sippers_server_host, :port => 4567})

from_ip = ip(sippers_server_host) 
to_ip   = ip(sippers_server_host) 
acd_ip  = ip('vscp1.ci.marchex.com') 

# define call specifications
# the direction of the '>' specifies the direction of the request
# this describes the actions, but also the expectations on the receiving end
conversation = {
  :case => 'conversation_1',
  :callee_number => '2606394937',
  :caller_number => '4151234567',
  :caller_name => 'Engelbert Humperdink',
  :roles => [
    {:name => 'Engelbert', :ip => "#{from_ip}:5060", :descr => 'Caller'},
    {:name => 'Barry', :ip => "#{to_ip}:5061", :descr => 'Callee'},
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

options = Hash.new
options[:conversation]  = conversation
options[:bg_delay]      = 1000
options[:acd_ip_port]   = "#{acd_ip}:5060"
options[:count]         = 1
options[:limit]         = 1

# Delete all previous logs
log_filenames = ruby_sippers.logs
log_filenames.each {|filename| puts ruby_sippers.delete_log(filename)}

# Make phone call
pid = ruby_sippers.call(options)
puts pid

# Retrieve new logs
log_filenames = ruby_sippers.logs
logs = Hash.new
log_filenames.each {|filename| logs[filename] = ruby_sippers.retrieve_log(filename)}


=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
