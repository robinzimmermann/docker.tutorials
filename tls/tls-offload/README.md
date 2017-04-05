To copy certs:

```
$ docker cp tlsoffload_certs_1:/x509 .
```

To Wireshark:

Add to `docker-compose.yml` services:

```yml
tcpdump:
  image: corfr/tcpdump
  network_mode: "host"
  volumes:
    - ./tcpdump:/data
  command: ["-i", "any", "-w", "/data/dump.pcap"]
```

```
$ tail -c +1 -f tcpdump/dump.pcap | wireshark -Y "tcp.port==80" -k -i -
```