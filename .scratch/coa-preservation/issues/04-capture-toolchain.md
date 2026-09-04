# Which capture toolchain, and can pcaps be decrypted after shutdown?

Type: research
Status: claimed
Blocked by: none

## Question

Choose how to capture the wire protocol, given a modified 3.3.5a client, RC4-encrypted
world headers, an extended opcode set no existing parser knows, an active anticheat, and a
machine with no Wireshark, Ghidra, or debugger installed.

Compare: client-side DLL injection hooking send/recv after decryption; a MITM proxy; and
raw pcap for later offline decryption. For each — setup hours, yield, behaviour on unknown
opcodes, detectability.

The pivotal sub-question: can a raw pcap be reliably decrypted after the server is gone?
If the RC4 session key can be recovered from client memory or derived from the logon
exchange, the strategy inverts — capture blindly now at near-zero setup cost, decode in
October. That single fact is worth more than any other in this ticket.

Also needed: whether WowPacketParser records raw payloads for opcodes it cannot identify,
since those are precisely the ones we care about.

Agent dispatched 2026-08-31; findings land in research/capture-toolchain.md.
