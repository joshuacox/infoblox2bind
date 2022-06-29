all: .cid

zone.example.com:
	./infoblox2bind.bash ./input.csv

.cid: zone.example.com
	bash run

clean:
	test -f .cid
	-docker kill `cat .cid`
	-docker rm `cat .cid`
	rm .cid

logs:
	docker logs `cat .cid`

enter:
	docker exec -it `cat .cid` /bin/bash

dig:
	dig @0 ww2.example.com
