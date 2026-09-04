# ASUS ProArt PX13 Fedora TAS2783 Ses Düzeltmesi

> **Not:** Bu rehber, gerçek bir ASUS ProArt PX13 üzerinde yapılan test ve sorun giderme sürecine dayanarak yapay zeka tarafından hazırlanmıştır. Buradaki çözüm ve komutlar gerçek cihaz üzerinde uygulanıp doğrulanmıştır.

## Sorun

ASUS ProArt PX13 HN7306EA / HN7306EAC modellerinde Fedora kullanırken dahili hoparlörler çalışmayabiliyor.

Cihazın ses yolu:

```text
AMD SoundWire
→ TI TAS2783
→ Dahili hoparlörler
```

Sorun olduğunda:

- Dahili hoparlör kayboluyor.
- PipeWire sadece `auto_null` gösteriyor.
- YouTube ve diğer HTML5 videolar yükleniyor ekranında kalabiliyor.
- Firefox, Brave ve Chromium aynı sorunu yaşayabiliyor.
- Uyku modundan dönüşte ses kilitlenebiliyor.

Kontrol:

```bash
pactl list short sinks
```

Bozuk durumda genelde:

```text
auto_null
```

görülüyor.

Asıl sorun tarayıcı veya internet değil. Sorun TAS2783 / SoundWire ses yolunda.

---

## Test edilen sistem

- ASUS ProArt PX13 HN7306EAC
- AMD Ryzen AI Max+ 395 / Strix Halo
- Fedora 44 KDE
- Secure Boot açık
- TI TAS2783
- AMD SoundWire

Test edilen kernel sürümleri arasında:

```text
7.0.12
7.0.14
7.1.3
7.1.4
7.1.10
```

bulunuyor.

Stok Fedora kernelinde sorun bu sürümlerde devam etti.

---

## Çözüm

Çözüm için 16 adet TAS2783 kernel patch uygulanıyor.

Bu patchlerden sonra şu 4 modül yeniden derleniyor:

```text
snd-soc-tas2783-sdw.ko
soundwire-amd.ko
snd-soc-sdw-utils.ko
snd-soc-core.ko
```

Secure Boot açık olduğu için modüller MOK anahtarıyla imzalanıyor.

Daha sonra şu klasöre kuruluyor:

```text
/lib/modules/<kernel>/updates/px13-audio/
```

Örnek:

```text
/lib/modules/7.1.10-200.fc44.x86_64/updates/px13-audio/
```

---

## Çalıştığını nasıl kontrol ederiz?

```bash
modinfo -n \
snd_soc_tas2783_sdw \
soundwire_amd \
snd_soc_sdw_utils \
snd_soc_core
```

Çalışan sistemde modüller:

```text
/updates/px13-audio/
```

altından gelmelidir.

Örnek:

```text
/lib/modules/7.1.10-200.fc44.x86_64/updates/px13-audio/snd-soc-tas2783-sdw.ko
/lib/modules/7.1.10-200.fc44.x86_64/updates/px13-audio/soundwire-amd.ko
/lib/modules/7.1.10-200.fc44.x86_64/updates/px13-audio/snd-soc-sdw-utils.ko
/lib/modules/7.1.10-200.fc44.x86_64/updates/px13-audio/snd-soc-core.ko
```

Eğer yollar:

```text
/kernel/
```

altından geliyorsa stok Fedora modülleri kullanılıyor demektir.

---

## PipeWire kontrolü

```bash
pactl list short sinks
```

Çalışan durumda:

```text
HiFi__Speaker__sink
```

görülmelidir.

`IDLE` normaldir.

Ses çalarken:

```text
RUNNING
```

olur.

---

# Kernel güncellemesi sonrası ses neden tekrar gidiyor?

Bu fix kernel sürümüne bağlıdır.

Örneğin 7.1.4 için hazırlanan modüller 7.1.10 için kullanılamaz.

Fedora yeni kernel kurduğunda sistem tekrar stok modüllere geçer:

```text
Kernel güncellenir
→ Eski patchli modüller eski kernelde kalır
→ Yeni kernel stok TAS2783 modüllerini kullanır
→ Ses tekrar gider
```

Bu yüzden kernel güncellemesinden sonra modüllerin yeni kernel için tekrar hazırlanması gerekir.

---

# PX13 Audio Autofix

Bu işlem için otomatik sistem hazırlandı.

Kullanılan servisler:

```text
px13-audio-autofix.service
px13-audio-autofix.path
px13-audio-autofix.timer
```

Autofix sistemi:

1. Yeni kerneli bulur.
2. Kernel source paketini bulur veya indirir.
3. 16 TAS2783 patchini uygular.
4. 4 gerekli modülü derler.
5. Modülleri MOK anahtarıyla imzalar.
6. `/updates/px13-audio/` altına kurar.
7. `depmod` çalıştırır.
8. Modüllerin doğru yere kurulduğunu kontrol eder.

---

# Önemli: Kernel güncellemesinden hemen sonra reboot yapmayın

Autofix yeni kernel için modülleri hazırlarken bilgisayarı yeniden başlatırsanız işlem yarıda kesilebilir.

Gerçek test sırasında bu durum yaşandı:

```text
Kernel güncellendi
→ Autofix başladı
→ Kernel source indirildi
→ Derleme başladı
→ Bilgisayar yeniden başlatıldı
→ Servis yarıda kesildi
→ Yeni kernel stok modüllerle açıldı
→ Ses yoktu
```

Autofix tekrar çalıştırılıp işlem tamamlandıktan sonra yeniden başlatıldı ve ses geri geldi.

---

# Kernel güncellemesinden sonra yapılacak işlem

Kernel güncellemesi bittikten sonra:

```bash
bash px13-kernel-after-update.sh
```

çalıştırın.

Betik yeni kerneli kontrol eder ve autofix işlemini tamamlar.

Başarılı olduğunda:

```text
OK: 4/4 PX13 SES MODULU FIXLI
```

mesajı çıkar.

En altta kırmızı olarak:

```text
BİTTİ!!! Yeniden başlat!
```

yazısını görmeden bilgisayarı yeniden başlatmayın.

Sonra:

```bash
sudo reboot
```

---

# Yeniden başlattıktan sonra kontrol

```bash
uname -r

modinfo -n \
snd_soc_tas2783_sdw \
soundwire_amd \
snd_soc_sdw_utils \
snd_soc_core

pactl list short sinks
```

Beklenen:

```text
/updates/px13-audio/
```

ve:

```text
HiFi__Speaker__sink
```

---

# Secure Boot

Bu çözüm Secure Boot açıkken test edilmiştir.

Modüller MOK anahtarıyla imzalanmaktadır.

Kontrol:

```bash
sudo mokutil --test-key /root/module-signing/MOK.der
```

Modül imzası:

```bash
modinfo snd_soc_tas2783_sdw | grep -E "signer|sig_hashalgo"
```

MOK anahtarını silmeyin. Yeni kernel sürümlerinde tekrar kullanılır.

---

# Sorun tekrar olursa

İlk olarak:

```bash
uname -r
```

Sonra:

```bash
modinfo -n \
snd_soc_tas2783_sdw \
soundwire_amd \
snd_soc_sdw_utils \
snd_soc_core
```

Sonra:

```bash
pactl list short sinks
```

Eğer:

```text
auto_null
```

görüyorsanız ve modüller:

```text
/kernel/
```

altından geliyorsa yeni kernel için fix henüz kurulmamıştır.

---

# Autofix logları

Son logları görmek için:

```bash
journalctl -u px13-audio-autofix.service -n 200 --no-pager
```

Canlı takip:

```bash
sudo journalctl -fu px13-audio-autofix.service
```

Başarılı işlem sonunda:

```text
OK: <kernel> için PX13 audio fix kuruldu.
BİTTİ.
Finished px13-audio-autofix.service
```

görülmelidir.

---

# Kısa özet

Sorun:

```text
Fedora kernel güncellemesi
→ TAS2783 patchli modüller eski kernelde kalıyor
→ Yeni kernel stok modülleri kullanıyor
→ PipeWire auto_null
→ Dahili hoparlör yok
```

Çözüm:

```text
Yeni kernel
→ 16 TAS2783 patch
→ 4 modül derle
→ MOK ile imzala
→ /updates/px13-audio/
→ reboot
→ HiFi Speaker çalışıyor
```

Kernel güncellemesinden sonra:

```bash
bash px13-kernel-after-update.sh
```

çalıştırın.

Şunu görün:

```text
OK: 4/4 PX13 SES MODULU FIXLI
BİTTİ!!! Yeniden başlat!
```

Sonra:

```bash
sudo reboot
```

---

## Uyarı

Bu işlem kernel modülü derleme, kernel patch uygulama ve Secure Boot modül imzalama işlemleri içerir.

Komutları çalıştırmadan önce kontrol edin.

Bu rehber gerçek ASUS ProArt PX13 HN7306EAC cihazında yapılan Fedora 44 testlerine dayanır.

Farklı BIOS, kernel veya donanım revizyonlarında sonuç değişebilir.

Kullanım sorumluluğu kullanıcıya aittir.
