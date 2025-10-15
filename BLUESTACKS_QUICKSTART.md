# 🚀 Hızlı Başlangıç - BlueStacks

## Tek Tıkla Çalıştırma

Terminal'de projenin ana dizininde:

```bash
# Gelişmiş versiyon (önerilen) ⭐
./run_bluestacks_advanced.sh

# veya basit versiyon
./run_bluestacks.sh
```

## ✨ Özellikler

### `run_bluestacks_advanced.sh` (Önerilen)
- 🚀 BlueStacks'i otomatik başlatır
- 🔌 Alternatif portları otomatik dener (5555, 5565, 5575, 5585)
- 📦 Dependencies kontrolü yapar
- 🎨 Renkli ve detaylı bilgilendirme
- ⌨️ Kısayol tuşları rehberi

### `run_bluestacks.sh` (Basit)
- ✅ BlueStacks kontrolü
- ✅ ADB bağlantısı (port 5555)
- ✅ Flutter uygulamasını başlatır

## 📚 Detaylı Kılavuz

Tüm detaylar için: [BLUESTACKS_GUIDE.md](./BLUESTACKS_GUIDE.md)

## ⚡ Hızlı İpuçları

### Alias Oluştur (Daha Hızlı)
```bash
# ~/.zshrc veya ~/.bashrc dosyasına ekle:
alias erdoflix="cd ~/projects/erdoflix && ./run_bluestacks_advanced.sh"

# Artık sadece:
erdoflix
```

### Hot Reload
Uygulama çalışırken kodunuzu düzenleyin ve terminal'de `r` tuşuna basın! 🔥

### Sorun mu Yaşıyorsunuz?
```bash
# ADB'yi yenile
adb kill-server && adb start-server
adb connect localhost:5555

# Script'i tekrar çalıştır
./run_bluestacks_advanced.sh
```

## 🎯 Kısayol Tuşları

| Tuş | Açıklama |
|-----|----------|
| `r` | Hot Reload 🔥 |
| `R` | Hot Restart |
| `h` | Yardım |
| `d` | Detach (arka plan) |
| `q` | Çıkış |

---

**Not:** İlk çalıştırmada BlueStacks ayarlarında "Android Debug Bridge" özelliğini etkinleştirmeyi unutmayın!
