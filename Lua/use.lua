local vote = require("Poll")


poll_id = '7230066'
answer_id = '32815555'
ref = 'http%3A//forourgloriousleader.weebly.com/poll-testing.html'
hash = '6fe7453bb8cebdbcd8cda9f28bc7d288'


submit(poll_id, answer_id, hash, ref)

--vote = http_get(poll_url(poll_id, answer_id, hash, ref))

--print(vote)
