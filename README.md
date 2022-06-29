# infoblox2bind
convert infoblox 2 bind zone


### Usage

You might want to export some variables before running.

Set the input file:

```
export INPUT_CSV_FILE='/tmp/555_All DNS Objects.csv'
```

Set the ZONE:

```
export ZONE=example.org
```

Set the IP of this name server:

```
export THIS_SERVER_IP=10.0.0.1}
```

```
export SERIAL=202206281738
export REFRESH=604800
export RETRY=86400
export TTL=604800
export EXPIRE=2419200
export NEGATIVE_CACHE_TTL=604800
```

Then run the script:

```
./infoblox2bind.bash
```

You can also specify the input file as the only argument:

```
./infoblox2bind.bash /tmp/555_All\ DNS\ Objects.csv
```

This will output a few files.

```
renamed '/tmp/tmp.l3W6nA7Pl3/zone.example.com' -> '/tmp/infoblox2bind/zone.example.com'
renamed '/tmp/tmp.l3W6nA7Pl3/named.conf' -> '/tmp/infoblox2bind/named.conf'
renamed '/tmp/tmp.l3W6nA7Pl3/named.conf.example.com' -> '/tmp/infoblox2bind/named.conf.example.com'
renamed '/tmp/tmp.l3W6nA7Pl3/run' -> '/tmp/infoblox2bind/run'
```

1. named.conf # This is a generated named.conf
1. named.conf.example.com # This is a generated named.conf.example.com
1. zone.example.com # This is the generated zonefile
1. run # This can be used to test the above files in a container

### Debug

Get some extra verbosity:

```
export VERBOSE=11
```


