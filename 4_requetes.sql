USE ELIXIR;

-- Donnez la liste distincte des catégories de parfums triées
SELECT DISTINCT CATEGORIE
FROM PARFUM
ORDER BY CATEGORIE;

-- Parfums contenant 'Noir' ou 'Velvet' dans le nom, tri décroissant par prix
SELECT ID_PARFUM, NOM_PARFUM, CATEGORIE, GENRE, PRIX
FROM PARFUM
WHERE NOM_PARFUM LIKE '%Noir%' OR NOM_PARFUM LIKE '%Velvet%'
ORDER BY PRIX DESC;

-- Clients inscrits entre deux dates et triés par date d'inscription
SELECT ID_CLIENT, NOM_CLIENT, PRENOM_CLIENT, EMAIL_CLIENT, DATE_INSCRIPTION
FROM CLIENT_
WHERE DATE_INSCRIPTION BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY DATE_INSCRIPTION ASC;


-- Parfums avec id dans une liste (IN)
SELECT ID_PARFUM, NOM_PARFUM, PRIX
FROM PARFUM
WHERE ID_PARFUM IN (1,2,3,5,10)
ORDER BY NOM_PARFUM;


-- Clients avec email en @example.fr et téléphone non NULL (masque + IS NOT NULL)
SELECT ID_CLIENT, NOM_CLIENT, PRENOM_CLIENT, EMAIL_CLIENT, TELEPHONE_CLIENT
FROM CLIENT_
WHERE EMAIL_CLIENT LIKE '%@example.fr' AND TELEPHONE_CLIENT IS NOT NULL
ORDER BY NOM_CLIENT, PRENOM_CLIENT;


-- Commandes dont le montant est entre 50 et 300 triées par montant
SELECT ID_COMMANDE, DATE_COMMANDE, CANAL, MONTANT_TOTAL, ID_CLIENT
FROM COMMANDE
WHERE MONTANT_TOTAL BETWEEN 50 AND 300
ORDER BY MONTANT_TOTAL DESC;

-- CA total et nombre de commandes par client (top 10)
SELECT c.ID_CLIENT, c.NOM_CLIENT, c.PRENOM_CLIENT,
COUNT(cm.ID_COMMANDE) AS nb_commandes,
COALESCE(SUM(cm.MONTANT_TOTAL),0) AS ca_total
FROM CLIENT_ c
LEFT JOIN COMMANDE cm ON cm.ID_CLIENT = c.ID_CLIENT
GROUP BY c.ID_CLIENT
ORDER BY ca_total DESC
LIMIT 10;

-- Trouvons le canal le plus utilisé
SELECT COMMANDE.canal, COUNT(*) AS nb_commandes
FROM COMMANDE
WHERE COMMANDE.date_commande BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY COMMANDE.canal
ORDER BY nb_commandes DESC;

-- Quantité vendue et CA par parfum 
SELECT p.ID_PARFUM, p.NOM_PARFUM,
SUM(d.QUANTITE) AS total_vendu,
SUM(d.QUANTITE * d.PRIX_UNITAIRE) AS ca_parfum
FROM PARFUM p
JOIN DETAILS_COMMANDE d ON d.ID_PARFUM = p.ID_PARFUM
GROUP BY p.ID_PARFUM
HAVING SUM(d.QUANTITE) > 1
ORDER BY total_vendu DESC;


-- Stock net par magasin (en tenant compte des OPERATION.TYPE_OPERATION)
SELECT m.ID_MAGASIN, m.NOM_MAGASIN,
SUM(CASE WHEN o.TYPE_OPERATION = 'ENTREE' THEN s.QUANTITE
WHEN o.TYPE_OPERATION = 'SORTIE' THEN -s.QUANTITE
ELSE 0 END) AS stock_net
FROM MAGASIN m
JOIN STOCK s ON s.ID_MAGASIN = m.ID_MAGASIN
JOIN OPERATION o ON o.ID_OPERATION = s.ID_OPERATION
GROUP BY m.ID_MAGASIN
HAVING stock_net > 0
ORDER BY stock_net DESC;


-- Nombre de fournisseurs par parfum (>=2 pour repérer multi-fournisseurs)
SELECT p.ID_PARFUM, p.NOM_PARFUM, COUNT(pr.ID_FOURNISSEUR) AS nb_fournisseurs
FROM PARFUM p
LEFT JOIN PROPOSE pr ON pr.ID_PARFUM = p.ID_PARFUM
GROUP BY p.ID_PARFUM
HAVING COUNT(pr.ID_FOURNISSEUR) >= 2
ORDER BY nb_fournisseurs DESC;


-- Clients sans commande
SELECT c.ID_CLIENT, c.NOM_CLIENT, c.PRENOM_CLIENT, c.EMAIL_CLIENT
FROM CLIENT_ c
WHERE NOT EXISTS (
SELECT 1 FROM COMMANDE cm WHERE cm.ID_CLIENT = c.ID_CLIENT
);


--  Fournisseurs qui proposent le prix minimum pour un parfum 
SELECT pr.ID_FOURNISSEUR, pr.ID_PARFUM, pr.PRIX_FOURNISSEUR
FROM PROPOSE pr
WHERE pr.PRIX_FOURNISSEUR <= ALL (
SELECT pr2.PRIX_FOURNISSEUR FROM PROPOSE pr2 WHERE pr2.ID_PARFUM = pr.ID_PARFUM
);

-- Clients dont la dépense totale dépasse la moyenne de dépense de tous les clients
SELECT t.ID_CLIENT, t.NOM_CLIENT, t.PRENOM_CLIENT, t.ca_total
FROM (
SELECT c.ID_CLIENT, c.NOM_CLIENT, c.PRENOM_CLIENT, COALESCE(SUM(cm.MONTANT_TOTAL),0) AS ca_total
FROM CLIENT_ c
LEFT JOIN COMMANDE cm ON cm.ID_CLIENT = c.ID_CLIENT
GROUP BY c.ID_CLIENT
) AS t
WHERE t.ca_total > (
SELECT AVG(sub.ca_total) FROM (
SELECT COALESCE(SUM(cm2.MONTANT_TOTAL),0) AS ca_total
FROM CLIENT_ c2
LEFT JOIN COMMANDE cm2 ON cm2.ID_CLIENT = c2.ID_CLIENT
GROUP BY c2.ID_CLIENT
) AS sub
);


-- Achats fournisseurs récents : sélectionner fournisseurs sans achat dans les 60 derniers jours (NOT EXISTS avec date)
SELECT f.ID_FOURNISSEUR, f.NOM_FOURNISSEUR
FROM FOURNISSEUR f
WHERE NOT EXISTS (
SELECT 1 FROM ACHAT_DETAIL ad
JOIN ACHAT_FOURNISSEUR af ON af.ID_ACHAT = ad.ID_ACHAT
WHERE ad.ID_FOURNISSEUR = f.ID_FOURNISSEUR
AND af.DATE_ACHAT >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
);

-- Parfums pour lesquels tous les fournisseurs proposent un prix strictement supérieur à 80 (ALL)
SELECT p.ID_PARFUM, p.NOM_PARFUM
FROM PARFUM p
WHERE 80 < ALL (
SELECT pr.PRIX_FOURNISSEUR FROM PROPOSE pr WHERE pr.ID_PARFUM = p.ID_PARFUM
);

-- Lister tous les fournisseurs, les parfums qu'ils proposent accompagner des différents prix.
SELECT f.nom_fournisseur, p.nom_parfum, pr.prix_fournisseur
FROM FOURNISSEUR f
INNER JOIN PROPOSE pr ON f.id_fournisseur = pr.id_fournisseur
INNER JOIN PARFUM p ON pr.id_parfum = p.id_parfum;
    
    -- Lister tous les parfums, les magasins et les quantités en stock
SELECT p.nom_parfum, m.nom_magasin, s.quantite AS quantite_disponible
FROM PARFUM p
-- Jointure externe pour inclure les parfums même s'ils ne sont pas encore stockés
LEFT JOIN STOCK s ON p.id_parfum = s.id_parfum
LEFT JOIN MAGASIN m ON s.id_magasin = m.id_magasin;

-- Lister les commandes avec le nom du client et le montant total
SELECT c.ID_COMMANDE, c.DATE_COMMANDE, cl.NOM_CLIENT, cl.PRENOM_CLIENT, c.MONTANT_TOTAL
FROM COMMANDE c
JOIN CLIENT_ cl ON c.ID_CLIENT = cl.ID_CLIENT;

-- Nombre de clients inscrits par année
SELECT YEAR(DATE_INSCRIPTION) AS ANNEE, COUNT(*) AS NB_CLIENTS
FROM CLIENT_
GROUP BY YEAR(DATE_INSCRIPTION)
ORDER BY ANNEE;

-- Parfums en promotion actuellement 
SELECT p.NOM_PARFUM, pr.TYPE_PROMO, pr.TAUX_REDUCTION
FROM PARFUM p
JOIN AFFECTER a ON p.ID_PARFUM = a.ID_PARFUM
JOIN PROMOTION pr ON a.ID_PROMOTION = pr.ID_PROMOTION
WHERE CURDATE() BETWEEN pr.DATE_DEBUT AND pr.DATE_FIN;

-- Clients qui ont passé plus de 3 commandes 
SELECT NOM_CLIENT, PRENOM_CLIENT
FROM CLIENT_
WHERE ID_CLIENT IN (
    SELECT ID_CLIENT
    FROM COMMANDE
    GROUP BY ID_CLIENT
    HAVING COUNT(*) > 3
);

-- Mettre à jour le salaire d’un employé
UPDATE EMPLOYE
SET SALAIRE = SALAIRE * 1.10
WHERE ID_EMPLOYE = 1;

-- Stock total d’un parfum dans un seul magasin
SELECT p.NOM_PARFUM, SUM(s.QUANTITE) AS STOCK_TOTAL
FROM STOCK s
JOIN PARFUM p ON s.ID_PARFUM = p.ID_PARFUM
JOIN MAGASIN m ON s.ID_MAGASIN = m.ID_MAGASIN
WHERE m.NOM_MAGASIN = 'IRIS LITTORAL'
GROUP BY p.NOM_PARFUM
ORDER BY STOCK_TOTAL DESC;

-- Afficher les employés avec leur magasin et manager 
SELECT e.NOM_EMPLOYE, e.PRENOM_EMPLOYE, e.POSTE, m.NOM_MAGASIN AS MAGASIN, 
       em.NOM_EMPLOYE AS MANAGER, em.PRENOM_EMPLOYE AS PRENOM_MANAGER
FROM EMPLOYE e
LEFT JOIN MAGASIN m ON e.ID_MAGASIN = m.ID_MAGASIN
LEFT JOIN EMPLOYE em ON e.ID_EMPLOYE_MANAGER = em.ID_EMPLOYE;
