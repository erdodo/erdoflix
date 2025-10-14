önbilgi: bu projede hiçbir flutter bilgim yok. bu yüzden mümkün olduğunca yapay zeka ile ilerleme yapılacak. api bilgileri roadmap/apiler.json dosyasında.


apiKey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInJvbGVOYW1lIjoicm9vdCIsImlhdCI6MTc2MDQ1NjI4NiwiZXhwIjozMzMxODA1NjI4Nn0.ikmX73jTYj73phAL-ZYf-HcslWjVVoNNzfPtoddvj_4

baseUrl: https://app.erdoganyesil.org

# Kesinlikle Yapılacaklar
- [x] Proje ok tuşları (sağa, sola, yukarı, aşağı) ile kontrol edilebilmeli
- [x] Proje, mobil cihazlarda ve televizyonda çalışabilmeli (web üzerinde çalışıyor, mobil test edilecek)
- [ ] televizyonda kumanda tuşlarını desteklemeli
- [x] mobil için dokunmatik kontroller eklenmeli (otomatik destekleniyor)

# tasarım detayları
- [x] proje genel manada netflix, youtube, spotify gibi platformların tasarım detaylarını içermeli
- [x] proje, kullanıcıların dikkatini dağıtmayacak sade bir tasarıma sahip olmalı
- [x] klavye navigasyonu ile tüm UI kontrol edilebilmeli (ok tuşları + Enter/Space)
- [x] focus efektleri (scale, glow, border) düzgün çalışmalı
- [x] z-index problemleri çözülmeli (focus olan kart her zaman üstte olmalı)
- [x] scroll animasyonları akıcı ve kullanıcı dostu olmalı


# roadmap
### 1
- [x] ana sayfa tasarımı (TAMAMLANDI - Netflix tarzı hero banner + 3 film satırı)
- [x] API entegrasyonu (TAMAMLANDI - Film listeleme, pagination, metadata)
- [x] klavye navigasyonu (TAMAMLANDI - 4 yön + Enter/Space ile tam kontrol)
- [x] infinity scroll (TAMAMLANDI - Her satırda 20'şer film, otomatik yükleme)
- [x] focus efektleri ve animasyonlar (TAMAMLANDI - Scale, glow, border, smooth scroll)
- [ ] kategori sayfaları tasarımı
- [ ] film detay sayfası tasarımı
- [ ] arama sayfası tasarımı
- [ ] player sayfası tasarımı
    - [ ] player sayfası mümkünse cihazın kendi oynatıcısını kullanmalı
    - [ ] player sayfası mümkünse cihazın kendi altyazı ve ses seçeneklerini kullanmalı
    - [ ] player sayfası mümkünse cihazın kendi ileri, geri, duraklat, oynat kontrollerini kullanmalı
### 2
- [ ] navbar tasarımı
    - [ ] mobil cihazlar için aşağıda bir navbar (filmler, diziler, anasayfa, arama, proffil)
    - [ ] mobil ve üstü için sağ tarafta ortalanmış bir navbar.
    - [ ] ok tuşları ile navbar elemanları arasında geçiş yapılabilmeli. ana sayfadan navbara ve navbardan ana sayfaya geçiş yapılabilmeli.
- [ ] kullanıcı girişi ve kayıt sayfası tasarımı
- [ ] kullanıcı profili sayfası tasarımı
- [ ] kullanıcı ayarları sayfası tasarımı
- [ ] kullanıcı favori listesi sayfası tasarımı
- [ ] kullanıcı izleme geçmişi sayfası tasarımı
### 3
- [ ] dizi sayfası tasarımı
- [ ] dizi sezon sayfası tasarımı
- [ ] dizi bölüm sayfası tasarımı
- [ ] dizi bölüm detay sayfası tasarımı
### 4
- [ ] admin paneli tasarımı
- [ ] içerik yönetim sayfası tasarımı
- [ ] kullanıcı yönetim sayfası tasarımı
- [ ] istatistikler sayfası tasarımı
