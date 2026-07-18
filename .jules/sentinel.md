## 2026-07-17 - Sensitive File Path Exposure in Logs
**Vulnerability:** File paths were being logged in plaintext using standard string interpolation (`\(url.path)`) in `OSLog` (`Logger`).
**Learning:** In Swift, `Logger` automatically assumes variables in interpolations are public unless specified otherwise or if they are custom objects. File paths, which can reveal device directory structures and user UUIDs, must be explicitly marked private.
**Prevention:** Use `\(variable, privacy: .private)` for sensitive information in `Logger` calls to ensure they are redacted in production sysdiagnose logs.
