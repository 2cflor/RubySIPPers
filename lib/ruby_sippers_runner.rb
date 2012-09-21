require 'net/ssh'

class RubySIPPersRunner


  def initialize(options = {})
    @runner_options = Hash.new
    @runner_options[:ssh_hostname]     = options[:ssh_hostname]
    @runner_options[:sipp]             = options[:sipp]
    @runner_options[:echo_cmd]         = options[:echo_cmd]
    @runner_options[:scenarios_location]  = options[:scenarios_location]
    @runner_options[:when]             = options[:when]
    @runner_options[:pids]             = Array.new
    @runner_options[:tcpdump]          = options[:tcpdump]
    @runner_options[:pcap]             = options[:pcap]
    @runner_options[:top]              = options[:top]
    @runner_options[:topfile]          = options[:topfile]
    @runner_options[:testing]          = options[:testing]
    @runner_options[:keep_files]       = options[:keep_files]
    @runner_options[:target_host]      = options[:target_host]
    @runner_options[:target_port]      = options[:target_port]
    @runner_options[:suppress_output]  = options[:suppress_output]
  end #initialize

  
  def run(options)
    @runner_options[:ssh_user] = options[:ssh_user]
    @runner_options[:fg_ip] = options[:fg_ip].gsub!(/\:/, ' -p ')
    @runner_options[:fg_xml_file] = options[:fg_xml_file]
    @runner_options[:bg_ips] = options[:bg_ips].map {|a| a.gsub(/\:/, ' -p ')}
    @runner_options[:bg_xml_files] = options[:bg_xml_files]
    @runner_options[:case] = options[:case]
    @runner_options[:count] = options[:count]
    @runner_options[:limit] = options[:limit]
    @runner_options[:sipp_options] = options[:sipp_options]
    @runner_options[:delay]  = options[:delay]
    @runner_options[:bg_delay]  = options[:bg_delay]
 
    number_of_tries = 0
    trying = true
    while (trying)  
      _connect_to_host
    
      # The directory containing the foreground xml file - this is where SIPP will drop its logs
      xml_dir = File.dirname(options[:fg_xml_file])
      logs = _ssh_exec!('ls #{xml_dir}/*.log 2>/dev/null')[0].split(/\s+/)
      if logs.count > 0 && File.exist?(logs[0])
        puts "Removing the logs files from #{xml_dir}"
        logs.each do |log|
          File.unlink(log) if File.exist?(log)
        end
      end
    
      # Set keep_files and case from the options hash, as they are used throughout the execution.

      @runner_options[:when] = Time.now.strftime("%Y%m%d.%H%M%S")
    
      if (@runner_options[:bg_delay])
        @runner_options[:fg_delay] = (@runner_options[:bg_delay] >= 2500 ? @runner_options[:bg_delay] - 2500 : 0)
      else
        @runner_options[:fg_delay] = 0
      end  
    
      # Start up the background processes
      index = 0
      @runner_options[:bg_ips].each do |ip|
        _run_background(ip, @runner_options[:bg_xml_files][index])
        index += index
      end
      sleep 1
    
      if @runner_options[:pids].size != @runner_options[:bg_ips].size
        _close_ssh
        raise  <<EOQ
The specified number of background processes should have been spawned.\n
actual #{@runner_options[:pids]} expected #{@runner_options[:bg_ips]}
EOQ

        exit
      end
      return_code = _run_foreground
      if (0 != return_code) # If SipP throws an error, retry and then fail
        _end_background
        _close_ssh
        number_of_tries = number_of_tries + 1
        if (number_of_tries == 2)
          trying = false
          raise 'The foreground sipp process should return no error code.'
          exit
        else
          puts "retrying"
        end
      else # if SipP foreground went fine, break the loop
        trying = false
      end
    end # while (trying)
    
    terminates_ok = _end_background
    if true != terminates_ok
      _close_ssh
      raise 'Background sipp instances should terminate on SIGUSR1'
      exit
    end
    
    logs = _read_logs(xml_dir)
    if '' != logs
      _close_ssh
      raise 'Error logs should be empty'
      exit
    end
    
    override_keep = @runner_options[:testing] ? ! @test_passed : 1
    
    if (logs != '' && (override_keep || @runner_options[:keep_files]))
      filename = "#{@runner_options[:case]}_#{@runner_options[:when]}.err"
      File.open(filename, 'w') { |f| f.write(logs) }
    end
    
    _close_ssh
    return !return_code
  end #run
  
  def _run_background(ip_address, xml)
    cmd = "#{@runner_options[:sipp]} #{@runner_options[:sipp_options]} -watchdog_minor_threshold 3000 -d #{@runner_options[:bg_delay]} -i #{ip_address} -bg -sf #{@runner_options[:scenarios_location]}/#{xml}"
    puts "starting background process: #{cmd}" if @runner_options[:echo_cmd]
    pid = _ssh_exec!(cmd)[0]
    if pid =~ /pid=\[(\d+)\]/i 
        @runner_options[:pids].push $1
        return $1
    else 
        puts "# Error running sipp (output #{pid})- check the contents of #{xml}" unless @options[:suppress_output]
        return 0
    end
  end #_run_background

  def _run_foreground
    cmd = "#{@runner_options[:sipp]} #{@runner_options[:target_host]}:#{@runner_options[:target_port]} #{@runner_options[:sipp_options]} -watchdog_minor_threshold 3000 -d #{@runner_options[:fg_delay]}"
    cmd = cmd + (@runner_options[:count] ? " -m #{@runner_options[:count]}" : "")
    cmd = cmd + (@runner_options[:rate] ? " -r #{@runner_options[:rate]}" : "")
    cmd = cmd + (@runner_options[:limit] ? " -l #{@runner_options[:limit]}" : "")
    cmd = cmd + (@runner_options[:collect_metrics] ? " -trace_err" : "")
    cmd = cmd + " -f 5 -i #{@runner_options[:fg_ip]} -sf #{@runner_options[:scenarios_location]}/#{@runner_options[:fg_xml_file]}"
    cmd = cmd + (@runner_options[:suppress_output] ? ' >/dev/null 2>&1' : '')
    puts "starting foreground process: #{cmd}" if @runner_options[:echo_cmd]
    return_code = _ssh_pty_exec!(cmd)
    puts return_code.inspect
		return return_code[2]
  end #_run_foreground
  
  def _end_background
    pids = @runner_options[:pids].join(',')
    backoff = 0
    puts "killing background process: #{pids}"
    if pids.size
      if (_ssh_exec!("ps -fp #{pids} | grep sipp")[0].size > 0)
        puts "# kill -SIGUSR1 @{#{pids}}" unless @runner_options[:suppress_output]
        _ssh_exec!("kill -SIGUSR1 #{pids}")
        while _ssh_exec!("ps -fp #{pids} | grep sipp")[0].size > 0
          if backoff >= 5
            _ssh_exec!("kill -9 #{pids}")
            return 0 if backoff >= 10
          end
          puts "." unless @runner_options[:suppress_output]
          sleep backoff
          backoff += 1
        end
      end
    end
    
    @runner_options[:pids].clear
    return backoff < 5
  end #_end_background
  
  def _read_logs(log_dir)
    log = ''
    _ssh_exec!("ls #{log_dir}/*.log 2>/dev/null")[0].split(/\s+/).each do |file|
      # TODO: make this work using SSH
      if File.size(file)
        log += " > cat #{file}"
        log += File.read(file)
      end
      File.unlink(file)
    end
    return log
  end #_read_logs

  def _connect_to_host
    @ssh = Net::SSH.start(@runner_options[:ssh_hostname], @runner_options[:ssh_user])
  end #_connect_to_host
  
  def _close_ssh
    if @ssh != nil
      @ssh.close
    end
  end #_close_ssh
  
  def _ssh_pty_exec!(command)
    stdout_data = ""
    stderr_data = ""
    exit_code = nil
    exit_signal = nil
    @ssh.open_channel do |channel|
      channel.request_pty do |ch, pty_success|
        if !pty_success
          puts "could not obtain pty"
        end

        channel.exec(command) do |ch, success|
          unless success
            abort "FAILED: couldn't execute command (ssh.channel.exec)"
          end
          channel.on_data do |ch,data|
            stdout_data+=data
          end

          channel.on_extended_data do |ch,type,data|
            stderr_data+=data
          end

          channel.on_request("exit-status") do |ch,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |ch, data|
            exit_signal = data.read_long
          end
        end
      end
    end
    @ssh.loop
    [stdout_data, stderr_data, exit_code, exit_signal]
  end #_ssh_pty_exec!
    
  def _ssh_exec!(command)
    stdout_data = ""
    stderr_data = ""
    exit_code = nil
    exit_signal = nil
    @ssh.open_channel do |channel|
      channel.exec(command) do |ch, success|
        unless success
          abort "FAILED: couldn't execute command (ssh.channel.exec)"
        end
        channel.on_data do |ch,data|
          stdout_data+=data
        end

        channel.on_extended_data do |ch,type,data|
          stderr_data+=data
        end

        channel.on_request("exit-status") do |ch,data|
          exit_code = data.read_long
        end

        channel.on_request("exit-signal") do |ch, data|
          exit_signal = data.read_long
        end
      end
    end
    @ssh.loop
    [stdout_data, stderr_data, exit_code, exit_signal]
  end #_ssh_exec!
  
end #RubySIPPersRunner

=begin
Copyright (C) 2012 Christian Flor, John Crawford, Tye Mcqueen, Ambrose Sterr at Marchex Inc.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License Version 2 as published by the Free Software Foundation;

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end
