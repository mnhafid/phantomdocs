# SYSROLEs to create in Retina

Part of [PHI-2119](README.md). SYSNAME is `PHANTOM` on every row.

**Status: proposal.** The names follow decision D16. The permission sets are derived and need review before anyone creates them in Retina.

## The 20 SYSROLEs

| # | SYSROLE | Type | Regulator | Read | Modify | Approval | Total seqs |
|---|---|---|---|---|---|---|---|
| 1 | `Projects - Modify - Leader` | Leader | Yes | 31 | 106 | 4 | 141 |
| 2 | `Projects - Modify - Member` | Member | No | 31 | 106 | 0 | 137 |
| 3 | `Projects - Read - Guest` | Guest | No | 31 | 0 | 0 | 31 |
| 4 | `Projects - Approval - Member` | Approval | No | 31 | 0 | 4 | 35 |
| 5 | `Operations & Surface Facilities - Modify - Leader` | Leader | Yes | 28 | 99 | 4 | 131 |
| 6 | `Operations & Surface Facilities - Modify - Member` | Member | No | 28 | 99 | 0 | 127 |
| 7 | `Operations & Surface Facilities - Read - Guest` | Guest | No | 28 | 0 | 0 | 28 |
| 8 | `Operations & Surface Facilities - Approval - Member` | Approval | No | 28 | 0 | 4 | 32 |
| 9 | `Production Operations - Modify - Leader` | Leader | Yes | 18 | 53 | 3 | 74 |
| 10 | `Production Operations - Modify - Member` | Member | No | 18 | 53 | 0 | 71 |
| 11 | `Production Operations - Read - Guest` | Guest | No | 18 | 0 | 0 | 18 |
| 12 | `Production Operations - Approval - Member` | Approval | No | 18 | 0 | 3 | 21 |
| 13 | `Subsurface Development Area 1 - Modify - Leader` | Leader | Yes | 1 | 3 | 0 | 4 |
| 14 | `Subsurface Development Area 1 - Modify - Member` | Member | No | 1 | 3 | 0 | 4 |
| 15 | `Subsurface Development Area 1 - Read - Guest` | Guest | No | 1 | 0 | 0 | 1 |
| 16 | `Subsurface Development Area 1 - Approval - Member` | Approval | No | 1 | 0 | 0 | 1 |
| 17 | `Subsurface Development Area 2 - Modify - Leader` | Leader | Yes | 1 | 3 | 0 | 4 |
| 18 | `Subsurface Development Area 2 - Modify - Member` | Member | No | 1 | 3 | 0 | 4 |
| 19 | `Subsurface Development Area 2 - Read - Guest` | Guest | No | 1 | 0 | 0 | 1 |
| 20 | `Subsurface Development Area 2 - Approval - Member` | Approval | No | 1 | 0 | 0 | 1 |

Every seq per SYSROLE is in [04-sysrole-acl.csv](04-sysrole-acl.csv).

`Super Admin` already exists and stays as it is. It is not patterned and keeps merged permissions.

## How the permission sets were derived

Each department's existing SYSROLE in `docs/organization-structure/PhantomRoles_6Roles.oracle.sql` is the source. Its seqs are split by the privilege name in the dev `permissions` table:

| Class | Rule |
|---|---|
| Read | Name starts with Read, View, Download, Export or List |
| Approval | Name ends with the word Approval, e.g. Contract Approval |
| Modify | Everything else |

| SYSROLE type | Gets |
|---|---|
| Leader | Read + Modify + Approval, the department's whole existing set |
| Member | Read + Modify |
| Guest | Read |
| Approval | Read + Approval |

Read is included in Approval because an approver has to be able to open what they approve. Modify excludes approval because your example user holds Modify and Approval as separate SYSROLEs.

## Needs review before creating

1. **No approval privileges exist for: Subsurface Development Area 1, Subsurface Development Area 2.** Their `Approval - Member` SYSROLE would be Read only. Decide what those departments approve, for example EUR update approval.
2. **The split is by name, not by the business meaning of each privilege.** The source sheet's View/Modify category is the authority and should be checked against this list.
3. **5 seqs have no usable privilege name and are excluded from every set:** 138, 140, 141, 142, 144.
4. **Spelling must be identical on dev and prod.** The parser reads the text before the first ` - `.
5. **ACLIDs** are placeholders the R3 team assigns, as with the earlier role files.
