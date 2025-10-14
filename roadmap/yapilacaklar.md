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
### 1 ✅ TAMAMLANDI
- [x] ana sayfa tasarımı (TAMAMLANDI - Netflix tarzı hero banner + kategori menüsü + 3 film satırı)
- [x] API entegrasyonu (TAMAMLANDI - Film, kategori listeleme, pagination, metadata)
- [x] klavye navigasyonu (TAMAMLANDI - 4 yön + Enter/Space ile tam kontrol, kategoriler dahil)
- [x] infinity scroll (TAMAMLANDI - Her satırda 20'şer film, otomatik yükleme)
- [x] focus efektleri ve animasyonlar (TAMAMLANDI - Scale, glow, border, smooth scroll)
- [x] kategori sayfaları tasarımı (TAMAMLANDI - Grid layout, klavye navigasyonu, pagination)
- [x] film detay sayfası tasarımı (TAMAMLANDI - Hero banner, metadata, benzer filmler)
- [x] routing sistemi (TAMAMLANDI - go_router ile /film/:id ve /category/:id)
- [x] navbar tasarımı (TAMAMLANDI)
    - [x] mobil cihazlar için aşağıda bir navbar (filmler, diziler, anasayfa, arama, profil)
    - [x] mobil ve üstü için sağ tarafta ortalanmış bir navbar
    - [x] ok tuşları ile navbar elemanları arasında geçiş yapılabilmeli. ana sayfadan navbara ve navbardan ana sayfaya geçiş yapılabilmeli
    - Özellikler:
        - Mobil: Alt tarafta 70px yükseklikte yatay navbar
        - Desktop: Sağ tarafta 80px genişlikte dikey navbar (orta hizada)
        - 5 menü: Anasayfa, Filmler, Diziler, Arama, Profil (icon + label)
        - Klavye kontrolü: Sağ/sol (mobil) veya yukarı/aşağı (desktop) ile gezinme
        - Focus efekti: Scale, glow, border, arka plan animasyonu
        - Desktop'ta en sağdaki içerikten sağ ok ile navbar'a geçiş
        - Mobilde son film satırından aşağı ok ile navbar'a geçiş
### 2

- [x] player sayfası tasarımı (TAMAMLANDI - better_player ile full-featured player)
    - [x] navigasyon tuşlarına tam destek (Space/K, ←→, ↑↓, F, M, C, Q, Esc)
    - [x] birden fazla kaynak desteği (Kalite seçimi: Q tuşu veya menü)
    - [x] altyazı desteği (SRT/WEBVTT, C tuşu ile seçim)
    - [x] oynatma hızı kontrolü (Better player built-in)
    - [x] mouse hareketleri veya klavye tuşları tetiklendiğinde butonlar açılsın yoksa direkt tam ekran oynasın (3sn otomatik gizlenme)
    - [x] video oynatıcı kontrolleri (play/pause, ileri/geri 10 saniye, ses açma/kapatma, tam ekran)
    - [x] video oynatıcı progress bar (ilerleme çubuğu) (Better player built-in)
    - [x] kaldığı yerden devam etme (resume_play API entegrasyonu, otomatik kaydetme)
    - [x] diğer playerlarda bulunan özellikler (Notifications, Picture-in-Picture hazır)

- [ ] arama sayfası tasarımı
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
