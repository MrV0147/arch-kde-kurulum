#!/usr/bin/env bash
# bashrc-qf.sh — satir duzenleme kisayollari.
# ~/.bashrc icinden 'source' edilir. Kurulum: klavye/07-satir-sil.sh
#
# ---------------------------------------------------------------------------
# NE ISE YARIYOR
#
# Terminalde "hepsini sec + sil" dogrudan mumkun degil: Konsole'un secimi
# kaydirma tamponunun GORSEL secimi, duzenlenebilir bir metin degil. Ama
# yazdigin komut satiri readline'in tamponunda duruyor ve bash 'bind -x' ile
# o tampona ERISIM VERIYOR: READLINE_LINE / READLINE_POINT.
#
# Yani "yazdigim uzun satir tek hamlede gitsin" istegi tam olarak karsilanabilir.
# ---------------------------------------------------------------------------

# NOT: Burada erken 'return' YOK. Bir tur oyle yazildi ve fonksiyonlar
# etkilesimli olmayan kabuklarda hic tanimlanmadi - test-satir-sil.sh'in
# alt kabukta calisan mantik olcumu de bu yuzden bos dondu. Fonksiyonlar HER
# ZAMAN tanimlanir (maliyeti yok, test edilebilir olur); yalnizca 'bind'
# cagrilari etkilesimli kabukla sinirlanir.

# --- yazdigin satirin TAMAMINI sil ------------------------------------------
# Imlec nerede olursa olsun. Ctrl+U'dan farki: Ctrl+U (unix-line-discard)
# yalnizca imlecten BASA kadar siler, imlecin saginda kalan yazi durur.
_qf_satir_sil() {
    READLINE_LINE=""
    READLINE_POINT=0
}

# --- panodaki metni satirdan cikar ------------------------------------------
# Fareyle (ya da Ctrl+A ile) sectigin ve Ctrl+C ile kopyaladigin metin satirda
# geciyorsa yalnizca onu siler. Gecmiyorsa satirin tamamini siler.
#
# Pano Klipper'dan okunuyor - wl-clipboard/xclip gerekmiyor.
_qf_secili_sil() {
    local sec
    sec="$(qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.getClipboardContents 2>/dev/null)"
    sec="${sec%$'\n'}"
    if [[ -n "$sec" && "$READLINE_LINE" == *"$sec"* ]]; then
        READLINE_LINE="${READLINE_LINE/"$sec"/}"
        READLINE_POINT=${#READLINE_LINE}
    else
        READLINE_LINE=""
        READLINE_POINT=0
    fi
}

# --- akilli Delete: satir sonunda satiri siler ---------------------------
# Kullanicinin akisi:  Ctrl+A (sec)  ->  [Ctrl+C]  ->  Delete
#
# Konsole'un secimi bash'e bildirilmiyor (DBus'ta boyle bir API yok), yani
# "secim var mi" diye soramayiz. Ama sormaya gerek de yok: readline'da
# Delete SATIR SONUNDA ZATEN HICBIR SEY YAPMAZ - sagda silinecek karakter
# yoktur. Bos duran bir tus vurusu. Ctrl+A'dan sonra imlec de tam orada olur.
#
# Yani: imlec satirin sonundaysa ve satir bossa DEGILSE -> satiri sil.
# Diger her durumda normal delete-char davranisi (yeniden uygulanmis hali).
# Boylece gunluk duzenleme hic bozulmuyor, kaybedilen bir tus yok.
_qf_delete() {
    local n=${#READLINE_LINE}
    if (( n > 0 && READLINE_POINT >= n )); then
        _QF_SON_SILINEN="$READLINE_LINE"
        READLINE_LINE=""
        READLINE_POINT=0
    else
        READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${READLINE_LINE:READLINE_POINT+1}"
    fi
}

# Yanlislikla silersen geri getir (Alt+Delete). Silinen satir _QF_SON_SILINEN'de
# duruyor; readline'in kendi kill-ring'ine bind -x ile yazmak mumkun degil, bu
# yuzden kendi kucuk geri almamiz var.
_qf_geri_al() {
    if [[ -n "${_QF_SON_SILINEN:-}" ]]; then
        READLINE_LINE="$_QF_SON_SILINEN"
        READLINE_POINT=${#READLINE_LINE}
    fi
}

# --- tus baglamalari --------------------------------------------------------
# Buradan asagisi yalnizca ETKILESIMLI kabukta calisir: 'bind' baska turlu
# anlamsiz ve hata basiyor.
[[ $- != *i* ]] && return 0

# Diziler TAHMIN EDILMIYOR: olc-tus.sh gercek terminalden olcup yaziyor.
# Dosya yoksa yalnizca Ctrl+U baglanir (o dizi belirsiz degil).
_qf_tuslar="${XDG_STATE_HOME:-$HOME/.local/state}/qf-tuslar.conf"

# Ctrl+U: kill-whole-line'a yukselt.
# Varsayilani unix-line-discard = yalnizca imlecten basa. kill-whole-line
# imlecin yerinden bagimsiz olarak satirin tamamini siler.
bind '"\C-u": kill-whole-line' 2>/dev/null

# STANDART DIZILER — olcume gerek yok.
# Delete tusu \e[3~ gonderir; degistiricili halleri xterm kodlamasiyla:
#     Shift       \e[3;2~        Ctrl        \e[3;5~
#     Alt         \e[3;3~        Ctrl+Shift  \e[3;6~
# Konsole xterm uyumlu. Olculdu: \e[3;5~ zaten readline'da kill-word'e bagli,
# yani bu kodlama bu terminalde gecerli. Kullanilmayan bir diziyi baglamak
# zararsiz oldugu icin bunlari dogrudan bagliyoruz - kullaniciyi olcum
# adimina mecbur birakmiyoruz.
bind -x '"\e[3~":   _qf_delete'      2>/dev/null   # Delete  (akilli)
bind -x '"\e[3;3~": _qf_geri_al'    2>/dev/null   # Alt+Delete (geri getir)
bind -x '"\e[3;2~": _qf_satir_sil'  2>/dev/null   # Shift+Delete
bind -x '"\e[3;6~": _qf_secili_sil' 2>/dev/null   # Ctrl+Shift+Delete

# Ctrl+A ile satir silme - yalnizca 08-ctrl-a-sil.sh acmissa.
# Varsayilan DEGIL: acildiginda Konsole'un "tumunu sec"i Ctrl+Shift+A'ya
# taşınıyor ve bu bir tercih meselesi.
if [[ -e "${XDG_STATE_HOME:-$HOME/.local/state}/qf-ctrl-a-sil" ]]; then
    bind -x '"\C-a": _qf_satir_sil' 2>/dev/null
fi

if [[ -r "$_qf_tuslar" ]]; then
    while IFS='=' read -r _ad _dizi; do
        [[ -z "${_ad:-}" || -z "${_dizi:-}" ]] && continue
        case "$_ad" in
            SATIR_SIL)    bind -x "\"$_dizi\": _qf_satir_sil"  2>/dev/null ;;
            SECILI_SIL)   bind -x "\"$_dizi\": _qf_secili_sil" 2>/dev/null ;;
            KELIME_GERI)  bind    "\"$_dizi\": backward-kill-word" 2>/dev/null ;;
            KELIME_ILERI) bind    "\"$_dizi\": kill-word"          2>/dev/null ;;
        esac
    done < "$_qf_tuslar"
fi
unset _qf_tuslar

# --- gecmiste onek aramasi --------------------------------------------------
# Yukari/Asagi: yazdiginin BASINA uyan komutlari arar. "git" yazip yukari
# basinca yalnizca git ile baslayan komutlar gelir. Uzun komutu yeniden
# yazma derdini kokunden azaltir.
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward'  2>/dev/null