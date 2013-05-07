require 'rubygems'
require 'sinatra'
require 'open3'
require 'nokogiri'
#require 'lib/xml_writer'

SIPP_PATH = ENV["SIPP_PATH"]
SIPP_LOG_PATH = "#{File.dirname(__FILE__)}/log"
SIPP_XML_PATH = "#{File.dirname(__FILE__)}/xml"

get '/ping' do
  halt(503, "SIPP_PATH not defined for Server process") if SIPP_PATH == nil
  Dir.mkdir(SIPP_LOG_PATH) if File::directory?(SIPP_LOG_PATH) == false
  Dir.mkdir(SIPP_XML_PATH) if File::directory?(SIPP_XML_PATH) == false
  'pong'
end

get '/log/delete/:id' do |id|
  puts request.body.read
  halt(501, "Not implemented")
end

get '/log/retrieve/:id' do |id|
  puts request.body.read
  halt(501, "Not implemented")
end

get '/log/list' do
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.filenames {
      Dir[File.join(SIPP_LOG_PATH, "*.log")].map{|f| File.basename(f)}.each do |f|
        xml.filename f
      end
    }
  end
  builder.to_xml
end

post '/call' do
  puts request.body.read
  halt(501, "Not implemented")
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
