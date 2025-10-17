.PHONY: lint run test clean

lint:
	shellcheck publish-chromium-layer.sh

run:
	./publish-chromium-layer.sh

test:
	bash -n publish-chromium-layer.sh

clean:
	rm -f layer_arn.txt