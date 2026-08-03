<%@ page import="redis.clients.jedis.Jedis" %>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    System.out.println("[INFO] PAGE_VIEW : Ouverture de la page history.jsp par " + request.getRemoteAddr());
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Historique des Services</title>
    <link rel="icon" href="images/observabilite.jpg">
    <!-- Intégration de Bootstrap 5 et Chart.js -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body class="container py-5">
    <div class="text-center mb-4">
        <img src="images/observabilite.jpg" alt="Logo Observabilité" class="mb-3" style="max-height: 80px;">
        <h1>Site de demo</h1>
        <h2 class="h5 text-muted">Vérification de la disponibilité des URLs</h2>
    </div>

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="m-0">Historique des disponibilités</h1>
        <a href="index.jsp" class="btn btn-secondary">Retour aux tests</a>
    </div>

    <%
        Jedis jedis = null;
        Set<String> keys = null;
        try {
            String redisHost = System.getenv("REDIS_HOST");
            if (redisHost == null) redisHost = "redis";
            jedis = new Jedis(redisHost, 6379);
            keys = jedis.keys("history:*");
        } catch (Exception e) {
            out.println("<div class='alert alert-danger'>Erreur de connexion à Redis : " + e.getMessage() + "</div>");
        }
    %>

    <div class="row">
    <%
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
        if (keys != null && !keys.isEmpty()) {
            int chartId = 0;
            for (String key : keys) {
                chartId++;
                String url = key.substring(8); // On retire "history:" pour l'affichage
                List<String> history = jedis.lrange(key, 0, -1);
                Collections.reverse(history); // Inverser pour l'ordre chronologique
                
                StringBuilder labels = new StringBuilder();
                StringBuilder data = new StringBuilder();
                
                for (int i = 0; i < history.size(); i++) {
                    String[] parts = history.get(i).split(":");
                    if(parts.length == 2) {
                        String timeLabel = "Test " + (i+1);
                        try {
                            long ts = Long.parseLong(parts[0]);
                            timeLabel = sdf.format(new Date(ts));
                        } catch (NumberFormatException e) {
                            // Conserve le label par défaut si le parsing échoue
                        }
                        labels.append("\"").append(timeLabel).append("\",");
                        data.append(parts[1]).append(",");
                    }
                }
                
                // Retirer les dernières virgules
                if(labels.length() > 0) labels.setLength(labels.length() - 1);
                if(data.length() > 0) data.setLength(data.length() - 1);
    %>
        <div class="col-md-6 mb-4">
            <div class="card shadow-sm h-100">
                <div class="card-header bg-primary text-white">
                    <h5 class="card-title m-0" style="font-size: 1rem; word-break: break-all;"><%= url %></h5>
                </div>
                <div class="card-body">
                    <canvas id="chart<%= chartId %>"></canvas>
                </div>
            </div>
        </div>
        
        <script>
            document.addEventListener("DOMContentLoaded", function() {
                var ctx = document.getElementById('chart<%= chartId %>').getContext('2d');
                new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: [<%= labels.toString() %>],
                        datasets: [{
                            label: 'Code HTTP Retourné (0 = Injoignable)',
                            data: [<%= data.toString() %>],
                            borderColor: 'rgba(200, 200, 200, 0.5)',
                            backgroundColor: 'rgba(200, 200, 200, 0.1)',
                            borderWidth: 2,
                            fill: true,
                            tension: 0.3,
                            pointRadius: 5,
                            pointBackgroundColor: function(context) {
                                var value = context.dataset.data[context.dataIndex];
                                if (value >= 0 && value <= 199) return '#dc3545'; // rouge
                                if (value >= 200 && value <= 299) return '#28a745'; // vert
                                if (value >= 300 && value <= 399) return '#ffc107'; // jaune
                                if (value >= 400 && value <= 499) return '#fd7e14'; // orange
                                if (value >= 500 && value <= 599) return '#dc3545'; // rouge
                                return '#6c757d'; // gris pour 0 ou erreur
                            },
                            pointBorderColor: '#fff',
                            segment: {
                                borderColor: function(context) {
                                    var value = context.p1.parsed.y;
                                    if (value >= 200 && value <= 299) return '#28a745';
                                    if (value >= 300 && value <= 399) return '#ffc107';
                                    if (value >= 400 && value <= 499) return '#fd7e14';
                                    if (value >= 500 && value <= 599) return '#dc3545';
                                    return '#6c757d';
                                }
                            }
                        }]
                    },
                    options: {
                        scales: {
                            y: {
                                beginAtZero: true,
                                suggestedMax: 500
                            }
                        }
                    }
                });
            });
        </script>
    <%
            }
        } else if (keys != null) {
            out.println("<div class='alert alert-info'>Aucun historique trouvé. Veuillez d'abord charger l'accueil pour générer des tests.</div>");
        }
        
        if (jedis != null) {
            jedis.close();
        }
    %>
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
</body>
</html>