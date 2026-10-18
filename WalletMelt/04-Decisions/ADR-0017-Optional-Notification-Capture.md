---
type: adr
status: proposed
created: 2026-10-18
updated: 2026-10-18
domain: architecture
related:
  - "[[Balance-Income-and-Auto-Capture-Exploration]]"
  - "[[Project-Constitution]]"
  - "[[Security-and-Authentication]]"
  - "[[ADR-0011-Accounts-Derived-Balance-and-Transfers]]"
---

# ADR-0017: Optional on-device notification capture (proposed)

## Status
**Proposed. On hold by the owner (2026-10-18): resume when they send sample alert texts.** Not started. Blocked on (1) real sample alert texts from the owner, (2) the owner's go-ahead after reading the risks below, and (3) a Play policy check done in the Play Console before the Play Store listing. This ADR deliberately does not claim what Google Play permits; that was not verified (searches did not return the policy text).

## Context
Users asked for expenses to be recorded from bank and wallet alerts. The Constitution lists SMS parsing as out of scope and the app has no INTERNET permission. Distribution today is a sideloaded APK; a Play Store listing is planned in one to two months. First supported senders requested by the owner: JazzCash, Easypaisa, Meezan, HBL, UBL, NayaPay, SadaPay, Mashreq.

## Proposed decision
1. **Mechanism**: an Android `NotificationListenerService` (small in-repo Kotlin service plus a method channel), not `READ_SMS`. The user turns it on in Android's Notification access screen; WalletMelt never requests SMS permission. Android only.
2. **Opt-in and amend the Constitution**: off by default; a plain-language disclosure screen before the user is sent to system settings; settings switch to turn it off and forget everything captured. The Constitution's out-of-scope line for SMS parsing is amended to say notification capture is allowed only as specified here.
3. **Allowlist, not firehose**: only notifications from apps the user selected (matched by package name) are read; everything else is dropped in memory immediately and never stored or logged.
4. **On-device rule parsing**: versioned local templates per sender extract amount, direction (debit/credit), counterparty, reference and optional balance-after. No network, no cloud or AI parsing. A template that cannot parse sends the item to a "Could not read" bucket, never to a guess.
5. **Never auto-post**: parsed items land in a **Review inbox** (confirm, edit, ignore). Confirm creates an expense (debit) or income (credit) on the account matched to the sender. Optional per-template auto-confirm is a later, separate decision.
6. **Dedupe**: match on amount, a time window and the reference against existing expenses, incomes and pending items so that a bank alert plus a wallet alert for one payment do not double count.
7. **Data minimisation**: store the parsed fields, a salted hash of the raw text (for dedupe) and the sender package; never store the notification body or title. Captured rows are included in backups only after confirmation (they are ordinary expenses/incomes by then).
8. **Android 13+ restricted settings**: sideloaded APKs cannot enable Notification access until the user allows restricted settings in App info; Android 15 adds an enhanced confirmation step. Onboarding must walk users through this, with screenshots. Play Store installs are not affected.
9. **Reliability**: OEM battery managers (common on Xiaomi, Oppo, Vivo, Infinix) can stop the listener; the app shows a health indicator and battery-exemption guidance, and the Review inbox also accepts a **paste or share a message** path that needs no permission.
10. **Play Store**: before listing, verify in the Play Console what declaration, prominent disclosure and data-safety answers notification access requires, and whether it is allowed for this app category. If it is restricted, ship the permission-free paste/share path only in the Play build (via a build flavor).

## Alternatives considered
1. **READ_SMS**: highest trust cost, heavily restricted on Play, already out of scope. Rejected.
2. **Cloud or LLM parsing**: breaks the offline promise. Rejected.
3. **Accessibility service**: far broader power and stricter store scrutiny. Rejected.
4. **Paste/share only**: safe and simple, but not automatic. Kept as the permission-free fallback and the first thing to ship.

## Open questions for the owner (blocking)
- 3 to 5 real, anonymised alert texts per sender (debit, credit, and failed or reversal if they exist).
- Is a sideloaded-APK-first release acceptable for this feature, with the Play build decided after the policy check?
- Should the first release be paste/share only (no special permission), with the listener following?

## Consequences
- **Positive**: Automatic capture without leaving the device; user stays in control through the Review inbox; minimal stored data.
- **Negative / Trade-offs**: Parsers need ongoing maintenance as alert formats change; restricted-settings friction for sideloaded users; unverified Play policy risk; needs a native Kotlin component in a Flutter app.
- **Neutral**: Would add a Review inbox table and settings, in a later schema bump.

## Related Decisions
- [[Balance-Income-and-Auto-Capture-Exploration]]
- [[ADR-0011-Accounts-Derived-Balance-and-Transfers]]
