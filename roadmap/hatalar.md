- [x] sağ sol tuşları ile kartlar arası geçiş yapılabiliyor ama animasyon düzgün değil. kartı ortalamaya çalışıp tekrar en sola gidiyor.
- [x] aşağı yukarı tuşları ile kartlar arası geçiş yapılsa da scrool değişmediği için aktif kart görüntülenemiyor.
- [x] film resimler 2:3 oranında geliyor. genişlik 2000, yükseklik 3000. buna göre gösterimi düzenle ve resimler bu oranda gelmezse bile bu orana sığdır ki resmin tamamını görebilelim.
- [x] film 1'de iken zindex olarak 2. filmden yukarda olması gerekiyor ama focus olunan film bir sonrakinin altında kalıyor. ve scale efekti tam olarak ortalı değil sağa doğru büyüyor
- [x] ana sayfada film gridleri için infinty scrool kullan. ilk başta 20 film çek sonrasında sağa doğru kaydıkça diğer sayfalar da yüklenerek devam etsin.
- [x] ana sayfadaki film kartı focus olduğunda biraz daha scale olmalı ve glow efekti daha belirgin olmalı. ancak sanırım scooldan dolayı bu efectler uygulandığında üst ve alt borderlar görüntülenmiyor
- [x] en üstteki hero banner'da da butonlar var bunlara da tuşlarla erişilebilmeli
- [x] focus efektinde gölgeler çok fazla daha da azaltılabilir
- [x] 2. karta focus iken 3. kart üstte kalıyor. normalde 1 ve 3 daha altta olmalı
- [x] 1. satırdayken yukarı ok tuşuna basınca hero bannera geçse de scrool yukarı çıkmıyor. hero banner görünmüyor.
- [x] kategoriler heronun altında olmasına rağmen heroda yukarı ok tuşuna basınca kategoriye geçmiyor. (DÜZELTİLDİ - Navigasyon mantığı hero→kategoriler aşağı ok, kategoriler→hero yukarı ok olarak düzeltildi)
- [x] navbarı sola al (DÜZELTİLDİ - Navbar desktop'ta sola taşındı)
- [x] navbarda aşağı yukarı tuşları ile geçiş yapılmıyor (DÜZELTİLDİ - Desktop'ta yukarı/aşağı ok ile navbar item'ları arasında gezinme eklendi)
- [x] navbar focus olduğunda scale efektinden dolayı yazı alta kayıyor. onun yerine renk değişimi ve glow efekti olabilir (DÜZELTİLDİ - Scale kaldırıldı, kırmızı renk + glow efekti eklendi)
- [x] navbarda aktif sayfa belli değil (DÜZELTİLDİ - Aktif sayfa kırmızı border ve hafif glow ile işaretleniyor)
- [x] navbar olduğundan dolayı header'ı kaldır (DÜZELTİLDİ - AppBar tamamen kaldırıldı)
- [x] populer filmler slider'ından kategorilere geçerken scrool kaymıyor (DÜZELTİLDİ - Kategori scroll handling eklendi, hero height + 30px)
- [x] film detay ve kategori gibi alt sayfalara gidildiğinde navbar kaybolmasın ve geri butonu çalışmıyor (DÜZELTİLDİ - Her sayfaya navbar eklendi, Escape/Backspace ile geri dön)
- [x] 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss. (DÜZELTİLDİ - Tüm dosyalarda withValues(alpha:) kullanımına geçildi)
- [x] navbar normalde sade ve renksiz olsun. focus olunca renkli ve glow efektli olsun. (DÜZELTİLDİ - Aktif sayfa renklendirmesi kaldırıldı, sadece focus'ta kırmızı+glow)
- [x] navbarın şuan boyutları çok uyumsuz. hepsinin genişlik ve yükseklikleri aynı olsun. icon ve text ortalansın. (DÜZELTİLDİ - Sabit 60x60px boyut, merkezi hizalama)
- [x] film detay sayfasında geri butonu çalışmıyor (DÜZELTİLDİ - Navigator.pop yerine context.go('/') kullanıldı)
- [x] navbara geçildiğinde önceki sayfaki focus kalıyor bu da navbara geçildiğinde enter tuşuna basınca önceki sayfada bir yere tıklanmasına sebep oluyor. (DÜZELTİLDİ - Enter/Space handler'lara !_isNavbarFocused check eklendi)
- [x] kategori sayfalarında film bulunamadı yazıyor sanırım apiler yanlış (DÜZELTİLDİ - filmler:list endpoint'i ile doğru filter formatı kullanıldı) örnek kategori filtrelemesi şöyle olmalı:
    ```shell
    curl 'https://app.erdoganyesil.org/api/filmler:list?pageSize=12&appends\[\]=turler&appends\[\]=kaynaklar_id&appends\[\]=film_altyazilari_id&page=1&filter=%7B%22$and%22:\[%7B%22turler%22:%7B%22id%22:%7B%22$eq%22:22%7D%7D%7D\]%7D' \
    -H 'accept: application/json, text/plain, */*' \
    -H 'accept-language: tr-TR,tr;q=0.7' \
    -H 'authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInRlbXAiOnRydWUsImlhdCI6MTc2MDQ1NjAyNiwic2lnbkluVGltZSI6MTc2MDQ1NjAyNjM0MiwiZXhwIjoxNzYwNzE1MjI2LCJqdGkiOiIxMzgwNGIwNy00MzIyLTRiNzAtOTRiNC0yYWVlN2EyY2RhN2MifQ.JUhj1jllAOxx_IFOr0bQXo0qZvg7n8nIFhhlexB8kZo' \
    -b 'rl_anonymous_id=RudderEncrypt%3AU2FsdGVkX1%2Bd%2FQf5X5QpqKBLcbdCwZiUI1nH5a0kKSzfs5u4dpTb81oZQVQoTomjYlljfbLtF9IU%2Bix5tJCQeA%3D%3D; rl_page_init_referrer=RudderEncrypt%3AU2FsdGVkX19dL9olajpyrAZe3jmP9qrXzVVQbLE2VxM%3D; rl_page_init_referring_domain=RudderEncrypt%3AU2FsdGVkX19qatQ5K8Rp8r%2F%2FoTCdE%2BEezu2eW9RlNRY%3D; rl_user_id=RudderEncrypt%3AU2FsdGVkX1%2Bb3Ragk6PJuXr6OWXd3lFa3B6GMzzgnKjqfMItEOWrFcMdFOFBl68hfjsai8rU2yRlrM0svzzAcLq%2FND3NnwzYQ6lzdzxrVFF533jVGV%2Bugg4Twld1D7Iv94nETlJ7ySMXFjPbnmEEmgCSysnkKKz69BJAyb%2F2jvg%3D; rl_trait=RudderEncrypt%3AU2FsdGVkX19DsnKgnkmsBFd%2FLpCLGXDi4WC5OUVxghcJt8OvNdlrcGXXInjH7SMNk5QUaB3PuaaeuoEHAnofypO18X2n1emNhvo38BRRTbmzp%2B0nEzOwWYHZAiWLT7yc2X3PGJQ2nq66xj0I%2Bo7ULA%3D%3D; rl_session=RudderEncrypt%3AU2FsdGVkX19J3HqIkRaXN%2FoBmc%2B2G4to4pK2EwRbmdCii57uIm06OP8zi6qoiOtjjIh9anSquCSeJufAcbxokrcij%2FWE0AraKLf0nJruUQpqkkZvGHfY7ZXV5mKhPLil8TPfKKnynThCWBi8Tlduvg%3D%3D; ph_phc_4URIAm1uYfJO7j8kWSe0J8lc8IqnstRLS7Jx8NcakHo_posthog=%7B%22distinct_id%22%3A%22992f3611e501fa2abb9e59e0238378fb31b41bad17666912ebbfeefae293d454%2378434fb6-fbdb-4761-9fb4-e66038e853fa%22%2C%22%24sesid%22%3A%5Bnull%2Cnull%2Cnull%5D%2C%22%24epp%22%3Atrue%2C%22%24initial_person_info%22%3A%7B%22r%22%3A%22%24direct%22%2C%22u%22%3A%22https%3A%2F%2Fn8n.erdoganyesil.org%2Fsignin%3Fredirect%3D%25252F%22%7D%7D; cf_clearance=28pXChN8.yUiLWv0.Kqfun29ffDMzPbYsvlisnZx4nI-1760460812-1.2.1.1-WVLCt8J7VjAz_Gvlh3vx5IujAwMO3bE05cee.OM7.sXAVhRsgfgb2VU7n9s9h4mMVaHT5K0bN74c_WxDXTvIBda9055FLJOXZFG6wkoJ_FTpE_k4yMnMtR3EoqbA0PbEwzJyGKvTZT_ddehSBnfINhlvMuIuCedgj4zcib408xtG.zfr9Mv1oNIFyd03R6SbttInQMQxtjhG7zZBfdNqMn1WEQXs4DSo6p1Kqw.7OJ8' \
    -H 'priority: u=1, i' \
    -H 'referer: https://app.erdoganyesil.org/apps/erdoFlix/admin/hv5xd6iae2k' \
    -H 'sec-ch-ua: "Brave";v="141", "Not?A_Brand";v="8", "Chromium";v="141"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "macOS"' \
    -H 'sec-fetch-dest: empty' \
    -H 'sec-fetch-mode: cors' \
    -H 'sec-fetch-site: same-origin' \
    -H 'sec-gpc: 1' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
    -H 'x-app: erdoFlix' \
    -H 'x-authenticator: basic' \
    -H 'x-hostname: app.erdoganyesil.org' \
    -H 'x-locale: en-US' \
    -H 'x-role: root' \
    -H 'x-timezone: +03:00' \
    -H 'x-with-acl-meta: true'
    ```
- [ ] characters 1.4.0 (1.4.1 available)
  flutter_hooks 0.20.5 (0.21.3+1 available)
  flutter_lints 5.0.0 (6.0.0 available)
  go_router 14.8.1 (16.2.4 available)
  lints 5.1.1 (6.0.0 available)
  material_color_utilities 0.11.1 (0.13.0 available)
  meta 1.16.0 (1.17.0 available)
  test_api 0.7.6 (0.7.7 available)

- [x] mobilde player sayfasında ekrana tıklamama rağmen kontroller çıkmıyor (DÜZELTİLDİ - GestureDetector eklendi, ekrana tıklayınca kontroller açılıp kapanıyor)
