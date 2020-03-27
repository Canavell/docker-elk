#!/bin/bash

#Elasticsearch
openssl genrsa -out elastic.key 2048

openssl req -new -sha256 -key elastic.key -subj "/CN=elasticsearch" -addext "subjectAltName = DNS:elasticsearch" -out elastic.csr

openssl x509 -req -in elastic.csr -CA rootCA.crt -CAkey rootCA.key -passin pass:STRONG_PASSWORD -CAcreateserial -out elastic.crt -days 365 -sha256

#Kibana
openssl genrsa -out kibana.key 2048

openssl req -new -sha256 -key kibana.key -subj "/CN=kibana" -out kibana.csr

openssl x509 -req -in kibana.csr -CA rootCA.crt -CAkey rootCA.key -passin pass:STRONG_PASSWORD -CAcreateserial -out kibana.crt -days 365 -sha256

#Logstash (optionally)
openssl genrsa -out logstash.key 2048

openssl req -new -sha256 -key logstash.key -subj "/CN=logstash" -out logstash.csr

openssl x509 -req -in logstash.csr -CA rootCA.crt -CAkey rootCA.key -passin pass:STRONG_PASSWORD -CAcreateserial -out logstash.crt -days 365 -sha256

openssl pkcs8 -in logstash.key -topk8 -nocrypt -out logstash.pkcs8.key 