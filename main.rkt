#lang racket/base

(require racket/match racket/list racket/port racket/string racket/file
         racket/tcp
         net/url
         (only-in srfi/13 string-contains)
         json)

(provide simplify-tweet/json
         get-tweets/json
         twitter-client
         twitter-server)

(define <seconds-between-twitter-requests> 60)
(define <number-of-cached-tweets> 100)
(define <number-of-tweets-sent> 20)

(define <twitter-api-url>
  (string->url
    (format "https://api.twitter.com/1.1/favorites/list.json?screen_name=~a&count=~a"
      "easybib"
      (min <number-of-cached-tweets> 200)))) ; 200 is the api's limit
(define <twitter-bearer-token> (string-trim (file->string "BEARER_TOKEN")))

(define log printf)

;;; tweets

(define (simplify-tweet/json j)
  (match j
    [(hash-table
       ('id id)
       ('text text)
       ('user (hash-table ('screen_name user) _ ...))
       _ ...)
     (make-hasheq `((id . ,id) (user . ,user) (text . ,text)))]
    [_ #f]))

(define *tweets* '())
(define (add-to-tweet-cache! ts)
  (log "adding ~a tweets\n" (length ts))
  (set! *tweets* (append ts *tweets*))
  (when (> (length *tweets*) <number-of-cached-tweets>)
    (set! *tweets* (drop *tweets* <number-of-cached-tweets>))))

(define (random-choice lst)
  (if (empty? lst)
    #f
    (list-ref lst (random (length lst)))))

;;; client

(define (get-tweets/json)
  (call/ec
    (lambda (return)
      (define twitter-http-sendrecv
        (lambda ()
          (http-sendrecv/url <twitter-api-url>
            #:headers (list (string-append "Authorization: Bearer " <twitter-bearer-token>)))))
      (define (get-port)
        (define-values (status header p)
          (with-handlers ([exn:fail? (lambda (e) ((log "http GET failed\n~a\n" e)
                                                  (return #f)))])
            (twitter-http-sendrecv)))
        (unless (string-contains (bytes->string/utf-8 status) "200")
          (log "not 200 OK\n\t~a\n\t~a\n" status (port->string p))
          (close-input-port p)
          (return #f))
          p)
      (define p (get-port))
      (define json
        (with-handlers ([exn:fail? (lambda (e) ((close-input-port p)
                                                (log "json parsing failed\n~a\n" e)
                                                (return #f)))])
          (read-json p)))
      (unless (list? json)
        (log "didn't receive a list on the top-level\n")
        (return #f))
      json)))

;; pushes tweets into *tweets*
(define (twitter-client)
  (define tweets/json (get-tweets/json))
  (when tweets/json
    (add-to-tweet-cache! (filter hash? (map simplify-tweet/json tweets/json))))
  (sleep <seconds-between-twitter-requests>))

;;; server

(define (twitter-server port)
  (define listener (tcp-listen port 5 #t))
  (let loop ()
      (accept-and-handle listener)
      (loop)))

(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    (thread (lambda ()
              (respond in out)
              (close-input-port in)
              (close-output-port out))))
  (thread (lambda ()
            (sleep 10) ; 10s read timeout
            (custodian-shutdown-all cust))))

(define (respond in out)
  (display "HTTP/1.0 200 There You Go\r\n" out)
  (display "Server: yes\r\nContent-Type: application/json\r\n\r\n" out)
  (define out-tweets
    (filter hash?
      (for/list ([i (in-range <number-of-tweets-sent>)])
        (random-choice *tweets*))))
  (display (jsexpr->string out-tweets) out)
  (display "\r\n" out))
