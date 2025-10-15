# 🚀 BlueStacks Launch Scripts

Bu klasörde BlueStacks emülatöründe Erdoflix uygulamasını çalıştırmak için iki farklı script bulunmaktadır.

## 📝 Script'ler

### 1. `run_bluestacks.sh` - Basit Launcher
Temel BlueStacks başlatma script'i.

**Özellikler:**
- BlueStacks çalışıyor mu kontrolü
- Otomatik ADB bağlantısı (port 5555)
- Flutter uygulamasını başlatma

**Kullanım:**
```bash
./run_bluestacks.sh
```

### 2. `run_bluestacks_advanced.sh` - Gelişmiş Launcher ⭐ (Önerilen)
Daha gelişmiş özellikler içeren script.

**Özellikler:**
- ✅ BlueStacks otomatik başlatma
- ✅ Alternatif portlar (5555, 5565, 5575, 5585)
- ✅ Dependencies kontrolü
- ✅ Renkli ve detaylı bilgilendirme
- ✅ Kısayol tuşları rehberi

**Kullanım:**
```bash
./run_bluestacks_advanced.sh
```

## 🔧 İlk Kurulum

### 1. Script'leri çalıştırılabilir yapın:
```bash
chmod +x run_bluestacks.sh
chmod +x run_bluestacks_advanced.sh
```

### 2. BlueStacks Ayarları
BlueStacks'te Android Debug Bridge'i etkinleştirin:
1. BlueStacks'i açın
2. ⚙️ **Ayarlar** > **Gelişmiş** > **Android Debug Bridge**
3. **Enable** seçeneğini aktif edin

## 📱 Kullanım Kılavuzu

### Hızlı Başlangıç:
```bash
# Basit versiyon
./run_bluestacks.sh

# Gelişmiş versiyon (önerilen)
./run_bluestacks_advanced.sh
```

### Manuel ADB Bağlantısı (Sorun yaşarsanız):
```bash
# ADB'yi yeniden başlat
adb kill-server
adb start-server

# BlueStacks'e bağlan
adb connect localhost:5555

# Bağlantıyı kontrol et
adb devices

# Flutter cihazlarını listele
flutter devices
```

## ⌨️ Kısayol Tuşları

Uygulama çalışırken terminal'de kullanabileceğiniz tuşlar:

- `r` - **Hot Reload** (kod değişikliklerini anında uygula) 🔥
- `R` - **Hot Restart** (uygulamayı yeniden başlat)
- `h` - **Yardım** menüsü
- `d` - **Detach** (flutter run'dan ayrıl ama uygulama çalışsın)
- `c` - **Clear** (ekranı temizle)
- `q` - **Quit** (uygulamadan çık)

## 🐛 Sorun Giderme

### Problem: "BlueStacks çalışmıyor" hatası
**Çözüm:**
```bash
# BlueStacks'i manuel başlatın
open -a BlueStacks

# Veya gelişmiş script kullanın (otomatik başlatır)
./run_bluestacks_advanced.sh
```

### Problem: "ADB bağlantısı kurulamadı" hatası
**Çözüm:**
```bash
# ADB'yi temizle ve yeniden başlat
adb kill-server
adb start-server

# BlueStacks'e tekrar bağlan
adb connect localhost:5555

# Farklı portları dene
adb connect localhost:5565
adb connect localhost:5575
```

### Problem: "Device unauthorized" hatası
**Çözüm:**
1. BlueStacks'te açılan "USB debugging" izin dialogunu onaylayın
2. ADB bağlantısını yeniden kurun:
```bash
adb disconnect localhost:5555
adb connect localhost:5555
```

### Problem: Flutter cihazları görmüyor
**Çözüm:**
```bash
# Flutter doctor çalıştır
flutter doctor

# Cihazları yenile
flutter devices --machine

# Android SDK yolunu kontrol et
echo $ANDROID_HOME
```

## 💡 İpuçları

### 1. Alias Oluşturma
Terminalde daha hızlı çalıştırmak için alias ekleyin:

```bash
# ~/.zshrc veya ~/.bashrc dosyasına ekleyin:
alias erdoflix="cd /Users/erdoganyesil/projects/erdoflix && ./run_bluestacks_advanced.sh"

# Sonra sadece şunu çalıştırın:
erdoflix
```

### 2. VS Code Task
VS Code'da task olarak ekleyin (`.vscode/tasks.json`):

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run on BlueStacks",
      "type": "shell",
      "command": "${workspaceFolder}/run_bluestacks_advanced.sh",
      "problemMatcher": [],
      "group": {
        "kind": "build",
        "isDefault": true
      }
    }
  ]
}
```

### 3. Hot Reload Workflow
Geliştirme sırasında:
1. Script'i çalıştırın
2. Kod değişikliği yapın
3. Terminal'de `r` tuşuna basın
4. Değişiklikler anında BlueStacks'te görünür 🔥

## 📊 Port Bilgileri

BlueStacks varsayılan portları:
- **5555** - Ana BlueStacks instance
- **5565** - İkinci BlueStacks instance
- **5575** - Üçüncü BlueStacks instance
- **5585** - Dördüncü BlueStacks instance

## 🔗 Yararlı Komutlar

```bash
# BlueStacks'in çalışıp çalışmadığını kontrol et
pgrep -f BlueStacks

# Bağlı tüm cihazları listele
adb devices -l

# Belirli bir cihazda log izle
flutter logs -d localhost:5555

# Uygulama performansını izle
flutter run --profile -d localhost:5555

# Build ve çalıştır (release mode)
flutter run --release -d localhost:5555
```

## 📚 Ek Kaynaklar

- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
- [ADB Komutları](https://developer.android.com/studio/command-line/adb)
- [BlueStacks Gelişmiş Ayarlar](https://support.bluestacks.com/)

---

**Not:** Bu script'ler macOS için optimize edilmiştir. Windows veya Linux kullanıyorsanız bazı komutları düzenlemeniz gerekebilir.
