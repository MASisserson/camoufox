# Camoufox Internalization and External Dependency Status

**Status date:** 2026-08-26  
**Scope:** Current Camoufox working tree, Linux x86_64 browser artifact, Python application image, third-party Python dependencies, and runtime external communications.

## Purpose

This document records the controls added while preparing Camoufox for internal use, the artifacts that have been tested, the third-party dependencies that remain, and the external communications that still require a decision or control.

It distinguishes between:

- Implemented source changes
- Controls verified in a candidate image
- Controls not yet validated or promoted
- Build-time external sources
- Runtime external communications
- URLs that remain in inactive code or data

## Executive summary

The current implementation is substantially more controlled than the original upstream behavior:

- Browser installation is explicit rather than an automatic side effect.
- The browser release API defaults to the internal GHES server.
- Automatic uBlock Origin installation is disabled.
- Public-IP HTTPS requests validate certificates.
- The application container includes the local Camoufox Python package and patched browser.
- BrowserForge is packaged as an internally versioned, SHA-256-verified wheel.
- Direct Python dependencies are pinned to the versions used by the tested application build, except optional extras that were not installed.
- Rustup and the Rust compiler are pinned, and `rustup-init` is checked against an approved SHA-256 before execution.

The implementation is not yet fully independent of external sources:

- Python transitive dependencies still download from public PyPI during the image build.
- Optional geolocation features call public IP and GeoIP services.
- The BrowserForge fingerprint dataset package remains externally sourced.
- The pinned-Rust Dockerfile has not yet been rebuilt and validated exactly as committed.
- The BrowserForge wheel candidate has passed tests but has not been promoted to `latest`.
- A formal SCA/SBOM scan and full Firefox telemetry review have not yet been completed.

## Current architecture

```text
Internal GHES Camoufox repository
            |
            +-- Patched Firefox/Camoufox browser build
            |
            +-- Local Camoufox Python package
            |
            +-- Verified BrowserForge wheel
                    |
                    +-- Public PyPI transitive dependencies (remaining)
```

The combined application image contains:

```text
/opt/camoufox/camoufox             Patched browser executable
Python site-packages/camoufox      Modified Camoufox Python package
Python site-packages/browserforge  Internally versioned BrowserForge package
```

`CAMOUFOX_EXECUTABLE_PATH` points the Python package to `/opt/camoufox/camoufox`, avoiding the normal cache lookup and browser-download path.

## Completed work

### Internal browser release source

The Python package defaults to the internal GHES API:

```text
https://github.asurint.com/api/v3
```

The default browser repository is:

```text
SWAT/asurint-camoufox
```

The API root can still be overridden with `CAMOUFOX_GITHUB_API_URL`. Browser release access from the current workstation has not been tested because this workstation cannot reach the internal GHES server.

### Explicit browser installation

`camoufox_path()` no longer downloads a missing or incompatible browser. It raises an error instructing the administrator to run `camoufox fetch` explicitly.

This prevents application startup from silently downloading a browser. The explicit `camoufox fetch` command remains capable of contacting the configured release service.

### uBlock Origin disabled

Automatic default-addon installation is disabled in:

- The Python launch path
- The Python `camoufox fetch` command
- The legacy Go launcher
- The browser preference that activates the uBlock asset bootstrap catalog

The downloader implementation and `uBOAssets.json` remain in the repository for potential future restoration. The catalog contains many external filter-list URLs, but the current internal launch paths do not activate it.

### TLS verification for public-IP discovery

Public-IP requests now use:

```python
verify=True
```

The insecure-warning suppression code was removed. Certificate validation was tested from the Linux runtime environment against all configured public-IP providers.

### Combined browser and Python application image

`Dockerfile.runtime` now installs the local Camoufox Python package and packages the patched browser under `/opt/camoufox`.

The Python launch logic supports a preinstalled browser through:

```text
CAMOUFOX_EXECUTABLE_PATH=/opt/camoufox/camoufox
```

Supporting changes allow the Python package to read the bundled browser version from `application.ini` and resolve bundled font resources relative to the explicit executable.

An end-to-end test successfully launched the browser through the Python API and rendered an in-memory page without downloading another browser.

### Internally versioned BrowserForge wheel

BrowserForge was built as:

```text
browserforge-1.2.4+asurint.1-py3-none-any.whl
```

The Camoufox dependency is pinned to:

```toml
browserforge = "1.2.4+asurint.1"
```

The runtime Dockerfile:

1. Copies the wheel from `third_party/python-wheels/`.
2. Verifies its SHA-256 before installation.
3. Installs the wheel and Camoufox in the same pip resolution.
4. Runs `pip check`.
5. Removes temporary installation inputs.

The candidate image recorded the local wheel URL and matching SHA-256 in its installed `direct_url.json` metadata.

### Verified Rust installer

The builder Dockerfile no longer pipes the mutable `sh.rustup.rs` response directly into Bash. It now:

1. Downloads Rustup `1.29.0` for `x86_64-unknown-linux-gnu`.
2. Verifies the downloaded executable against an approved SHA-256.
3. Installs the minimal Rust `1.97.1` toolchain.
4. Deletes the temporary installer.

The approval record is stored under `approval-records/`.

The Rust installer change is documented in the repository README. The Dockerfile in its current form still requires a complete candidate build and Camoufox rebuild before this control is considered fully validated.

## Verified artifacts and candidates

### Patched Linux x86_64 browser ZIP

```text
Artifact: camoufox-152.0.4-beta.28-lin.x86_64.zip
SHA-256: 8AE917E174E076A6DDC97E755618C8C878076F6CE1FFF7082CF4BE3AA89FE28F
Result: Build and packaging completed successfully
```

This browser build used Rust `1.97.1` through a temporary pinned-toolchain build command. It predates validation of the current pinned-installer Dockerfile implementation.

### BrowserForge wheel

```text
Artifact: browserforge-1.2.4+asurint.1-py3-none-any.whl
SHA-256: 5601AC98166736CE0FE03FE324874AE9726E3228D4D5CCCF440A6F1492EA5D20
Embedded name: browserforge
Embedded version: 1.2.4+asurint.1
```

### BrowserForge wheel candidate image

```text
Image tag: camoufox-application:browserforge-wheel-candidate
Image ID: 42b36881f3d3e78b35cd6b8a16620c97864b49081d105e1e1e13287c77f20343
Status: Tested, not promoted to latest
```

Candidate checks completed successfully:

- BrowserForge wheel SHA-256 verification
- `browserforge==1.2.4+asurint.1` installation
- `pip check`
- Installed provenance metadata referencing the local wheel
- Python-to-Camoufox launch
- In-memory test page with title `internal-browserforge-ok`

## Direct Python dependencies

The Camoufox Python project currently pins these direct runtime drgdrdtsgeependencies:

| Package           |  Pinned version | Current source                       |
| ----------------- | --------------: | ------------------------------------ |
| browserforge      | 1.2.4+asurint.1 | Verified local wheel                 |
| inquirer          |           3.4.1 | Public PyPI                          |
| language-tags     |           1.3.1 | Public PyPI                          |
| lxml              |           6.1.2 | Public PyPI                          |
| numpy             |           2.5.2 | Public PyPI                          |
| orjson            |          3.12.0 | Public PyPI                          |
| platformdirs      |           4.9.6 | Base image / public Python ecosystem |
| playwright        |          1.60.0 | Public PyPI                          |
| PySocks           |           1.7.1 | Public PyPI                          |
| PyYAML            |           6.0.3 | Public PyPI                          |
| requests          |          2.34.2 | Public PyPI                          |
| rich              |          15.0.0 | Public PyPI                          |
| rich-click        |           1.9.8 | Public PyPI                          |
| screeninfo        |           0.8.1 | Public PyPI                          |
| typing-extensions |          4.16.0 | Public PyPI                          |
| ua-parser         |           1.0.2 | Public PyPI                          |

The project declares Python compatibility as `^3.10`; the current application base image uses Python 3.12.

### Optional dependencies

These extras were not installed in the tested application image and therefore have not been assigned internally verified versions:

| Package | Purpose                         | Current constraint           |
| ------- | ------------------------------- | ---------------------------- |
| geoip2  | Optional GeoIP database support | Unpinned optional dependency |
| PySide6 | Optional GUI support            | Unpinned optional dependency |

They must be pinned, reviewed, and mirrored before the corresponding extras are approved for use.

## Remaining transitive Python dependencies

The BrowserForge wheel still resolves these packages from public PyPI:

| Package                      | Observed candidate version | Reason                                    |
| ---------------------------- | -------------------------: | ----------------------------------------- |
| apify-fingerprint-datapoints |                     0.15.0 | BrowserForge statistical fingerprint data |
| click                        |                      8.5.0 | BrowserForge CLI/runtime dependency       |

`apify-fingerprint-datapoints` is high priority because it supplies data used directly in fingerprint generation. Internalizing BrowserForge source without internalizing this dataset does not fully control the fingerprint input chain.

Other transitive packages observed during the candidate build include:

```text
blessed
certifi
charset-normalizer
editor
greenlet
idna
jinxed
markdown-it-py
mdurl
pyee
pygments
readchar
runs
ua-parser-builtins
urllib3
wcwidth
xmod
```

The Camoufox package build also obtains `poetry-core` as an isolated build-system dependency.

Direct version pins do not freeze these transitive packages. A fully reproducible build requires an approved, hashed constraints set or an internal wheelhouse containing every required wheel.

## Runtime external communications

### Public-IP discovery

When automatic geolocation is requested with `geoip=True`, Camoufox may query the following HTTPS services in order until one succeeds:

```text
https://api.ipify.org
https://checkip.amazonaws.com
https://ipinfo.io/ip
https://icanhazip.com
https://ifconfig.co/ip
https://ipecho.net/plain
```

Certificate verification is enabled. This behavior is feature-triggered rather than required for a basic browser launch.

Recommended decision:

- Disable automatic discovery and require the caller to supply an IP, or
- Replace the public list with one approved internal service.

### Proxy IP and timezone lookup

The synchronous and asynchronous APIs contain proxy helper paths that query:

```text
http://ip-api.com/json?fields=query,timezone
```

This endpoint uses plain HTTP in the current code. It should be disabled, replaced with an internal service, or changed to an approved authenticated HTTPS service before the helper is approved.

### GeoIP database downloads

The configured GeoIP sources include:

```text
https://cdn.jsdelivr.net/npm/@ip-location-db/geolite2-city-mmdb/...
https://raw.githubusercontent.com/sapics/ip-location-db/...
https://github.com/daijro/geoip-all-in-one/releases/latest/download/...
```

These downloads are optional, but they remain externally controlled and are not pinned by digest in the current configuration.

Recommended decision:

- Package an approved database in the application image, or
- Host an approved, versioned database internally and verify its digest.

### Browser release access

Browser fetch operations target the internal GHES API by default. They occur only when explicitly requested after the implicit-download change.

The repository configuration still includes additional repository names inherited from upstream. Because the API root defaults to GHES, they are queried under the internal GHES API rather than public GitHub unless `CAMOUFOX_GITHUB_API_URL` is overridden. These fallback entries should be reviewed and removed if they are not approved.

### Intended browsing traffic

The browser connects to destinations supplied by the application. These destinations are business traffic rather than Camoufox callbacks, but they must still be included in deployment network policy and data-flow documentation.

## Inactive external references

The following external references remain present but are currently disabled or non-executable:

- Mozilla Add-ons URL for downloading uBlock Origin
- Public filter-list URLs in `uBOAssets.json`
- Documentation, source-attribution, and support URLs
- Commented uBlock preference and launcher calls

Static scanners may still report these strings. Security documentation should distinguish their presence from reachable runtime behavior. Removing inactive assets entirely would simplify scanning but would conflict with the current decision to retain the code for possible restoration.

## Accepted build-time external sources

Build-time external access is accepted for the current phase but must be documented for architecture and audit review.

| Source                                          | Purpose                                                  |
| ----------------------------------------------- | -------------------------------------------------------- |
| `mcr.microsoft.com`                             | Playwright Python runtime base image                     |
| Docker Hub / Ubuntu image registry              | Builder base image                                       |
| Ubuntu archive and security repositories        | OS packages and maintainer scripts                       |
| Public PyPI / `files.pythonhosted.org`          | Python wheels and build dependencies                     |
| `static.rust-lang.org`                          | Verified Rustup executable and Rust toolchain components |
| Mozilla infrastructure                          | Firefox source bootstrap and build toolchains            |
| GitHub and GitLab sources used by build scripts | Optional tools, source inputs, and maintenance scripts   |

The Rustup executable is versioned and checksum-verified. The later Rust toolchain downloads remain dependent on Rust distribution manifests and HTTPS. An internal Rust distribution mirror is the stronger long-term control.

## Remaining risks and gaps

1. **Transitive Python dependencies are not locked.** Candidate builds can resolve newer transitive versions without a Camoufox source change.
2. **Public PyPI remains required.** The application image cannot yet build with `--no-index`.
3. **BrowserForge data remains external.** `apify-fingerprint-datapoints` must be reviewed and internalized.
4. **Optional geolocation communicates externally.** Public IP, timezone, and database endpoints need an explicit policy decision.
5. **Plain HTTP remains in proxy lookup.** `ip-api.com` traffic is not protected by TLS.
6. **The pinned-Rust Dockerfile is not fully validated.** A clean builder image and full browser build are still required.
7. **The BrowserForge candidate is not promoted.** The current `latest` tag may still refer to the earlier application image.
8. **No formal SCA/SBOM evidence has been produced.** Package and container scans remain required.
9. **Full Firefox runtime telemetry review is incomplete.** Disabled updater settings do not substitute for network observation and source review.
10. **Licensing review is incomplete.** BrowserForge is Apache-2.0, but all bundled libraries, fonts, browser components, patches, datasets, and notices require formal inventory and legal review.
11. **Working-tree changes are not yet committed.** Current controls and artifacts must be reviewed and committed before they constitute an auditable release.

## Recommended next steps

### Priority 1: complete the Python dependency chain

1. Mirror and review `apify-fingerprint-datapoints`.
2. Build an internally versioned wheel and record its SHA-256.
3. Generate an exact inventory of all transitive packages and versions.
4. Download or build approved wheels for the complete dependency graph.
5. Store the wheels in an approved internal registry or controlled wheelhouse.
6. Change the application build to use `--no-index` and only approved wheels.
7. Add hash verification and `pip check` to the final install process.

### Priority 2: resolve runtime geolocation traffic

1. Determine whether automatic geolocation is a required business feature.
2. If not required, disable automatic public-IP and GeoIP downloads.
3. If required, define one approved internal HTTPS endpoint and one approved database source.
4. Remove the plain-HTTP `ip-api.com` path.
5. Test runtime network behavior with egress logging enabled.

### Priority 3: validate and promote the controlled build

1. Build `camoufox-builder` from the current pinned-Rust Dockerfile.
2. Verify Rustup, Rust, Cargo, and installed target versions.
3. Complete a fresh Linux x86_64 browser build.
4. Rebuild the application image with the new browser and wheelhouse.
5. Run Python and GUI smoke tests.
6. Generate an SBOM and run SCA/container scans.
7. Record artifact and image digests.
8. Promote only the reviewed candidate tags.

## Evidence to retain

For each approved release, retain:

- Git commit IDs for Camoufox and BrowserForge
- Upstream base tags and commits
- Internal package versions
- Source and wheel SHA-256 values
- Builder and application image digests
- Browser ZIP digest
- Dependency lock or wheelhouse manifest
- SCA, container, and malware-scan results
- Approval tickets and reviewers
- Smoke-test output
- Runtime network-observation results

## Status conclusion

The current candidate demonstrates that Camoufox can launch using an internally versioned and verified BrowserForge wheel without fetching BrowserForge from Daijro at build time. The primary remaining dependency-control problem is the public PyPI transitive dependency graph, beginning with `apify-fingerprint-datapoints`. The primary remaining callback problem is optional geolocation behavior, particularly public-IP services, the plain-HTTP `ip-api.com` helper, and externally hosted GeoIP databases.
