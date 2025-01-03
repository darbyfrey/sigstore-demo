Sigstore Demo
=============

This is an example project showing how to build, attest, sign, and verify an application using [Sigstore](https://www.sigstore.dev/)

### Build

The build artifact in this case is just a plain text file. The build stage uses the [Artifact prevenance metadata](https://docs.gitlab.com/ee/ci/runners/configure_runners.html#artifact-provenance-metadata) feature to generagte a provenance metadata file for the build artifact. The generated file is called `demo.txt-metadata.json `.

### Attest

Attestation uses `cosign attest-blob` to take the input `--predicate demo.txt-metadata.json` and build artifact (`demo.txt`), along with GitLab as the OIDC provider. It produces an attesation file (`demo.txt.att`), along with a signature (`demo.txt.att.sig`) and certificate (`demo.txt.att.crt`) for the attestation.

### Sign

Signing uses `cosign sign-blob` along with GitLab as the OIDC provider to produce signature (`demo.txt.sig`) and certificate (`demo.txt.crt`) files for the build artifact (`demo.txt`).

### Verify

The verify stage has two jobs `verify-attestation` and `verify-package`. These use the `cosign verify-blob-attestation` and `cosign verify-blob` commands to verify the attestation and package against the provided certificates and signatures.
