#!/bin/bash

# Android Kablosuz Eşleştirme Script'i
echo "======================================"
echo "Android Kablosuz Eşleştirme"
echo "======================================"
echo ""
echo "Telefonunuzda:"
echo "1. Ayarlar → Geliştirici seçenekleri → Kablosuz hata ayıklama"
echo "2. 'Eşleştirme koduyla cihaz eşleştir' tıklayın"
echo ""

read -p "IP adresini girin (örn: 192.168.1.125): " ip
read -p "Port numarasını girin (örn: 39895): " port
read -p "Eşleştirme kodunu girin (6 haneli): " code

echo ""
echo "Eşleştirme başlatılıyor..."
echo "$code" | adb pair $ip:$port

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Eşleştirme başarılı!"
    echo ""
    read -p "Ana port numarasını girin (genellikle 5555 veya farklı bir port, Kablosuz hata ayıklama ana ekranında görünür): " main_port

    echo "Bağlantı kuruluyor..."
    adb connect $ip:$main_port

    echo ""
    echo "Bağlı cihazlar:"
    adb devices

    echo ""
    echo "Flutter cihazları:"
    flutter devices
else
    echo ""
    echo "❌ Eşleştirme başarısız!"
    echo "Lütfen bilgileri kontrol edip tekrar deneyin."
fi
