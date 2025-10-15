#!/bin/bash

# Erdoflix - BlueStacks Launch Script
# Bu script BlueStacks emülatörüne Flutter uygulamasını otomatik olarak başlatır

echo "🚀 Erdoflix - BlueStacks Launcher"
echo "=================================="
echo ""

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# BlueStacks'in çalışıp çalışmadığını kontrol et
echo "📱 BlueStacks kontrolü yapılıyor..."
if ! pgrep -f "BlueStacks" > /dev/null; then
    echo -e "${RED}❌ BlueStacks çalışmıyor!${NC}"
    echo "   Lütfen önce BlueStacks'i başlatın."
    exit 1
fi
echo -e "${GREEN}✅ BlueStacks çalışıyor${NC}"
echo ""

# ADB bağlantısını kontrol et
echo "🔌 ADB bağlantısı kontrol ediliyor..."
adb devices | grep -q "localhost:5555"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  BlueStacks bağlı değil, bağlanılıyor...${NC}"
    adb connect localhost:5555
    sleep 2
fi

# Bağlantı durumunu tekrar kontrol et
adb devices | grep "localhost:5555" | grep -q "device"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ BlueStacks ADB bağlantısı başarılı${NC}"
else
    echo -e "${RED}❌ BlueStacks'e bağlanılamadı!${NC}"
    echo "   Çözüm:"
    echo "   1. BlueStacks Ayarlar > Gelişmiş > Android Debug Bridge'i aktif edin"
    echo "   2. Terminal'de şu komutu çalıştırın: adb connect localhost:5555"
    exit 1
fi
echo ""

# Flutter cihazlarını listele
echo "📋 Mevcut cihazlar:"
flutter devices
echo ""

# Flutter uygulamasını başlat
echo "🎬 Erdoflix uygulaması başlatılıyor..."
echo "   Cihaz: BlueStacks (localhost:5555)"
echo "   Mode: Debug"
echo ""
echo -e "${YELLOW}💡 İpucu: Hot reload için terminalde 'r' tuşuna basın${NC}"
echo ""

# Projeyi BlueStacks'te çalıştır
flutter run -d localhost:5555

# Script sonlandığında
echo ""
echo "👋 Uygulama kapatıldı"
