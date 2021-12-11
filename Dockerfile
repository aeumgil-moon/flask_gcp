# Use the official lightweight Python image.
# https://hub.docker.com/_/python
# 가져올 이미지
FROM ubuntu:18.04

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# Python
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \ 
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get -y install software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update --fix-missing && \
    apt-get -y install --fix-missing python3.8 && \
    apt-get -y install --fix-missing python3.8-dev && \
    apt-get -y install --fix-missing python3-pip && \
    python3.8 -m pip install pip --upgrade

ENV HOME .

# mecab start
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata g++ git curl
RUN apt-get install python3-setuptools
RUN apt-get install -y default-jdk default-jre
# mecab end

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

# Install production dependencies.
RUN pip install -r requirements.txt

# mecab start
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 6
RUN update-alternatives --config python3
RUN cd ${HOME} && \
    curl -s https://raw.githubusercontent.com/konlpy/konlpy/master/scripts/mecab.sh | bash -s
# mecab end

RUN export LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

# Run the web service on container startup. Here we use the gunicorn
# webserver, with one worker process and 8 threads.
# For environments with multiple CPU cores, increase the number of workers
# to be equal to the cores available.
# Timeout is set to 0 to disable the timeouts of the workers to allow Cloud Run to handle instance scaling.
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 aeumgil:app