<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    System.out.println("[INFO] PAGE_VIEW : Ouverture de la page embeded.jsp par " + request.getRemoteAddr());
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Site Embarqué</title>
    <link rel="icon" href="images/observabilite.jpg">
    <!-- Intégration de Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="container py-5">
    <div class="text-center mb-4">
        <img src="images/observabilite.jpg" alt="Logo Observabilité" class="mb-3" style="max-height: 80px;">
        <h1>Site de demo</h1>
        <h2 class="h5 text-muted">Vérification de la disponibilité des URLs</h2>
    </div>

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="h4 m-0">Contenu Embarqué</h2>
        <a href="index.jsp" class="btn btn-secondary btn-sm">Retour à l'accueil</a>
    </div>

    <%
        String targetUrl = request.getParameter("url");
        if (targetUrl == null || targetUrl.trim().isEmpty()) {
            targetUrl = "https://elearning.rousseltm.fr/";
        }
    %>
    <div class="border rounded shadow-sm overflow-hidden" style="height: 70vh; background-color: #f8f9fa;">
        <iframe src="<%= targetUrl %>" width="100%" height="100%" style="border: none;"></iframe>
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