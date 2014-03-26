PROG=twitter-streamd
all: $(PROG)

BEARER_TOKEN:
	@echo see https://dev.twitter.com/docs/auth/application-only-auth
	@echo essentially:
	@echo '  - start drinking'
	@echo '  - create an app at dev.twitter.com'
	@echo '  - do'
	@echo
	@echo '      FOO=$$(echo -n "$$CONSUMER_KEY:$$CONSUMER_SECRET" | base64 | tr -d "\n")'
	@echo
	@echo '  - POST that to api.twitter.com/oauth2/token as described in the docs'
	@echo
	@echo '      curl -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" -H "Authorization: Basic $$FOO" --data "grant_type=client_credentials" "https://api.twitter.com/oauth2/token"'
	@echo
	@echo '  - and put the access token from the JSON you got back into a file named BEARER_TOKEN'

$(PROG): start.rkt main.rkt BEARER_TOKEN
	raco exe -o $@ -v $<

test:
	racket test.rkt

run: $(PROG)
	./$(PROG)

.PHONY: test run
