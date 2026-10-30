# Local certificate templates

`ecc-csr.conf` and `gen-certs.sh` are templates for a personal CA and a server certificate. Replace
the example subject and `homelab.example` names before generating certificates. The script creates
private keys; run it only in a directory without existing key material.

Generated keys, certificates, CSRs, and serial files remain local and are ignored by Git. No private
CA is installed by the shared system configuration. Add your own verified CA through
`security.pki.certificateFiles` when a host needs it.

The Caddy host template uses Caddy's internal CA for local TLS and is disabled by default. Configure
your actual domain and ACME credentials before enabling it. PostgreSQL and its Grafana datasource
use certificate paths under their own state directories; supply your own certificate and CA there
before using those templates.
