# op5-docker
> This build requires additional files not included in this git repo. id_rsa needs to be created and the public keys added to the Master servers .ssh/authorized_keys so the the contaner can ssh to the master servers. You should also create an authorized_key file that contains ALL master servers public. It's not 100% required but if you do not, you will need to modify the Dockerfile so that it does not attempt to add it.

> Currently the docker_compose.yml is not used but will be incorperate once OP5 can seperate mysql and other services from the need to run on the same host.

### Deploy Docker via docker deply script
```
deploy_docker.sh -r {type} -s {Site} -h {Hostname} -i {Host IP} -m {Master01_FQDN,Master01_IP(,Master02_FQDN,Master02_IP)}
```
<dl>
  <dt>EXAMPLE:
	<dd>```
depoly_docker.sh -r poller -s PoP -n testpoller001 -i 4.4.4.4 -m op5-master001.op5.com,1.1.1.1,op5-master002.op5.com,2.2.2.2
```
</dl>

> In this example an op5 poller named testpoller001 would be deployed to a server at ip 4.4.4.4 and connected to two masters.  One master named op5-master001.op5.com at IP 1.1.1.1 and another master named op5-master002.op5.com at IP 2.2.2.2

## Run
> This is done automatically during the deploy_docker script
```
run_op5.sh -n {Hostname}
```

## Stop
```
docker stop {ContainerID}
```
