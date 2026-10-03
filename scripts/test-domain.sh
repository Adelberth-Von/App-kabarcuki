#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p work/qa-classes
curl --fail --location --silent --show-error https://repo.maven.apache.org/maven2/org/json/json/20240303/json-20240303.jar -o work/json.jar
javac --release 8 -encoding UTF-8 -cp work/json.jar -d work/qa-classes src/id/kabar/app/{ZoneCountries,StatusLogic,Pairing,GpsPoint,KabarState,Relay,ScopedFiles}.java tests/DomainTests.java
java -cp work/qa-classes:work/json.jar id.kabar.app.DomainTests
