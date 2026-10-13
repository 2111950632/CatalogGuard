# Development

This is the szs PO/POT catalog checker. Keep the checking core in MoonBit.
The Node.js CLI may read files and print results, but must not implement PO,
format, plural, or catalog validation. Preserve explicit unsupported diagnostics.

Run moon check, moon test, moon info, and moon fmt for changed MoonBit code.
Run the CLI integration checks after changing the protocol or entry point.
Keep tests independent of production implementation, with both passing and
deliberately broken inputs. Never update expected output merely to hide a failure.

Preserve the public API and the schema version in JSON reports. Track production
code separately from tests, examples, generated interfaces, and external fixtures.
