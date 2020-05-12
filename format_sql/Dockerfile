FROM alpine:3
MAINTAINER Agustin <guriandoro@gmail.com>

RUN apk add --no-cache python3 py-pip bash
RUN pip3 install --upgrade pip
RUN pip3 install --upgrade sqlparse

COPY format_query.py /format_query.py
RUN chmod +x /format_query.py

ENTRYPOINT ["python3","/format_query.py"]

