# Verification contract — see code/VERIFY.md (A1 pilot).
# NOT verified green in this sandbox — no Flutter SDK here. Run once on a machine
# with `flutter` on PATH before relying on this gate.
verify-fast:
	flutter analyze && flutter test

verify-full:
	flutter analyze && flutter test

.PHONY: verify-fast verify-full
