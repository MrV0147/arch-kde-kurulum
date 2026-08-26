# Klavye ve Kısayol Referansı

> Bunu ileride unuttuğunda açacaksın. **Canlı durum** için: `bash ~/klavye/durum.sh`
> **Her şeyi geri almak** için: `sudo bash ~/klavye/02-rollback.sh`

---

## ① Klavye düzeni — "F harfler, Q semboller"

İki düzen kayıtlı, panel butonundan geçiş yapılıyor:

| Düzen | XKB adı | Panelde |
|---|---|---|
| Standart Türkçe Q | `tr` | boş kapsül, içinde **Q** |
| Hibrit | `tr(f_custom)` | dolu kapsül, içinde **F** |

### Kural (tek cümle)

> **Harfler F'den, semboller Q'dan.**
> Daha teknik: seviye 1–2 (harf/büyük harf) F klavyeden, seviye 3–4 (AltGr,
> AltGr+Shift) fiziksel tuşta Q'da ne varsa aynen.

**Sonuç: `f_custom`'ın AltGr katmanı `tr` ile bire bir aynı.** Ölçüldü — 32 harf
tuşunda 0 fark, 453 sembol/diğer tuşta 0 fark.

### Tuş şeması

```
SAYI SIRASI — İKİ DÜZENDE DE AYNI (hiç dokunulmadı)
  "   1   2   3   4   5   6   7   8   9   0   *   -

              Q (tr)                         F harfli (tr f_custom)
  ┌───────────────────────────┐    ┌───────────────────────────┐
  │  q  w  e  r  t  y  u  ı  o  p  ğ  ü   │  f  g  ğ  ı  o  d  r  n  h  p  q  w  │
  │  a  s  d  f  g  h  j  k  l  ş  i   ,  │  u  i  e  a  ü  t  k  m  l  y  ş   ,  │
  │  z  x  c  v  b  n  m  ö  ç      .     │  j  ö  v  c  ç  z  s  b  x      .     │
  └───────────────────────────┘    └───────────────────────────┘
                                              ▲              ▲
                                     virgül yerinde       x burada
```

### `x` neden orada?

Gerçek F klavyede `x`, virgülün olduğu tuştadır (`<BKSL>`). Ama o tuş bizde
**Q'nun virgül/noktalı virgülü** olarak kalıyor — kural bu. F'de `ç` harfi
`<AB05>`'e taşındığı için Q'nun `ç` tuşu (`<AB09>`) boşalıyor; `x` oraya
yerleşiyor. Böylece 32 harfin hepsi tam, hiçbir Q sembolü kaybolmuyor.

### AltGr örnekleri (hepsi Q'daki yerinde)

| Bas | Çıkan | Not |
|---|---|---|
| `AltGr` + fiziksel **Q** tuşu | `@` | F'de orada `f` var, ama `@` yerinde |
| `AltGr` + fiziksel **E** tuşu | `€` | |
| `AltGr` + fiziksel **T** tuşu | `₺` | |
| `AltGr` + fiziksel **Ü** tuşu | `~` | |
| `AltGr` + fiziksel **Ş** tuşu | `´` | |
| `AltGr` + fiziksel **Ö** tuşu | `×` | |
| `AltGr` + fiziksel **Ç** tuşu | `·` | bu tuş artık `x` ama `·` yerinde |

### Dosyalar

| Ne | Nerede |
|---|---|
| Harf tanımı | `/usr/share/X11/xkb/symbols/tr` → `xkb_symbols "f_custom"` |
| KDE'nin görmesi için | `/usr/share/X11/xkb/rules/evdev.xml` |
| CLI araçlarının görmesi için | `/usr/share/X11/xkb/rules/evdev.lst` |
| Hangi düzenler kayıtlı | `~/.config/kxkbrc` → `[Layout]` |
| Bloğu üreten script | `~/klavye/uret-f_custom.sh` |
| Doğrulayan test | `~/klavye/test-f_custom.sh` |

> **Paket güncellemesi:** `symbols/tr` ve `evdev.xml`, `xkeyboard-config`
> paketine ait — her güncelleme siler. `/etc/pacman.d/hooks/95-xkb-f_custom.hook`
> güncelleme sonrası otomatik yeniden enjekte ediyor.

---

## ② Konsole (terminal) kısayolları

| Tuş | Ne yapar | Aksiyon adı | Nerede tanımlı | Eskiden neydi / ne kaybettim |
|---|---|---|---|---|
| `Ctrl+C` · `Ctrl+Insert` | **Kopyala** | `edit_copy` | `sessionui.rc` | Eskiden `Ctrl+Shift+C`. Seçim yokken tuş terminale geçer → **`Ctrl+C` hâlâ işlemi durdurur** |
| `Ctrl+Shift+C` | **SIGINT** (işlemi durdur) | — | keytab (katman 2, isteğe bağlı) | Eskiden Kopyala'ydı |
| `Ctrl+V` · `Shift+Insert` | Yapıştır | `edit_paste` | `sessionui.rc` | Eskiden `Ctrl+Shift+V` |
| `Ctrl+Shift+V` | Yapıştır (ikinci) | `edit_paste` | `sessionui.rc` | Değişmedi, eski alışkanlık korundu |
| `Ctrl+A` | **Tümünü seç** (kaydırma tamponu) | `select-all` | `sessionui.rc` | Eskiden `Ctrl+Shift+A`. **Kayıp: `C-a` = satır başına git → yerine `Home` tuşu** |
| `Ctrl+F` | Bul | `edit_find` | `sessionui.rc` | Eskiden `Ctrl+Shift+F`. **Kayıp:** readline `C-f` (ileri karakter) → yerine **`→` tuşu** |
| `F3` | Sonrakini bul | `edit_find_next` | `sessionui.rc` | Eskiden `Ctrl+Shift+F3` |
| `Shift+F3` | Öncekini bul | `edit_find_prev` | `sessionui.rc` | — |
| `Ctrl+T` | Yeni sekme | `new-tab` | `konsoleui.rc` | Eskiden `Ctrl+Shift+T`. Kayıp: readline `C-t` (harf takası) — pratikte kullanılmaz |
| `Ctrl+W` | Sekmeyi kapat | `close-session` | `sessionui.rc` | Eskiden `Ctrl+Shift+W`. **Kayıp: `C-w` = önceki kelimeyi sil → yerine `Alt+Backspace`** |

**Sekme geçişi `Shift+Sağ` / `Shift+Sol` olarak kaldı.** `Ctrl+Tab` atanmadı:
sekme gezinme aksiyonları (`next-view`/`previous-view`) hiçbir menüde yer
almadığı için Konsole'un yazdığı `ui.rc` dosyalarında da görünmüyorlar. Adlarını
tahmin etmek yerine dokunmadım — istersen Konsole'un kendi kısayol penceresinden
elle atayabilirsin.

**Dosyalar:**

| Dosya | Ne için |
|---|---|
| `~/.local/share/konsole/shortcuts/VSCode` | **Kısayolların gerçek yeri** |
| `~/.config/konsolerc` → `[Shortcut Schemes] Current Scheme=VSCode` | Şemayı etkinleştirir |
| `~/.local/share/kxmlgui5/konsole/{konsoleui,sessionui}.rc` | Menü yapısı + **gerçek aksiyon adları** (buradan doğrulanıyor, buraya yazılmıyor) |
| `~/.local/share/konsole/VSCode.keytab` | SIGINT katman 2 (isteğe bağlı) |

> **Mekanizma notu — üç dosyayı da bulmak zaman aldı.** Konsole 26.08
> "Yeni Şema" dediğinde `kxmlgui5/konsole/` altına `konsoleui.rc` +
> `sessionui.rc` yazıyor ve içlerine boş bir `<ActionProperties scheme="VSCode"/>`
> koyuyor. **Kısayolların yeri orası değil.** Şemanın gövdesi
> `~/.local/share/konsole/shortcuts/VSCode` dosyasında —
> `KShortcutSchemesHelper` şemayı `QStandardPaths::AppDataLocation` altında
> `shortcuts/<ad>` olarak arıyor, Konsole için bu `~/.local/share/konsole`.
> Konsole o dosyayı boş oluşturuyor: `<gui><ActionProperties/></gui>`.
>
> `ui.rc` dosyalarına yazmayı bir tur denedik — **hata bile vermedi, sessizce
> hiçbir şey olmadı.** Aksiyon adları için hâlâ o dosyalar okunuyor (menü
> yapısı orada), ama kısayol yazmak için şema dosyası kullanılıyor.
>
> Ayrıca `konsolerc` → `[Shortcut Schemes] Current Scheme=VSCode` **ayarlı
> olmalı**; ayarlı değilse şema hiç yüklenmez.

> **Ayırıcı tuzağı — bir kısayola iki tuş verirken.** Qt'nin
> `QKeySequence::listFromString` ayırıcısı `"; "` — noktalı virgül **artı
> boşluk**. Boşluğu koymazsan Qt tüm dizgeyi tek kombinasyon sanıp
> ayrıştıramaz ve aksiyona **boş** kısayol verir; hata da vermez. Ölçüldü:
>
> ```
> "Ctrl+C;Ctrl+Ins"   ->  1 adet  ['']                      boş
> "Ctrl+C; Ctrl+Ins"  ->  2 adet  ['Ctrl+C', 'Ctrl+Ins']    doğru
> ```
>
> Bu yüzden bir tur `Ctrl+A` çalışırken (tek kısayol, ayırıcı yok) `Ctrl+C`
> hiçbir şey yapmıyordu. `test-konsole.sh` artık dizgeleri Qt'nin kendisine
> ayrıştırtıp boş çıkanı yakalıyor.

**Doğrulama:** `bash ~/klavye/test-konsole.sh` (Konsole içinde çalıştır)

### Kısayollar iki düzende de aynı fiziksel tuşta — nasıl

Bir kısayol normalde "şu fiziksel tuş" değil, **"`c` harfini üreten tuş"**
demektir. Düzen değişince harf taşınır, kısayol da onunla taşınır — ve ölçtük ki
Q ile `f_custom` arasında **32 harften 30'u yer değiştiriyor** (yalnız `p` ve `l`
sabit). En kötüsü de `C` ile `V` birbirinin yerine geçiyordu.

Bu **XKB katmanında** çözüldü: `Control` basılıyken tuş, o fiziksel konumun
**Q klavyedeki harfini** üretiyor.

```
Q'nun C tuşu (AB03):   yazarken → v          Ctrl ile → c    →  Ctrl+C
Q'nun V tuşu (AB04):   yazarken → c          Ctrl ile → v    →  Ctrl+V
```

Yani F düzeninde yazarken F harfleri geliyor, ama `Ctrl+C` hep Q'daki `C`
tuşunda kalıyor. **32 harfin hepsi için geçerli**, sadece C/V için değil.

| Nasıl çalışıyor | |
|---|---|
| Tip | `QF_CTRL_ALPHABETIC` — `types/complete` içine enjekte edilir |
| Mekanizma | `Control` bir **seviye seçici**: `map[Control] = Level5` |
| Kritik satır | `preserve[Control] = Control` |
| Kapsam | **Tüm uygulamalar** — Konsole, Firefox, VS Code, hepsi |

`preserve[]` olmasaydı `Control` bir seviye seçici olarak *tüketilir* ve uygulama
yalnızca `c` görürdü, `Ctrl+C` değil. Aynı deseni upstream de kullanıyor:
`types/pc` → `PC_CONTROL_SUPER_LEVEL2`.

**Ölçüldü** (`test-f_custom.sh`, ölçüm 5–6): 32 harf tuşunun hepsinde 5. seviye
= o tuşun Q'daki harfi, 0 fark; `preserve[Control]` derlenmiş keymap'te mevcut.

Bunun yanında `Ctrl+Insert` / `Shift+Insert` de bağlı — `Insert` harf tuşu
olmadığı için zaten hiçbir düzende taşınmıyor, ikinci bir güvence.

### SIGINT nasıl çalışıyor — iki katman

1. **Seçim geçişi (asıl):** Konsole'un `Kopyala` aksiyonu bir şey seçili
   değilken pasiftir; pasif aksiyon tuşu yutmaz, `Ctrl+C` terminale geçer.
   Yani normal kullanımda `Ctrl+C` = eskisi gibi işlemi durdurur.
2. **Keytab (garanti):** Metin *seçiliyken* de durdurmak gerekirse
   `Ctrl+Shift+C` doğrudan `0x03` (ETX) baytı gönderir.

> **Neden `stty intr ^[...]` kullanmadık:** `stty intr` ile `Ctrl+Shift+C`
> **atanamaz.** Terminal, `Ctrl+C` ve `Ctrl+Shift+C` için aynı baytı (`0x03`)
> gönderir — Shift bilgisi kontrol karakteri protokolünde yoktur. `stty` tek
> bayt alır, tuş kombinasyonu değil. Bu yüzden çözüm terminal emülatörünün
> kendi tuş katmanında. **`~/.bashrc` ve `stty` hiç değiştirilmedi** → SSH,
> tmux ve `vim` içinde her şey standart.

---

## ②-B Satır düzenleme — yazdığını tek hamlede silmek

Terminalde `Ctrl+A` ile "hepsini seç, sonra sil" doğrudan çalışmaz: Konsole'un
seçimi **kaydırma tamponunun görsel seçimi**, düzenlenebilir bir metin değil.
Ama yazdığın komut satırı readline'ın tamponunda durur ve bash `bind -x` ile o
tampona erişim verir (`READLINE_LINE` / `READLINE_POINT`). İstediğin şey tam
olarak bunun üzerinden yapıldı.

| Tuş | Ne yapar | Nerede tanımlı |
|---|---|---|
| `Ctrl+U` | **Yazdığın satırın tamamını sil** — imleç nerede olursa olsun | `bashrc-qf.sh` → `kill-whole-line` |
| `Shift+Delete` | Aynısı (ölçülen tuşa göre bağlanır) | `_qf_satir_sil` |
| `Ctrl+Shift+Delete` | **Panodaki metni satırdan çıkar** — yoksa satırın tamamını sil | `_qf_secili_sil` |
| `Ctrl+Backspace` | Önceki kelimeyi sil | `backward-kill-word` |
| `Ctrl+Delete` | Sonraki kelimeyi sil | `kill-word` |
| `↑` / `↓` | Yazdığının **başına uyan** komutları geçmişte ara | `history-search-backward/forward` |

**"Seç → sil" akışı:** bir parçayı fareyle seç → `Ctrl+C` (kopyala) →
`Ctrl+Shift+Delete`. Panodaki metin satırda geçiyorsa **yalnızca o parça**
silinir; geçmiyorsa satırın tamamı gider.

> **`Ctrl+U` neden panoya bakmıyor:** `Ctrl+A` tek başına panoya kopyalamaz.
> Varsayılan tuş panoyu okusaydı, ekrandaki seçimle ilgisi olmayan **eski** bir
> pano içeriğini satırdan silebilirdi. Sessiz yanlış silme, silmemekten kötüdür.
> Panoya dayalı davranış ayrı bir tuşta, isteyerek çağrılıyor.

**Tuş dizileri tahmin edilmiyor:** `olc-tus.sh` gerçek terminalde tuşa bastırıp
gelen baytları ölçer ve `~/.local/state/qf-tuslar.conf`'a yazar; `bashrc-qf.sh`
onu okuyup bağlar. Ölçülmemiş bir tuş **bağlanmaz** — uydurma dizi yazılmaz.

**Doğrulama:** `bash ~/klavye/test-satir-sil.sh` — 6 ölçüm, ikisi fonksiyonları
alt kabukta çağırıp `READLINE_LINE`'ın gerçekten değiştiğini **tuşa basmadan**
ölçer.

---

## ③ Global (KDE) kısayolları

| Tuş | Ne yapar | Nerede tanımlı | Not |
|---|---|---|---|
| `Ctrl+Shift+Esc` | Sistem İzleyicisi (Görev Yöneticisi) | `~/.config/kglobalshortcutsrc` → `[services]` | Windows alışkanlığı |

**İsteğe bağlı** (`bash ~/klavye/06-global-kisayol.sh --tumu` ile eklenir):

| Tuş | Ne yapar | Nereden tanıdık |
|---|---|---|
| `Meta+E` | Dolphin | Windows `Win+E` |
| `Meta+Shift+S` | Spectacle, bölge seçimi | Windows `Win+Shift+S` |
| `Ctrl+Alt+T` | Konsole | Linux klasiği |

**Zaten vardı, dokunulmadı:** `Meta+V` (pano geçmişi) · `Meta+L` (kilitle) ·
`Meta+D` (masaüstünü göster) · `Ctrl+Alt+Del` (oturum ekranı)

> **Bilgi — sistemde önceden var olan çakışmalar** (bu kurulumun işi değil,
> Krohnkite döşeme eklentisinden geliyor):
> `Meta+D` (Masaüstüne Bak ↔ Krohnkite Decrease) ·
> `Meta+T` (Döşeme Düzenleyici ↔ Krohnkite Tile) ·
> `Meta+L` (Oturumu Kilitle ↔ Krohnkite Focus Right)

---

## ④ KASTEN DOKUNULMAYANLAR — ve nedeni

Bunlar "unutulmadı", bilerek bırakıldı.

| Ne | Neden dokunulmadı |
|---|---|
| **`Ctrl+Z`** | Geri Al'a bağlanmadı. Bağlansaydı **SIGTSTP** (işlemi uyutma) kaybolurdu — `fg`/`bg` iş akışının can damarı. Terminalde "geri al" diye bir kavram zaten yok; komut satırında yanlış yazdıysan **`Ctrl+_`** (readline undo) var. |
| **`Ctrl+X`** | Konsole'da **Kes (Cut) aksiyonu yok** — terminal çıktısı düzenlenebilir bir tampon değil, kesilecek bir şey yok. Bağlanacak aksiyon olmadığı için tuş boşta kaldı. **Sonuç iyi: nano'dan `Ctrl+X` ile çıkmaya devam ediyorsun**, bash'te de `C-x` öneki (`C-x C-e` = komutu editörde aç) çalışıyor. |
| **`stty`** | Hiç değiştirilmedi. `stty intr` hâlâ `^C`. Böylece SSH, tmux, `vim`, `htop` — hepsi standart davranıyor. |
| **`~/.bashrc`** | ⚠️ **Artık dokunuluyor** — tek satırlık bir `source`. `bind -x` bir bash builtin'i olduğu için `.inputrc`'ye yazılamıyor ve `READLINE_LINE`'a erişimin başka yolu yok. Asıl kod ayrı dosyada (`~/.local/share/qf-klavye/`), `.bashrc`'de yalnızca iki satırlık sentinel'li blok var. Geri alma tek satırı siler. |
| **`/etc/X11/xorg.conf.d/00-keyboard.conf`** | İçine `f_custom` **yazılmadı**, kasten. Bu dosya **giriş ekranını (SDDM)** belirler. Düz `tr` (Q) olarak sabitlendi ki bilgisayarı açarken parolanı hangi düzende yazacağın belirsiz kalmasın. |
| **`Meta+V`, `Meta+L`, `Meta+D`** | Zaten atanmıştı, üzerine yazılmadı. |
| **Panel yapılandırması** | `plasma-org.kde.plasma.desktop-appletsrc` **elle düzenlenmedi** — plasmashell çalışırken üzerine yazıyor ve değişiklik kaybolurdu. Widget panele, Plasma'nın kendi betik API'siyle eklendi (`org.kde.PlasmaShell.evaluateScript` → `panel.addWidget`). Kaldırmak için: panele sağ tık → Bileşenleri Düzenle → widget'ın üzerinde çarpı. |

### ⚠️ Kilit ekranı

Kilit ekranı SDDM değil; oturumun **o anki** düzenini kullanır. **F'deyken
kilitlersen kilit ekranı da F olur.** Giriş ekranı (bilgisayarı ilk açtığın an)
her zaman Q'dur. Kilitlemeden önce emin olmak istersen panel butonuna bakıp
Q'ya al.

---

## ⑤ Ne kaybettim → yerine ne kullanacağım

| Kaybolan | Ne yapıyordu | Yerine |
|---|---|---|
| `Ctrl+W` (bash) | Önceki kelimeyi sil | **`Alt+Backspace`** |
| `Ctrl+F` (bash) | Bir karakter ileri | **`→` tuşu** |
| `Ctrl+A` (bash) | Satır başına git | **`Home` tuşu** |
| `Ctrl+T` (bash) | İki harfin yerini değiştir | — (pratikte kullanılmaz) |
| F'nin AltGr karakterleri (`¥ ® ¶ § « »`) | F klavyenin kendi AltGr katmanı | Yok — çünkü **Q'da da yoktu**. AltGr katmanı Q'yla bire bir aynı tutuldu. |

---

## ⑥ Geri alma

| Ne istiyorum | Komut |
|---|---|
| **Her şeyi geri al** (TTY'den de çalışır) | `sudo bash ~/klavye/02-rollback.sh` |
| Sadece klavye varyantını kaldır | `sudo bash ~/klavye/03-xkb-kur.sh --kaldir` |
| Sadece Konsole kısayollarını kaldır | `bash ~/klavye/04-konsole-kisayol.sh --kaldir` |
| Sadece global kısayolları kaldır | `bash ~/klavye/06-global-kisayol.sh --kaldir` |
| Sadece widget'ı + ikinci düzeni kaldır | `bash ~/klavye/05-panel-widget.sh --kaldir` |
| Durumu gör | `bash ~/klavye/durum.sh` |
| Klavye doğru mu ölç | `bash ~/klavye/test-f_custom.sh` |

**Masaüstü hiç açılmazsa:** `Ctrl+Alt+F3` → giriş yap →
`sudo bash ~/klavye/02-rollback.sh --force`

Yedekler: `~/klavye/yedek/SON/` (zaman damgalı) ve orijinal dosyaların yanında
`.backup` uzantılı kopyalar.