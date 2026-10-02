#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p work/apple-tests apple/Fixtures
curl -fsSL https://repo.maven.apache.org/maven2/org/json/json/20240303/json-20240303.jar -o work/apple-tests/json.jar
javac -encoding UTF-8 -cp work/apple-tests/json.jar -d work/apple-tests src/id/kabar/app/Pairing.java src/id/kabar/app/StatusLogic.java src/id/kabar/app/GpsPoint.java src/id/kabar/app/KabarState.java tests/Interop.java
java -cp work/apple-tests:work/apple-tests/json.jar id.kabar.app.Interop generate apple/Fixtures
(cd apple && swift test)
java -cp work/apple-tests:work/apple-tests/json.jar id.kabar.app.Interop verify apple/Fixtures
