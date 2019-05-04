.PHONY: clean


clean:
	rm *.zip || true
	rm */*.zip || true
	rm */*.class || true
	rm */*/*.class || true
	rm */*/*/*.class || true
	rm tasks/*.pdf || true
	rm student_template/*.pdf || true

prepare: clean
	cd tasks && pdflatex sheet.tex
	cp tasks/*.pdf student_template/
	zip -r solution.zip solution/* task/*.pdf

	cd student_template && \
		zip -r student_template.zip ./ && \
		cd .. && \
		mv student_template/student_template.zip .

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

	docker run --rm -it --net="none"                    \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  patwie/test_java_submission:v3

	echo "RUN private tests 0.1"
	cp student_template.zip /tmp/submission.zip
	cp unittest_private_0.1.zip /tmp/unittest.zip

	docker run --rm -it --net="none"                    \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  patwie/test_java_submission:v3

	sudo rm /tmp/submission.zip
	sudo rm /tmp/unittest.zip


simulate-solution:
	echo "RUN public tests 0.1"
	cp solution.zip /tmp/submission.zip
	cp unittest_public_0.1.zip /tmp/unittest.zip

	docker run --rm -it --net="none"                    \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  patwie/test_java_submission:v3

	echo "RUN private tests 0.1"
	cp solution.zip /tmp/submission.zip
	cp unittest_private_0.1.zip /tmp/unittest.zip

	docker run --rm -it --net="none"                    \
	  -v /tmp/submission.zip:/data/submission.zip:ro    \
	  -v /tmp/unittest.zip:/data/unittest.zip:ro        \
	  patwie/test_java_submission:v3

	sudo rm /tmp/submission.zip
	sudo rm /tmp/unittest.zip
