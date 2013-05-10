$:.unshift File.join(File.expand_path(File.dirname(__FILE__)),'.')

require 'rubygems'
require 'sinatra'
require 'open3'
require 'nokogiri'
require 'uri'
require 'json'
require 'xml_writer'

SIPP_PATH = ENV["SIPP_PATH"] || File.dirname(__FILE__)
SIPP_LOG_PATH = "#{File.dirname(__FILE__)}/xml"
SIPP_XML_PATH = "#{File.dirname(__FILE__)}/xml"
@@xml_writer = RubySIPPersXMLWriter.new

@@active_pids = Array.new

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

get '/pid/kill/:pid' do |pid|
  puts "KILL: #{pid}"
  Process.kill('INT', pid.to_i)  
end

get '/pid/list' do 
  active_pids.to_json
end

post '/call' do
  # Retrieve options passed from client
  options = JSON.parse(params[:options])

  # Create Files
  options["xml_files"] = @@xml_writer.make_sipp_xml(options["conversation"])

  # Make Call
  pids = make_call(options)
  
  # Return pid
  pids.to_json
end

helpers do
  def active_pids
    @@active_pids.each do |pid|
      begin 
        Process.getpgid(pid)
      rescue Errno::ESRCH
        @@active_pids.delete(pid)
      end
    end
    return @@active_pids
  end
  
  def make_call(options)
    xml_files = options["xml_files"]
    pids = Hash.new
    pids[:secondary] = Array.new
    
    options["conversation"]["roles"].each_index do |i|
      next if i == 0  # This kicks off the call and needs to be done after the other processes are up and waiting
      pids[:secondary].push run_sipp(options, options["conversation"]["roles"][i]["ip"], xml_files[i])
    end

    # Launch the primary process
    pids[:primary] = run_sipp(options, options["conversation"]["roles"][0]["ip"], xml_files[0], true)
   
    puts "PID: #{pids}"
    return pids
  end
  
  def run_sipp(options, ip, xml_file, primary = false)
    sipp      = File.expand_path("#{SIPP_PATH}/sipp")
    log       = File.join(File.expand_path(SIPP_LOG_PATH),File.basename(xml_file, '.*') + ".log")
    ip, port  = ip.split(":")
    pids      = Hash.new
    
    # Set up Commandline options
    opts = Array.new
    opts.push options["acd_ip_port"]      if options["acd_ip_port"] && primary
    opts.push options["sipp_options"]     if options["sipp_options"]
    opts.push "-d #{options["bg_delay"]}" if options["bg_delay"]
    opts.push "-i #{ip}"                  if ip
    opts.push "-p #{port}"                if port
    opts.push "-bg"  
    opts.push "-sf #{SIPP_XML_PATH}/#{xml_file}"
    opts.push "-trace_err"
    opts.push "-trace_screen"
    opts.push "-trace_stat"
    opts.push "-m #{options["count"]}"    
    opts.push "-l #{options["limit"]}"       
    
    # Start SIPp in Background mode
    puts "starting background process: #{sipp} #{opts.join(" ")}"
    pids[:fg_pid] = spawn("#{sipp} #{opts.join(" ")}", [:out, :err]=>[log, "w"])
    Process.detach(pids[:fg_pid])
    sleep 0.5    
    
    # Retrieve Background PID from log
    contents = File.read(log)
    if contents =~ /pid=\[(\d+)\]/i
      pids[:bg_pid] = $1.to_i
    else 
      pids[:bg_pid] = 0
    end  
    
    @@active_pids.push pids[:fg_pid]
    @@active_pids.push pids[:bg_pid]
    return pids
  end
end

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
