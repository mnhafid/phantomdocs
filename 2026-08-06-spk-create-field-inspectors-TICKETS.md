# Tickets: SPK Create Silently Drops Field Inspectors

Source spec: [FSD-spk-create-field-inspectors](2026-08-06-spk-create-field-inspectors-FSD.md)
Branch: `feat/spkapprovaldate`

| ID | Title | Size | Blocked by | Covers |
|---|---|---|---|---|
| T-01 | Bind `user_field_inspectors` on SPK create, keep legacy shape | S | — | FR-001, FR-002, FR-003, FR-004, FR-007, NFR-004 |
| T-02 | Validate and persist inspectors in `CreateSpkAsync` | S | T-01 | FR-005, FR-006, NFR-001, NFR-002, NFR-003 |

**Coverage check:** all 7 FRs and all 4 NFRs are covered by 2 tickets. No orphans in either direction.

Total estimate: under one dev-day. No epic grouping needed.

---

## T-01 — Bind `user_field_inspectors` on SPK create, keep legacy shape

**Size:** S · **Blocked by:** — · **Covers:** FR-001, FR-002, FR-003, FR-004, FR-007, NFR-004

### Context

`AddSpkRequest` listens on `field_inspectors` as `List<Guid>`; every real client posts `user_field_inspectors` as an array of user objects. The key never matches, `System.Text.Json` drops the unmapped member without error, and the SPK saves with zero inspectors. See FSD §2.

### Work

In `src-be/Logics/Services/Spks/SpksDto.cs`, `AddSpkRequest`:

- Add `[JsonPropertyName("user_field_inspectors")] public List<UserAct> UserFieldInspectors { get; set; } = new();` — same shape as `UpdateSpkRequest` ([SpksDto.cs:223](../src-be/Logics/Services/Spks/SpksDto.cs:223)).
- Keep the existing `field_inspectors` property as `List<Guid>`, renamed to something unambiguous (e.g. `LegacyFieldInspectorIds`) and marked deprecated in an XML doc comment. Request-only; it must never be serialized into a response.
- Add a resolution helper on the DTO — `IReadOnlyList<Guid> ResolveFieldInspectorIds()` — returning the de-duplicated union of both keys. Keeping it on the DTO holds `CreateSpkAsync` complexity flat (NFR-004).

### Acceptance criteria

```gherkin
Given a POST /spks body whose user_field_inspectors holds one user object
When the body is deserialized into AddSpkRequest
Then ResolveFieldInspectorIds() returns exactly that one user id

Given a POST /spks body whose legacy field_inspectors holds one GUID string
When the body is deserialized
Then ResolveFieldInspectorIds() returns exactly that one id

Given a body carrying both keys, sharing one id and adding one more
When the body is deserialized
Then ResolveFieldInspectorIds() returns two ids, with no duplicate

Given a body where the same user id appears twice under user_field_inspectors
When the body is deserialized
Then ResolveFieldInspectorIds() returns one id

Given a body with neither key, or with both set to null or []
When the body is deserialized
Then ResolveFieldInspectorIds() returns an empty list and no exception is thrown

Given a body where field_inspectors holds "not-a-guid"
When the request is posted
Then the endpoint returns 400 and no SPK is created
```

### Tests

Add to `src-be/Tests` (new `SpkFieldInspectorBindingTests.cs`, or extend `SpksServiceTests.cs`). Pure deserialization — no DB needed. Use the verbatim payload from FSD §2 as the first case so the reported bug is pinned by a test that fails before the fix.

---

## T-02 — Validate and persist inspectors in `CreateSpkAsync`

**Size:** S · **Blocked by:** T-01 · **Covers:** FR-005, FR-006, NFR-001, NFR-002, NFR-003

### Context

With T-01 the ids arrive; `CreateSpkAsync` must check they refer to real users and map them onto `Spk.UserInspectors`. The approver validation immediately above ([SpksService.cs:258-275](../src-be/Logics/Services/Spks/SpksService.cs:258)) is the pattern to copy — same count-comparison, same failure envelope.

### Work

In `src-be/Logics/Services/Spks/SpksService.cs`, `CreateSpkAsync`:

- Resolve ids once via `request.ResolveFieldInspectorIds()`.
- Add the existence check directly after the progress-approver check, in the same form: `Users.CountAsync(u => ids.Contains(u.Id) && u.DeletedAt == null)`, compared against `ids.Count`. On mismatch return `new SpkResultDto { IsSuccess = false, ResultMessage = "User Field Inspector not found" }`. Skip the query when the list is empty (NFR-001).
- Replace the mapping at [SpksService.cs:337](../src-be/Logics/Services/Spks/SpksService.cs:337) so it projects the resolved ids into `SpkFieldInspector { Id = Guid.NewGuid(), UserId = id }`.
- Touch nothing in `UpdateSpkAsync`, `UpdateSpkInspectorsAsync`, `UpdateSpkFieldInspectorsAsync`, or the various-WBS path (NFR-003).

> Audit columns (`CreatedAt` / `CreatedBy`) are deliberately **not** set here — out of scope per FSD §3. Do not fold that fix into this ticket.

### Acceptance criteria

```gherkin
Given a create request naming two users that exist and are not soft-deleted
When CreateSpkAsync runs
Then the SPK is created with is_success true
And spk_field_inspectors holds two rows carrying the new spk_id and those user ids

Given a create request naming one existing user and one id absent from users
When CreateSpkAsync runs
Then it returns is_success false with "User Field Inspector not found"
And no SPK row and no inspector row is written

Given a create request naming a user whose deleted_at is set
When CreateSpkAsync runs
Then it returns is_success false with "User Field Inspector not found"

Given a create request with no inspectors at all
When CreateSpkAsync runs
Then the SPK is created with is_success true and zero inspector rows
And the users table is not queried for inspectors

Given an SPK created with two inspectors
When GET /spks/{id} is called
Then field_inspectors lists both users with their full_name and email
```

### Tests

Extend `src-be/Tests/SpksServiceTests.cs` (EF InMemory + Moq, existing `BuildService` harness). Seed `users` rows for the valid cases and assert on `db.SpkFieldInspectors` after the call.

### Manual verification

Post the FSD §2 payload against the running API, then `GET /api/v1/spks/{id}` and confirm `field_inspectors` contains `1B860F20-5FCA-4E60-9362-5C8F125BB5F7`.
