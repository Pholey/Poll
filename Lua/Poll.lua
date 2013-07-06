local http = require("socket.http")
local ltn12 = require("ltn12")
local s_mt = getmetatable("");
local s = s_mt.__index;
timestamp = tostring(socket.gettime())

--a little something to override the __mod operator (%) on strings for pythonic string management.
function s_mt:__mod(p)
  if type(p) == "table" then
    return self:format(unpack(p))
  end
  return self:format(p)
end

function http_get(uri)
  local t = {}
  local respt = http.request{
    url = uri,
    headers = {
                        ['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                        ["Accept-Encoding"] = "deflate",
                        ["Accept-Language"] = 'en-US,en;q=0.5',
                        ["Content-Type"] = "application/x-www-form-urlencoded",
                        ['Connection'] = 'keep-alive'
                },
  --proxy = "127.0.0.1:8118"
    sink = ltn12.sink.table(t)
  }
  return table.concat(t)
end


function vote_id(hash, poll_id)
  sess = tostring(http_get("http://polldaddy.com/n/%s/%s?" % { hash, poll_id }..timestamp):match[['(.-)']])
  return sess
end

function poll_url(poll_id, answer_id, hash, ref)
  URL = 'http://polls.polldaddy.com/vote-js.php?p=%s&b=0&a=%s,&o=&va=0&cookie=0&n=%s&url=%s' % { poll_id, vote_id(hash, poll_id), sess, ref }
  return URL
end


function submit(poll_id, answer_id, hash, ref)
  vote = http_get(poll_url(poll_id, answer_id, hash, ref))
  if vote:find("Thank you for voting!") then
    print("Vote submitted!")
  else
    print("You were banned!")
  end
end
