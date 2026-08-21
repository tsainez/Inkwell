## 2024-07-24 - Exposure of File Paths in Logger
**Vulnerability:** File paths in logger weren't marked private, leading to exposure of internal paths in `StrokeReference.swift`.
**Learning:** In Swift, `url.path` in OSLog exposes potentially sensitive internal file structure if not explicitly hidden using `.private`.
**Prevention:** Always mark sensitive strings with `privacy: .private` in `Logger` interpolations.
## 2024-07-24 - Exposure of Error Data in Crash Reports
**Vulnerability:** The \`InkwellApp\` initialization passed a raw Swift Error directly into \`fatalError()\`. When this hits the system crash reporter, the interpolated error object often includes underlying NSError domains that leak exact file paths inside the app container, or details about the application's internal Core Data schema.
**Learning:** Functions that immediately terminate the process and write to OS crash logs (\`fatalError\`, \`preconditionFailure\`, etc.) are public surfaces. Interpolating unredacted \`Error\` variables into these functions is an information exposure risk.
**Prevention:** Avoid interpolating \`Error\` or arbitrary state directly into crash-terminating messages. Use static, opaque messages that indicate failure state without revealing environmental structure.
## 2024-08-01 - Exposure of Error Descriptions in Logs
**Vulnerability:** Error descriptions (`error.localizedDescription`) were logged without `.private` modifier, potentially exposing sensitive information such as file paths or internal details into system logs.
**Learning:** `Logger` in Swift implicitly interpolates strings as public unless specified otherwise. Raw error descriptions often contain paths or system details that shouldn't be publicly logged.
**Prevention:** Always mark error descriptions in logs with `privacy: .private` and avoid using `localizedDescription` when `String(describing: error)` provides safer raw context for debugging without localized string leakage.
