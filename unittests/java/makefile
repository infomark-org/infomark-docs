.PHONY: clean

DOCKER_CALL = docker run --rm -it --net="none"
DOCKER_IMAGE = patwie/test_java_submission:v3

clean:
	rm *.zip || true
	rm */*.zip || true
	rm */*.class || true
	rm */*/*.class || true
	rm */*/*/*.class || true
	rm */*.pdf || true

prepare: clean
	cd tasks && pdflatex sheet.tex
	zip -r solution.zip \
		solution/* \
		task/*.pdf

	zip -r student_template.zip  \
		student_template_0.1 \
		task/*.pdf

	cd unittest_public_0.1 && \
		zip -r unittest_public_0.1.zip ./ && \
		cd .. && \
		mv unittest_public_0.1/unittest_public_0.1.zip .

	cd unittest_private_0.1 && \
		zip -r unittest_private_0.1.zip ./ && \
		cd .. && \
		mv unittest_private_0.1/unittest_private_0.1.zip .



simulate-template:
	echo "RUN public tests 0.1"
	cp student_template.zip /tmp/submission.zip
	cp unittest_public_0.1.zip /tmp/unittest.zip

	$(DOCKER_CALL)                                      \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  $(DOCKER_IMAGE)

	echo "RUN private tests 0.1"
	cp student_template.zip /tmp/submission.zip
	cp unittest_private_0.1.zip /tmp/unittest.zip

	$(DOCKER_CALL)                                      \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  $(DOCKER_IMAGE)

	sudo rm /tmp/submission.zip
	sudo rm /tmp/unittest.zip


simulate-solution:
	echo "RUN public tests 0.1"
	cp solution.zip /tmp/submission.zip
	cp unittest_public_0.1.zip /tmp/unittest.zip

	$(DOCKER_CALL)                                      \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  $(DOCKER_IMAGE)

	echo "RUN private tests 0.1"
	cp solution.zip /tmp/submission.zip
	cp unittest_private_0.1.zip /tmp/unittest.zip

	$(DOCKER_CALL)                                      \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  $(DOCKER_IMAGE)

	sudo rm /tmp/submission.zip
	sudo rm /tmp/unittest.zip
