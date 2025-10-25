# Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           AZURE CLOUD                            │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Log Generator VM (Standard_B1ms)                      │    │
│  │  ┌──────────────┐      ┌─────────────────┐            │    │
│  │  │ Log Scripts  ├─────►│  Rsyslog Client │            │    │
│  │  │  + Systemd   │      │   (TLS Enabled) │            │    │
│  │  └──────────────┘      └────────┬────────┘            │    │
│  │                                  │                    │    │
│  └──────────────────────────────────┼────────────────────┘    │
│                                     │                         │
└─────────────────────────────────────┼─────────────────────────┘
                                      │  TLS 6514 (self-signed)
                                      │
┌─────────────────────────────────────▼─────────────────────────┐
│                            AWS CLOUD                           │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Log Collector EC2 (m7i-flex.large)                    │  │
│  │  ┌────────────────┐    ┌──────────────────┐            │  │
│  │  │ Rsyslog Server │───►│    Logstash      │            │  │
│  │  │  (TLS 6514)    │    │  (Docker)        │            │  │
│  │  └────────────────┘    └────────┬─────────┘            │  │
│  │                                  │                     │  │
│  │                         ┌────────▼─────────┐            │  │
│  │                         │  Elasticsearch   │            │  │
│  │                         │  (Docker)        │            │  │
│  │                         └────────┬─────────┘            │  │
│  │                                  │                     │  │
│  │                         ┌────────▼─────────┐            │  │
│  │                         │     Kibana       │◄───────────┤  │
│  │                         │   (Docker)       │            │  │
│  │                         └──────────────────┘            │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                                     ▲
                                     │
                              Browser hits Kibana
                              (`http://<ip>:5601`)
```

## Components at a Glance
- **Azure generator**: Ubuntu 22.04 VM (Standard_B1ms). Runs `scripts/generate-logs.sh` on a systemd timer, forwards via rsyslog with GnuTLS. NSG allows SSH from a trusted CIDR and outbound 6514 to AWS.
- **AWS collector**: Ubuntu 22.04 EC2 (m7i-flex.large). Docker Compose brings up Elasticsearch, Logstash, and Kibana; `ansible/roles/rsyslog-server` enables TLS rsyslog that writes to `/var/log/remote/<host>/<program>.log`.
- **Certificates**: Ansible’s `rsyslog-server` role generates the CA + server cert on the collector and shares the CA with the generator so rsyslog can validate the TLS endpoint.

## End-to-End Flow
1. Log scripts on the Azure VM emit Apache/auth/app/system events and send them to syslog.
2. Azure rsyslog client ships the messages to AWS over TLS 6514.
3. AWS rsyslog server writes files under `/var/log/remote/…`.
4. Logstash tails those files, parses, and indexes into Elasticsearch (`syslog-YYYY.MM.DD`).
5. Kibana exposes the data at `http://<collector-ip>:5601`.

## Security Highlights
- SSH access restricted to known CIDRs; password auth disabled on both hosts.
- Kibana limited to management CIDRs; Elasticsearch bound to localhost inside the container network.
- Encrypted EBS volume on the collector; Azure NSG limits inbound to SSH and allows outbound TLS to the collector.

## Future Ideas
- Terminate HTTPS in front of Kibana (load balancer or reverse proxy).
- Expand to multi-node Elasticsearch for high availability.
- Move both VMs to private subnets once VPN/peering is available.
