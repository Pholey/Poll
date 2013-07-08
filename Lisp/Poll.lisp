(ql:quickload :drakma)
(ql:quickload :cl-ppcre)

#| Few notes, this was made in the first 12 hours of me ever interacting with CL,
so granted, this code is not going to be the best. Docs on Common Lisp are very 
poor and scarce so if you know of a better way, please let me know! |#


(defun retrieve-poll-data () 
  (let* ((poll-id "7215679")
         (answer_id "32748420")
         (unix_t (write-to-string (encode-universal-time 0 0 0 1 1 1970 0)))
         (url (concatenate 'string "http://polldaddy.com/n/f04601649c4e1a4b35354ba1a1bb6fdd/" poll-id "?" unix_t)))
    (cl-ppcre:regex-replace #\|
                            (second  (cl-ppcre:split "\'" (flex:octets-to-string
                                                               (drakma:http-request url))))
                            "%7C")))

(defun submit ()
    (flex:octets-to-string
        (drakma:http-request 
         (format nil 
                 "http://polls.polldaddy.com/vote-js.php?p=7215679&b=0&a=32748420,&o=&va=0&cookie=0&n=~A&url=http%3A//forourgloriousleader.weebly.com/poll-testing.html" (retrieve-poll-data))
        ;; this seemed to be the item that was giving us troubles.
        ;; i simply removed it since we manually escape the pipe...
        ;; :url-encoder (lambda (str) (drakma:url-encode str :ascii))
         :additional-headers
         '(("Accept" . "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
          ("Accept-Language" . "en-US,en;q=0.5")
          ("Accept-Encoding" . "deflate")
          ("Connection" . "keep-alive")))))

(submit)

