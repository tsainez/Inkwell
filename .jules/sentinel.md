## 2024-07-24 - Exposure of File Paths in Logger
**Vulnerability:** File paths in logger weren't marked private, leading to exposure of internal paths in `StrokeReference.swift`.
**Learning:** In Swift, `url.path` in OSLog exposes potentially sensitive internal file structure if not explicitly hidden using `.private`.
**Prevention:** Always mark sensitive strings with `privacy: .private` in `Logger` interpolations.
## 2024-07-24 - Exposure of Error Data in Crash Reports
**Vulnerability:** The \`InkwellApp\` initialization passed a raw Swift Error directly into \`fatalError()\`. When this hits the system crash reporter, the interpolated error object often includes underlying NSError domains that leak exact file paths inside the app container, or details about the application's internal Core Data schema.
**Learning:** Functions that immediately terminate the process and write to OS crash logs (\`fatalError\`, \`preconditionFailure\`, etc.) are public surfaces. Interpolating unredacted \`Error\` variables into these functions is an information exposure risk.
**Prevention:** Avoid interpolating \`Error\` or arbitrary state directly into crash-terminating messages. Use static, opaque messages that indicate failure state without revealing environmental structure.
## 2026-08-14 - Exposure of Error Descriptions in Logger
**Vulnerability:** `error.localizedDescription` was interpolated into `logger.error` without privacy modifiers. This exposes potentially sensitive internal file structure or execution environment details to sysdiagnose logs when an operation (like file reading or JSON decoding) fails.
**Learning:** In Swift, string interpolations in `Logger` can leak sensitive application state. While custom objects may be private by default, strings extracted from errors (`localizedDescription`) are interpolated as normal strings and must be explicitly redacted.
**Prevention:** Always mark error descriptions or potentially sensitive strings with `privacy: .private` in `Logger` interpolations.
