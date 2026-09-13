# Realmwalkers - Legends of Azeroth Upstream Fix Log

This document tracks source-level changes made by the Realmwalkers project
against the Legends-of-Azeroth Pandaria 5.4.8 upstream source.

## Policy

- Deviate from upstream only when required to correct a confirmed defect.
- Keep each fix as small and isolated as possible.
- Do not mix unrelated cleanup or refactoring into a fix.
- Document evidence before making the source change.
- Test each change independently.
- Keep each fix in its own Git commit whenever practical.
- Preserve enough information for the issue and patch to be reported upstream.

---

# RW-FIX-001
## Playerbots random character creation divide-by-zero

### Status
Confirmed upstream defect - patched and runtime-validated.

### Component
Playerbots

### Files

- `modules/mod_playerbots/src/Factory/RandomPlayerbotFactory.cpp`
- `src/server/game/DataStores/DBCStores.h`

### Symptom

Worldserver crashes while Playerbots creates random characters.

Observed Linux kernel error:

`trap divide error`

Crash address resolves inside:

`RandomPlayerbotFactory::CreateRandomBot(...)`

Disassembly at the crash shows an integer division where the divisor is zero.

### Root Cause

The core defines two CharSections DBC stores:

- `sCharSectionsStore`
- `sChrSectionStore`

`CharSections.dbc` is loaded into:

`sCharSectionsStore`

However, Playerbots reads character appearance data from:

`sChrSectionStore`

The `sChrSectionStore` object is never populated.

As a result, Playerbots finds no appearance records and creates empty vectors for:

- skin colors
- faces
- hair
- facial hair

Random character creation subsequently executes modulo operations using the
size of these vectors. A zero-sized vector results in integer divide-by-zero.

### Evidence

`src/server/game/DataStores/DBCStores.cpp`

Defines:

`DBCStorage <CharSectionsEntry> sCharSectionsStore(CharSectionsEntryfmt);`

and separately:

`DBCStorage <CharSectionsEntry> sChrSectionStore(CharSectionsEntryfmt);`

The DBC loader loads only:

`LOAD_DBC(..., sCharSectionsStore, ..., "CharSections.dbc");`

Playerbots uses:

`for (uint32 index = 0; index < sChrSectionStore.GetNumRows(); ++index)`

and:

`const CharSectionsEntry* charSection = sChrSectionStore.LookupEntry(index);`

Repository search confirmed no loader exists for `sChrSectionStore`.

### DBC Validation

Freshly extracted MoP 5.4.8 build 18414 `CharSections.dbc` was verified:

- Magic: WDBC
- Records: 16610
- Fields: 10
- Record size: 40
- String block size: 598869
- Total file size exactly matches calculated DBC size

Playable race/gender combinations contain valid Skin, Face and Hair records.
The DBC itself is not missing the required appearance data.

### Applied Fix

Playerbots now uses the already-loaded canonical:

`sCharSectionsStore`

instead of the unused:

`sChrSectionStore`

Because `sCharSectionsStore` was not exported in `DBCStores.h`, the existing
canonical store was also added to that header.

The unused duplicate `sChrSectionStore` definition/declaration was deliberately
left untouched. Removing it would be unrelated cleanup and should be handled
separately if desired.

### Build Validation

Worldserver rebuilt successfully from the patched source.

Build result:

- Exit code: 0
- Binary:
  `/srv/realmwalkers-mop/build/src/server/worldserver/worldserver`
- SHA256:
  `6b06e022f74f20459a3f55f6b2814d6ff166622a53dec94d3d488e89e77e9fc3`

### Runtime Validation

The patched worldserver was run directly against the staged fresh MoP 5.4.8
build 18414 extracted data.

The original divide-by-zero was not reproduced.

Playerbots progressed successfully through random-character initialization and
reported:

- 200 random bot accounts
- 1692 characters available
- 63 farming cache zones loaded
- 1230 farming spots loaded
- 123 city zones loaded
- `AI Playerbots initialized`

This confirms that random Playerbot character creation progressed past the
previous `rand() % 0` crash and that the corrected CharSections store is being
used successfully.

The test worldserver later encountered a separate null-pointer crash in:

`GameEventMgr::RunSmartAIScripts(uint16, bool)`

That crash occurred only after Playerbots had fully initialized and is being
tracked independently as RW-FIX-002. It is not considered a failure of
RW-FIX-001.

### Validation Result

RW-FIX-001 is considered runtime-validated.

The production source diff for this fix contains only:

1. Export of the already-existing loaded `sCharSectionsStore`.
2. Two Playerbots references changed from `sChrSectionStore` to
   `sCharSectionsStore`.

No unrelated cleanup or refactoring is included.

### Upstream Reporting

Prepare issue/PR for Legends-of-Azeroth after successful Realmwalkers testing.
