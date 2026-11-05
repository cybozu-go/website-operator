---
name: update-builder-images
description: Update the website-operator build container images (ubuntu / BASE_TAG / nginx / node / python) to the latest versions. Covers the ubuntu base digest, nginx stable, Node.js and pnpm SHA256 checksums, and the TAG revisions. Use whenever the user wants to refresh or bump the builder images, even if they do not name them. Triggers include "update the builder images", "bump nodejs / pnpm", "update nginx", "update the ubuntu base", or a new Node.js, pnpm, nginx, or ubuntu release being mentioned.
---

# Update builder images

## Prerequisites

- Tools: `crane`, `jq`, `curl`, `sha256sum`, `git`. Docker is optional (see step 4).
- Network access to `ghcr.io`, `nodejs.org`, `github.com`, `api.github.com`, and `nginx.org`. Inside the sandbox these hosts may need to be allowed. If a request is refused, report which host.
- Run every command from the repository root.

## Target files

| File | Contents |
| --- | --- |
| `containers/BASE_TAG` | `<ubuntu tag>@sha256:<digest>` |
| `containers/ubuntu/TAG` | ubuntu base tag (no revision suffix) |
| `containers/nginx/Dockerfile` | `NGINX_VERSION=<version>-1` |
| `containers/nginx/TAG` | `<nginx version>.<revision>` |
| `containers/node/Dockerfile` | `NODE_VERSION`, `PNPM_VERSION`, and the 4 `--checksum=sha256:...` values |
| `containers/node/TAG` | `<node version>.<revision>` |
| `containers/python/TAG` | `<python version>.<revision>` |

Every file above ends with a trailing newline.

`containers/elasticsearch` does not use BASE_TAG and is out of scope for this skill. Handle it only when explicitly asked.

## Version formats

The Dockerfiles are the source of truth for the current values. Read them from the file; do not rely on values written in this document.

- `NODE_VERSION` has no `v` prefix (`24.22.1`).
- `PNPM_VERSION` has a `v` prefix (`v11.25.0`). The Dockerfile URL is `.../releases/download/${PNPM_VERSION}/...`, so the prefix must be kept.
- `NGINX_VERSION` carries a package suffix (`1.30.4-1`). `containers/nginx/TAG` does not (`1.30.4.3`).

## Update policy

- **ubuntu base**: the latest `24.04.YYYYMMDD` tag in `ghcr.io/cybozu/ubuntu`. Get the digest with `crane digest`.
- **nginx**: the latest patch in the nginx.org stable line that the Dockerfile already uses (stable uses even minor numbers).
- **Node.js / pnpm**: the latest minor.patch within the major the Dockerfile already uses. Do not change the major yourself; that is a human decision.
- **python**: keep the current 3.12 tag line and bump only the revision when the base changes.

## TAG revision rules

- When the version changes: reset to `<version>.1` (example: node `24.22.1.3` → `24.22.2.1`).
- When the version stays the same but the contents change, for example a base update: increment the trailing revision by 1 (example: python `3.12.3.5` → `3.12.3.6`). Apply this to nginx, node, and python.
- ubuntu uses the base tag as-is. It has no revision suffix. When the ubuntu base changes, `ubuntu/TAG` and `BASE_TAG` both change to the new tag.

## Procedure

Shell variables do not carry over between tool calls. Define each variable in the call that uses it. Step 1 derives the majors from the Dockerfiles, and step 0 saves the old values for the report.

### 0. Record the current values

```sh
cat > "$TMPDIR/builder-old.env" <<EOF
OLD_UBUNTU_TAG=$(cat containers/ubuntu/TAG)
OLD_NGINX_VERSION=$(sed -n 's/^ARG NGINX_VERSION=//p' containers/nginx/Dockerfile)
OLD_NODE_VERSION=$(sed -n 's/^ARG NODE_VERSION=//p' containers/node/Dockerfile)
OLD_PNPM_VERSION=$(sed -n 's/^ARG PNPM_VERSION=//p' containers/node/Dockerfile)
EOF
cat "$TMPDIR/builder-old.env"
```

### 1. Find the latest versions

```sh
# Majors and the nginx line, read from the Dockerfiles
NODE_MAJOR=$(sed -n 's/^ARG NODE_VERSION=\([0-9]*\)\..*/\1/p' containers/node/Dockerfile)
PNPM_MAJOR=$(sed -n 's/^ARG PNPM_VERSION=v\([0-9]*\)\..*/\1/p' containers/node/Dockerfile)
NGINX_LINE=$(sed -n 's/^ARG NGINX_VERSION=\([0-9]*\.[0-9]*\)\..*/\1/p' containers/nginx/Dockerfile)

# Latest ubuntu base tag and its digest
crane ls ghcr.io/cybozu/ubuntu | grep '^24\.04\.' | sort -V | tail -1
crane digest ghcr.io/cybozu/ubuntu:<tag>

# Latest nginx stable patch in the current line (the version is the part between "nginx_" and "-1~")
curl -sfS https://nginx.org/packages/ubuntu/pool/nginx/n/nginx/ \
  | grep -o "nginx_${NGINX_LINE}\.[0-9]*-1~noble_amd64\.deb" | sort -uV | tail -1

# Latest release in the current Node.js major (NODE_VERSION form: no v)
curl -sfS https://nodejs.org/dist/index.json \
  | jq -r --arg prefix "v${NODE_MAJOR}." '[.[] | select(.version | startswith($prefix))][0].version'

# Latest non-prerelease pnpm in the current major (tag_name has the v, like PNPM_VERSION)
curl -sfS 'https://api.github.com/repos/pnpm/pnpm/releases?per_page=100' \
  | jq -r '.[] | select(.prerelease == false) | .tag_name' | grep "^v${PNPM_MAJOR}\." | sort -V | tail -1
```

If nothing newer than the current Dockerfile values exists, stop and report "no update needed".

### 2. Get the SHA256 checksums

Node.js: use the official SHASUMS file. `<NODE_VERSION>` has no `v`; the URL adds it.

```sh
curl -sfS https://nodejs.org/dist/v<NODE_VERSION>/SHASUMS256.txt \
  | grep -E 'linux-(x64|arm64)\.tar\.gz$'
```

pnpm: use the asset digest from GitHub Releases. `<PNPM_VERSION>` includes the `v`.

```sh
curl -sfS https://api.github.com/repos/pnpm/pnpm/releases/tags/<PNPM_VERSION> \
  | jq -r '.assets[] | select(.name | test("pnpm-linux-(x64|arm64)\\.tar\\.gz$")) | "\(.name) \(.digest)"'
```

Remove the `sha256:` prefix from `digest` before writing it into the Dockerfile.

### 3. Edit the files

- Edit the files listed in the table above. When only the revision changes, change only the `TAG` file.
- Keep the trailing newline in every file. `git diff` should not show `\ No newline at end of file`. CI and `e2e/Makefile` read these files with `$(cat ...)`, which strips the newline, so it does not affect the build.
- The tag part of `ubuntu/TAG` and `BASE_TAG` must match.
- When the base is updated, bump the revisions of nginx, node, and python according to the rules above. ubuntu has no revision to bump.

### 4. Verify

```sh
# No old version strings remain (the values come from step 0)
. "$TMPDIR/builder-old.env"
grep -rn -e "$OLD_NODE_VERSION" -e "$OLD_PNPM_VERSION" -e "$OLD_NGINX_VERSION" containers/ .github/
```

Investigate every hit. A hit is acceptable only when it is an unrelated string, not a pinned version.

Check the Node.js and pnpm archives. Download them into a fresh directory, never into the repository.

```sh
REPO=$(pwd)
DIR=$(mktemp -d "$TMPDIR/builder-XXXX")
cd "$DIR"
curl -sfSLO https://nodejs.org/dist/v<NODE_VERSION>/node-v<NODE_VERSION>-linux-x64.tar.gz
curl -sfSLO https://nodejs.org/dist/v<NODE_VERSION>/node-v<NODE_VERSION>-linux-arm64.tar.gz
curl -sfSLO https://github.com/pnpm/pnpm/releases/download/<PNPM_VERSION>/pnpm-linux-x64.tar.gz
curl -sfSLO https://github.com/pnpm/pnpm/releases/download/<PNPM_VERSION>/pnpm-linux-arm64.tar.gz

# Node.js: the downloads must match the official SHASUMS file
curl -sfSL -o SHASUMS256.txt https://nodejs.org/dist/v<NODE_VERSION>/SHASUMS256.txt
grep -E 'linux-(x64|arm64)\.tar\.gz$' SHASUMS256.txt | sha256sum -c -

# The four --checksum values in the Dockerfile must equal the archives' hashes.
# An empty diff means they match.
grep -o 'sha256:[0-9a-f]\{64\}' "$REPO/containers/node/Dockerfile" | sed 's/^sha256://' | sort > expected.txt
sha256sum node-*.tar.gz pnpm-*.tar.gz | awk '{print $1}' | sort > actual.txt
diff expected.txt actual.txt && echo "checksums match"
cd "$REPO"
```

`ADD --checksum` also verifies these during the build. This check exists to catch a mismatch before building.

Check the ubuntu base. The tag and digest in `BASE_TAG` must match what the registry reports.

```sh
UBUNTU_TAG=$(cat containers/ubuntu/TAG)
test "$(cat containers/BASE_TAG)" = "${UBUNTU_TAG}@$(crane digest ghcr.io/cybozu/ubuntu:${UBUNTU_TAG})" \
  && echo "BASE_TAG matches"
```

Lint the Dockerfile if Docker is available:

```sh
docker build --check containers/<image>
```

If Docker is not installed, or the installed version does not support `--check`, record that in the report. Do not treat it as a failure of the update.

### 5. Report

Produce a table of old and new values, using the values from step 0. Include the verification results from step 4. Changing the files is enough; do not commit. Commit and push only when asked. Follow the existing commit history for the message style (for example, `Bump Node.js to v24.22.2` or `Update Ubuntu base image to 24.04.20261027`).

## Notes

Stop and report the situation instead of continuing when any of these happen:

- The major version of Node.js or pnpm would change.
- A checksum cannot be obtained from the official source.
- The downloaded archives do not match the checksums in the Dockerfile.
- `BASE_TAG` does not match the registry digest after the update.
