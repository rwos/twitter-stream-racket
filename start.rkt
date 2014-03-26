#lang racket/base

(require "main.rkt")

(thread twitter-client)
(twitter-server 8080)
