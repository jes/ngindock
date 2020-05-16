build/ngindock: build.header lib/Ngindock/*.pm lib/Ngindock.pm ngindock
	mkdir -p build/
	cat $^ | sed 's/^use Ngindock/import Ngindock/' > build/ngindock
	chmod +x build/ngindock

install: build/ngindock
	install -m 0755 build/ngindock /usr/bin/ngindock

clean:
	rm -f build/ngindock
