
![Logo](https://avatars.githubusercontent.com/u/8182156?s=50&v=4)
# Repmgr checker for Safewalk MT
This docker service aims to protect Safewalk MT of multiple postgres SQL servers  running as primary at the same time. The service consist of a docker container that runs a bash script monitoring the "cluster show" output and take actions in case of detecting more than 1 postgres SQL servers running as primary.

The fix will be applied just 1 time, if the cluster remains on a unhealthy status a notificacion can be sent to the administrator to take furter actions


## Features

- Detect if exist more than 1 postgres SQL servers running as primary
- Wait 60 seconds before applying the fix 
- Fix the cluster by rebooting the service that should not be primary
- Log messages about the status of the cluster after and before applying de fix


## Installation

Clone this repo on any of the docker swarm nodes

```bash
 docker stack deploy -c service-stack.yml repmgr-checker
```

Check if the service is running correctly

``` bash
docker service  logs repmgr-checker-service_repmgr-checker
```
The folloing output is a sample of a healthly repmgr cluster

``` bash
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    | INFO: The number of PG in primary is: 1  - do nothing
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    | postgresql-repmgr 16:00:34.31
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    | postgresql-repmgr 16:00:34.32 Welcome to the Bitnami postgresql-repmgr container
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    | postgresql-repmgr 16:00:34.32 Subscribe to project updates by watching https://github.com/bitnami/containers
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    | postgresql-repmgr 16:00:34.32 Submit issues and feature requests at https://github.com/bitnami/containers/issues
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    | postgresql-repmgr 16:00:34.32
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    |
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    |  ID   | Name | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    | ------+------+---------+-----------+----------+----------+----------+----------+-----------------------------------------------------------------------------------------
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    |  1000 | pg-0 | primary | * running |          | default  | 100      | 7        | user=repmgr password=repmgrpassword host=pg-0 dbname=repmgr port=5432 connect_timeout=5
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    |  1001 | pg-1 | standby |   running | pg-0     | default  | 100      | 7        | user=repmgr password=repmgrpassword host=pg-1 dbname=repmgr port=5432 connect_timeout=5
repmgr-checker-service_repmgr-checker.1.kgw55ehxrqei@MT-QA-Node-LAN-1    |  1002 | pg-2 | standby |   running | pg-0     | default  | 100      | 7        | user=repmgr password=repmgrpassword host=pg-2 dbname=repmgr port=5432 connect_timeout=5
```

