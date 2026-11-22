@php
    $base = rtrim((string) config('shawarma.apk_base'), '/');
    $staff = ($mode ?? 'client') === 'equipe';
    $apps = $staff
        ? [
            ['file' => 'mr-shawarma-livreur.apk', 'name' => 'Application Livreur', 'emoji' => '🛵', 'desc' => 'Voir les commandes, ouvrir l\'itinéraire, confirmer les livraisons.'],
            ['file' => 'mr-shawarma-admin.apk', 'name' => 'Application Administrateur', 'emoji' => '📊', 'desc' => 'Gérer le menu, les promotions, les commandes et les statistiques.'],
        ]
        : [
            ['file' => 'mr-shawarma-client.apk', 'name' => 'Mr. Shawarma', 'emoji' => '🌯', 'desc' => 'Commande tes shawarmas et suis ta livraison en direct.'],
        ];
@endphp
<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#0A0806">
<title>{{ $staff ? 'Espace équipe' : 'Télécharger l\'application' }} · Mr. Shawarma</title>
<link rel="icon" href="/brand/logo.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Anton&family=Poppins:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
  :root{--ink:#0A0806;--card:#1B150F;--line:#2D2318;--gold:#F2C230;--gold2:#E0A417;--cream:#FFF4DC;--dim:#B8AB95;--flame:#E2571F}
  *{box-sizing:border-box;margin:0}
  body{background:var(--ink);color:var(--cream);font-family:'Poppins',system-ui,sans-serif;min-height:100vh;overflow-x:hidden}
  .hero{position:relative;height:340px;overflow:hidden}
  .hero img.bg{width:100%;height:100%;object-fit:cover;animation:zoom 18s ease-in-out infinite alternate}
  .hero:after{content:"";position:absolute;inset:0;background:linear-gradient(180deg,rgba(0,0,0,.45),rgba(10,8,6,0) 35%,rgba(10,8,6,.85) 78%,var(--ink))}
  .hero .logo{position:absolute;top:18px;left:50%;transform:translateX(-50%);width:74px;z-index:2;animation:float 3s ease-in-out infinite}
  .hero .word{position:absolute;bottom:4px;left:50%;transform:translateX(-50%);height:150px;z-index:2;animation:rise .9s .1s both}
  main{max-width:520px;margin:0 auto;padding:6px 20px 48px}
  h1{font-family:'Anton',sans-serif;font-weight:400;letter-spacing:.8px;font-size:26px;text-align:center;margin:8px 0 6px;animation:rise .8s .2s both}
  p.lead{color:var(--dim);text-align:center;font-size:14px;margin-bottom:22px;animation:rise .8s .3s both}
  .app{background:var(--card);border:1px solid var(--line);border-radius:24px;padding:18px;margin-bottom:14px;animation:rise .8s .4s both}
  .app .top{display:flex;gap:14px;align-items:center;margin-bottom:14px}
  .app .ico{width:56px;height:56px;border-radius:16px;background:#0A0806;border:1px solid var(--line);display:grid;place-items:center;font-size:28px}
  .app b{font-size:16px;display:block}.app small{color:var(--dim);font-size:12.5px;line-height:1.35;display:block;margin-top:2px}
  .btn{display:block;text-align:center;text-decoration:none;color:var(--ink);font-weight:800;padding:15px;border-radius:18px;
       background:linear-gradient(135deg,#FAD35A,#E0A417);box-shadow:0 8px 22px rgba(242,194,48,.28);position:relative;overflow:hidden;transition:transform .12s}
  .btn:active{transform:scale(.97)}
  .btn:after{content:"";position:absolute;top:0;left:-60%;width:40%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,.55),transparent);transform:skewX(-20deg);animation:shine 3.6s infinite}
  .btn.off{background:var(--line);color:var(--dim);box-shadow:none;pointer-events:none}.btn.off:after{display:none}
  h2{font-family:'Anton',sans-serif;font-weight:400;letter-spacing:.8px;font-size:18px;margin:26px 0 12px;display:flex;align-items:center;gap:10px}
  h2:before{content:"";width:4px;height:20px;border-radius:2px;background:linear-gradient(135deg,#FAD35A,#E0A417)}
  ol{list-style:none;counter-reset:s;display:grid;gap:10px}
  ol li{counter-increment:s;background:var(--card);border:1px solid var(--line);border-radius:16px;padding:12px 14px 12px 52px;position:relative;font-size:13.5px;line-height:1.4}
  ol li:before{content:counter(s);position:absolute;left:14px;top:50%;transform:translateY(-50%);width:26px;height:26px;border-radius:50%;
       background:linear-gradient(135deg,#FAD35A,#E0A417);color:var(--ink);font-weight:800;display:grid;place-items:center;font-size:13px}
  .note{color:var(--dim);font-size:12.5px;line-height:1.5;margin-top:14px;text-align:center}
  .qr{text-align:center;margin-top:26px}.qr img{background:#fff;padding:10px;border-radius:16px;width:170px;height:170px}
  footer{text-align:center;color:var(--dim);font-size:12px;margin-top:30px}footer a{color:var(--gold)}
  .chips{display:flex;justify-content:center;gap:10px;margin-top:22px;font-family:'Anton';letter-spacing:1.8px;color:var(--gold);font-size:12px}
  @keyframes rise{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:none}}
  @keyframes float{50%{transform:translateX(-50%) translateY(-7px)}}
  @keyframes zoom{to{transform:scale(1.12)}}
  @keyframes shine{0%{left:-60%}45%,100%{left:140%}}
</style>
</head>
<body>
<div class="hero">
  <img class="bg" src="/brand/hero.jpg" alt="">
  <img class="logo" src="/brand/logo.png" alt="Mr. Shawarma">
  <img class="word" src="/brand/wordmark.png" alt="Mr. Shawarma — Le secret c'est la sauce">
</div>
<main>
  <h1>{{ $staff ? 'ESPACE ÉQUIPE' : 'TÉLÉCHARGE L\'APPLICATION' }}</h1>
  <p class="lead">{{ $staff ? 'Applications réservées au livreur et à l\'administrateur.' : 'Commande en 2 minutes, paie à la livraison ou par Mobile Money.' }}</p>

  @foreach ($apps as $a)
    <div class="app">
      <div class="top">
        <div class="ico">{{ $a['emoji'] }}</div>
        <div><b>{{ $a['name'] }}</b><small>{{ $a['desc'] }}</small></div>
      </div>
      @if ($base !== '')
        <a class="btn" href="{{ $base }}/{{ $a['file'] }}" download>⬇  Télécharger pour Android</a>
      @else
        <a class="btn off">Lien bientôt disponible</a>
      @endif
    </div>
  @endforeach

  <h2>Comment installer</h2>
  <ol>
    <li>Appuie sur <b>Télécharger</b>, puis ouvre le fichier <b>.apk</b> reçu.</li>
    <li>Si Android le demande, autorise l'installation depuis ce navigateur (Paramètres &gt; Sécurité).</li>
    <li>Si un avertissement de sécurité apparaît (l'application n'est pas encore sur le Play Store), choisis <b>« Installer quand même »</b>.</li>
    <li>Ouvre <b>Mr. Shawarma</b> et crée ton compte.</li>
  </ol>
  <p class="note">Disponible sur Android. Version iPhone : bientôt.</p>

  <div class="chips"><span>SAVEUR</span><span>•</span><span>QUALITÉ</span><span>•</span><span>FRAÎCHEUR</span></div>

  <div class="qr">
    <img id="qr" alt="QR code de cette page" width="170" height="170">
    <p class="note">Scanne pour ouvrir cette page sur un autre téléphone.</p>
  </div>

  <footer>
    <a href="/politique-confidentialite.html">Politique de confidentialité</a>
  </footer>
</main>
<script>
  document.getElementById('qr').src = 'https://api.qrserver.com/v1/create-qr-code/?size=340x340&margin=0&data=' + encodeURIComponent(location.href);
</script>
</body>
</html>
