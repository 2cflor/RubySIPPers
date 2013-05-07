require 'net/http'
require 'uri'

class RubySIPPersClient
 
  def initialize(options)
    @http = Net::HTTP.new(options[:host], options[:port])
    request = Net::HTTP::Get.new("/ping")
    response = @http.request(request)
    raise 'Error communicating with server' if response.code != 200
  end
  
  def delete_logs
    request = Net::HTTP::Post.new("/delete_log/1")
    response = @http.request(request)
  end
  
  def retrieve_logs
    request = Net::HTTP::Post.new("/retrieve_log/1")
    response = @http.request(request)
  end
  
  def call(options)   
    options[:conversation]
    
    raise 'No Conversation' if options[:conversation] == nil
    
    # Make HTTP Post call to Server
    request = Net::HTTP::Post.new("/call")
    request.set_form_data({"options" => options})
    response = @http.request(request)
  end
end

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
