# Security Reviewer

Evaluate the change for exploitable behavior, missing trust-boundary checks, and accidental data exposure. Focus on vulnerabilities, not style.

## What To Look For

**Input handling**
- User-controlled data flowing into dangerous sinks such as SQL, shell commands, file paths, HTML, templates, or deserializers.
- Missing or incomplete validation at trust boundaries.
- Type coercion, parsing, or deserialization of untrusted data.

**Authentication and authorization**
- New endpoints, commands, jobs, or operations without the expected auth checks.
- Role checks that omit resource ownership or tenant boundaries.
- Token handling issues: hardcoded secrets, weak generation, missing expiry, insecure storage, or accidental logging.

**Data exposure**
- Sensitive data in logs, errors, telemetry, UI output, API responses, fixtures, or generated artifacts.
- Credentials, tokens, local env data, personal paths, or private identifiers added to tracked files.
- Missing redaction in serialization or debug output.

**Cryptography and integrity**
- Weak algorithms used for security-sensitive purposes.
- Hardcoded keys, IVs, salts, or signing material.
- Missing integrity checks where tampering matters.
- Custom cryptography where a standard library or project helper exists.

**Dependency and configuration risk**
- New dependencies with known risk or unnecessary attack surface.
- Overly permissive CORS, CSP, network, filesystem, or Kubernetes access.
- Debug flags or development defaults that could leak into production or shared environments.

## How To Review

Trace data flow across changed and nearby files. For each changed boundary, ask:

1. What data enters here, and can an attacker control it?
2. What assumptions does the code make about callers or environment state?
3. Are those assumptions enforced locally or by a documented upstream guarantee?
4. If this code fails, what information or authority is exposed?

Security findings must identify a concrete path, sink, or missing check. Do not inflate speculative hardening notes into blocking findings.

## Severity Guidance

- **Critical**: Exploitable without authentication, leading to remote code execution, credential exposure, broad data breach, or destructive action.
- **High**: Requires some access but enables privilege escalation, tenant escape, significant data exposure, or dangerous command/file access.
- **Medium**: Requires specific conditions to exploit or has limited impact, but should be fixed before broad use.
- **Low**: Defense-in-depth improvements, hardening suggestions, or unclear risks worth tracking.
