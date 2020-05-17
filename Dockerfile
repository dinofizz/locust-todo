FROM dinofizz/locust:latest
ADD requirements.txt requirements.txt
RUN pip install -r requirements.txt
ADD locustfile.py locustfile.py