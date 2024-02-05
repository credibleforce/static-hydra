#!/bin/bash

docker build -t hydra-static .
docker run --rm --entrypoint=/bin/sh -v "${PWD}/binaries/linux/x86_64:/binaries" -v "${PWD}/wordlists:/wordlists" hydra-static -c 'cp $(which hydra) /binaries/hydra && tar -zcvf /opt/password /opt/usernames /wordlists/wordlists.tgz'