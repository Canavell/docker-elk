#!/bin/bash

#Our CA
openssl genrsa -des3 -passout pass:STRONG_PASSWORD -out rootCA.key 4096

openssl req -x509 -new -nodes -key rootCA.key -sha256 -passin pass:STRONG_PASSWORD -subj "/CN=RU" -days 15000 -out rootCA.crt