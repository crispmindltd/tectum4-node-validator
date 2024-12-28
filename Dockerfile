FROM ubuntu:latest

WORKDIR /app


COPY  src/Linux64/Release/exe/lnodeconsole /app/
COPY run.sh /app/run.sh
COPY settings_valid.ini /app/settings.ini
RUN apt-get update && apt-get install -y iputils-ping && apt-get install -y telnet
RUN chmod +x /app/lnodeconsole
RUN chmod +x /app/run.sh
EXPOSE 50000
CMD ["/app/run.sh"]