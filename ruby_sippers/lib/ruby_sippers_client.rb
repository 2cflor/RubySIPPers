require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'

class RubySIPPersClient
  def initialize(options)
    @http = Net::HTTP.new(options[:host], options[:port])
    request = Net::HTTP::Get.new("/ping")
    response = @http.request(request)
    raise response.body if response.code != "200"
  end
  
  def delete_log(filename)
    request = Net::HTTP::Get.new("/log/delete/#{filename}")
    response = @http.request(request)
    response.body
  end
  
  def delete_all_logs
    log_filenames = self.logs
    log_filenames.each {|filename| puts self.delete_log(filename)}    
  end
  
  def retrieve_log(filename)
    request = Net::HTTP::Get.new("/log/retrieve/#{filename}")
    response = @http.request(request)
    response.body
  end
  
  def retrieve_all_logs
    logs = Hash.new
    self.logs.each {|filename| logs[filename] = self.retrieve_log(filename)}
    logs
  end

  def pids
    request = Net::HTTP::Get.new("/pid/list")
    response = @http.request(request)
    JSON.parse(response.body)
  end   
  
  def pid_kill(pid)
    request = Net::HTTP::Get.new("/pid/kill/#{pid}")
    response = @http.request(request)
    response.body
  end    
  
  def kill_all_pids
    pids = self.pids
    pids.each {|pid| puts self.pid_kill(pid)}    
  end  
  
  def logs
    request = Net::HTTP::Get.new("/log/list")
    response = @http.request(request)
    xml = Nokogiri::XML(response.body)
    xml.xpath("/filenames/filename").map { |i| i.content }
  end

  def call(options)   
    options[:conversation]
    
    raise 'No Conversation' if options[:conversation] == nil
    
    # Make HTTP Post call to Server
    request = Net::HTTP::Post.new("/call")
    request.set_form_data({:options => options.to_json})
    response = @http.request(request)
    JSON.parse(response.body)
  end
  
  def wait_for_call(pid = nil)
    i = 0
    while self.pids.size > 0 do
      break if pid != nil && self.pids.include?(pid) == false
      puts "[#{i}] Active PIDs: #{self.pids.join(", ")}"
      i += 1
      sleep 1
    end    
  end
end

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
