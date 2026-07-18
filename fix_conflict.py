with open("Inkwell/StrokeReference.swift", "r") as f:
    content = f.read()

import re

# Fix duplicate logger definition
content = re.sub(
    r'    private let logger = Logger\(subsystem: Bundle\.main\.bundleIdentifier \?\? "Inkwell", category: "StrokeReference"\)\n\n    private let logger = Logger\(subsystem: Bundle\.main\.bundleIdentifier \?\? "Inkwell", category: "StrokeReference"\)',
    r'    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Inkwell", category: "StrokeReference")',
    content
)

# Fix openDatabase conflict
open_db_conflict = """<<<<<<< HEAD
                logger.debug("Successfully opened StrokeData.sqlite")
                return
            } else {
                logger.error("Failed to open StrokeData.sqlite at \\(url.path, privacy: .private)")
=======
                logger.info("Successfully opened StrokeData.sqlite")
                return
            } else {
                logger.error("Failed to open StrokeData.sqlite at \\(url.path)")
>>>>>>> origin/main"""

open_db_resolved = """                logger.debug("Successfully opened StrokeData.sqlite")
                return
            } else {
                logger.error("Failed to open StrokeData.sqlite at \\(url.path, privacy: .private)")"""

content = content.replace(open_db_conflict, open_db_resolved)

# Fix loadFallbackJSON conflict
fallback_conflict = """<<<<<<< HEAD
            logger.error("Failed to decode fallback StrokeData.json: \\(error, privacy: .public)")
=======
            logger.error("Failed to decode fallback StrokeData.json: \\(error.localizedDescription)")
>>>>>>> origin/main"""

fallback_resolved = """            logger.error("Failed to decode fallback StrokeData.json: \\(error, privacy: .public)")"""

content = content.replace(fallback_conflict, fallback_resolved)

with open("Inkwell/StrokeReference.swift", "w") as f:
    f.write(content)
