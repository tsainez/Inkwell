## 2024-07-24 - Exposure of File Paths in Logger
**Vulnerability:** File paths in logger weren't marked private, leading to exposure of internal paths in `StrokeReference.swift`.
**Learning:** In Swift, `url.path` in OSLog exposes potentially sensitive internal file structure if not explicitly hidden using `.private`.
**Prevention:** Always mark sensitive strings with `privacy: .private` in `Logger` interpolations.
## 2024-07-24 - Exposure of Error Data in Crash Reports
**Vulnerability:** The \`InkwellApp\` initialization passed a raw Swift Error directly into \`fatalError()\`. When this hits the system crash reporter, the interpolated error object often includes underlying NSError domains that leak exact file paths inside the app container, or details about the application's internal Core Data schema.
**Learning:** Functions that immediately terminate the process and write to OS crash logs (\`fatalError\`, \`preconditionFailure\`, etc.) are public surfaces. Interpolating unredacted \`Error\` variables into these functions is an information exposure risk.
**Prevention:** Avoid interpolating \`Error\` or arbitrary state directly into crash-terminating messages. Use static, opaque messages that indicate failure state without revealing environmental structure.
## 2024-07-24 - Exposure of Error Data in System Logs
**Vulnerability:** Similar to crash reporters, logging unredacted Error objects or `error.localizedDescription` in `OSLog` (`Logger`) can expose internal details or sensitive file paths into sysdiagnose logs if not explicitly marked private.
**Learning:** `OSLog` treats standard String interpolations as public unless specified otherwise. Explicitly string-converted Error objects, including `error.localizedDescription`, are a common vector for information leakage.
**Prevention:** Always mark error descriptions with `privacy: .private` in `Logger` interpolations, e.g., `\(String(describing: error), privacy: .private)`.
