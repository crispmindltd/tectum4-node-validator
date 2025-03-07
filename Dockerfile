FROM ubuntu:latest

WORKDIR /app

RUN apt-get update && apt-get install -y iputils-ping telnet mc libcurl4

COPY  src/Linux64/Release/exe/lnodeconsole /app/
COPY run.sh /app/run.sh
RUN chmod +x /app/lnodeconsole
RUN chmod +x /app/run.sh
