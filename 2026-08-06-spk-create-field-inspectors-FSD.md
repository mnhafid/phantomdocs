# FSD: SPK Create Silently Drops Field Inspectors

| | |
|---|---|
| **Type** | Defect specification (no PRD — see §1) |
| **Status** | Draft |
| **Date** | 2026-08-06 |
| **Version** | 0.1 |
| **Branch** | `feat/spkapprovaldate` |
| **Severity** | High — silent data loss, success response |

## 1. Why there is no PRD

The "why" is one sentence: `POST /api/v1/spks` accepts field inspectors, reports success, and stores none of them. There is no product decision to make and no non-goal worth writing, so this document carries the requirements directly.

## 2. Defect

**Observed.** Creating an SPK with a populated `user_field_inspectors` array returns `201` with `is_success: true` and `"Success create SPK"`. Reading the SPK back returns `field_inspectors` empty. No error, no log, no partial write.

**Reproduction**

```
POST /api/v1/spks
{
  "contract_id": "7cdfdc1e-43f5-40e1-a97b-3062cb8ab460",
  "spk_title": "SPK Descccc 0004",
  ...
  "user_field_inspectors": [
    { "id": "1B860F20-5FCA-4E60-9362-5C8F125BB5F7",
      "full_name": "R3 Test agungeka",
      "email": "r3test.agungeka@yopmail.com" }
  ]
}
→ 201 { "data": { "id": "aa11aa8b-…", "is_success": true, "result_message": "Success create SPK" } }
→ GET /api/v1/spks/aa11aa8b-…  ⇒ "field_inspectors": []
```

**Root cause.** `AddSpkRequest` ([SpksDto.cs:181](../src-be/Logics/Services/Spks/SpksDto.cs:181)) declares:

```csharp
[JsonPropertyName("field_inspectors")]
public List<Guid> UserFieldInspectors { get; set; } = new();
```

Two independent mismatches against the real payload:

| | DTO expects | Client sends | Effect |
|---|---|---|---|
| JSON key | `field_inspectors` | `user_field_inspectors` | Property never populated; `System.Text.Json` ignores unmapped members by default, so no error is raised |
| Element shape | `Guid` | `{ id, full_name, email }` | Would throw `JsonException` even if the key matched |

Because the key never matches, the list stays empty and `CreateSpkAsync` ([SpksService.cs:337](../src-be/Logics/Services/Spks/SpksService.cs:337)) maps an empty collection into `Spk.UserInspectors`. The insert succeeds with zero `spk_field_inspectors` rows.

**Why only create is affected.** Both sibling contracts are already correct:

| Contract | JSON key | Element type | Correct? |
|---|---|---|---|
| `AddSpkRequest` ([SpksDto.cs:181](../src-be/Logics/Services/Spks/SpksDto.cs:181)) | `field_inspectors` | `Guid` | **No** |
| `UpdateSpkRequest` ([SpksDto.cs:223](../src-be/Logics/Services/Spks/SpksDto.cs:223)) | `user_field_inspectors` | `UserAct` | Yes |
| `CreateSpkVariousWbsRequest` ([SpksDto.cs:637](../src-be/Logics/Services/Spks/SpksDto.cs:637)) | `user_field_inspectors` | `UserAct` | Yes |

**Current workaround.** `POST /api/v1/spks/{spkId}/field-inspector` ([SpksEndpoint.cs:117](../src-be/WebApi/Services/Spks/SpksEndpoint.cs:117)) replaces the inspector set on an existing SPK and works correctly. Every SPK created through the broken path can be repaired with one extra call.

## 3. Scope

**In scope**

- Binding `user_field_inspectors` (array of user objects) on `POST /api/v1/spks`.
- Continuing to accept the legacy `field_inspectors` (array of GUIDs) shape.
- Validating that each referenced user exists, consistent with the existing approver check.
- Persisting the resulting `spk_field_inspectors` rows.
- Regression tests that pin the wire contract.

**Out of scope** (decided during requirements review, 2026-08-06)

- **Audit columns.** `SpkFieldInspector.CreatedAt` / `CreatedBy` are non-nullable but left unset in `CreateSpkAsync` ([SpksService.cs:337](../src-be/Logics/Services/Spks/SpksService.cs:337)) and `UpdateSpkInspectorsAsync` ([SpksService.cs:594](../src-be/Logics/Services/Spks/SpksService.cs:594)). Both columns are `datetime2`/`uniqueidentifier`, so rows persist as `0001-01-01` with an empty creator rather than failing. Pre-existing on the update path; tracked separately.
- **Backfilling** SPKs already created without inspectors. Users re-add them via `POST /spks/{spkId}/field-inspector`.
- **Auditing other `Add*Request` DTOs** for the same class of key mismatch.
- Any change to the update or various-WBS create paths.
- Any migration — the table and entity are correct.

## 4. Functional requirements

Traceability: `D1` = inspectors submitted at create are persisted. `D2` = no silent success on bad input.

| ID | Requirement | Traces |
|---|---|---|
| **FR-001** | `POST /api/v1/spks` must bind `user_field_inspectors` as an array of user objects, using the same `UserAct` shape as `UpdateSpkRequest`. Only `id` is read; `full_name`, `email`, `status`, and `role` are accepted and ignored. | D1 |
| **FR-002** | The endpoint must continue to accept the legacy `field_inspectors` key as an array of GUID strings. The field is deprecated and never appears in any response. | D1 |
| **FR-003** | When both keys are present, the system must union the two sets and de-duplicate by user id. Duplicate ids within a single key must also collapse to one row. | D1 |
| **FR-004** | When both keys are absent, `null`, or empty arrays, the SPK must be created with zero inspectors and `is_success: true`. Inspectors remain optional at create time. | D1 |
| **FR-005** | Before persisting, the system must verify every resolved inspector id exists in `users` with `deleted_at IS NULL`. If any id fails, it must abort with `is_success: false` and `result_message: "User Field Inspector not found"`, persisting nothing. The check must sit alongside the existing approver checks ([SpksService.cs:258-275](../src-be/Logics/Services/Spks/SpksService.cs:258)) and use the same count-comparison form. | D2 |
| **FR-006** | Persisted inspectors must be readable without a further write, via `GET /api/v1/spks/{id}` → `field_inspectors` and via the SPK BoQ progress detail ([SpkBoqProgressService.cs:864](../src-be/Logics/Services/SpkBoqProgress/SpkBoqProgressService.cs:864)). | D1 |
| **FR-007** | A malformed element — a non-object under `user_field_inspectors`, a non-GUID string under `field_inspectors`, or a missing `id` — must fail deserialization and return `400`, not a partial write. | D2 |

### Non-functional

| ID | Requirement |
|---|---|
| **NFR-001** | The validation must add at most one `COUNT` query, executed only when the resolved id list is non-empty — matching the approver checks. |
| **NFR-002** | No schema change, no migration, no change to `SpkFieldInspector`. |
| **NFR-003** | `UpdateSpkAsync`, `UpdateSpkFieldInspectorsAsync`, and `CreateSpkVariousWbsAsync` must be byte-for-byte unchanged in behaviour. |
| **NFR-004** | `CreateSpkAsync` cognitive complexity must not increase beyond the current level; resolution and validation go in private helpers per [CLAUDE.md](../CLAUDE.md). |

## 5. Behaviour matrix

| `user_field_inspectors` | `field_inspectors` | Result |
|---|---|---|
| absent / `null` / `[]` | absent / `null` / `[]` | SPK created, 0 inspector rows, `is_success: true` |
| 2 valid users | absent | SPK created, 2 rows |
| absent | 2 valid GUIDs | SPK created, 2 rows |
| user A | GUIDs A, B | SPK created, 2 rows (A de-duplicated) |
| user A twice | absent | SPK created, 1 row |
| 1 valid, 1 unknown/soft-deleted | — | Nothing persisted, `is_success: false`, `"User Field Inspector not found"` |
| `["not-an-object"]` | — | `400`, nothing persisted |
| — | `["not-a-guid"]` | `400`, nothing persisted |

## 6. Interfaces

**`POST /api/v1/spks`** — request body, inspector-related fields only:

```jsonc
{
  "user_field_inspectors": [                    // preferred
    { "id": "1b860f20-5fca-4e60-9362-5c8f125bb5f7",
      "full_name": "R3 Test agungeka",          // accepted, ignored
      "email": "r3test.agungeka@yopmail.com" }  // accepted, ignored
  ],
  "field_inspectors": ["1b860f20-…"]            // deprecated, still accepted
}
```

Response envelope is unchanged. On validation failure the endpoint returns the existing failure shape:

```jsonc
{ "data": { "id": "00000000-…", "is_success": false,
            "result_message": "User Field Inspector not found" },
  "status": "success", "message": "Create spk succeed" }
```

> **Note on HTTP status.** `AddSpkAsync` ([SpksEndpoint.cs:260](../src-be/WebApi/Services/Spks/SpksEndpoint.cs:260)) returns `201` for every non-exception outcome, so business-rule failures already arrive as `201` with `is_success: false` — this is how "SPK sequence number already exist" and "User Approver not found" behave today. FR-005 follows that convention rather than introducing a one-off `400`. Changing the endpoint to map `is_success: false` to `400` would alter every existing failure message's status code and is out of scope; flagged in §8.

**`GET /api/v1/spks/{id}`** — unchanged. `field_inspectors` is populated from `spk_field_inspectors` ([SpksService.cs:2788](../src-be/Logics/Services/Spks/SpksService.cs:2788)).

## 7. Assumptions

Recorded so they are visible and reversible:

1. **User `status` is not checked**, only `deleted_at IS NULL` — mirroring the approver validation exactly. An inactive-but-not-deleted user can be assigned as inspector.
2. The deprecated `field_inspectors` field stays on the DTO indefinitely; no sunset date is set. It is request-only and never serialized.
3. `UserAct.Id` of `Guid.Empty` is treated as an invalid id and fails FR-005 (it will not exist in `users`).
4. Ordering of persisted inspectors is not significant; no ordering guarantee is specified or tested.
5. No client is known to send the legacy shape — back-compat is defensive, per the decision to cover unseen callers (mobile, integrations).

## 8. Flagged, not fixed

Genuine issues found while diagnosing, deliberately left out of this change:

1. **Unset audit columns** on `SpkFieldInspector` in the create and update paths (§3). The various-WBS path ([SpksService.cs:1721](../src-be/Logics/Services/Spks/SpksService.cs:1721)) sets them correctly, so the data is already inconsistent across paths.
2. **`is_success: false` returns `201`** on `POST /spks`, so clients must inspect the body to detect failure.
3. **Unmapped JSON members are ignored silently** across the API. This bug class recurs wherever a DTO key drifts from the client contract; `JsonSerializerOptions.UnmappedMemberHandling = Disallow` would surface it, at the cost of rejecting requests with extra fields.

## 9. Verification

Test project: `src-be/Tests` (xUnit + EF InMemory + Moq, see `SpksServiceTests.cs`).

| Test | Asserts |
|---|---|
| Deserialize the exact payload from §2 into `AddSpkRequest` | one resolved inspector id — pins FR-001 and the reported bug |
| Deserialize legacy `field_inspectors` GUID array | one resolved id — FR-002 |
| Deserialize both keys with an overlapping id | de-duplicated union — FR-003 |
| Deserialize with neither key | empty list, no exception — FR-004 |
| `CreateSpkAsync` with two valid inspectors | two `spk_field_inspectors` rows with the right `spk_id` / `user_id` — FR-001, FR-006 |
| `CreateSpkAsync` with one unknown user id | `is_success: false`, `"User Field Inspector not found"`, zero SPK rows and zero inspector rows — FR-005 |
| `CreateSpkAsync` with no inspectors | SPK created, `is_success: true`, zero inspector rows — FR-004 |

Manual check: run the §2 payload against the running API and confirm `GET /spks/{id}` returns the inspector.
