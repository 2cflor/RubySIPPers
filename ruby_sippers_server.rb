require 'rubygems'
require 'sinatra'
require 'open3'
#require 'lib/xml_writer'

SIPP_PATH = ENV["SIPP_PATH"]
SIPP_LOG_PATH = "#{SIPP_PATH}/log"
SIPP_XML_PATH = "#{SIPP_PATH}/xml"

get '/ping' do
  halt(503, "SIPP_PATH not defined for Server process") if SIPP_PATH == nil
  'pong'
end

post '/log/delete/:id' do |id|
  puts request.body.read
  halt(503, "Not implemented")
end

post '/log/retrieve/:id' do |id|
  puts request.body.read
  halt(503, "Not implemented")
end

post '/log/list' do
  puts request.body.read
  halt(503, "Not implemented")
end

post '/call' do
  puts request.body.read
  halt(503, "Not implemented")
  # Create Files
  
  # Make Call
  
  # Return log id
end

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
