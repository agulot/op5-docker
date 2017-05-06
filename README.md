# op5-docker
### Build
```
docker build -t {ContainerName} .
```

## Run
```
docker run --net=host -it --env-file ./op5.env {ContainerName} (--net=host is NOT optimal and need to be corrected. This will be fixed via docker-compose at soem point)
```

## Stop
```
docker stop {ContainerName}
```
