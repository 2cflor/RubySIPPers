require 'nokogiri'
require 'open-uri'

class RubySIPPersXMLWriter

RESPONSE_CODES = {
    "100" => "100 Trying",
    "180" => "180 Ringing",
    "181" => "181 Call Is Being Forwarded",
    "182" => "182 Queued",
    "183" => "183 Session Progress",
    "199" => "199 Early Dialog Terminated",
    "200" => "200 OK",
    "202" => "202 Accepted",
    "204" => "204 No Notification",
    "300" => "300 Multiple Choices",
    "301" => "301 Moved Permanently",
    "302" => "302 Moved Temporarily",
    "305" => "305 Use Proxy",
    "380" => "380 Alternative Service",
    "400" => "400 Bad Request",
    "401" => "401 Unauthorized",
    "402" => "402 Payment Required",
    "403" => "403 Forbidden",
    "404" => "404 Not Found",
    "405" => "405 Method Not Allowed",
    "406" => "406 Not Acceptable",
    "407" => "407 Proxy Authentication Required",
    "408" => "408 Request Timeout",
    "410" => "410 Gone",
    "412" => "412 Conditional Request Failed",
    "413" => "413 Request Entity Too Large",
    "414" => "414 Request-URI Too Long",
    "415" => "415 Unsupported Media Type",
    "416" => "416 Unsupported URI Scheme",
    "417" => "417 Unknown Resource-Priority",
    "420" => "420 Bad Extension",
    "421" => "421 Extension Required",
    "422" => "422 Session Interval Too Small",
    "423" => "423 Interval Too Brief",
    "424" => "424 Bad Location Information",
    "428" => "428 Use Identity Header",
    "429" => "429 Provide Referrer Identity",
    "430" => "430 Flow Failed",
    "433" => "433 Anonymity Disallowed",
    "436" => "436 Bad Identity-Info",
    "437" => "437 Unsupported Certificate",
    "438" => "438 Invalid Identity Header",
    "439" => "439 First Hop Lacks Outbound Support",
    "440" => "440 Max-Breadth Exceeded",
    "469" => "469 Bad Info Package",
    "470" => "470 Consent Needed",
    "480" => "480 Temporarily Unavailable",
    "481" => "481 Call/Transaction Does Not Exist",
    "482" => "482 Loop Detected",
    "483" => "483 Too Many Hops",
    "484" => "484 Address Incomplete",
    "485" => "485 Ambiguous",
    "486" => "486 Busy Here",
    "487" => "487 Request Terminated",
    "488" => "488 Not Acceptable Here",
    "489" => "489 Bad Event",
    "491" => "491 Request Pending",
    "493" => "493 Undecipherable",
    "494" => "494 Security Agreement Required",
    "500" => "500 Server Internal Error",
    "501" => "501 Not Implemented",
    "502" => "502 Bad Gateway",
    "503" => "503 Service Unavailable",
    "504" => "504 Server Time-out",
    "505" => "505 Version Not Supported",
    "513" => "513 Message Too Large",
    "580" => "580 Precondition Failure",
    "600" => "600 Busy Everywhere",
    "603" => "603 Decline",
    "604" => "604 Does Not Exist Anywhere",
    "606" => "606 Not Acceptable"  
}  
  
  ##################################################
  # generate sipP readable xml files from user input
  # param: hash of call specs
  # return: array of xml filenames
  ##################################################
  def make_sipp_xml(call_specs)
    seperated_call_specs = _seperate_call_specs(call_specs)
    xml_filenames = []
    seperated_call_specs.each do |call_specs|
      xml_filenames.push(_write_xml(call_specs))
    end
    return xml_filenames
  end #make_sipp_xml
  
  ##################################################
  # fill in unspecified call data
  # param: hash of intertwined call specs 
  # return: array of individual call spec hashes
  ##################################################    
  def _seperate_call_specs(call_specs)
    call_legs_array = []
    call_specs["roles"].each do |role|
      single_leg_call_specs = {}
      single_leg_call_specs["case"] = call_specs["case"]
      single_leg_call_specs["callee_number"] = call_specs["callee_number"]
      single_leg_call_specs["caller_name"] = call_specs["caller_name"]
      single_leg_call_specs["caller_number"] = call_specs["caller_number"]
      single_leg_call_specs["role"] = role
      single_leg_call_specs["sequence"] = []
      call_specs["sequence"].each do |step|
        if step.keys[0].match(/#{role["name"]}/)
          single_leg_call_specs["sequence"].push(step)
        end
      end
      call_legs_array.push(single_leg_call_specs)
    end
    return call_legs_array
  end #_seperate_call_specs
  
  ##################################################
  # write xml files
  # param: hash of complete call specs
  # return: xml filename
  ##################################################
  def _write_xml(single_leg_call_specs)
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
     xml.doc.create_internal_subset(
     'scenario',
     nil,
     "sipp.dtd"
     )
      xml.scenario("name" => "#{single_leg_call_specs["case"]}_#{single_leg_call_specs["role"]["descr"]}") do
        single_leg_call_specs["sequence"].each do |step|
          flow = step.keys[0]
          #split flow string into array and direct flow left-to-right
          flow_components = flow.split(/ /)
          flow_components.delete("")
          if (flow_components.include?("<"))
            flow_components.reverse!
            index = flow_components.index("<")
            while (index)
              flow_components[index] = ">"
              index = flow_components.index("<")
            end
          end
          # Checking if the current role is sending, then building the <send> tag
          if (flow_components[0] == single_leg_call_specs["role"]["name"] &&  flow_components[1] == '>')
            header_variables = {}
            header_variables["request"] = flow_components[2].upcase
            header_variables["callee_number"] = single_leg_call_specs["callee_number"]
            header_variables["case"] = single_leg_call_specs["case"]
            if (single_leg_call_specs["caller_name"])
              header_variables["caller_name"] = single_leg_call_specs["caller_name"]
            end
            if (single_leg_call_specs["caller_number"])
              header_variables["caller_number"] = single_leg_call_specs["caller_number"]
            end
            if (step[flow]["retrans"])
              xml.send_("retrans" => "#{(step[flow]["retrans"]*1000).to_int}") do
                xml.cdata (_build_header(header_variables))
              end
            else
              xml.send_ do
                xml.cdata (_build_header(header_variables))
              end
            end
          # Checking if the current role is receiving, then building the <recv> tag
          elsif (flow_components[flow_components.size-1] == single_leg_call_specs["role"]["name"] && flow_components[flow_components.size-2] == '>')
            attributes = {}
            if (flow_components[flow_components.size-3].match(/\d/))
              attributes["response"] = flow_components[flow_components.size-3]
            else
              attributes["request"] = flow_components[flow_components.size-3].upcase
            end
            if (step[flow]["within"])
              attributes["timeout"] = (step[flow]["within"]*1000).to_int
            end
            if (step[flow]["optional"])
              attributes["optional"] = step[flow]["optional"]
            end
            if (step[flow]["rtd"])
              attributes["rtd"] = step[flow]["rtd"]
            end
            if (step[flow]["crlf"])
              attributes["crlf"] = step[flow]["crlf"]
            end
            xml.recv(attributes) do
              if (step[flow]["action"])
                xml.action do
                  if (step[flow]["action"]["ereg"])
                    step[flow]["action"]["ereg"].each do |expression|
                      xml.ereg(expression) do
                      end
                    end
                  end
                end
              end
            end  
          elsif (flow_components.include?("nop"))
            xml.nop do
              xml.action do
                if (step[flow]["action"]["log"])
                  xml.log_(step[flow]["action"]["log"]) do           
                  end
                end
                if (step[flow]["action"]["exec"])
                  xml.exec(step[flow]["action"]["exec"]) do
                  end
                end
              end
            end
          elsif (flow_components.include?("pause"))
            if ((flow_components[flow_components.size-1] == single_leg_call_specs["role"]["name"] && flow_components[flow_components.size-2] == ':') || 
                 (flow_components[0] == single_leg_call_specs["role"]["name"] && flow_components[1] == ':'))               
              xml.pause("milliseconds" => "#{(step[flow]["pause"]*1000).to_int}") do
              end
            end
          end
        end
        xml.ResponseTimeRepartition("value" => "10, 20, 30, 40, 50, 100, 150, 200") do       
        end
        xml.CallLengthRepartition("value" => "10, 50, 100, 500, 1000, 5000, 10000") do
        end
      end
    end
    filename = "#{single_leg_call_specs["case"]}_role_#{single_leg_call_specs["role"]["name"]}.xml"
    # write the file
    temp_file = File.new("./xml/temp", "w")
    temp_file.write(builder.to_xml)
    temp_file.close
    
    temp_file = File.open("./xml/temp", "r")
    xml_file = File.new("./xml/#{filename}", "w")
    temp_file.each do |line|
      if (line.match(/!DOCTYPE/))
        line = "#{line}\n"
      end
      line.gsub!("]]>", "]]>\n")
      line.gsub!("<![CDATA[", "\n<![CDATA[\n")
      xml_file.puts("#{line}")
    end
    temp_file.close
    File.delete("./xml/temp")
    xml_file.close
    return filename
  end #_write_xml

  def _build_header(header_variables)
    if !(header_variables["request"].match(/\d/))
      header = <<EOQ
      #{header_variables["request"].upcase} sip:#{header_variables["callee_number"]}@[remote_ip]:[remote_port] SIP/2.0
      Accept: application/sdp
      Allow: INVITE,ACK,CANCEL,BYE
      From: "#{header_variables["caller_name"] || 'SIPP'}" <sip:#{header_variables["caller_number"] || "SIPP"}@[local_ip]:[local_port]>;tag=[call_number]
      To: sut <sip:#{header_variables["callee_number"]}@[remote_ip]:[remote_port]>
      Via: SIP/2.0/[transport] [local_ip]:[local_port];branch=[branch]
      Call-ID: [call_id]
      CSeq: [cseq] #{header_variables["request"]}
      Contact: "#{header_variables["caller_name"] || 'SIPP'}" <sip:#{header_variables["caller_number"] || "SIPP"}@[local_ip]:[local_port]>
      Max-Forwards: 3
      Subject: #{header_variables["name"]}
      Content-Type: application/sdp
      Content-Length: [len]

      v=0
      o=user1 53655765 2353687637 IN IP[local_ip_type] [local_ip]
      s=-
      c=IN IP[media_ip_type] [media_ip]
      t=0 0
      m=audio [media_port] RTP/AVP 8
      a=rtpmap:8 PCMU/8000
      a=rtmap:101 telephone-event/8000
      a=fmtp:101 0-11,16
EOQ
  else
  header = <<EOQ
      SIP/2.0 #{RESPONSE_CODES[header_variables[:request]]}
      [last_Via:]
      [last_From:]
      [last_To:];tag=[pid]SIPpTag01[call_number]
      [last_Call-ID:]
      [last_CSeq:]
      Contact: <sip:[local_ip]:[local_port];transport=[transport]>
      Content-Length: 0
EOQ
    end
    return header
  end #_build_header
  
  private :_seperate_call_specs, :_write_xml, :_build_header
  
end #RubySIPPersXMLWriter

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
