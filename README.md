# Türkçe F/Q Hibrit Klavye + KDE Masaüstü Kurulumu

Arch Linux + KDE Plasma 6 (Wayland) için, **ölçülerek doğrulanmış** bir masaüstü
kurulumu. Ana parçası şu: *F klavyenin harf konumlarında yaz, ama tüm sembolleri
Q klavyedeki yerinde tut.*

```
Üst  sıra:  f  g  ğ  ı  o  d  r  n  h  p  q  w      ← F klavye harfleri
Sayı sırası: "  1  2  3  4  5  6  7  8  9  0  *  -   ← Q klavye, dokunulmadı
AltGr + Q tuşu = @                                   ← Q klavye, dokunulmadı
```

Yanında: VS Code tarzı terminal kısayolları, tek tıkla düzen değiştiren panel
widget'ı ve TTY'den çalışan tam geri alma.

---

## Neden

Türkçe F klavye ile daha hızlı yazılır, ama F'nin sembol yerleşimi Q'dan farklı.
Yıllardır Q kullanan biri için asıl kas hafızası **sembollerde**: `@`, `€`,
noktalama, parantezler. Bu proje ikisini ayırıyor — harfler F'den, semboller
Q'dan.

Bunu yapmanın "temiz" yolu var: XKB'de `include "tr(basic)"` ile Q'nun her şeyini
miras al, sonra **sadece 32 harf tuşunun 1. ve 2. seviyesini** F'ye çevir.
3. ve 4. seviye (AltGr katmanı) fiziksel tuşta Q'da neyse o kalır.

Ölçüldü: `f_custom` varyantının AltGr katmanı `tr` ile **bire bir aynı** —
32 harf tuşunda 0 fark, 453 sembol/diğer tuşta 0 fark.

---

## Kurulum

```bash
git clone https://github.com/MrV0147/arch-kde-kurulum.git ~/klavye
cd ~/klavye
bash kur.sh
```

`kur.sh` seni sırayla yürütür ve `sudo` ya da elle bir şey gereken yerde
**durur, ne yapacağını söyler** — kendisi `sudo` çalıştırmaz.

### Adım adım (kur.sh'ın izlediği sıra)

| # | Adım | Kim yapar |
|---|---|---|
| 1 | `sudo bash 01-yedekle.sh` — yedek + giriş ekranını Q'ya sabitle | **sen** (sudo) |
| 2 | `sudo bash 03-xkb-kur.sh` — `f_custom` varyantı + pacman hook | **sen** (sudo) |
| 3 | `bash test-f_custom.sh` — 7 ölçüm | otomatik |
| 4 | `bash 05-panel-widget.sh` — iki düzen kaydı + widget | otomatik |
| 5 | Widget'ı panele ekle | **sen** (yoksa `40-panel.sh` ekler) |
| 6 | Konsole → Ayarlar → Klavye Kısayollarını Yapılandır → **Şemaları Yönet → Yeni Şema** → ad: `VSCode` → Kaydet | **sen** (15 sn, GUI) |
| 7 | `bash 04-konsole-kisayol.sh` — kısayolları şemaya yaz | otomatik |
| 8 | **Konsole'u tamamen kapat, yeniden aç** | **sen** |
| 9 | `bash test-konsole.sh` — 11 otomatik + yönlendirmeli ölçüm | otomatik |
| 10 | `bash 06-global-kisayol.sh` — `Ctrl+Shift+Esc` | otomatik |
| 11 | Oturumu kapat/aç — global kısayol etkin olsun | **sen** |
| 11a | `bash yenile-keymap.sh` — KWin keymap'i tazele | otomatik (03 çağırır) |
| 11b | `bash test-klavye-ctrl.sh` — F düzeninde Ctrl konumları | **sen** (canlı tuş) |
| 11c | `bash olc-tus.sh` → `bash 07-satir-sil.sh` — satır düzenleme | **sen** (tuş ölçümü) |
| 12 | `masaustu/` scriptleri — **isteğe bağlı**, görünümü değiştirir | **sen**, `--goster` ile bakarak |

**6. adım neden elle:** Konsole 26.08 menü tanımını Qt kaynağına gömüyor; aksiyon
adları diskte yok. "Yeni Şema" dediğinde `konsoleui.rc` + `sessionui.rc` yazıyor
ve script gerçek adları oradan **doğruluyor** — tahmin etmiyor.

**8. adım neden şart:** Kısayollar uygulama açılışında okunuyor. Açık pencerede
eskiler geçerli kalır.

**11. adım neden şart:** KWin `kglobalshortcutsrc`'yi izlemiyor, başlangıçta
okuyor.

Durumu her an görmek için:

```bash
bash durum.sh        # ne kurulu, ne aktif — dosyadan değil sistemden okur
bash test-f_custom.sh  # klavye gerçekten doğru mu (7 ölçüm)
```

Her şeyi geri almak — masaüstü hiç açılmasa bile, TTY'den (`Ctrl+Alt+F3`):

```bash
sudo bash ~/klavye/02-rollback.sh --force
```

---

## Ne yapıyor

### 1 — Yedek ve geri alma

Dokunulan her dosyanın zaman damgalı yedeği + `.backup` kopyası (var olanı
ezmez). `02-rollback.sh` TTY'den tek komutla her şeyi geri alır, kullanıcı
dosyalarının sahipliğini `chown` ile düzeltir.

Ayrıca **giriş ekranını Q'ya sabitler** (`localectl set-x11-keymap tr`). Sebep:
SDDM oturumdaki düzenden bağımsızdır; sabitlemezsen parola ekranında hangi
düzende olduğun belirsiz kalır.

### 2 — `tr(f_custom)` klavye varyantı

`uret-f_custom.sh`, XKB bloğunu **elle yazmaz** — `xkbcli compile-keymap`
çıktısından üretir:

```
seviye 1-2  ←  tr(f)      (F klavye harf konumları)
seviye 3-4  ←  tr(basic)  (Q klavye AltGr katmanı)
```

Böylece kaynak dosyada *görünmeyen* miras seviyeler de doğru yakalanır. Örnek:
`tr(basic)` içinde `<AD11>` yalnızca `{[gbreve, Gbreve]}` yazar, ama derlenmiş
keymap'te 3. ve 4. seviye `latin`'den mirasla doludur.

`03-xkb-kur.sh` idempotenttir ve **hiçbir şeyi yazmadan önce** değişikliği
`/tmp`'deki sanal bir XKB kökünde dener:

```
xmllint --noout evdev.xml
xkbcli compile-keymap --layout tr --variant f_custom
xkbcli compile-keymap --layout tr            # Q hâlâ bozulmadı mı
```

Üçü de geçmeden gerçek dosyaya dokunulmaz. Bir pacman hook'u,
`xkeyboard-config` her güncellendiğinde varyantı yeniden enjekte eder — yoksa
ilk güncellemede sessizce kaybolurdu.

**`x` harfi nerede:** Gerçek F klavyede `x`, virgül tuşundadır (`<BKSL>`). Ama o
tuş burada Q'nun virgül/noktalı virgülü olarak kalıyor. F'de `ç` harfi `<AB05>`'e
taşındığı için Q'nun `ç` tuşu (`<AB09>`) boşalıyor; `x` oraya yerleşiyor.
32 harfin hepsi tam, hiçbir Q sembolü kaybolmuyor.

### 3 — Konsole kısayolları (VS Code tarzı)

`Ctrl+C` kopyala, `Ctrl+V` yapıştır, `Ctrl+F` bul, `Ctrl+T`/`Ctrl+W` sekme.

**SIGINT'e ne oluyor:** Konsole'un `Kopyala` aksiyonu seçim yokken pasiftir;
pasif aksiyon tuşu yutmaz, `Ctrl+C` terminale geçer. Yani normal kullanımda
`Ctrl+C` eskisi gibi işlemi durdurur. Metin seçiliyken de durdurmak istersen
`Ctrl+Shift+C` için isteğe bağlı bir keytab katmanı var.

> `stty intr` ile `Ctrl+Shift+C` **atanamaz.** Terminal her ikisi için de aynı
> baytı (`0x03`) gönderir; Shift bilgisi kontrol karakteri protokolünde yoktur.
> Bu yüzden `~/.bashrc` ve `stty` hiç değiştirilmiyor — SSH, tmux, vim standart
> kalıyor.

`Ctrl+X` ve `Ctrl+Z` **kasten** boş bırakıldı: Konsole'da Kes aksiyonu yok
(terminal çıktısı düzenlenebilir değil), yani `Ctrl+X` terminale geçer ve
nano'dan çıkış çalışmaya devam eder. `Ctrl+Z` de SIGTSTP olarak kalır.

**Aksiyon adları tahmin edilmiyor, iki dosya iki ayrı iş yapıyor.** Konsole 26.08
menü tanımını Qt kaynağına gömüyor. Bir kez *Şemaları Yönet → Yeni Şema*
dediğinde `konsoleui.rc` + `sessionui.rc` dosyalarını **gerçek aksiyon adlarıyla**
yazıyor — script adları oradan doğruluyor. Ama kısayollar oraya yazılmıyor:

```
~/.local/share/kxmlgui5/konsole/{konsoleui,sessionui}.rc   ← aksiyon adları (oku)
~/.local/share/konsole/shortcuts/VSCode                    ← kısayollar (yaz)
konsolerc → [Shortcut Schemes] Current Scheme=VSCode       ← şemayı etkinleştir
```

`KShortcutSchemesHelper` şemayı `QStandardPaths::AppDataLocation` altında
`shortcuts/<ad>` yolunda arıyor. Bir tur `ui.rc` dosyalarına yazdık — **hata bile
vermedi, sessizce hiçbir şey olmadı.**

> **Ayırıcı tuzağı:** Bir aksiyona iki kısayol verirken ayırıcı `"; "` —
> noktalı virgül **artı boşluk**. Boşluksuz yazarsan Qt tüm dizgeyi tek
> kombinasyon sanıp ayrıştıramaz ve aksiyona **boş** kısayol verir, sessizce.
> Ölçüldü: `"Ctrl+C;Ctrl+Ins"` → `['']`, `"Ctrl+C; Ctrl+Ins"` → 2 adet.
> Script kısayolları liste olarak tutup ayırıcıyı tek yerde uyguluyor;
> `test-konsole.sh` de dizgeleri Qt'ye ayrıştırtıp boş çıkanı yakalıyor.

**Kısayollar düzene bağlıdır.** Bir kısayol "şu fiziksel tuş" değil, "`c` harfini
üreten tuş" demektir — F düzenine geçince `C` ile `V` yer değiştirir. Bu yüzden
`Ctrl+Insert` / `Shift+Insert` de bağlı: `Insert` harf tuşu olmadığı için hiçbir
düzende taşınmaz. Ayrıntı: `KISAYOLLAR.md`.

Doğrulama: `bash test-konsole.sh` — 11 otomatik ölçüm, ardından SIGINT ve
kopyalama için yönlendirmeli testler (sonucu senin "çalıştı galiba" demene
bırakmadan, `sleep`'in çıkış kodundan ve Klipper'dan okuyor).

### 4 — Q/F panel widget'ı

```
Sol tık   → düzeni değiştir
Sağ tık   → kısayol listesi (yardım paneli)
Tekerlek  → düzenler arasında gez
```

Kompakt, yuvarlak, bayraksız — sadece yüksek kontrastlı bir **Q** ya da **F**.
F'de dolu kapsül, Q'da sadece kenarlık: düzeni metin okumadan da ayırt edersin.

Alt süreç yok: `org.kde.plasma.workspace.keyboardlayout` QML modülü doğrudan
kullanılıyor, `layoutChanged` sinyali harfi anında güncelliyor. Poll yok,
`qdbus` çağrısı yok.

Sağ tık panelinin içeriği QML'e gömülü değil — `uret-yardim.sh` onu **canlı
sistemden** üretir. Bir kısayolu değiştirdiğinde panel yalan söylemez.

### 5 — Masaüstünün tamamı (`masaustu/`)

Açılış ekranından panel bileşenlerine kadar. **Her scriptin `--goster` kipi var**
— hiçbir şey yazmadan ne yapacağını anlatır:

```bash
bash masaustu/10-kwin.sh --goster              # köşe eylemleri, efektler, Alt+Tab
bash masaustu/30-gorunum.sh --goster           # tema, renk, ikon, imleç, GTK
bash masaustu/40-panel.sh --goster             # panel + masaüstü yapısı
bash masaustu/50-giris-ekrani.sh --goster      # SDDM, kilit ekranı, plymouth
bash masaustu/60-standart-kisayollar.sh --goster
bash masaustu/20-ek-bilesenler.sh --liste      # üçüncü parti bileşen kaynakları
```

| Dosya | Ne kurar |
|---|---|
| `10-kwin.sh` | Köşe eylemleri (sol üst Genel Görünüm, sağ üst Başlatıcı, sol alt Masaüstü, sağ alt Kilit), efektler, `coverswitch` Alt+Tab, orta tık yapıştırmayı kapatma |
| `20-ek-bilesenler.sh` | Üçüncü parti tema/plasmoid/paket listesi — lisans ve kaynaklarıyla |
| `30-gorunum.sh` | Lucy renk şeması (sarı vurgu), Papirus-Dark, Bibata imleç, Darkly, GTK 3/4 uyumu. Önce "kurulu mu" diye **bakar**, eksiği söyler |
| `40-panel.sh` | Panelleri Plasma'nın kendi betik API'siyle kurar — idempotent, `appletsrc`'ye elle dokunmaz |
| `50-giris-ekrani.sh` | SDDM Wayland greeter + kilit ekranı |
| `60-standart-kisayollar.sh` | KDE uygulama geneli kısayolları (`Redo=Ctrl+R` takası) |
| `panel-colorizer-ayarlari.json` | Panel Colorizer ayarları (bileşenin kendi içe aktarma penceresinden) |
| **`ENVANTER.md`** | **Tam envanter** — her özelleştirme, hangi dosyada durduğu, depoda olup olmadığı ve yoksa nedeni |

> `50-giris-ekrani.sh` deponun en pahalı öğrenilmiş parçası. SDDM'yi Wayland
> greeter'a alıyor (çift monitörde giriş formunun iki kez çıkması + X11
> greeter'ın ardında bıraktığı Xorg sürecinin `:0`'ı tutması). **Uyarı:** paket
> varsayılanı `CompositorCommand=weston` ve weston kurulu olmayabilir; sadece
> `DisplayServer=wayland` yazıp bunu ezmezsen boot loop olur. Script ikisini
> birlikte yazıyor ve `kwin_wayland` yoksa çalışmayı reddediyor.

Üçüncü parti tema/plasmoid'ler **depoya kopyalanmadı** — hepsinin kendi lisansı
var (GPL-3.0, LGPL, MIT), yalnızca kaynakları listeleniyor.

**Kişisel olan hiçbir şey depoda yok:** görev çubuğu başlatıcıları, uygulama
menüsü favorileri, hava durumu konumu, duvar kâğıdı dosya yolu, KDE Connect
cihazı, ekran/etkinlik UUID'leri, dokunmatik yüzey aygıt kimlikleri. Gerekçeleri
tek tek `masaustu/ENVANTER.md` sonundaki tabloda.

---

## Dosyalar

| Dosya | Ne yapar |
|---|---|
| `kur.sh` | Sıralı kurulum rehberi |
| `durum.sh` | Canlı durum raporu |
| `KISAYOLLAR.md` | Tam kısayol referansı — ne kaybettin, yerine ne kullanacaksın |
| `01-yedekle.sh` | Yedek + giriş ekranını Q'ya sabitle |
| `02-rollback.sh` | Her şeyi geri al (TTY'den çalışır) |
| `uret-f_custom.sh` | XKB bloğunu derlenmiş keymap'ten üret |
| `03-xkb-kur.sh` | Varyantı enjekte et + pacman hook |
| `test-f_custom.sh` | 7 ölçüm — harf, AltGr, sembol denetimi |
| `test-konsole.sh` | Konsole kısayolları: 11 otomatik + yönlendirmeli ölçüm |
| `yenile-keymap.sh` | **KWin'e keymap'i yeniden derletir** — oturum kapatmadan |
| `test-klavye-ctrl.sh` | F düzeninde Ctrl konumları: 4 otomatik + canlı tuş ölçümü |
| `olc-tus.sh` | Bir tuşun gönderdiği baytları ölçer (tahmin yerine) |
| `07-satir-sil.sh` | Satır düzenleme kısayollarını kurar (`.bashrc` + `bind -x`) |
| `test-satir-sil.sh` | Satır silme: 10 ölçüm, ikisi tuşa basmadan |
| `08-ctrl-a-sil.sh` | İsteğe bağlı: `Ctrl+A` = satırı komple sil |
| `payload/bashrc-qf.sh` | `_qf_satir_sil` / `_qf_secili_sil` + tuş bağlamaları |
| `04-konsole-kisayol.sh` | Konsole kısayol şeması |
| `05-panel-widget.sh` | İki düzen kaydı + widget kurulumu |
| `06-global-kisayol.sh` | `Ctrl+Shift+Esc` vb. |
| `uret-yardim.sh` | Widget yardım panelinin içeriği |
| `masaustu/` | KWin, tema, panel, SDDM scriptleri |
| `masaustu/ENVANTER.md` | **Tam envanter** — her özelleştirme, nerede durduğu, depoda olup olmadığı |
| `payload/tr-f_custom.xkb` | Üretilmiş XKB bloğu (kaynak değil çıktı; `uret-f_custom.sh` yeniden üretir) |
| `payload/plasmoid/org.kaan.qftoggle/` | Widget: `metadata.json`, `main.qml` (rozet), `Yardim.qml` (sağ tık paneli) |
| `payload/VSCode.keytab` | SIGINT katman 2 — yalnız `--keytab` ile kurulur, normalde gerekmez |

---

## Gereksinimler

Arch Linux + KDE Plasma 6, Wayland. Kullanılan araçlar:

```
xkeyboard-config  libxkbcommon (xkbcli)  libxml2 (xmllint)
konsole  plasma-desktop  plasma-workspace  qt6-tools (qdbus6)  systemd (busctl)
python  (üretici ve test scriptleri için)
```

Hepsi standart bir Plasma kurulumunda zaten var.

---

## Windows'ta çalışır mı?

Hayır — XKB, Konsole ve plasmoid'lerin hiçbiri Windows'ta yok. Ama 4 fazın
ikisi Windows'ta zaten hazır geliyor: Windows Terminal'de `Ctrl+C` zaten
"seçim varsa kopyala, yoksa SIGINT" davranışında ve `Ctrl+Shift+Esc` zaten
Görev Yöneticisi'ni açıyor. Asıl iş klavye düzeni: **MSKLC** ile aynı mantık
(harfler F'den, AltGr katmanı Q'dan) `.dll` olarak üretilebilir.

---

## Lisans

MIT — `LICENSE`. Üçüncü parti tema ve plasmoid'ler kendi lisanslarına tabidir
ve bu depoda **yer almaz**, yalnızca kaynakları listelenir.
