#!/bin/bash
# The script does automatic checking on a Go package and its sub-packages, including:
# 1. gofmt         (http://golang.org/cmd/gofmt/)
# 2. goimports     (https://github.com/bradfitz/goimports)
# 3. golint        (https://github.com/golang/lint)
# 4. go vet        (http://golang.org/cmd/vet)
# 5. race detector (http://blog.golang.org/race-detector)
# 6. test coverage (http://blog.golang.org/cover)

COVERALLS_TOKEN=t47LG6BQsfLwb9WxB56hXUezvwpED6D11

set -e
 
# Automatic checks
echo "gofmt"
test -z "$(gofmt -l -d .     | tee /dev/stderr)"
echo "goimports"
test -z "$(goimports -l -d . | tee /dev/stderr)"
echo "golint"
test -z "$(golint .          | tee /dev/stderr)"
echo "go vet"
go vet ./...
# go test -race ./... - Lets disable for now
 
# Run test coverage on each subdirectories and merge the coverage profile.
 
echo "mode: count" > profile.cov
 
# Standard go tooling behavior is to ignore dirs with leading underscors
for dir in $(find . -maxdepth 10 -not -path './.git*' -not -path '*/_*' -type d);
do
if ls $dir/*.go &> /dev/null; then
    go test -covermode=count -coverprofile=$dir/profile.tmp $dir
    if [ -f $dir/profile.tmp ]
    then
        cat $dir/profile.tmp | tail -n +2 >> profile.cov
        rm $dir/profile.tmp
    fi
fi
done
 
go tool cover -func profile.cov
 
# To submit the test coverage result to coveralls.io,
# use goveralls (https://github.com/mattn/goveralls)
# goveralls -coverprofile=profile.cov -service=travis-ci -repotoken t47LG6BQsfLwb9WxB56hXUezvwpED6D11
#
# If running inside Travis we update coveralls. We don't want his happening on Macs
if [ "$TRAVIS" == "true" ]
then
	goveralls -v -coverprofile=profile.cov -service travis.ci -repotoken $COVERALLS_TOKEN
fi
