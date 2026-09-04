#!/usr/bin/env bash
set -euo pipefail

echo "==== PX13 KERNEL SONRASI SES FIX ===="

echo "---- Hedef kernel bulunuyor ----"

TARGET_KV="$(
  comm -12 \
    <(find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V) \
    <(find /usr/src/kernels -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V) \
  | tail -n 1
)"

if [ -z "$TARGET_KV" ]; then
  echo "HATA: /lib/modules ile /usr/src/kernels arasında eşleşen kernel bulunamadı."
  exit 1
fi

echo "Hedef kernel: $TARGET_KV"

echo "---- Gerekli paketler kontrol ediliyor ----"

sudo dnf install -y \
  gcc make git openssl mokutil patch \
  "kernel-devel-$TARGET_KV" \
  kernel-headers

echo "---- Autofix hazırlanıyor ----"

sudo systemctl daemon-reload
sudo systemctl reset-failed px13-audio-autofix.service 2>/dev/null || true

echo "---- PX13 audio autofix çalışıyor ----"

sudo systemctl start px13-audio-autofix.service

echo "---- Modüller kontrol ediliyor ----"

PATHS="$(modinfo -k "$TARGET_KV" -n \
  snd_soc_tas2783_sdw \
  soundwire_amd \
  snd_soc_sdw_utils \
  snd_soc_core 2>&1)"

echo "$PATHS"

FIX_COUNT="$(printf '%s\n' "$PATHS" \
  | awk '/\/updates\/px13-audio\// {c++} END {print c+0}')"

echo

if [ "$FIX_COUNT" -eq 4 ]; then
  echo "============================================"
  echo "OK: 4/4 PX13 SES MODULU FIXLI"
  echo "Kernel: $TARGET_KV"
  echo "============================================"
  echo
  printf '\033[1;31mBİTTİ!!! Yeniden başlat!\033[0m\n'
else
  echo "============================================"
  echo "HATA: FIX TAMAMLANMADI - REBOOT ATMA"
  echo "Fixli modul sayisi: $FIX_COUNT / 4"
  echo "============================================"
  echo
  echo "---- AUTOFIX SON LOG ----"
  journalctl -u px13-audio-autofix.service -n 200 --no-pager
  exit 1
fi
