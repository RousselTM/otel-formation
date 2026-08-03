<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="redis.clients.jedis.Jedis" %>
<%
    String logCountry = request.getParameter("log_country");
    if (logCountry != null) {
        System.out.println("[INFO] WEATHER_VIEW : Consultation de la météo pour " + logCountry + " par " + request.getRemoteAddr());
        String temp = request.getParameter("temp");
        String wind = request.getParameter("wind");
        try {
            String redisHost = System.getenv("REDIS_HOST");
            if (redisHost == null) redisHost = "redis";
            Jedis jedis = new Jedis(redisHost, 6379);
            jedis.set("last_weather_country", logCountry);
            if (temp != null && wind != null) {
                jedis.set("last_weather_temp", temp);
                jedis.set("last_weather_wind", wind);
            }
            jedis.close();
        } catch (Exception e) {
            System.err.println("[ERROR] Redis: " + e.getMessage());
        }
        return; // On arrête l'exécution ici (appel API de log uniquement)
    }
    System.out.println("[INFO] PAGE_VIEW : Ouverture de la page meteo.jsp par " + request.getRemoteAddr());
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Météo des Pays</title>
    <link rel="icon" href="images/observabilite.jpg">
    <!-- Intégration de Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="container py-5">
    <div class="text-center mb-4">
        <img src="images/observabilite.jpg" alt="Logo Observabilité" class="mb-3" style="max-height: 80px;">
        <h1>Site de demo</h1>
        <h2 class="h5 text-muted">Météo en temps réel</h2>
    </div>

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="h4 m-0">Sélectionnez un pays</h2>
        <a href="index.jsp" class="btn btn-secondary btn-sm">Retour à l'accueil</a>
    </div>

    <div class="row text-center mb-4">
        <!-- J'ai ajouté le Canada pour arriver au compte exact de 5 pays demandés -->
        <div class="col-md mb-2"><button class="btn btn-outline-primary w-100" onclick="fetchWeather('Cameroun', 3.848, 11.502)">🇨🇲 Cameroun</button></div>
        <div class="col-md mb-2"><button class="btn btn-outline-primary w-100" onclick="fetchWeather('France', 48.8566, 2.3522)">🇫🇷 France</button></div>
        <div class="col-md mb-2"><button class="btn btn-outline-primary w-100" onclick="fetchWeather('Japon', 35.6895, 139.6917)">🇯🇵 Japon</button></div>
        <div class="col-md mb-2"><button class="btn btn-outline-primary w-100" onclick="fetchWeather('Etats-Unis', 38.8951, -77.0364)">🇺🇸 Etats-Unis</button></div>
        <div class="col-md mb-2"><button class="btn btn-outline-primary w-100" onclick="fetchWeather('Canada', 45.4215, -75.6972)">🇨🇦 Canada</button></div>
    </div>

    <div class="card shadow-sm bg-light">
        <div class="card-body text-center" id="weather-result" style="min-height: 150px; display: flex; align-items: center; justify-content: center; flex-direction: column;">
            <p class="text-muted m-0">Cliquez sur un pays pour afficher sa météo.</p>
        </div>
    </div>

    <footer class="text-center mt-5 text-muted">
        <hr>
        <p>Auteur : Equipe RousselTM</p>
        <p>
            <a href="https://elearning.rousseltm.fr/" target="_blank" class="btn btn-primary">Notre site de formation (autonome)</a>
            <a href="embeded.jsp?url=https://elearning.rousseltm.fr/" target="_blank" class="btn btn-primary">Notre site de formation (embarqué)</a>
            <a href="meteo.jsp" class="btn btn-info">Météo des pays</a>
        </p>
    </footer>

    <script>
        function fetchWeather(country, lat, lon) {
            console.log("[INFO] Chargement de la météo pour : " + country);

            const resultDiv = document.getElementById('weather-result');
            resultDiv.innerHTML = '<div class="spinner-border text-primary mb-2" role="status"></div><p class="m-0">Recherche des données météo en cours...</p>';
            
            fetch('https://api.open-meteo.com/v1/forecast?latitude=' + lat + '&longitude=' + lon + '&current_weather=true')
                .then(response => response.json())
                .then(data => {
                    const temp = data.current_weather.temperature;
                    const wind = data.current_weather.windspeed;
                    resultDiv.innerHTML = 
                        '<h3 class="card-title text-primary">' + country + '</h3>' +
                        '<div class="display-4 fw-bold">' + temp + ' °C</div>' +
                        '<p class="text-muted mt-2 mb-0">Vent : ' + wind + ' km/h</p>';
                        
                    // Log et stockage Redis côté serveur
                    fetch('meteo.jsp?log_country=' + encodeURIComponent(country) + '&temp=' + temp + '&wind=' + wind, { 
                        cache: 'no-store' 
                    }).catch(e => console.error("Erreur d'envoi du log serveur :", e));
                })
                .catch((e) => resultDiv.innerHTML = '<p class="text-danger m-0">Erreur lors de la récupération de la météo pour ' + country + '.</p>');
        }
    </script>
</body>
</html>