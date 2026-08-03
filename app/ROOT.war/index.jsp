<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.util.List" %>
<%@ page import="redis.clients.jedis.Jedis" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    System.out.println("[INFO] PAGE_VIEW : Ouverture de la page index.jsp par " + request.getRemoteAddr());
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Statut des Services</title>
    <link rel="icon" href="images/observabilite.jpg">
    <meta http-equiv="refresh" content="15">
    <!-- Intégration de Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="container py-5">
    <div class="text-center mb-4">
        <img src="images/observabilite.jpg" alt="Logo Observabilité" class="mb-3" style="max-height: 80px;">
        <h1>Site de demo</h1>
        <h2 class="h5 text-muted">Vérification de la disponibilité des URLs</h2>
    </div>

    <%!
        private String checkUrlStatus(String testUrl, String displayUrl, Jedis jedis) {
            String status;
            int responseCode = 0;
            long timestamp = System.currentTimeMillis();
            try {
                URL url = new URL(testUrl);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(5000);
                connection.setReadTimeout(5000);
                connection.connect();
                
                responseCode = connection.getResponseCode();
                if (responseCode >= 200 && responseCode < 400) {
                    status = "<span class='badge bg-success'>UP (" + responseCode + ")</span>";
                } else {
                    status = "<span class='badge bg-warning text-dark'>WARNING (" + responseCode + ")</span>";
                }
            } catch (Exception e) {
                status = "<span class='badge bg-danger'>DOWN (" + e.getMessage() + ")</span>";
            }

            // Sauvegarde dans Redis (format "timestamp:codeHTTP")
            if (jedis != null) {
                try {
                    jedis.lpush("history:" + displayUrl, timestamp + ":" + responseCode);
                    jedis.ltrim("history:" + displayUrl, 0, 49); // Conserve les 50 derniers résultats max
                } catch (Exception e) {
                    // Ignorer les erreurs d'écriture Redis pour ne pas bloquer l'affichage
                }
            }

            return status;
        }

        private String getHistoryHtml(String urlString, Jedis jedis) {
            if (jedis == null) return "";
            try {
                List<String> history = jedis.lrange("history:" + urlString, 0, 9);
                if (history == null || history.isEmpty()) return "<div class='text-muted small mt-2'>Aucun historique</div>";
                StringBuilder sb = new StringBuilder("<div class='mt-2 small'><strong>Derniers tests :</strong> ");
                for (String h : history) {
                    String[] parts = h.split(":");
                    if (parts.length == 2) {
                        int code = Integer.parseInt(parts[1]);
                        String badgeClass = (code >= 200 && code < 400) ? "bg-success" : (code > 0 ? "bg-warning text-dark" : "bg-danger");
                        sb.append("<span class='badge ").append(badgeClass).append(" me-1'>").append(code).append("</span>");
                    }
                }
                sb.append("</div>");
                return sb.toString();
            } catch (Exception e) {
                return "";
            }
        }
    %>
    <%
        // Connexion à Redis
        Jedis jedis = null;
        try {
            String redisHost = System.getenv("REDIS_HOST");
            if (redisHost == null) redisHost = "redis";
            jedis = new Jedis(redisHost, 6379);
        } catch (Exception e) {
            // Ignorer si la librairie Jedis est introuvable ou si le serveur est injoignable
        }
    %>

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="h4 m-0">URLs Publiques</h2>
        <a href="history.jsp" class="btn btn-outline-primary btn-sm">Graphiques d'historique</a>
    </div>

    <div class="row mb-4">
        <%
            String[] externalUrls = {
                "https://elearning.rousseltm.fr/",
                "https://www.rousseltm.fr",
                "https://martin.lekpa.fr",
                "https://construction.my-smartlife.fr/"
            };
            for (String urlString : externalUrls) {
        %>
        <div class="col-md-4 mb-3">
            <div class="card shadow-sm h-100">
                <div class="card-body">
                    <h6 class="card-title text-truncate" title="<%= urlString %>"><%= urlString %></h6>
                    <div class="mb-2">Statut : <%= checkUrlStatus(urlString, urlString, jedis) %></div>
                    <%= getHistoryHtml(urlString, jedis) %>
                </div>
            </div>
        </div>
        <% } %>
    </div>

    <h2 class="h4 mb-3 border-top pt-4">Instances Alloy Internes</h2>
    <div class="row">
        <%
            String[] internalUrls = {
                "http://alloy-agent:12345",
                "http://alloy-proxy:12346"
            };
            for (String urlString : internalUrls) {
        %>
        <div class="col-md-6 mb-3">
            <div class="card shadow-sm h-100">
                <div class="card-body">
                    <h6 class="card-title text-truncate" title="<%= urlString %>"><%= urlString %></h6>
                    <div class="mb-2">Statut : <%= checkUrlStatus(urlString, urlString, jedis) %></div>
                    <%= getHistoryHtml(urlString, jedis) %>
                </div>
            </div>
        </div>
        <% } %>
    </div>

    <h2 class="h4 mb-3 border-top pt-4">Section Random (Statuts HTTP)</h2>
    <div class="row">
        <%
            // Tableau des statuts HTTP demandés
            int[] randomCodes = {200, 201, 203, 403, 404, 500};
            // Génère une seule URL aléatoire avec httpbin.org
            int code = randomCodes[(int)(Math.random() * randomCodes.length)];
            String testUrl = "https://httpbin.org/status/" + code;
            String displayUrl = "https://httpbin.org/status";
        %>
        <div class="col-md-12 mb-3">
            <div class="card shadow-sm h-100">
                <div class="card-body">
                    <h6 class="card-title text-truncate" title="<%= displayUrl %>"><%= displayUrl %></h6>
                    <div class="mb-2">Statut (test: <%= code %>) : <%= checkUrlStatus(testUrl, displayUrl, jedis) %></div>
                    <%= getHistoryHtml(displayUrl, jedis) %>
                </div>
            </div>
        </div>
    </div>

    <h2 class="h4 mb-3 border-top pt-4">Dernier pays consulté (Météo)</h2>
    <div class="row">
        <div class="col-md-12 mb-4">
            <div class="card shadow-sm">
                <div class="card-body" id="last-country-details">
                    <%
                        String lastCountry = null;
                        String lastTemp = null;
                        String lastWind = null;
                        if (jedis != null) {
                            try {
                                lastCountry = jedis.get("last_weather_country");
                                lastTemp = jedis.get("last_weather_temp");
                                lastWind = jedis.get("last_weather_wind");
                            } catch (Exception e) {}
                        }
                        
                        if (lastCountry != null) {
                    %>
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <h5 class="m-0">Informations sur : <strong><%= lastCountry %></strong></h5>
                            <span class="badge bg-info">Dernière météo : <%= lastTemp %> °C | Vent : <%= lastWind %> km/h</span>
                        </div>
                        <div id="country-api-result">
                            <div class="spinner-border spinner-border-sm text-primary" role="status"></div> Recherche des détails du pays...
                        </div>
                        <script>
                            document.addEventListener("DOMContentLoaded", function() {
                                let countryQuery = "<%= lastCountry %>";
                                if (countryQuery === 'Etats-Unis' || countryQuery === 'États-Unis') countryQuery = 'USA';
                                else if (countryQuery === 'Royaume-Uni') countryQuery = 'UK';
                                
                                // On tente par nom d'abord, puis par traduction en cas d'échec
                                fetch('https://restcountries.com/v3.1/name/' + encodeURIComponent(countryQuery))
                                    .then(response => {
                                        if (!response.ok) {
                                            return fetch('https://restcountries.com/v3.1/translation/' + encodeURIComponent(countryQuery));
                                        }
                                        return response;
                                    })
                                    .then(response => response.json())
                                    .then(data => {
                                        if (data && Array.isArray(data) && data.length > 0) {
                                            const country = data[0];
                                            const flag = country.flags ? (country.flags.svg || country.flags.png) : '';
                                            const capital = country.capital && country.capital.length > 0 ? country.capital.join(', ') : 'Non disponible';
                                            const currencies = country.currencies ? Object.values(country.currencies).map(c => (c.name || 'Inconnu') + (c.symbol ? ' (' + c.symbol + ')' : '')).join(', ') : 'Non disponible';
                                            const languages = country.languages ? Object.values(country.languages).join(', ') : 'Non disponible';
                                            const timezones = country.timezones && country.timezones.length > 0 ? country.timezones.join(', ') : 'Non disponible';
                                            const countryCode = country.cca2; // Code ISO 2 lettres pour la seconde API
                                            
                                            document.getElementById('country-api-result').innerHTML = `
                                                <div class="d-flex align-items-center mt-3">
                                                    <img src="\${flag}" alt="Drapeau" style="width: 60px; height: auto; border: 1px solid #ddd; border-radius: 4px; margin-right: 15px;">
                                                    <ul class="list-unstyled m-0">
                                                        <li><strong>Capitale :</strong> \${capital}</li>
                                                        <li><strong>Monnaie :</strong> \${currencies}</li>
                                                        <li><strong>Langue(s) :</strong> \${languages}</li>
                                                        <li><strong>Fuseau(x) horaire(s) :</strong> \${timezones}</li>
                                                        <li id="demo-data"><strong>Démographie & Gouvernement :</strong> <span class="spinner-border spinner-border-sm text-secondary" role="status"></span> (Interrogation via Wikidata...)</li>
                                                    </ul>
                                                </div>
                                            `;
                                            
                                            // Seconde API : Wikidata pour la population et le président
                                            if (countryCode) {
                                                const sparqlQuery = `SELECT ?population ?presidentLabel WHERE { ?country wdt:P297 "${countryCode}". OPTIONAL { ?country wdt:P1082 ?population. } OPTIONAL { ?country wdt:P35|wdt:P6 ?president. } SERVICE wikibase:label { bd:serviceParam wikibase:language "fr,en". } } LIMIT 1`;
                                                fetch('https://query.wikidata.org/sparql?query=' + encodeURIComponent(sparqlQuery), {
                                                    headers: { 'Accept': 'application/sparql-results+json' }
                                                })
                                                    .then(res => {
                                                        if (!res.ok) throw new Error("Erreur HTTP " + res.status);
                                                        return res.json();
                                                    })
                                                    .then(wikiData => {
                                                        if (wikiData && wikiData.results && wikiData.results.bindings.length > 0) {
                                                            const bindings = wikiData.results.bindings[0];
                                                            const population = bindings.population && bindings.population.value ? new Intl.NumberFormat('fr-FR').format(bindings.population.value) + ' habitants' : 'Non disponible';
                                                            const president = bindings.presidentLabel && bindings.presidentLabel.value ? bindings.presidentLabel.value : 'Non disponible';
                                                            document.getElementById('demo-data').innerHTML = `<strong>Population :</strong> \${population}<br><strong>Chef d'État / Gouvernement :</strong> \${president}`;
                                                        } else {
                                                            document.getElementById('demo-data').innerHTML = `<strong>Informations :</strong> Données non disponibles pour le code \${countryCode}.`;
                                                        }
                                                    })
                                                    .catch(err => {
                                                        document.getElementById('demo-data').innerHTML = `<strong>Informations :</strong> Erreur de l'API Wikidata (\${err.message}).`;
                                                    });
                                            }
                                        } else {
                                            document.getElementById('country-api-result').innerHTML = '<p class="text-warning m-0 mt-2">Détails introuvables via l\'API pour ce pays.</p>';
                                        }
                                    })
                                    .catch(err => {
                                        document.getElementById('country-api-result').innerHTML = '<p class="text-danger m-0 mt-2">Erreur de connexion à l\'API publique.</p>';
                                    });
                            });
                        </script>
                    <%
                        } else {
                    %>
                        <p class="text-muted m-0">Aucun pays n'a été consulté récemment dans la section météo.</p>
                    <%
                        }
                    %>
                </div>
            </div>
        </div>
    </div>

    <%
        if (jedis != null) {
            jedis.close();
        }
    %>

    <footer class="text-center mt-5 text-muted">
        <hr>
        <p>Auteur : Equipe RousselTM</p>
        <p>
            <a href="https://elearning.rousseltm.fr/" target="_blank" class="btn btn-primary">Notre site de formation (autonome)</a>
            <a href="embeded.jsp?url=https://elearning.rousseltm.fr/" target="_blank" class="btn btn-primary">Notre site de formation (embarqué)</a>
            <a href="meteo.jsp" class="btn btn-info">Météo des pays</a>
        </p>
    </footer>

    <!-- Scripts Bootstrap -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>