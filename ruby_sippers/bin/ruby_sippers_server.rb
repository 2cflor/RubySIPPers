$:.unshift File.join(File.expand_path(File.dirname(__FILE__)),'.')

require 'rubygems'
require 'sinatra'
require 'open3'
require 'nokogiri'
require 'uri'
require 'pp'
require 'json'
require 'xml_writer'

SIPP_PATH = ENV["SIPP_PATH"] || File.dirname(__FILE__)
SIPP_LOG_PATH = "#{File.dirname(__FILE__)}/log"
SIPP_XML_PATH = "#{File.dirname(__FILE__)}/xml"
@@xml_writer = RubySIPPersXMLWriter.new

get '/ping' do
  Dir.mkdir(SIPP_LOG_PATH) if File::directory?(SIPP_LOG_PATH) == false
  Dir.mkdir(SIPP_XML_PATH) if File::directory?(SIPP_XML_PATH) == false
  'pong'
end

get '/log/delete/:filename' do |filename|
  path = "#{SIPP_LOG_PATH}/#{filename}"
  halt(404, "Log file not found") if File.exists?(path) == false
  File.delete(path)
  "#{filename} Deleted"
end

get '/log/retrieve/:filename' do |filename|
  path = "#{SIPP_LOG_PATH}/#{filename}"
  halt(404, "Log file not found") if File.exists?(path) == false
  File.read(path)
end

get '/log/list' do
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.filenames { Dir[File.join(SIPP_LOG_PATH, "*.log")].map{|f| File.basename(f)}.each { |f| xml.filename f } }
  end
  builder.to_xml
end

post '/call' do
  # Retrieve options passed from client
  options = JSON.parse(params[:options])

  # Create Files
  options["xml_files"] = @@xml_writer.make_sipp_xml(options["conversation"])

  # Make Call
  outtext = make_call(options)
  
  # Return log filename
  outtext
end

helpers do
  def make_call(options)
    fg_xml = options["xml_files"][0]
    bg_xmls = [options["xml_files"][1]]
    
    sipp = "#{SIPP_PATH}/sipp"
    opts = ""
    i, o, wait_thr = Open3.popen2e("#{sipp} #{opts}")
    outtext = o.read
    o.close   
    
    return outtext
  end
end

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
