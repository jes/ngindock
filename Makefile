build/ngindock: build.header lib/Ngindock/*.pm lib/Ngindock.pm bin/ngindock
	mkdir -p build/
	cat $^ | grep -v 'use Ngindock' > build/ngindock

install: build/ngindock
	install -m 0755 build/ngindock /usr/bin/ngindock
