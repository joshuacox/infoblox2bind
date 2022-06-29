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
using /tmp/555_All DNS Objects.csv
```

You can also specify the input file as the only argument:

```
./infoblox2bind.bash /tmp/555_All\ DNS\ Objects.csv
```

This will output a few files.

```
named.conf # This is a generated named.conf
named.conf.example.com # This is a generated named.conf.example.com
zone.example.com # This is the generated zonefile
run # This can be used to test the above files in a container
```

### Debug

Get some extra verbosity:

```
export VERBOSE=11
```


