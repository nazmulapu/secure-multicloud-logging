# Troubleshooting Notes

Quick reminders for the common bumps I’ve hit.

## Deploy/Provision
- **Azure VM size unavailable** → switch `azure_region` or `vm_size` in `terraform/azure/variables.tf` (e.g., `westeurope`, `Standard_B1ms`). Verify available SKUs with `az vm list-skus --location <region> --size Standard_B`.
- **Terraform lock** → if you’re sure no run is active, `terraform force-unlock <LOCK_ID>` or cancel the stuck run in Terraform Cloud.

## Connectivity
- **SSH fails** → confirm inventory IPs (`ansible/inventory/hosts.yml`), rerun `scripts/sync-terraform-outputs.sh`, and make sure your current public IP is allowed in Terraform variables/NSG.
- **Port 6514 unreachable** → check Azure NSG rule `Rsyslog-TLS-Outbound` and AWS security group ingress for 6514.

## Pipeline
- **No files in `/var/log/remote`** → on Azure: `sudo systemctl status rsyslog`, `sudo journalctl -u rsyslog`; ensure the CA cert was copied (playbook does this). On AWS: `sudo journalctl -u rsyslog` for TLS errors.
- **Files present but nothing in Elasticsearch** → check permissions (`sudo ls -l /var/log/remote`), then `docker logs logstash`. Restart Logstash if sincedb got stuck (`docker restart logstash`).
- **Timestamps off** → adjust the date filter in `ansible/roles/elk-docker/templates/logstash-syslog.conf.j2` to match source timezone.

## Kibana/Elasticsearch
- **Kibana 5601 unreachable** → `docker ps`, `docker logs kibana`, ensure security group allows port 5601 from your IP. Restart container if it’s boot-looping.
- **Cluster red / no indices** → `curl localhost:9200/_cluster/health`. If red, check disk (`df -h`), memory (`docker stats`), or shard issues (`curl _cat/shards`). Free space or bump heap as needed.

## Handy Commands
```bash
./scripts/test-deployment.sh <collector_ip> <generator_ip>   # full smoke test
ssh ubuntu@<collector_ip> "docker ps"                        # container status
ssh ubuntu@<collector_ip> "sudo tail -f /var/log/syslog"     # rsyslog server logs
ssh azureuser@<generator_ip> "sudo journalctl -u rsyslog -f" # rsyslog client logs
```

If something weird persists, capture the relevant logs and configs and throw them into a GitHub issue or email—90% of the fixes start with looking at rsyslog or Logstash logs.***
