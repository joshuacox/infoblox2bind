$(eval KUBASH_DIR := $(HOME)/.kubash)
$(eval KUBASH_BIN := $(KUBASH_DIR)/bin)

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

test:
	bats .ci/test.bats

bats:
	$(eval TMP := $(shell mktemp -d --suffix=BATSTMP))
	cd $(TMP) \
	&& git clone --depth=1 https://github.com/sstephenson/bats.git
	ls -lh $(TMP)
	ls -lh $(TMP)/bats
	cd $(TMP)/bats \
	&& sudo ./install.sh /usr/local
	rm -Rf $(TMP)
