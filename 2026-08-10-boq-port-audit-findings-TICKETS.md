# Tickets: Deferred Findings from the BOQ Port Audit

Source: the 2026-08-10 comparison of `pms-backend` `POST /api/v1/contracts/boqs/upload` against phiDev. These six findings surfaced during that audit and were **explicitly excluded** from [BOQ Template Detection](2026-08-10-boq-template-detection-PRD.md) as non-goals, because none of them concerns which parser runs.

There is no PRD or FSD behind this file. Each ticket's acceptance criteria derive from measured evidence recorded in the finding itself, not from a specification. Two findings (F-01, F-02) were confirmed empirically; the rest by code and configuration reading.

**F-01 reaches well beyond BOQ.** It was found in the BOQ endpoint but affects 15 upload sites across 11 files. Sequence it accordingly.

## Summary

| ID | Title | Severity | Size | Blocked by | Evidence |
|---|---|---|---|---|---|
| F-01 | Sanitize uploaded filenames before writing to disk | Critical | M | — | 15 call sites, verified by grep |
| F-02 | Fix culture-dependent decimal parsing in BOQ row parsing | High | S | — | Measured: 100× inflation under `id-ID` |
| F-03 | Restore a permission gate on the BOQ endpoints | High | M | — | Go enforces `RBACMiddleware("5","31")`; phiDev has none |
| F-04 | Set an explicit request size limit on upload endpoints | Low | S | — | Kestrel default ~28.6 MB vs Go's explicit 25 MB |
| F-05 | Align the Type-4 detail fan-out order with Go | Low | S | — | phiDev `PM,DC,PC`; Go `PM,PC,DC` |
| F-06 | Repair or retire stale BOQ template `file_url` values | Low | S | T-05 (template detection set) | URLs point at `ipms-bucket`; phiDev is configured for `phantom-dev` |

**Suggested order:** F-01 and F-02 first — both are exploitable or silently corrupting today. F-03 next. F-04, F-05, F-06 are cleanup and can ride along with any BOQ work.

---

## F-01: Sanitize uploaded filenames before writing to disk

- **Severity:** Critical · **Size:** M · **Blocked by:** —

**Context**

Every multipart upload endpoint takes the client-supplied `IFormFile.FileName` — which comes from the `Content-Disposition` header and is **not** sanitized by ASP.NET Core — and joins it directly onto a server path before opening it with `FileMode.Create`. A filename of `../../appsettings.json` escapes the intended folder and overwrites an arbitrary file the process can write.

`SanitizeFileName` already exists at [BoqsService.cs:1082](../src-be/Logics/Services/Boqs/BoqsService.cs:1082) but is applied only to the MinIO object key at [:507](../src-be/Logics/Services/Boqs/BoqsService.cs:507). No endpoint sanitizes the local filesystem path.

Confirmed sites (raw `file.FileName` into `Path.Combine`):

| File | Line(s) |
|---|---|
| `WebApi/Services/Boqs/BoqsEndpoint.cs` | 529 (`SaveUploadedFileAsync`, used by 3 endpoints) |
| `WebApi/Services/SpkBoqDocuments/SpkBoqDocumentsEndpoint.cs` | 273 |
| `WebApi/Services/ProjectRebaselines/ProjectRebaselinesEndPoint.cs` | 242, 404, 412 |
| `WebApi/Services/ProjectDocuments/ProjectDocumentsEndPoint.cs` | 327, 335 |
| `WebApi/Services/SpkDocuments/SpkDocumentsEndPoint.cs` | 277 |
| `WebApi/Services/ProjectTasks/ProjectTasksEndPoint.cs` | 111, 125 |
| `WebApi/Services/Mpp/MppEndpoint.cs` | 151, 166 |
| `WebApi/Services/Banks/BanksEndpoint.cs` | 159 |
| `WebApi/Services/FileUploadAttachment/FileUploadAttachmentEndpoint.cs` | 132 |
| `Logics/Services/ProjectRebaselines/ProjectRebaselinesService.cs` | 529 (uses a stored `rebaseline.FileName`) |

**Scope of work**

- Promote a filename-sanitizing helper to a shared location (`Phantom.Base.Shared.Helpers` or equivalent) — strip directory components via `Path.GetFileName`, replace `Path.GetInvalidFileNameChars()`, and fall back to a default when nothing remains. The existing `SanitizeFileName` is a working starting point.
- Apply it at all 15 sites above, replacing the raw `file.FileName`.
- Prefix each written filename with a generated GUID so two concurrent uploads of the same filename cannot clobber each other's temp file — a second, separate bug at every one of these sites.
- Assert, after joining, that the resolved absolute path is still under the intended folder, so a future regression cannot reintroduce the escape.
- Leave the storage object keys alone; the BOQ one is already sanitized.

**Acceptance criteria**

- Given an upload whose filename is `../../evil.txt`, When it is posted to any of the affected endpoints, Then nothing is written outside the intended upload folder.
- Given an upload whose filename is `..\\..\\evil.txt`, When posted, Then the same holds.
- Given two concurrent uploads with identical filenames, When both are processed, Then neither overwrites the other's temp file.
- Given a filename that sanitizes to an empty string, When posted, Then a default name is used and no exception is thrown.

**Out of scope**

Changing what any endpoint does with the file after it lands, or the MinIO object-key scheme.

**Test notes**

`IFormFile.FileName` is attacker-controlled; a test that fakes it via the filesystem proves nothing. Drive it through a real multipart request with a crafted `Content-Disposition`. Cover both `/` and `\` separators — the server runs on Linux but the framework normalizes neither.

---

## F-02: Fix culture-dependent decimal parsing in BOQ row parsing

- **Severity:** High · **Size:** S · **Blocked by:** —

**Context**

`ParseDouble` at [BoqsService.cs:1503](../src-be/Logics/Services/Boqs/BoqsService.cs:1503) combines `NumberStyles.Any` with `InvariantCulture`, but ClosedXML's `GetString()` renders numeric cells using `CurrentCulture`. Under a comma-decimal locale the decimal separator is read as a thousands separator — `NumberStyles.Any` permits it — and every fractional money value inflates 100×.

Measured against the project's own ClosedXML 0.105.0:

```
en-US: '1234.56' -> 1234.56      '5000000.75' -> 5000000.75
id-ID: '1234,56' -> 123456       '5000000,75' -> 500000075
de-DE: '1234,56' -> 123456       '5000000,75' -> 500000075
```

`WebApi.csproj` sets `InvariantGlobalization=false`, and the culture pinning in `Program.cs:37-39` is commented out, so the culture is whatever the host OS reports. An Indonesian-locale server is plausible for this deployment. The Go backend is immune — `cast.ToFloat64` always uses `.`.

The defect affects every money column in all four BOQ templates. Whole-number values stringify identically in every culture, so it bites only on fractional amounts; the inflated total would likely trip the contract-value tolerance gate, turning a valid upload into a rejection with a nonsensical error rather than persisting silently.

**Scope of work**

- Narrow the parse so a comma can never be absorbed as a group separator — drop `NumberStyles.Any` to `NumberStyles.Float`, or read the typed cell value instead of round-tripping through a string.
- Audit the other Excel readers for the same pairing of a culture-rendered string with an invariant parse: `MaterialMonitoring`, `WellZoneAssignment` imports, `WellDeclineRate`, `Banks` bulk import.
- Decide separately whether to pin `CultureInfo.DefaultThreadCurrentCulture`; it would mask this class of bug rather than fix it, so treat it as defence in depth, not the remedy.

**Acceptance criteria**

- Given a workbook cell holding `1234.56`, When parsed under `en-US`, `id-ID` and `de-DE`, Then the result is `1234.56` in all three.
- Given a cell holding `5000000`, When parsed under all three cultures, Then the result is `5000000`.
- Given a cell holding text that is not a number, When parsed, Then the result is `0`, unchanged from today.

**Out of scope**

Quantity parsing. `int.TryParse` floors `10.9` to `0` in phiDev and `cast.ToInt` does the same in Go — consistent behavior, not a divergence, and changing it would alter the header/item classification rule.

**Test notes**

Assert across all three cultures explicitly; a suite that runs only on an `en-US` developer machine passes while the bug is live in production. The existing probe used `CultureInfo.CurrentCulture` assignment around a ClosedXML read and is a workable fixture.

---

## F-03: Restore a permission gate on the BOQ endpoints

- **Severity:** High · **Size:** M · **Blocked by:** —

**Context**

Go guards BOQ upload with `RBACMiddleware("5","31")` and the read endpoints with `("5","32")` ([contract.go:72-76](../../pms-backend/internal/app/router/contract.go:72)). phiDev's `R3ComponentFilter` performs authentication, session resolution and department scoping, but no per-endpoint permission check — and `RbacRouteMaps.cs` covers only `/api/v1/custom-configurations`. Any authenticated user with an active department scope can upload a contract BOQ, and create, rename or delete file templates.

This is recorded as NFR-005 in the template-detection FSD so its absence there is deliberate rather than overlooked. It is not fixed by that work.

**Scope of work**

- Decide how permission IDs map onto phiDev's model — reuse Go's numeric module/permission pairs, or the phiDev permission model — and record the decision.
- Add the BOQ routes to the route-permission map, or introduce an endpoint filter carrying the required permission.
- Cover upload, the BOQ and detail reads, and the category and file-template mutations.
- Audit whether other ported endpoint groups have the same gap; BOQ is unlikely to be alone.

**Acceptance criteria**

- Given an authenticated user without the BOQ upload permission, When they post an upload, Then the response is `403` and no BOQ is created.
- Given an authenticated user with the permission, When they post a valid upload, Then it succeeds.
- Given an unauthenticated request, When posted, Then the response is `401`, unchanged from today.

**Out of scope**

Changing `R3ComponentFilter`'s authentication or department-scoping behavior.

**Test notes**

Per an existing project note, `R3ComponentFilter` ignores `AllowAnonymous` — confirm any new filter composes correctly with it rather than duplicating or bypassing its checks.

---

## F-04: Set an explicit request size limit on upload endpoints

- **Severity:** Low · **Size:** S · **Blocked by:** —

**Context**

Go caps the BOQ upload body at 25 MB via `middleware.BodyLimit("25MB")`. phiDev sets `RequestSizeLimit` only on the DCA endpoint; there is no Kestrel `MaxRequestBodySize` override and no `FormOptions` override, so every other upload falls back to Kestrel's 30,000,000-byte default — roughly 28.6 MB.

So this is a policy gap, not an exposure: the effective cap is about 14% above Go's and applies by accident rather than by decision.

**Scope of work**

- Add an explicit `RequestSizeLimit` to the upload endpoints, matching Go's 25 MB for BOQ unless there is a reason to differ.
- Confirm the rejection surfaces as a clean `413`, not an unhandled exception.

**Acceptance criteria**

- Given a 30 MB upload, When posted to the BOQ upload endpoint, Then the response is `413` and no partial file remains on disk.
- Given a 20 MB upload, When posted, Then it is processed normally.

**Out of scope**

Streaming or chunked-upload support.

**Test notes**

Verify no partial temp file survives a rejected oversize request — F-01's write happens before parsing.

---

## F-05: Align the Type-4 detail fan-out order with Go

- **Severity:** Low · **Size:** S · **Blocked by:** —

**Context**

For Template 4, phiDev emits detail rows in the order `PM, DC, PC, Discipline Eng, Designer Eng` at [BoqsService.cs:1453](../src-be/Logics/Services/Boqs/BoqsService.cs:1453), following the template's column order. Go emits `PM, PC, DC, …`. Every detail carries its own kind and value, so **no value is mis-assigned** — only the `order` sequence, and therefore the display order of details, differs between the two systems for rows where both PC and DC are non-zero.

Purely cosmetic. Listed so the divergence is a recorded decision rather than an unexplained difference someone rediscovers later.

**Scope of work**

- Decide whether phiDev matches Go's emission order or keeps column order, and record the choice in a comment at the call site.
- If aligning, swap the two tuples; nothing else changes.

**Acceptance criteria**

- Given a Type 4 row with non-zero PC and DC, When parsed, Then the detail order matches the documented decision.
- Given the same row, When parsed, Then `DC`'s total comes from the `DC` column and `PC`'s from the `PC` column, whichever order is chosen.

**Out of scope**

Types 1, 2 and 3, whose fan-out order already matches Go.

**Test notes**

The second criterion is the one that matters — it guards against "fixing" the order by swapping the *values* rather than the emission sequence.

---

## F-06: Repair or retire stale BOQ template `file_url` values

- **Severity:** Low · **Size:** S · **Blocked by:** T-05 in the template-detection set

**Context**

All four `boq_file_templates.file_url` values point into `ipms-bucket`, the Go-era bucket, while phiDev's `CloudStorage:BucketName` is `phantom-dev`. `GET /boqs/file-templates` therefore returns URLs for objects outside the bucket phiDev is configured for.

T-05 in the template-detection set makes downloads code-generated, which removes the functional dependency — but the stale URLs keep being returned to any client reading the template list.

**Scope of work**

- Decide between: null the `file_url` values now that downloads are generated; or repoint the list response at the generated-template endpoint.
- If nulling, confirm no frontend consumes `file_url` from `GET /boqs/file-templates` first.

**Acceptance criteria**

- Given the template list endpoint, When called, Then every returned template exposes a working download route or no URL at all — never a URL into a bucket the service is not configured for.

**Out of scope**

Dropping the `file_url` column; deferred for one release by decision (template-detection FSD §11).

**Test notes**

Check the frontend before nulling — this is the one ticket here that can break a consumer.
