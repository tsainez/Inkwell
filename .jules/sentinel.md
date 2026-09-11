## 2024-07-24 - Exposure of File Paths in Logger
**Vulnerability:** File paths in logger weren't marked private, leading to exposure of internal paths in `StrokeReference.swift`.
**Learning:** In Swift, `url.path` in OSLog exposes potentially sensitive internal file structure if not explicitly hidden using `.private`.
**Prevention:** Always mark sensitive strings with `privacy: .private` in `Logger` interpolations.
## 2024-07-24 - Exposure of Error Data in Crash Reports
**Vulnerability:** The \`InkwellApp\` initialization passed a raw Swift Error directly into \`fatalError()\`. When this hits the system crash reporter, the interpolated error object often includes underlying NSError domains that leak exact file paths inside the app container, or details about the application's internal Core Data schema.
**Learning:** Functions that immediately terminate the process and write to OS crash logs (\`fatalError\`, \`preconditionFailure\`, etc.) are public surfaces. Interpolating unredacted \`Error\` variables into these functions is an information exposure risk.
**Prevention:** Avoid interpolating \`Error\` or arbitrary state directly into crash-terminating messages. Use static, opaque messages that indicate failure state without revealing environmental structure.
## 2025-01-24 - Exposure of Error Data in Logger
**Vulnerability:** In `IDSDecomposer.swift` and `StrokeReference.swift`, error data was passed directly to the Logger via string interpolation (`\(error.localizedDescription)`). This exposes internal error details, such as localized descriptions, into sysdiagnose logs without redaction.
**Learning:** Explicitly marking error strings as `.private` is a valid defense-in-depth security enhancement. It guarantees that sensitive error details won't inadvertently leak into sysdiagnose logs if default behaviors are misunderstood or changed.
**Prevention:** Always use `\(String(describing: error), privacy: .private)` when logging error details to ensure they are properly redacted.
