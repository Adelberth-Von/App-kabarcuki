"""Refresh public-domain IANA country labels. Clock/DST rules still come from the OS.

zone.tab is intentionally used: unlike zone1970.tab, it preserves each country's
identifier (e.g. Europe/Brussels is BE, even when clock rules match Paris).
"""
from pathlib import Path
from urllib.request import urlopen
import hashlib

root = Path(__file__).resolve().parents[1]
data = {name: urlopen('https://data.iana.org/time-zones/tzdb/' + name, timeout=30).read()
        for name in ('zone.tab', 'backward')}
countries = {}
for line in data['zone.tab'].decode().splitlines():
    if line and not line.startswith('#'):
        country, _, zone, *_ = line.split()
        countries[zone] = country
links = [line.split()[1:3] for line in data['backward'].decode().splitlines() if line.startswith('Link')]
for _ in range(4):
    for target, alias in links:
        if target in countries and alias not in countries:
            countries[alias] = countries[target]
rows = sorted(countries.items())
comment = '// Generated from public-domain IANA zone.tab + backward; see scripts/update-zone-countries.py.\n'
java = comment + 'package id.kabar.app;\nimport java.util.*;\nfinal class ZoneCountries {\n    static final Map<String,String> ALL = new HashMap<>();\n    static {\n'
java += ''.join('        ALL.put("%s","%s");\n' % row for row in rows)
java += '    }\n}\n'
(root / 'src/id/kabar/app/ZoneCountries.java').write_text(java, encoding='utf-8')
swift = comment + 'enum ZoneCountries {\n    static let all: [String:String] = [\n'
swift += ''.join('        "%s":"%s",\n' % row for row in rows)
swift += '    ]\n}\n'
(root / 'apple/Sources/KabarCore/ZoneCountries.swift').write_text(swift, encoding='utf-8')
(root / 'scripts/zone-data-source.txt').write_text('IANA tzdb; public domain. Country names are localized by the OS.\n' + '\n'.join(name + ' SHA256 ' + hashlib.sha256(blob).hexdigest() for name, blob in data.items()) + '\n', encoding='utf-8')
print('Generated', len(rows), 'country labels on both platforms.')
