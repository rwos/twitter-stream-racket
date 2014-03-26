#lang racket/base
 
(require rackunit
         racket/list
         json
         "main.rkt")

(define *example-tweets*
  (call-with-input-file "fixture/favorites.json" read-json))

(check-equal?
  (simplify-tweet/json (first *example-tweets*))
  (make-hasheq
    '((text . "Note to self:  don't die during off-peak hours on a holiday weekend.")
      (user . "theSeanCook")
      (id . 243014525132091393))))

(check-equal?
  (simplify-tweet/json (second *example-tweets*))
  (make-hasheq
    '((text . "TWIT NPC. TWIT DUNGEONMASTER.")
      (user . "regisl")
      (id . 242778296117514240))))

(check-pred list? (get-tweets/json) "the twitter client isn't set-up correctly")
