#
# dnsdist
#
{% if 'dnsdist' in salt['pillar.get']('netbox:config_context:roles') %}

dnsdist-repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] http://repo.powerdns.com/{{ grains.lsb_distrib_id | lower }} {{ grains.oscodename }}-dnsdist-15 main
    - clean_file: True
    - key_url: https://repo.powerdns.com/FD380FBB-pub.asc
    - file: /etc/apt/sources.list.d/dnsdist.list

dnsdist:
  pkg.installed:
    - refresh: True
    - require:
      - pkgrepo: dnsdist-repo
  service.running:
    - enable: True
    - restart: True
    - require:
      - file: /etc/dnsdist/dnsdist.conf
      - file: /var/lib/dnsdist
      - cmd: generate-DNSCrypt-ProviderCert
      - file: dnsdist-service-override
    - watch:
      - cmd: generate-DNSCrypt-ProviderCert
      - file: /etc/dnsdist/dnsdist.conf
      - file: dnsdist-service-override

/etc/dnsdist/dnsdist.conf:
  file.managed:
    - source: salt://dnsdist/dnsdist.conf.j2
    - template: jinja
    - require:
        - pkg: dnsdist

generate-DNSCrypt-ProviderCert:
  cmd.run:
    - name: /usr/bin/dnsdist -e 'generateDNSCryptProviderKeys("/var/lib/dnsdist/providerPublic.cert", "/var/lib/dnsdist/providerPrivate.key")'
    - creates: /var/lib/dnsdist/providerPrivate.key
    - require:
      - pkg: dnsdist
      - file: /var/lib/dnsdist

/var/lib/dnsdist:
  file.directory:
    - user: _dnsdist
    - group: _dnsdist
    - require:
      - pkg: dnsdist

dnsdist-service-override:
  file.managed:
    - name: /etc/systemd/system/dnsdist.service.d/override.conf
    - source: salt://dnsdist/dnsdist.override.service
    - makedirs: True

{% endif %}
