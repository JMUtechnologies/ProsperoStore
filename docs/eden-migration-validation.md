# ProsperoEden migration validation

The production change tested was commit `6b1ebc0583df4fe384dcdff7a2d7994cb4c9b67c`.
Subsequent additions publish the harness and this report; they do not change
production migration behavior.

## Automated checks and application build

- Linux Store host suite passed with AddressSanitizer and UndefinedBehaviorSanitizer
  (`STORE_FUZZ_SECONDS=0 bash tools/store-test.sh`). Parser fuzzing was disabled;
  the parser was unchanged.
- Regression cases cover normal and subsequent updates, empty destinations,
  custom settings, conflicting destinations, symbolic links, malformed settings,
  older backups, cross-filesystem refusal, interrupted migration, and recovery.
- Native PS5 release ZIP built with Clang 18 on Linux x86_64. Runtime and executable
  integrity validators passed. ZIP integrity, title ID `PPSA99000`, build label,
  and all 116 entries' `0777` permissions were verified.

## Console validation

Tested on an **original/phat PS5 running firmware 4.50**, as confirmed by the
tester, on 2026-10-10. The standalone payload compiled the production
`transaction.cpp` unmodified and passed **15 controlled scenarios**:

- Normal migration followed by a subsequent update.
- Refusal for destination conflicts, custom game-files selection, and malformed settings.
- Protection of an earlier backup containing unmigrated legacy data.
- Recovery after nine simulated interruption boundaries (app placement, each of
  seven directory moves, and recording), including repeated recovery.
- A destination conflict introduced after app placement, preservation of both
  copies, and successful recovery after resolving the fixture conflict.

One symbolic-link fixture could not be created on the console (`errno=17`) and
was skipped. This is a fixture setup limitation, not a claim about console-wide
symbolic-link support. The corresponding Linux refusal test passed.

The harness redirects app, data, staging, backup, journal, and receipt paths into
`/data/prosperostore/.eden-fix-test-6b1ebc0-20261010-r2`. It uses synthetic metadata,
dummy executable bytes, and tiny dummy personal files. Registration refresh is
disabled; download, available-space, and running-app probes are mocked. It does
not launch the dummy app or replace the real Store/Eden installation.

Before/after inventories of the real Eden `roms`, `keys`, `firmware`, `updates`,
and `user` directories, and the configuration hash, matched. This was an inventory
comparison, not full hashing of game contents. Temporary fixture directories were
removed after retrieving the report.

```text
PASS: 15 console scenarios; 1 unsupported setup check(s)
SKIP: symlink fixture could not be created; errno=17
Production code commit: 6b1ebc0
Real Eden files and settings were not accessed.
```

The last line describes the harness; the verification separately read the real
folder inventories and configuration for comparison.

## Reproducing the controlled console check

With the repository's PS5 payload SDK available and its compiler/linker prerequisites
installed, run:

```sh
PS5_PAYLOAD_SDK=/path/to/ps5-payload-sdk bash tools/store-eden-console-test.sh
```

Without the environment variable, the SDK defaults to `.deps/native/ps5-payload-sdk`.
The script builds and validates `build/console-migration-test/eden-migration-test.elf`.
Send that ELF using the console's existing external ELF loader. The script only
builds; it does not connect to or change a console.

Read `result.txt` under the isolated fixture directory via the console's file server.
The payload refuses to reuse an existing fixture root (exit code 2); remove only
that test directory after collecting the result before rerunning. It does not
clean up automatically, so failed cases remain inspectable.

## Scope still unverified

This was not an end-to-end Store-interface update of a real Eden installation.
Interruptions were simulated in the payload, not physical power cuts.
Cross-filesystem refusal was exercised on Linux, not on a second PS5 drive.
The standalone payload uses the payload SDK runtime; the full Store application
was built and integrity-checked separately.
