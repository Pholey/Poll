=begin rdoc

A problem posed by a correspondent who wanted to be able to interact
with polldaddy and process an error in their code.  The issue is that
given in a browser, the final poll url returns some data, then more js
code that does something.  Issued in a browser, the full response is
given. But issued programmatically, only the first part returns.

What I believe is happening on the server side is that the script to
return the initial data is closed and another script takes over to
deliver the second part, which inserts a script into the current
DOM. This switching is done in a way that the user agent thinks the
connection has closed and so closes it's end and completes processing.

Real browsers, though, seem immune to this, and continue to accept
input. How are they doing this, and can it be emulated
programmatically?

=end

require 'net/http'
require 'curb'
require 'watir'
require 'mechanize'

class Poll
  attr_accessor :poll_id, :answer_id, :session_uri, :target_url, :polldaddy

  def initialize
    # The following parts were given in order to test the interaction
    # with polldaddy.com
    self.poll_id      = '7215679'
    self.answer_id    = '32748420'
    self.session_uri  = "http://polldaddy.com/n/f04601649c4e1a4b35354ba1a1bb6fdd/#{self.poll_id}?#{Time.now.to_i}"
    self.target_url   = 'http://forourgloriousleader.weebly.com/poll-testing.html'
    self.polldaddy    = "http://polls.polldaddy.com/vote-js.php"
  end
  
  def vote_id
    # The data returned from the initial request to get
    # the url to send back to receive the final response
    # contains the "vote id".

    # This is the correspondent's original method.
    # self.sess.scan(/PDV_n#{poll_id}='([^']+)'/).to_s.gsub!('[','').gsub!(']','').gsub!('"','')
    
    # The actual needed data is a bit easier to extract.
    # It comes back in this form:
    #   "PDV_n7215679='50f2f74bcd|888';PD_vote7215679(0);"
    # What is needed is inbetween the single quotes.
    self.sess.scan(/'(.+?)'/)
  end

  # Provides the URL needed to retrieve the poll information
  def poll_url
    query_string = {
      p:       self.poll_id,
      b:       0,
      a:       self.answer_id,
      o:       '',
      va:      0,
      cookie:  0,
      n:       self.vote_id,
      url:     self.target_url
    }

    uri = URI.parse(self.polldaddy)
    uri.query = URI.encode_www_form(query_string)
    uri.to_s
  end

  # Obtains the response to get the session key
  # to send in the final request.
  def sess
    self.http_get(self.session_uri)
  end

  # Get the poll response using Net::HTTP
  def poll
    self.http_get(self.poll_url)
  end

  # Get the poll response using libcurl
  def poll2
    self.curl_get(self.poll_url)
  end

  # Get the poll response using the curl cli program
  def poll3
    self.curl_cli_get(self.poll_url)
  end

  # Get the poll response using Watir Webdriver
  # The watir browser object is returned with
  # this instead of the poll response content
  def poll4
    self.watir_get(self.poll_url)
  end

  # Get the poll response using Mechanize
  def poll5
    self.mech_get(self.poll_url)
  end

  # Use Net::HTTP to retrieve the uri and return the body of the response
  def http_get(uri)
    uri = URI.parse(uri)
    req = Net::HTTP::Get.new uri
    req['user-agent'] = 'Mac Safari'
    
    body = ''

    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req) do |res|
        res.read_body do |segment|
          body << segment       # this will retrieve the parts if the response is chunked
        end
      end
    end
    body
  end
  
  # Use libcurl to retrieve the uri and return the body of the response
  def curl_get(uri)
    uri = URI.parse(uri).to_s
    response = Curl.get(uri)
    response.body_str
  end
  
  # Use the curl cli client to retrieve the uri and return the body of the response
  def curl_cli_get(uri)
    uri = URI.parse(uri).to_s
    curl_cmd = `which curl`.chomp
    curl_options = {
      compressed: '',
      fail: '',
      silent: '',
      :"user-agent" => 'Mac Safari'
    }
    
    `#{curl_cmd} #{hash_to_cli_options(curl_options)} '#{uri}'`.chomp

  end

  # Use watir webdriver to naviage to the uri and return the watir browser
  def watir_get(uri)
    uri = URI.parse(uri).to_s

    b = Watir::Browser.new :firefox
    b.goto uri
    b
  end

  # Use mechanize to retrieve the uri and return the body of the response
  def mech_get(uri)
    uri = URI.parse(uri).to_s
    agent = Mechanize.new
    agent.ignore_bad_chunking= true # setting this to see if it will stay open to get the second part of response
    page = agent.get uri
    page.body
  end
  
  private
  
  def hash_to_cli_options(options)

    options.reduce('') do |s,o|
      s << "--#{o.first} #{o.last} "
    end

  end

end


