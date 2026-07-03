#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "error: $*" >&2
  exit 1
}

for path in \
  "Sources/FVendors/SwiftUI" \
  "Sources/FVendors/UIKit" \
  "Sources/FVendors/Common/FWrapper.swift"
do
  if [[ -e "$path" ]]; then
    fail "FVendors umbrella must stay core-only; move UI helpers to FVendorsExt: $path"
  fi
done

if grep -q '@_exported[[:space:]]\+import[[:space:]]\+FVendorsExt' Sources/FVendors/FVendors.swift; then
  fail "FVendors must not re-export FVendorsExt; app targets should import FVendorsExt explicitly for UI helpers"
fi

if grep -R -n -E '^[[:space:]]*import[[:space:]]+(SwiftUI|UIKit)\b' --include '*.swift' Sources/FVendors; then
  fail "FVendors umbrella must not contain SwiftUI/UIKit code; keep UI helpers in FVendorsExt"
fi

if grep -R -n -E '\b(EnvironmentClient|FeatureFlagClient|ReachabilityClient|AuthTokenClient)\b' --include '*.swift' Sources; then
  fail "new package-owned client APIs require approved hard-gate evidence before entering Sources"
fi

swift package dump-package | python3 -c '
import json
import sys

package = json.load(sys.stdin)
products = {product.get("name"): product.get("targets", []) for product in package.get("products", [])}
fvendors_ext_targets = products.get("FVendorsExt")
if fvendors_ext_targets != ["FVendorsExt"]:
    raise SystemExit(
        "error: FVendorsExt must remain a first-class SwiftPM library product "
        f"targeting FVendorsExt; got {fvendors_ext_targets}"
    )

for target in package.get("targets", []):
    if target.get("name") == "FVendors":
        dependencies = []
        for dependency in target.get("dependencies", []):
            if "byName" in dependency:
                dependencies.append(dependency["byName"][0])
            elif "target" in dependency:
                dependencies.append(dependency["target"][0])
            elif "product" in dependency:
                dependencies.append(dependency["product"][0])
        expected = {"FVendorsClientsLive", "FVendorsClients", "FVendorsModels"}
        dependency_set = set(dependencies)
        if dependency_set != expected:
            raise SystemExit(
                "error: FVendors target dependencies must stay core-only; "
                f"expected {sorted(expected)}, got {sorted(dependency_set)}"
            )
        break
else:
    raise SystemExit("error: Package.swift does not define FVendors target")
'

echo "FVendors boundary check passed"
