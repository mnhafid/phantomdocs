# 08 — Config (branch): merge ict-main ke release/20261116-dev (konflik PR #1491)

- **Ticket / PR:** PR #1491 (release/20261116-dev → ict-main); PR sync ke ict-dev dan phi-dev menyusul
- **Dicatat:** 20 Nov 2026
- **Status:** merge di-stage di `.worktrees/release-20261116`; menunggu user commit + push

## Alasan

PR #1491 punya 24 file konflik dengan `ict-main`. Release tidak bisa di-merge sebelum konflik selesai.

## Perubahan

- `origin/ict-main` di-merge ke `release/20261116-dev`. Semua konflik diselesaikan ke sisi release.
- Tree hasil merge = tree HEAD release (742cc7fb). **Tidak ada perubahan logic.**
- Baris ict-main yang dibuang sudah digantikan oleh PR berikutnya (#1389, #1244, #1452, dll).
- Sync ke phi-dev: 34 file konflik, semua ke sisi phi-dev; tree akhir = `origin/phi-dev`.
  Override manual (rerere salah pilih): 3 file water-flood InjectionWellProducerReading* → versi phi-dev.

## Langkah deploy

1. User: `git commit` lalu `git push origin release/20261116-dev`.
2. Buka PR release/20261116-dev → ict-dev (bersih, 0 file berubah).
3. Buat branch sync phi-dev, merge `origin/phi-dev`, override 3 file water-flood, cek tree == `origin/phi-dev`, buka PR → phi-dev.
4. Hapus worktree scratch `.worktrees/release-20261116-to-phi-dev`.

## Gap yang diketahui

- release / ict-main belum punya 33e79d73 (PHI-2133): `producer-history` water-flood masih mengembalikan `producers`, bukan `wells`.

## Verifikasi

- `git diff <release HEAD> <merge commit>` kosong.
- Build PhantomSolution.sln: 0 error.
- PR #1491 tidak lagi menunjukkan konflik.
