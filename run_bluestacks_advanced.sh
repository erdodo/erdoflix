#!/bin/bash

# Erdoflix - BlueStacks Advanced Launch Script
# Bu script BlueStacks emülatörünü başlatır ve Flutter uygulamasını çalıştırır

echo "🚀 Erdoflix - BlueStacks Advanced Launcher"
echo "==========================================="
echo ""

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Proje dizini
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR"

# Fonksiyon: BlueStacks kontrolü
check_bluestacks() {
    if pgrep -f "BlueStacks" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Fonksiyon: ADB bağlantısı
connect_adb() {
    local port=$1
    echo "🔌 BlueStacks'e bağlanılıyor (port: $port)..."
    adb connect localhost:$port > /dev/null 2>&1
    sleep 2
    
    # Bağlantıyı kontrol et
    if adb devices | grep "localhost:$port" | grep -q "device"; then
        echo -e "${GREEN}✅ ADB bağlantısı başarılı (localhost:$port)${NC}"
        return 0
    else
        return 1
    fi
}

# 1. BlueStacks kontrolü
echo "📱 BlueStacks durumu kontrol ediliyor..."
if ! check_bluestacks; then
    echo -e "${YELLOW}⚠️  BlueStacks çalışmıyor${NC}"
    echo ""
    echo "BlueStacks'i başlatmak ister misiniz? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "🔄 BlueStacks başlatılıyor..."
        # macOS için BlueStacks başlatma
        open -a "BlueStacks" 2>/dev/null || open -a "BlueStacks.app" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${BLUE}⏳ BlueStacks başlatılıyor, lütfen bekleyin...${NC}"
            sleep 10
            
            # Başlatıldığını kontrol et
            for i in {1..30}; do
                if check_bluestacks; then
                    echo -e "${GREEN}✅ BlueStacks başarıyla başlatıldı${NC}"
                    break
                fi
                echo -n "."
                sleep 2
            done
            echo ""
        else
            echo -e "${RED}❌ BlueStacks başlatılamadı!${NC}"
            echo "   Lütfen manuel olarak BlueStacks'i başlatın ve scripti tekrar çalıştırın."
            exit 1
        fi
    else
        echo "   Lütfen önce BlueStacks'i başlatın ve scripti tekrar çalıştırın."
        exit 1
    fi
else
    echo -e "${GREEN}✅ BlueStacks zaten çalışıyor${NC}"
fi
echo ""

# 2. ADB bağlantısı (alternatif portlar)
echo "🔌 ADB bağlantısı kuruluyor..."
CONNECTED=false
BLUESTACKS_PORT=""

# Yaygın BlueStacks portları
PORTS=(5555 5565 5575 5585)

for port in "${PORTS[@]}"; do
    if connect_adb $port; then
        CONNECTED=true
        BLUESTACKS_PORT="localhost:$port"
        break
    fi
done

if [ "$CONNECTED" = false ]; then
    echo -e "${RED}❌ BlueStacks'e bağlanılamadı!${NC}"
    echo ""
    echo "Çözüm adımları:"
    echo "1. BlueStacks'i açın"
    echo "2. Ayarlar > Gelişmiş > Android Debug Bridge'i etkinleştirin"
    echo "3. Aşağıdaki komutları deneyin:"
    echo "   $ adb kill-server"
    echo "   $ adb start-server"
    echo "   $ adb connect localhost:5555"
    exit 1
fi
echo ""

# 3. Flutter cihaz kontrolü
echo "📋 Flutter cihazları kontrol ediliyor..."
flutter devices | grep -q "$BLUESTACKS_PORT"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Flutter cihaz listesinde BlueStacks bulunamadı${NC}"
    echo "   Flutter cihazlarını yenileniyor..."
    flutter devices > /dev/null
fi
echo -e "${GREEN}✅ Cihaz hazır${NC}"
echo ""

# 4. Dependencies kontrolü (opsiyonel)
echo "📦 Dependencies kontrol ediliyor..."
if [ ! -d "build" ] || [ ! -f "pubspec.lock" ]; then
    echo -e "${YELLOW}⚠️  Dependencies eksik, yükleniyor...${NC}"
    flutter pub get
fi
echo -e "${GREEN}✅ Dependencies hazır${NC}"
echo ""

# 5. Uygulama bilgileri
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📱 Uygulama: Erdoflix${NC}"
echo -e "${BLUE}🎯 Cihaz: BlueStacks ($BLUESTACKS_PORT)${NC}"
echo -e "${BLUE}🔧 Mode: Debug${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}💡 Kısayol Tuşları:${NC}"
echo "   r - Hot reload"
echo "   R - Hot restart"
echo "   h - Yardım menüsü"
echo "   d - Detach (arka planda çalıştır)"
echo "   q - Çıkış"
echo ""

# 6. Flutter uygulamasını başlat
echo "🎬 Uygulama başlatılıyor..."
echo ""

flutter run -d $BLUESTACKS_PORT

# Script sonlandığında
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👋 Erdoflix kapatıldı"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
