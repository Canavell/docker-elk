# Conception

* We use EFK stack. This means that stack consists from three parts:
  * **E** for Elasticsearch
  * **F** for Filebeats and Fluentd
  * **K** for Kibana
  
**Notice**: we are not going to use Logstash. It's buggy part of stack and ELK team doesn't suggest to use it.

## "How does it work?"
* Fluentd is an agent on a client host. It makes raw string structured, populates it with host info, then sends directly to Elasticsearch. Fluentd creates **structured** logs.
* Elasticsearch stores, manages and *sometimes* takes part in converting our logs from raw strings into structured logs

```
-Okay, you said Elasticsearch *sometimes* converts raw strings into structured logs, right? 
- Correct. It works together with things called Beats. Beats are the new part of ELK-stack (or in our case EFK) that replace Logstash.
```
* Filebeat. This is an agent on client machine that does at least three things:
  * creates **Ingest Pipeline** in Elasticsearch
  * sends raw log strings populated with host info directly in Elasticsearch
  * creates dashboards in Kibana (optionally)

```
-What is "Ingest Pipeline"? What a mess! I don't get it!
-This is how Elasticsearch replaces Logstash. 
0. Filebeat stores predefined pipelines for different programs like Nginx, Apache, Mysql, etc. 
1. When you setup your Filebeat, it sends those pipelenes into Elasticsearch and creates two things in Elasticsearch: Ingest Pipelines and Index.
2. Then you finally activate your Filebeat and it starts sending logs populated with host info into Elasticsarch. 
When Filebeat sends logs, it specifies two things in HTTP-request: Index and Ingest Pipeline which Filebeat wants to use for particular log string. 
3. Elasticsearch recieves three things: log string, Index name and Ingest Pipeline name. Then
* Elasticsearch takes log string and puts it into Ingest Pipeline (actually it works inside Ingest Node)
* Ingest Pipeline creates structured log
* Elasticsearch takes structured log from Ingest Pipeline and writes it into Index
-Yay, that's pretty simple!
```

When Filebeat sends log it looks like that:
```
curl -X POST localhost:9200/my_index/_doc?pipeline=nginx_pipeline \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "172.17.0.1 - - [24/Dec/2019:10:09:42 +0000] \"GET / HTTP/1.1\" 200 95 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36\" \"-\""
}'
```


# ELK Installation 

* In `./elastalert/smtp_auth_file.yaml` replace `name@gmail.com` and `password` with your actual Gmail username and password
* `$ chmod +x ./ssl/certs/certificates-creator.sh && chmod +x ./ssl/certs/ca-creator.sh`
* Edit `./ssl/certs/certificates-creator.sh` and replace `STRONG_PASSWORD` with really strong password
* Edit `./ssl/certs/ca-creator.sh` and replace `STRONG_PASSWORD` with really strong password
* `$ ./ssl/certs/ca-creator.sh`
* `$ ./ssl/certscertificates-creator.sh`
* Add to ctonrab (don't forget to replace `ELK_STACK` to your actual path)
  * `0 1 * * * cd /ELK_STACK/ssl/certs/certificates-creator.sh && docker-compose restart`
* `$ docker-compose up -d`
* `$ docker exec -ti elasticsearch bash -c "bin/elasticsearch-setup-passwords auto --batch"`
* Copy output and save it somewhere! It's extremly important!
* Copy `kibana` user's password from output above and edit `./kibana/config/kibana.yml`
  * Put `kibana` to `elasticsearch.username` 
  * Put copied password to `elasticsearch.password`
* `$ docker-compose restart kibana`
* Edit `./elastalert/elastalert.yaml` and change `es_password` with newly generated `elastic` password
* Remove `ELASTIC_PASSWORD` env variable from `./docker-compose.yml`
* `$ docker-compose up -d`
* `$ docker-compose restart`
* Go to [Kibana](https:localhost:5601/)
  * User: `elastic`
  * Passord: `use_one_generated_above`


# Creating roles and users

## Fluentd Role
* Go to `Kibana->Management->Security->Role->Create role`
* `Role name`: **fluentd**
* `Elasticsearch->Cluster privilleges`: **monitor**
* `Run as Privileges`: keep it empty
* `Elasticsearch->Index privileges->Privileges`: check all but **All**, **delete**, **delete_index**
* `Elasticsearch->Index privileges->Indices`: **fluentd-*** (check all indexes that connected with fluentd)
## Fluentd User
* `Kibana->Management->Security->User->Create user`
* `Username`: **fluentd**
* `Password`: **whatever_you_want**
* `Confirm password`: **whatever_you_want**
* `Full name`: **Fluentd Agent**
* `Roles`: **fluentd** (from above)


## Filebeat Role
* Go to `Kibana->Management->Security->Role->Create role`
* `Role name`: **filiebeat**
* `Elasticsearch->Cluster privilleges`: **monitor**, **manage_pipeline**, **manage_ingest_pipelines**, **manage_ilm**, **manage_index_templates**
* `Run as Privileges`: keep it empty
* `Elasticsearch->Index privileges->Privileges`: check all but **All**, **delete**, **delete_index**
* `Elasticsearch->Index privileges->Indices`: **filebeat-*** (check all indexes that connected with filebeat)
## Filebeat User
* `Kibana->Management->Security->User->Create user`
* `Username`: **filebeat**
* `Password`: **whatever_you_want**
* `Confirm password`: **whatever_you_want**
* `Full name`: **Filebeat Agent**
* `Roles`: **filebeat** (from above)

Okay, from this point we are ready to get logs from clients.

# Client's machine installation
You have to do it for every client.

### Creating Kibana Space
* Open [Kibana](https:localhost:5601/)
* Create new `Kibana Space` from GUI
* Go to `Kibana's Console` and run `GET /api/spaces/space`
* Copy need `id` from `spaces` output


## Filebeat isntallation
* Install filebeat on clinent's machine
* Copy `./ssl/certs/rootCA.crt` to client's machine `/etc/filebeat/ssl/rootCA.crt`
* Copy `./extensions/beats/filebeat/filebeat.yml` to client's machine `/etc/filebeat/filebeat.yml`
* Edit `/etc/filebeat/filebeat.yml`
* Put `filebeat` to `output.elasticsearch.username` 
* Put `filebeat` user's `password` to `output.elasticsearch.password`
* Put `id` of  `Kibana Space` you've created above in `setup.kibana.space.id`
* Put `["/etc/filebeat/ssl/rootCA.crt"]` in `setup.kibana.ssl.certificate_authorities` 
* Put `["/etc/filebeat/ssl/rootCA.crt"]` in `output.elasticsearch.ssl.certificate_authorities`
* Put your actual `Kibana`s URL in `setup.kibana.host`
* Put your actual `Elasticsearch`'s URL in `output.elasticsearch.hosts`
* Copy `./extensions/beats/filebeat/ingest/nginx/access/default.json` to `/usr/share/filebeat/module/nginx-time/access/ingest/default.json` on client's machine
* `$ sudo filebeat modules enable nginx-time apache mysql system`
* Change your nginx log format wit this definition:
```
log_format  plus '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" $request_time $upstream_response_time';
    access_log  /var/log/nginx/access.log plus;
```
* Go to `/etc/filebeat/modules.d/`
* Edit every module enabled (`nginx.yml`, `system.yml`, `apache.yml`, `mysql.yml`) and put there actual pathes to your log files on client's machine
* `$ sudo filebeat setup`
* `$ sudo filebeat -e`

## Fluentd installation

* Install **td-agent** [See difference between Fluentd and td-agent](https://www.fluentd.org/faqs)
* Copy `./ssl/certs/rootCA.crt` to client's machine `/etc/td-agent/ssl/rootCA.crt`
* Copy `./extensions/fluentd/php.conf` to `/etc/td-agent/php.conf`
* Edit `/etc/td-agent/php.conf`
* Put `/etc/td-agent/ssl/rootCA.crt` in `ca_file` 
* Put `fluentd` in `user`
* Put `fluentd` user's password in `password`
* Set actual `Elasticsearch` URL's in `host`
* Specify your actual log's path in `path`
* `$ systemctl start td-agent`


**Remebmer**: logs should be in PSR format. You can see example in `./extensions/php-logger/index.php`