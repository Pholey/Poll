['net/http','socksify/http','net/telnet'].map{|l| require l}

class Poll
  attr_accessor :poll_id, :answer_id, :session_uri, :target_url, :polldaddy, :pipemask, :user_agent_string,
  :proxyhost, :proxyport

  def initialize
    # The following parts were given in order to test the interaction
    # with polldaddy.com
    self.poll_id = '7215679'
    self.answer_id = '32748420'
    self.session_uri = "http://polldaddy.com/n/f04601649c4e1a4b35354ba1a1bb6fdd/#{self.poll_id}?#{Time.now.to_i}"
    self.target_url = 'http%3A//forourgloriousleader.weebly.com/poll-testing.html'
    self.polldaddy = "http://polls.polldaddy.com/vote-js.php"
    self.pipemask = 'XXXPIPEXXX' # needed to get around something the server is doing
    self.user_agent_string = 'Mozilla/5.0 (Windows NT 6.1; rv:10.0) Gecko/20100101 Firefox/10.0'
    @additional_headers = {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-US,en;q=0.5',
      'Accept-Encoding' => 'deflate',
      'Connection' => 'keep-alive'
      #On my system every single one was needed, rather than just the
    }

  end
  
  def vote_id
    # The data returned from the initial request to get
    # the url to send back to receive the final response
    # contains the "vote id".

    # This is the correspondent's original method.
    # self.sess.scan(/PDV_n#{poll_id}='([^']+)'/).to_s.gsub!('[','').gsub!(']','').gsub!('"','')
    
    #the above method was used due to the fact that aquiring a Vote_ID sometimes failed returning a result
    #that had data in between quotes. that way, in case of failure, it would return nothing.
    
    # The actual needed data is a bit easier to extract.
    # It comes back in this form:
    # "PDV_n7215679='50f2f74bcd|888';PD_vote7215679(0);"
    # What is needed is inbetween the single quotes.
    #
    self.sess[/'(.+?)'/,1]#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
  end

  # Provides the URL needed to retrieve the poll information
  def poll_url
    query_string = {
      p: self.poll_id,
      b: 0,
      a: self.answer_id,
      o: '',
      va: 0,
      cookie: 0,
      # n: self.vote_id.gsub(/\|/,self.pipemask),
      n: self.vote_id,
      url: self.target_url
    }

    # uri = URI.parse(self.polldaddy)
    # uri.query = URI.encode_www_form(query_string)
    # uri.query = my_query_maker(query_string)
    uri = self.polldaddy + "?" + my_query_maker(query_string)
    uri.to_s#.tap{|t| STDERR.puts "Trace: #{caller[1]} returning #{t}"}
  end

#define other users with this to create a poll URL, submit with http_get(c_poll_url) or tor_get(c_poll_url)
  def c_poll_url(poll_id, answer_id, custom_vote_hash, referrer_URL) 
    query_string = {
      p: poll_id,
      b: 0,
      a: answer_id,
      o: '',
      va: 0,
      cookie: 0,
      n: self.c_vote_id(custom_vote_hash),
      url: referrer_URL
    }


    uri = self.polldaddy + "?" + my_query_maker(query_string)
    uri.to_s
  end

  # Obtains the response to get the session key
  # to send in the final request.
  def sess
    self.http_get(self.session_uri)#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
  end

  # Get the poll response using Net::HTTP
  def submit
    self.http_get(self.poll_url)#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
  end
  # Use Net::HTTP to retrieve the uri and return the body of the response
  def http_get(uri)
    req = Net::HTTP::Get.new uri
    @additional_headers.keys.each do |k|
      req[k] = @additional_headers[k]
    end
    #STDERR.puts "Trace: #{caller[0]} req: #{req.inspect}"
    temp_uri = URI.parse(self.polldaddy)
    body=''
    Net::HTTP.start(temp_uri.hostname, temp_uri.port, proxyhost, proxyport) do |http|
      http.request(req) do |res|
        res.read_body do |segment|
          body << segment # this will retrieve the parts if the response is chunked
        end
      end
    end
    body#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
  end

  def tor_submit
    self.tor_get(self.poll_url)#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
  end

  def tor_get(uri)
    req = Net::HTTP::Get.new uri
    @additional_headers.keys.each do |k|
      req[k] = @additional_headers[k]
    end
    #STDERR.puts "Trace: #{caller[0]} req: #{req.inspect}"
    temp_uri = URI.parse(self.polldaddy)
    body=''
    Net::HTTP.SOCKSProxy('127.0.0.1', 9050).start(temp_uri.hostname, temp_uri.port, proxyhost, proxyport) do |http|
      http.request(req) do |res|
        res.read_body do |segment|
          body << segment # this will retrieve the parts if the response is chunked
        end
      end
    end
    body#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
  end
  
  def new_ip(control_port, password)
    localhost = Net::Telnet::new("Host" => "localhost", "Port" => control_port.to_i, "Timeout" => 10, "Prompt" => /250 OK\n/)
    localhost.cmd('AUTHENTICATE "#{password}"') { |c| print c; throw "Cannot authenticate to Tor" if c != "250 OK\n" }
    localhost.cmd('signal NEWNYM') { |c| print c; throw "Cannot switch Tor to new route" if c != "250 OK\n" }
    localhost.close
  end

#defines a custom vote session ID for if more than one person is wanted
  def c_vote_id(hash)
    sess_uri = "http://polldaddy.com/n/#{hash}/#{self.poll_id}?#{Time.now.to_i}"
    raw_id = self.http_get(sess_uri)
    raw_id[/'(.+?)'/,1]
  end


  def hash_to_cli_options(options)

    options.reduce('') do |s,o|
      s << "--#{o.first} #{o.last} "
    end#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}

  end

  def fix_uri(uri)
    # uri.gsub(/#{self.pipemask}/,'|').gsub(/%2F/,'/').tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
    uri
  end

  def my_query_maker(q)
    q.reduce([]) do |s, o|
      s << "#{o.first}=#{o.last}"
    end.join("&")#.tap{|t| STDERR.puts "Trace: #{caller[1]}: returning #{t}"}
  end



end



