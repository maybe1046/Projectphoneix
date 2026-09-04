# Install and smoke-test the capture toolchain

Type: task
Status: open
Blocked by: 04

## Question

Install whatever ticket 04 selects and prove it works end-to-end against the live server
before the real capture sessions — a toolchain that fails at hour 40 of 50 is a
catastrophe; one that fails at hour 3 is an inconvenience.

The smoke test must demonstrate: a capture file is produced; world traffic is decrypted (or
is provably decryptable later); at least one known-custom opcode (1862) appears with its
payload intact; and unknown opcodes are recorded rather than dropped.

Record the exact setup — versions, flags, config, invocation — in the repo, so a second
machine or a second helper can be brought online without rediscovering it.
