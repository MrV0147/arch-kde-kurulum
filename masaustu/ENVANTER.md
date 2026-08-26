# Masaüstü Envanteri

Bu makinedeki **her** özelleştirmenin listesi: ne olduğu, hangi dosyada durduğu,
depoda karşılığının olup olmadığı ve **yoksa neden yok**.

Kural şu: *ayar* gider, *kimlik* gitmez. Bir değerin (renk, tuş, köşe eylemi)
paylaşılmasında sakınca yok; hangi uygulamaları kullandığın, nerede oturduğun,
hangi dosyaları açtığın gitmez.

Efsane: ✅ depoda · ⚙️ depoda ama elle adım gerekiyor · 🚫 kasten dışarıda

---

## 1. Açılış (boot)

| Ne | Değer | Nerede | Durum |
|---|---|---|---|
| Önyükleyici | GRUB, özelleştirilmemiş | `/boot/grub/grub.cfg` | 🚫 makineye özgü (disk UUID'leri) |
| Açılış animasyonu | Plymouth teması **`bgrt`** | plymouth yapılandırması | ✅ `50-giris-ekrani.sh --goster` belgeliyor |

`bgrt` firmware'in kendi logosunu kullanır — ek tema paketi gerekmez, üretici
logosuyla açılır.

---

## 2. Giriş ekranı (SDDM)

| Ne | Değer | Durum |
|---|---|---|
| Görüntü sunucusu | **Wayland greeter** | ✅ `50-giris-ekrani.sh` |
| Bileşik yönetici | `kwin_wayland --no-lockscreen --no-global-shortcuts --locale1` | ✅ |
| Greeter ortamı | `QT_WAYLAND_SHELL_INTEGRATION=layer-shell` | ✅ |
| Klavye düzeni | düz `tr` (Q) — varyantsız | ✅ `01-yedekle.sh` |

Bu, deponun en pahalı öğrenilmiş parçası. İki sorunu çözüyor: çift monitörde
giriş formunun iki kez çıkması, ve X11 greeter'ın ardında bırakıp gitmediği
Xorg sürecinin `:0`'ı tutması (gamescope'un Xwayland'i açamamasına yol açıyordu).

> **Tuzak:** SDDM paketinin varsayılanı `CompositorCommand=weston --shell=kiosk`
> ve weston kurulu olmayabilir. Sadece `DisplayServer=wayland` yazıp bunu
> ezmezsen **boot loop** olur. Script ikisini birlikte yazıyor ve
> `kwin_wayland` yoksa çalışmayı reddediyor.

---

## 3. Kilit ekranı

| Ne | Değer | Durum |
|---|---|---|
| Otomatik kilit | **kapalı** (`Autolock=false`, `Timeout=0`) | ✅ `50-giris-ekrani.sh` |

> Kilit ekranı SDDM değildir; oturumun **o anki** klavye düzenini kullanır.
> F düzenindeyken kilitlersen kilit ekranı da F olur. Giriş ekranı her zaman Q.

---

## 4. Görünüm

| Ne | Değer | Nerede | Durum |
|---|---|---|---|
| Genel görünüm | **Nothing** | `kdeglobals [KDE] LookAndFeelPackage` | ⚙️ tema ayrı kurulur |
| Renk şeması | **Lucy** (sarı vurgu `255,229,0`) | `kdeglobals [General] ColorScheme` | ⚙️ |
| Vurgu rengi | `255,229,0`, duvar kâğıdından **alınmıyor** | `kdeglobals [General]` | ✅ `30-gorunum.sh` |
| Simge teması | **Papirus-Dark** | `kdeglobals [Icons]` | ⚙️ paket: `papirus-icon-theme` |
| İmleç | **Bibata-Modern-Ice** (24 px) | `kcminputrc [Mouse]` | ⚙️ AUR |
| Widget stili | **Darkly** | `kdeglobals [KDE] widgetStyle` | ⚙️ |
| Pencere dekorasyonu | **org.kde.darkly** | `kwinrc [org.kde.kdecoration2]` | ⚙️ |
| Kontrast | `contrast=4`, `frameContrast=0.2` | `kdeglobals [KDE]` | ✅ |
| GTK uyumu | koyu tema + aynı simge/imleç | `gtk-3.0`, `gtk-4.0/settings.ini` | ✅ `30-gorunum.sh` |
| Yazı tipi | `Noto Sans 10` (GTK tarafı) | `gtk-*/settings.ini` | ✅ |

Kurulu ama **kullanılmayan** alternatifler: `Scratchy` (tema + genel görünüm),
`Nothing.colors`, `Scratchy.colors` renk şemaları, `Gradient-Dark-Icons`.

---

## 5. KWin — pencere yönetimi

| Ne | Değer | Durum |
|---|---|---|
| **Sol üst köşe** | Genel Görünüm | ✅ `10-kwin.sh` |
| **Sağ üst köşe** | Uygulama Başlatıcı | ✅ |
| **Sol alt köşe** | Masaüstünü Göster | ✅ |
| **Sağ alt köşe** | Ekranı Kilitle | ✅ |
| Alt+Tab görünümü | `coverswitch`, pencereleri vurgula | ✅ |
| Açık efektler | blur · glide · magiclamp · translucency · wobblywindows · gestures | ✅ |
| Kapalı efektler | cube · fallapart | ✅ |
| Masaüstü kaydırma | `RollOverDesktops=true` (kenardan taşınca öteki masaüstü) | ✅ |
| Orta tık yapıştırma | **kapalı** (`EnablePrimarySelection=false`) | ✅ |
| Ekran yırtılması | kapalı (`AllowTearing=false`) | ✅ |
| Döşeme betiği | **Krohnkite** (kurulu, `krohnkiteEnabled=false` → şu an pasif) | ⚙️ |
| Krohnkite kayan sınıflar | `steam, lutris, heroic, gamescope, net.lutris.Lutris, hl2_linux` | ✅ `10-kwin.sh` |
| Sanal masaüstü | 1 adet, adı `İş` | 🚫 tek masaüstü, taşımaya değmez |
| Tile düzenleri | 25/50/25 yatay, padding 4 | 🚫 ekran+masaüstü UUID'lerine bağlı |

---

## 6. Paneller

**İki alt panel** (her ekranda bir tane), yükseklik **50**, hizalama **ortalı**,
otomatik gizleme **yok**.

| Bileşen | 1. ekran | 2. ekran | Durum |
|---|---|---|---|
| `icontasks` (simgesel görev yöneticisi) | ✅ | ✅ | ✅ `40-panel.sh` |
| `systemtray` (sistem tepsisi) | ✅ | ✅ | ✅ |
| `panel.colorizer` (Panel Renklendirici) | ✅ | ✅ | ⚙️ + ayar dosyası |
| `kickerdash` (tam ekran uygulama menüsü) | ✅ | — | ✅ |
| `digitalclock` (saat) | ✅ | — | ✅ |
| `systemmonitor.diskusage` (disk) | — | ✅ | ✅ |
| `org.kaan.qftoggle` (Q/F) | ✅ | ✅ | ✅ |

**Sistem tepsisi öğeleri (17):** kdeconnect · vault · devicenotifier ·
networkmanagement · keyboardindicator · printmanager · manage-inputmethod ·
clipboard · kscreen · cameraindicator · volume · weather · notifications ·
keyboardlayout · brightness · battery · mediacontroller — ✅ hepsi kuruluyor.

**Panel Colorizer ayarları:** `panel-colorizer-ayarlari.json` (107 KB) —
bileşenin kendi *Ayarları İçe Aktar* penceresinden yüklenir. Şu an
`isEnabled=false`, yani hazır ama kapalı.

---

## 7. Masaüstü

Masaüstü kapsayıcısı `org.kde.plasma.folder`, duvar kâğıdı eklentisi
**Smart Video Wallpaper Reborn** (video duvar kâğıdı).

| Bileşen | 1920×1080'de konum (sol, üst, gen, yük) | Durum |
|---|---|---|
| YoRHa HUD | 32, 32, 528, 240 | ⚙️ elle eklenir |
| Vector Clock | 1408, 32, 496, 192 | ⚙️ |
| Side Menu | 24, 556, 392, 420 | ⚙️ |
| Audio Visualizer | 1408, 848, 496, 208 | ⚙️ |

Konumlar `40-panel.sh --goster` çıktısında da var.

---

## 8. Klavye ve kısayollar

| Katman | Nerede | Durum |
|---|---|---|
| `tr(f_custom)` klavye varyantı | `/usr/share/X11/xkb/…` | ✅ `03-xkb-kur.sh` |
| Konsole VS Code kısayolları | `kxmlgui5/konsole/VSCode.shortcuts` | ✅ `04-konsole-kisayol.sh` |
| KDE uygulama geneli (`Redo=Ctrl+R`) | `kdeglobals [Shortcuts]` | ✅ `60-standart-kisayollar.sh` |
| `Ctrl+Shift+Esc` → Görev Yöneticisi | `kglobalshortcutsrc [services]` | ✅ `06-global-kisayol.sh` |
| Klavye düzeni değiştirme | `Meta+Alt+K` / `Meta+Alt+L` (KDE varsayılanı) | 🚫 varsayılan |

**Krohnkite kaynaklı mevcut çakışmalar** (bu deponun işi değil, bilgi olarak):
`Meta+D` · `Meta+T` · `Meta+L` — her biri hem KDE hem Krohnkite tarafından
kullanılıyor.

---

## 9. Giriş aygıtları

| Ne | Değer | Durum |
|---|---|---|
| Touchpad | doğal kaydırma açık, kaydırma çarpanı `0.45`, yazarken devre dışı **değil**, tıklama yöntemi `2` | 🚫 aygıt kimliğine bağlı |
| Fare | kaydırma yöntemi `0` | 🚫 aygıt kimliğine bağlı |

`kcminputrc`'de bu ayarlar `[Libinput][satıcı][ürün][AYGIT ADI]` başlığı altında
durur — başka bir makinede o başlık tutmaz. Değerler burada yazılı, elle
girilebilir.

---

## 10. Diğer

| Ne | Durum |
|---|---|
| Otomatik başlayan: **ZapZap** (WhatsApp istemcisi) | 🚫 kişisel uygulama tercihi |
| Konsole profili | özelleştirilmemiş (varsayılan) |
| Powerdevil (güç yönetimi) | özelleştirilmemiş |
| Gece rengi (night color) | kapalı / varsayılan |
| Sistem zili | `UseSystemBell=true` |

---

## Kasten dışarıda bırakılanlar — ve nedeni

| Ne | Neden |
|---|---|
| Görev çubuğu başlatıcıları | Hangi uygulamaları kullandığını gösterir |
| Uygulama menüsü favorileri | Aynı sebep |
| Hava durumu konumu | **Nerede yaşadığını** gösterir |
| Duvar kâğıdı video dosyası | Yol harici SSD'ye işaret ediyor (`/mnt/ssd/…`) |
| KDE Connect eşleşmiş cihaz | Telefon kimliği |
| Ekran / etkinlik / masaüstü UUID'leri | Makineye özgü, başka yerde anlamsız |
| `ItemGeometries-<çözünürlük>` | Bu makinenin ekran çözünürlüğüne bağlı |
| Touchpad/fare aygıt kimlikleri | Donanım kimliği |
| GRUB yapılandırması | Disk UUID'leri taşır |
| Üçüncü parti tema/plasmoid dosyaları | Başkalarının eseri, kendi lisansları var — kaynakları listelendi, kopyalanmadı |

Kural: *"Bunun içinde beni tanıtan bir şey var mı?"* Cevap "belki" ise girmez.