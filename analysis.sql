-- =====================================================================
-- analysis.sql - Analyse e-commerce (PostgreSQL)

-- =====================================================================
SET client_encoding TO 'UTF8';


-- =====================================================================
-- Exercice 1 - Explorer les produits
-- =====================================================================

-- Liste de tous les produits
SELECT nom, categorie, prix, stock
FROM produit
ORDER BY categorie, nom;

-- Produits dont le prix est supérieur à 100 €
SELECT nom, categorie, prix, stock
FROM produit
WHERE prix > 100
ORDER BY prix DESC;
-- Résultat : 65 produits répartis en 5 catégories (Informatique 17,
-- Maison 13, Mode 13, Sport 13, Audio 9), de 15,19 € à 348,70 €.
-- 43 produits sur 65 (66 %) coûtent plus de 100 € : le catalogue est
-- plutôt orienté vers des produits de valeur moyenne à élevée.


-- =====================================================================
-- Exercice 2 - Explorer les clients
-- =====================================================================

-- Clients habitant dans une ville donnée
SELECT id, nom, prenom, email, ville, date_inscription
FROM client
WHERE ville = 'Paris';

-- Nombre de clients par ville
SELECT ville, COUNT(*) AS nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC, ville;
-- Résultat : 10 clients à Paris. Les 100 clients sont répartis
-- exactement à égalité entre 10 villes (10 clients chacune) : la ville
-- ne permet donc pas de distinguer les clients par leur nombre.


-- =====================================================================
-- Exercice 3 - Explorer les commandes
-- =====================================================================
-- La jointure se fait sur la clé étrangère commande.client_id.
SELECT co.id AS id_commande,
       co.date_commande,
       co.statut,
       cl.id AS id_client,
       cl.nom,
       cl.prenom,
       cl.email,
       cl.ville
FROM commande co
JOIN client cl ON cl.id = co.client_id
ORDER BY co.date_commande, co.id;
-- Résultat : 500 commandes, du 1er janvier au 29 décembre 2025.
-- Statuts : 279 livrées, 112 expédiées, 93 payées, 16 annulées.


-- =====================================================================
-- Exercice 4 - Montant de chaque ligne
-- =====================================================================
SELECT lc.id AS id_ligne,
       lc.commande_id,
       lc.produit_id,
       lc.quantite,
       lc.prix_unitaire,
       lc.quantite * lc.prix_unitaire AS montant_ligne
FROM ligne_commande lc
ORDER BY lc.commande_id, lc.id;
-- Résultat : 1 547 lignes ; une commande contient de 1 à 5 lignes
-- (3,1 en moyenne).


-- =====================================================================
-- Exercice 5 - Montant total de chaque commande
-- =====================================================================
SELECT co.id AS id_commande,
       co.date_commande,
       co.statut,
       COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total
FROM commande co
LEFT JOIN ligne_commande lc ON lc.commande_id = co.id
GROUP BY co.id, co.date_commande, co.statut
ORDER BY co.id;
-- Résultat : 500 commandes, de 28,86 € à 4 162,98 €.


-- =====================================================================
-- Exercice 6 - Chiffre d'affaires par catégorie (hors annulées)
-- =====================================================================
SELECT p.categorie,
       SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires,
       SUM(lc.quantite)                    AS quantite_vendue
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires DESC;
-- Résultat :
--   Sport          162 149,83 €  (26,3 %)    780 unités
--   Informatique   138 024,98 €  (22,4 %)  1 051 unités
--   Mode           124 202,00 €  (20,1 %)    753 unités
--   Maison         111 359,19 €  (18,0 %)    727 unités
--   Audio           81 758,76 €  (13,2 %)    490 unités
-- Interprétation : Sport génère le plus de CA, mais c'est Informatique
-- qui vend le plus d'unités. Le prix moyen payé par unité l'explique :
-- 207,88 € en Sport contre 131,33 € en Informatique. Le volume et le
-- chiffre d'affaires ne racontent donc pas la même chose.


-- =====================================================================
-- Exercice 7 - Top 10 des produits les plus vendus (en quantité)
-- =====================================================================
SELECT p.nom AS produit,
       p.categorie,
       SUM(lc.quantite) AS quantite_vendue
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY quantite_vendue DESC, p.nom
LIMIT 10;
-- Résultat : Montre sport 1 (101), Casque 1 (94), Écran 2 (94),
-- Aspirateur 2 (88), Ballon 1 (86), Plaid 1 (81), Sac à dos 1 (81),
-- Veste 1 (79), Bouilloire 1 (77), SSD 1 (77).
-- Les 5 catégories sont représentées : aucun produit ne domine
-- nettement les volumes.


-- =====================================================================
-- Exercice 8 - Produits générant le plus de chiffre d'affaires
-- =====================================================================
SELECT p.nom AS produit,
       p.categorie,
       SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY chiffre_affaires DESC, p.nom;
-- Résultat : en tête Sac à dos 1 (24 925,47 €), Gourde 1 (23 589,49 €)
-- et Écouteurs 1 (21 678,00 €) ; en dernier Casquette 1 (729,07 €).
-- Sac à dos 1 est le seul produit à la fois dans le top 3 du CA et dans
-- le top 10 des quantités : c'est un produit clé. Les autres produits
-- du top CA sont surtout des produits chers (plus de 290 €).


-- =====================================================================
-- Exercice 9 - Clients
-- =====================================================================
SELECT cl.id AS id_client,
       cl.nom,
       cl.prenom,
       COUNT(DISTINCT co.id)                                        AS nb_commandes_passees,
       COUNT(DISTINCT co.id) FILTER (WHERE co.statut <> 'annulée')  AS nb_commandes_non_annulees,
       COALESCE(SUM(lc.quantite * lc.prix_unitaire)
                FILTER (WHERE co.statut <> 'annulée'), 0)           AS montant_depense
FROM client cl
LEFT JOIN commande co       ON co.client_id   = cl.id
LEFT JOIN ligne_commande lc ON lc.commande_id = co.id
GROUP BY cl.id, cl.nom, cl.prenom
ORDER BY montant_depense DESC, cl.id;
-- Résultat : la meilleure cliente est Alice Dubois (id 59) avec
-- 11 commandes et 17 169,00 € dépensés. Vérification : le client 55 a
-- passé 5 commandes, dont 4 non annulées.

-- Clients n'ayant jamais passé de commande (quel que soit le statut)
SELECT cl.id AS id_client, cl.nom, cl.prenom, cl.email, cl.date_inscription
FROM client cl
LEFT JOIN commande co ON co.client_id = cl.id
WHERE co.id IS NULL
ORDER BY cl.id;
-- Résultat : 10 clients (id 91 à 100), un par ville, soit 10 % des
-- inscrits. Certains sont inscrits depuis 2023 : ce sont des comptes
-- "dormants" à réactiver (offre de bienvenue, relance email).


-- =====================================================================
-- Exercice 10 - Panier moyen
-- Panier moyen = chiffre d'affaires / nombre de commandes (hors annulées)
-- =====================================================================

-- Panier moyen global
SELECT SUM(lc.quantite * lc.prix_unitaire)  AS chiffre_affaires,
       COUNT(DISTINCT co.id)                AS nb_commandes,
       ROUND(SUM(lc.quantite * lc.prix_unitaire)
             / COUNT(DISTINCT co.id), 2)    AS panier_moyen
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
WHERE co.statut <> 'annulée';
-- Résultat : 617 494,76 € / 484 commandes = 1 275,82 € par commande.

-- Panier moyen par mois
SELECT DATE_TRUNC('month', co.date_commande)::date AS mois,
       COUNT(DISTINCT co.id)                       AS nb_commandes,
       SUM(lc.quantite * lc.prix_unitaire)         AS chiffre_affaires,
       ROUND(SUM(lc.quantite * lc.prix_unitaire)
             / COUNT(DISTINCT co.id), 2)           AS panier_moyen
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
WHERE co.statut <> 'annulée'
GROUP BY DATE_TRUNC('month', co.date_commande)
ORDER BY mois;

-- Différence entre les trois indicateurs :
--  * Chiffre d'affaires : total encaissé (quantité × prix payé),
--    ici 617 494,76 €.
--  * Nombre de commandes : combien de fois les clients ont acheté,
--    ici 484 commandes non annulées.
--  * Panier moyen : CA / nombre de commandes = montant moyen d'une
--    commande, ici 1 275,82 €.
--  CA = nombre de commandes × panier moyen. Exemple dans nos données :
--  février a beaucoup de commandes (44) mais le plus petit panier
--  (1 015,31 €) ; octobre a peu de commandes (34) mais le plus gros
--  panier (1 578,81 €). Résultat : octobre fait plus de CA que février.
--  COUNT(DISTINCT co.id) est indispensable : une commande a plusieurs
--  lignes, sans DISTINCT on compterait les lignes et non les commandes.


-- =====================================================================
-- Exercice 11 - Catégoriser les commandes selon leur montant
-- =====================================================================
-- Toutes les commandes sont classées (y compris les annulées), avec leur
-- statut. Les annulées sont exclues seulement du calcul du CA plus bas.
WITH montants AS (
    SELECT co.id AS id_commande,
           co.date_commande,
           co.statut,
           COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total
    FROM commande co
    LEFT JOIN ligne_commande lc ON lc.commande_id = co.id
    GROUP BY co.id, co.date_commande, co.statut
)
SELECT id_commande,
       date_commande,
       statut,
       montant_total,
       CASE
           WHEN montant_total < 500  THEN 'Petit panier'
           WHEN montant_total < 1500 THEN 'Panier moyen'
           ELSE 'Gros panier'
       END AS categorie_panier
FROM montants
ORDER BY id_commande;

-- Répartition par catégorie de panier
WITH montants AS (
    SELECT co.id AS id_commande,
           co.statut,
           COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total
    FROM commande co
    LEFT JOIN ligne_commande lc ON lc.commande_id = co.id
    GROUP BY co.id, co.statut
)
SELECT CASE
           WHEN montant_total < 500  THEN 'Petit panier'
           WHEN montant_total < 1500 THEN 'Panier moyen'
           ELSE 'Gros panier'
       END                                              AS categorie_panier,
       COUNT(*)                                         AS nb_commandes,
       COUNT(*) FILTER (WHERE statut <> 'annulée')      AS nb_commandes_non_annulees,
       COALESCE(SUM(montant_total)
                FILTER (WHERE statut <> 'annulée'), 0)  AS chiffre_affaires
FROM montants
GROUP BY 1
ORDER BY MIN(montant_total);
-- Résultat (500 commandes classées) :
--   Petit panier   103 commandes (99 non annulées)    29 995,75 €
--   Panier moyen   206 commandes (201 non annulées)  192 525,62 €
--   Gros panier    191 commandes (184 non annulées)  394 973,39 €
-- Interprétation : les gros paniers représentent 38 % des commandes
-- mais 64 % du CA, alors que les petits paniers (21 % des commandes)
-- ne pèsent que 5 % du CA. Le CA repose sur les grosses commandes.


-- =====================================================================
-- Exercice 12 - Analyse temporelle
-- =====================================================================

-- CA par mois, rang et évolution par rapport au mois précédent
WITH ca_mensuel AS (
    SELECT DATE_TRUNC('month', co.date_commande)::date AS mois,
           SUM(lc.quantite * lc.prix_unitaire)         AS chiffre_affaires
    FROM commande co
    JOIN ligne_commande lc ON lc.commande_id = co.id
    WHERE co.statut <> 'annulée'
    GROUP BY DATE_TRUNC('month', co.date_commande)
)
SELECT mois,
       chiffre_affaires,
       RANK() OVER (ORDER BY chiffre_affaires DESC) AS rang,
       LAG(chiffre_affaires) OVER (ORDER BY mois)   AS ca_mois_precedent,
       ROUND(100.0 * (chiffre_affaires - LAG(chiffre_affaires) OVER (ORDER BY mois))
             / NULLIF(LAG(chiffre_affaires) OVER (ORDER BY mois), 0), 2) AS evolution_pct
FROM ca_mensuel
ORDER BY mois;

-- CA par trimestre
SELECT EXTRACT(YEAR    FROM co.date_commande) AS annee,
       EXTRACT(QUARTER FROM co.date_commande) AS trimestre,
       SUM(lc.quantite * lc.prix_unitaire)    AS chiffre_affaires
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
WHERE co.statut <> 'annulée'
GROUP BY 1, 2
ORDER BY 1, 2;
-- Résultat : T1 126 281,09 € ; T2 163 556,12 € ; T3 161 427,15 € ;
-- T4 166 230,40 €.
-- Interprétation :
--  * Périodes les plus fortes : mai (68 841,64 €), août (65 441,63 €)
--    et décembre (60 655,34 €).
--  * Périodes les plus faibles : janvier (34 765,36 €), avril
--    (35 932,15 €) et septembre (40 578,54 €).
--  * Évolution générale : l'année démarre lentement (T1 nettement le
--    plus faible), puis l'activité se stabilise autour de 160 000 € par
--    trimestre, avec un T4 le plus fort. Le second semestre fait 13 %
--    de plus que le premier (327 657,55 € contre 289 837,21 €).
--    D'un mois à l'autre, l'activité reste irrégulière
--    (+91,6 % d'avril à mai, -38,0 % d'août à septembre).


-- =====================================================================
-- Exercice 13 - Commandes antérieures à l'inscription du client
-- =====================================================================
SELECT co.id AS id_commande,
       cl.id AS id_client,
       co.date_commande,
       cl.date_inscription,
       cl.date_inscription - co.date_commande AS jours_d_ecart
FROM commande co
JOIN client cl ON cl.id = co.client_id
WHERE co.date_commande < cl.date_inscription
ORDER BY co.id;

-- Nombre d'anomalies
SELECT COUNT(*) AS nb_anomalies
FROM commande co
JOIN client cl ON cl.id = co.client_id
WHERE co.date_commande < cl.date_inscription;
-- Résultat : 30 anomalies (6 % des 500 commandes), qui concernent
-- 12 clients, tous inscrits en 2025. L'écart va de 2 à 194 jours ; le
-- client 49 cumule à lui seul 5 anomalies.
-- Interprétation : une commande ne peut pas exister avant l'inscription.
-- Soit la date de commande est fausse, soit la date d'inscription a été
-- modifiée après coup (par exemple lors d'une réinscription). Il faut
-- corriger à la source et ajouter un contrôle à l'insertion (trigger) :
-- une contrainte CHECK ne peut pas comparer deux tables.


-- =====================================================================
-- Exercice 14 - Produits jamais vendus
-- =====================================================================
SELECT p.nom AS produit, p.categorie, p.prix, p.stock
FROM produit p
WHERE NOT EXISTS (
    SELECT 1
    FROM ligne_commande lc
    WHERE lc.produit_id = p.id
)
ORDER BY p.categorie, p.nom;
-- Résultat : 5 produits, un par catégorie : Platine vinyle 1 (Audio,
-- 279,00 €, 18 en stock), Imprimante 1 (Informatique, 189,90 €, 42),
-- Grille-pain 1 (Maison, 44,90 €, 65), Chemise 1 (Mode, 49,90 €, 80),
-- Corde à sauter 1 (Sport, 19,90 €, 120).
-- Au total 325 unités en stock, soit 22 296,30 € au prix catalogue.
-- Intérêt pour l'entreprise :
--  * stock immobilisé = argent bloqué et coût de stockage ;
--  * produit peut-être trop cher, mal référencé ou peu visible ;
--  * actions possibles : promotion, meilleure mise en avant,
--    déréférencement, arrêt du réapprovisionnement.


-- =====================================================================
-- Exercice 15 - Tableau de bord
-- =====================================================================

-- ---------- A. Exploration ----------

-- Nombre de lignes de chaque table
SELECT 'client' AS nom_table, COUNT(*) AS nb_lignes FROM client
UNION ALL
SELECT 'produit', COUNT(*) FROM produit
UNION ALL
SELECT 'commande', COUNT(*) FROM commande
UNION ALL
SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;
-- Résultat : client 100, produit 65, commande 500, ligne_commande 1 547.

-- Colonnes et types de données
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('client', 'produit', 'commande', 'ligne_commande')
ORDER BY table_name, ordinal_position;
-- Résultat : integer pour les identifiants, quantités et stock ;
-- character varying pour les textes ; numeric pour les prix ; date pour
-- les dates. is_nullable vaut NO partout.

-- Valeurs manquantes (COUNT(colonne) ne compte pas les NULL)
SELECT 'client' AS nom_table,
       COUNT(*) - COUNT(nom)              AS nom_null,
       COUNT(*) - COUNT(prenom)           AS prenom_null,
       COUNT(*) - COUNT(email)            AS email_null,
       COUNT(*) - COUNT(ville)            AS ville_null,
       COUNT(*) - COUNT(date_inscription) AS date_inscription_null
FROM client;

SELECT 'produit' AS nom_table,
       COUNT(*) - COUNT(nom)       AS nom_null,
       COUNT(*) - COUNT(categorie) AS categorie_null,
       COUNT(*) - COUNT(prix)      AS prix_null,
       COUNT(*) - COUNT(stock)     AS stock_null
FROM produit;

SELECT 'commande' AS nom_table,
       COUNT(*) - COUNT(client_id)     AS client_id_null,
       COUNT(*) - COUNT(date_commande) AS date_commande_null,
       COUNT(*) - COUNT(statut)        AS statut_null
FROM commande;

SELECT 'ligne_commande' AS nom_table,
       COUNT(*) - COUNT(commande_id)   AS commande_id_null,
       COUNT(*) - COUNT(produit_id)    AS produit_id_null,
       COUNT(*) - COUNT(quantite)      AS quantite_null,
       COUNT(*) - COUNT(prix_unitaire) AS prix_unitaire_null
FROM ligne_commande;
-- Résultat : 0 valeur manquante partout. C'est logique : toutes les
-- colonnes sont NOT NULL dans notre schéma. En revanche, l'exercice 13
-- montre qu'une donnée peut être présente mais incohérente.


-- ---------- B. Analyse commerciale ----------

-- Indicateurs en une seule requête (hors annulées)
SELECT SUM(lc.quantite * lc.prix_unitaire)        AS chiffre_affaires,
       COUNT(DISTINCT co.id)                      AS nb_commandes,
       ROUND(SUM(lc.quantite * lc.prix_unitaire)
             / COUNT(DISTINCT co.id), 2)          AS panier_moyen,
       COUNT(DISTINCT co.client_id)               AS nb_clients_actifs
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
WHERE co.statut <> 'annulée';
-- Résultat : CA 617 494,76 € ; 484 commandes ; panier moyen 1 275,82 € ;
-- 90 clients actifs (au moins une commande non annulée) sur 100 inscrits.

-- Taux d'annulation
SELECT COUNT(*)                                   AS nb_commandes_total,
       COUNT(*) FILTER (WHERE statut = 'annulée') AS nb_annulees,
       ROUND(100.0 * COUNT(*) FILTER (WHERE statut = 'annulée')
             / COUNT(*), 2)                       AS taux_annulation_pct
FROM commande;
-- Résultat : 16 commandes annulées sur 500, soit 3,2 %. Le montant
-- annulé est de 21 279,93 € : les annulations pèsent peu sur l'activité.


-- ---------- C. Top 10 clients par chiffre d'affaires ----------
SELECT cl.id AS id_client,
       cl.nom,
       cl.prenom,
       cl.ville,
       COUNT(DISTINCT co.id)               AS nb_commandes,
       SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM client cl
JOIN commande co       ON co.client_id   = cl.id
JOIN ligne_commande lc ON lc.commande_id = co.id
WHERE co.statut <> 'annulée'
GROUP BY cl.id, cl.nom, cl.prenom, cl.ville
ORDER BY chiffre_affaires DESC, cl.id
LIMIT 10;
-- Ces 10 clients réalisent 138 579,49 €, soit 22,4 % du CA. Ce sont des
-- clients fidèles (7 à 11 commandes chacun) plutôt que des acheteurs
-- d'une seule très grosse commande.


-- ---------- D. Synthèse mensuelle ----------
DROP TABLE IF EXISTS synthese_mensuelle;

CREATE TABLE synthese_mensuelle AS
SELECT DATE_TRUNC('month', co.date_commande)::date AS mois,
       COUNT(DISTINCT co.id)                       AS nb_commandes,
       SUM(lc.quantite * lc.prix_unitaire)         AS chiffre_affaires,
       ROUND(SUM(lc.quantite * lc.prix_unitaire)
             / COUNT(DISTINCT co.id), 2)           AS panier_moyen
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
WHERE co.statut <> 'annulée'
GROUP BY DATE_TRUNC('month', co.date_commande);

SELECT * FROM synthese_mensuelle ORDER BY mois;


-- =====================================================================
-- =====================================================================
-- PARTIE 7 - ANALYSE LIBRE
-- Pour chaque analyse : question, données, requête, résultat,
-- observation, intérêt pour l'entreprise.
-- =====================================================================
-- =====================================================================


-- =====================================================================
-- Analyse libre 1 - Écart entre prix payé et prix actuel du catalogue
-- ---------------------------------------------------------------------
-- Question : Les clients ont-ils payé moins cher (ou plus cher) que le
--            prix affiché aujourd'hui ? Dans quelles catégories ?
-- Données  : ligne_commande.prix_unitaire (prix payé),
--            produit.prix (prix actuel), produit.categorie,
--            commande.statut (on exclut les annulées).
-- Méthode  : on compare le CA réel au CA qu'on aurait obtenu en vendant
--            les mêmes quantités au prix actuel.
-- Limites  : on mesure un écart de PRIX, pas une perte de MARGE : sans
--            le coût d'achat des produits, on ne peut pas conclure sur
--            la rentabilité.
-- =====================================================================
SELECT p.categorie,
       COUNT(*)                                            AS nb_lignes,
       COUNT(*) FILTER (WHERE lc.prix_unitaire < p.prix)   AS nb_lignes_sous_prix_actuel,
       COUNT(*) FILTER (WHERE lc.prix_unitaire > p.prix)   AS nb_lignes_au_dessus_prix_actuel,
       ROUND(100.0 * COUNT(*) FILTER (WHERE lc.prix_unitaire < p.prix)
             / COUNT(*), 1)                                AS pct_lignes_sous_prix_actuel,
       SUM(lc.quantite * lc.prix_unitaire)                 AS ca_reel,
       SUM(lc.quantite * p.prix)                           AS ca_au_prix_actuel,
       SUM(lc.quantite * (p.prix - lc.prix_unitaire))      AS ecart_euros,
       ROUND(100.0 * (1 - SUM(lc.quantite * lc.prix_unitaire)
             / NULLIF(SUM(lc.quantite * p.prix), 0)), 2)   AS ecart_moyen_pct
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY ecart_moyen_pct DESC;

-- Écart global, toutes catégories confondues
SELECT SUM(lc.quantite * (p.prix - lc.prix_unitaire))      AS ecart_total_euros,
       ROUND(100.0 * (1 - SUM(lc.quantite * lc.prix_unitaire)
             / NULLIF(SUM(lc.quantite * p.prix), 0)), 2)   AS ecart_moyen_pct
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée';

-- Niveau de réduction de chaque ligne vendue sous le prix actuel
SELECT ROUND(100.0 * (1 - lc.prix_unitaire / p.prix)) AS reduction_pct,
       COUNT(*)                                       AS nb_lignes
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
  AND lc.prix_unitaire < p.prix
GROUP BY 1
ORDER BY 1;
-- Niveaux de réduction : uniquement 5 % (255 lignes), 10 % (262 lignes)
-- et 20 % (258 lignes). Aucune ligne n'a été vendue plus cher que le
-- prix actuel.
-- Observation : plus d'une vente sur deux se fait sous le prix catalogue,
-- et toujours selon trois paliers fixes. Cela ressemble à une politique
-- de promotions (codes à 5, 10 ou 20 %) plutôt qu'à des changements de
-- prix, qui donneraient des écarts quelconques. Au total, 40 350,04 €
-- n'ont pas été encaissés par rapport au prix catalogue. Le Sport,
-- première catégorie en CA, est aussi la plus remisée.
-- Intérêt : les promotions sont devenues la norme et non l'exception.
-- Il faudrait vérifier, avec les coûts d'achat, si les remises à 20 %
-- restent rentables, et si le Sport se vendrait aussi bien avec moins
-- de promotions.


-- =====================================================================
-- Analyse libre 2 - Le CA dépend-il de quelques gros clients ? (Pareto)
-- ---------------------------------------------------------------------
-- Question : Quelle part du CA est réalisée par les 20 % des clients
--            actifs qui dépensent le plus ?
-- Données  : CA par client (commande + ligne_commande, hors annulées).
-- Méthode  : les 90 clients actifs sont classés par CA décroissant puis
--            découpés en 5 groupes égaux avec NTILE(5) : chaque groupe
--            contient 18 clients. Le groupe 1 = les 20 % des clients
--            actifs les plus dépensiers. Les 10 clients sans achat ne
--            sont pas inclus.
-- =====================================================================
WITH ca_client AS (
    SELECT co.client_id,
           SUM(lc.quantite * lc.prix_unitaire) AS ca
    FROM commande co
    JOIN ligne_commande lc ON lc.commande_id = co.id
    WHERE co.statut <> 'annulée'
    GROUP BY co.client_id
),
quintiles AS (
    SELECT client_id,
           ca,
           NTILE(5) OVER (ORDER BY ca DESC) AS groupe
    FROM ca_client
)
SELECT groupe,
       CASE groupe
           WHEN 1 THEN 'Top 20 % des clients actifs'
           WHEN 2 THEN '20-40 %'
           WHEN 3 THEN '40-60 %'
           WHEN 4 THEN '60-80 %'
           ELSE        'Derniers 20 %'
       END                                                AS tranche_clients,
       COUNT(*)                                           AS nb_clients,
       SUM(ca)                                            AS chiffre_affaires,
       ROUND(100.0 * SUM(ca) / SUM(SUM(ca)) OVER (), 1)   AS part_du_ca_pct,
       ROUND(100.0 * SUM(SUM(ca)) OVER (ORDER BY groupe)
             / SUM(SUM(ca)) OVER (), 1)                   AS part_cumulee_pct
FROM quintiles
GROUP BY groupe
ORDER BY groupe;
-- Résultat :
--   Top 20 % des clients actifs (18)   218 888,74 €   35,4 %   cumul 35,4 %
--   20-40 %                    (18)   151 595,42 €   24,6 %   cumul 60,0 %
--   40-60 %                    (18)   116 936,94 €   18,9 %   cumul 78,9 %
--   60-80 %                    (18)    88 088,14 €   14,3 %   cumul 93,2 %
--   Derniers 20 %              (18)    41 985,52 €    6,8 %   cumul 100 %
-- Observation : la loi des 80/20 ne s'applique pas ici. Les 20 % des
-- clients actifs les plus dépensiers font 35,4 % du CA, et il faut 60 %
-- des clients pour atteindre 78,9 % du CA. Le CA est donc bien réparti.
-- Intérêt : l'entreprise ne dépend pas de quelques gros clients ; perdre
-- un client important aurait un impact limité. La priorité n'est pas
-- de protéger une poignée de comptes, mais de faire progresser le
-- groupe des derniers 20 % (6,8 % du CA seulement).


-- =====================================================================
-- Analyse libre 3 - Les clients reviennent-ils ?
-- ---------------------------------------------------------------------
-- Question : Les clients actifs rachètent-ils, et à quel rythme ?
-- Données  : commande.client_id, commande.date_commande, commande.statut.
-- Choix    : on n'utilise pas le délai "inscription -> premier achat".
--            Les commandes ne couvrent que 2025 alors que 69 des 90
--            clients actifs se sont inscrits avant 2025 : on ne voit pas
--            leurs achats antérieurs, le délai serait faux. On mesure
--            plutôt le temps entre deux commandes successives, qui ne
--            dépend que de données disponibles.
-- =====================================================================

-- 3a. Répartition des clients actifs selon leur nombre de commandes
--     non annulées
WITH nb_cmd AS (
    SELECT client_id, COUNT(*) AS nb
    FROM commande
    WHERE statut <> 'annulée'
    GROUP BY client_id
)
SELECT CASE
           WHEN nb = 1 THEN '1 - Une seule commande'
           WHEN nb = 2 THEN '2 - Deux commandes'
           ELSE             '3 - Trois commandes ou +'
       END                                                AS profil,
       COUNT(*)                                           AS nb_clients,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_clients
FROM nb_cmd
GROUP BY 1
ORDER BY 1;
-- Résultat : 1 seule commande : 2 clients (2,2 %) ; 2 commandes :
-- 8 clients (8,9 %) ; 3 commandes ou plus : 80 clients (88,9 %).
-- En moyenne, 5,4 commandes par client actif sur l'année.

-- 3b. Nombre de jours entre deux commandes successives d'un même client
--     (LAG avec PARTITION BY : on compare chaque commande à la
--     précédente du même client)
WITH achats AS (
    SELECT client_id,
           date_commande
             - LAG(date_commande) OVER (PARTITION BY client_id
                                        ORDER BY date_commande, id)
             AS jours_depuis_precedente
    FROM commande
    WHERE statut <> 'annulée'
)
SELECT COUNT(jours_depuis_precedente)                        AS nb_intervalles,
       ROUND(AVG(jours_depuis_precedente), 1)                AS intervalle_moyen_jours,
       PERCENTILE_CONT(0.25) WITHIN GROUP
           (ORDER BY jours_depuis_precedente)                AS premier_quartile,
       PERCENTILE_CONT(0.5) WITHIN GROUP
           (ORDER BY jours_depuis_precedente)                AS intervalle_median_jours,
       PERCENTILE_CONT(0.75) WITHIN GROUP
           (ORDER BY jours_depuis_precedente)                AS troisieme_quartile,
       MAX(jours_depuis_precedente)                          AS intervalle_max_jours,
       ROUND(100.0 * COUNT(*) FILTER (WHERE jours_depuis_precedente <= 60)
             / COUNT(jours_depuis_precedente), 1)            AS pct_rachat_sous_60_jours
FROM achats;
-- Résultat : 394 intervalles ; moyenne 51,7 jours ; médiane 36 jours ;
-- 1er quartile 15 jours ; 3e quartile 74,75 jours ; maximum 285 jours.
-- 68,0 % des rachats ont lieu moins de 60 jours après l'achat précédent.
-- Observation : la clientèle active est très fidèle. Presque 9 clients
-- actifs sur 10 ont commandé au moins 3 fois en 2025, et un client
-- repasse commande en général un peu plus d'un mois après la précédente.
-- Le vrai point faible est ailleurs : 10 inscrits n'ont jamais commandé.
-- Intérêt : la fidélisation fonctionne déjà ; l'effort doit porter sur
-- l'activation des nouveaux inscrits. Le rythme médian donne aussi un
-- repère concret : un client sans commande depuis plus de 75 jours
-- (3e quartile) sort de son rythme habituel et peut être relancé.


-- =====================================================================
-- Analyse libre 4 - Quel jour de la semaine vend-on le plus ?
-- ---------------------------------------------------------------------
-- Question : Les clients achètent-ils plus en semaine ou le week-end ?
-- Données  : commande.date_commande, montants des lignes, hors annulées.
-- Méthode  : EXTRACT(ISODOW) donne 1 = lundi ... 7 = dimanche.
-- Remarque : 2025 compte 53 mercredis et 52 de chaque autre jour,
--            l'écart est négligeable.
-- =====================================================================
SELECT EXTRACT(ISODOW FROM co.date_commande) AS num_jour,
       CASE EXTRACT(ISODOW FROM co.date_commande)
           WHEN 1 THEN 'Lundi'
           WHEN 2 THEN 'Mardi'
           WHEN 3 THEN 'Mercredi'
           WHEN 4 THEN 'Jeudi'
           WHEN 5 THEN 'Vendredi'
           WHEN 6 THEN 'Samedi'
           ELSE        'Dimanche'
       END                                   AS jour,
       COUNT(DISTINCT co.id)                 AS nb_commandes,
       SUM(lc.quantite * lc.prix_unitaire)   AS chiffre_affaires,
       ROUND(SUM(lc.quantite * lc.prix_unitaire)
             / COUNT(DISTINCT co.id), 2)     AS panier_moyen
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
WHERE co.statut <> 'annulée'
GROUP BY 1, 2
ORDER BY 1;
-- Observation : le vendredi se détache nettement avec 17,6 % du CA, grâce
-- au plus grand nombre de commandes (à égalité avec le mercredi) et au
-- panier moyen le plus élevé. Le week-end est le moment le plus calme :
-- 124 commandes (25,6 % du total pour 2 jours sur 7), avec un panier
-- équivalent à celui de la semaine.
-- Intérêt : programmer les promotions et les newsletters juste avant le
-- vendredi pour profiter du pic ; prévoir plus de personnel logistique
-- et service client en fin de semaine.


-- =====================================================================
-- Analyse libre 5 - Risque de rupture de stock
-- ---------------------------------------------------------------------
-- Question : Pour chaque produit vendu, combien de mois le stock actuel
--            peut-il tenir au rythme de vente observé ?
-- Données  : produit.stock, quantités vendues (hors annulées),
--            nombre de mois couverts par les données (12).
-- Méthode  : couverture (en mois) = stock / ventes moyennes par mois.
-- Limite   : suppose que le rythme de vente passé va continuer.
-- =====================================================================
WITH nb_mois AS (
    SELECT COUNT(DISTINCT DATE_TRUNC('month', date_commande)) AS n
    FROM commande
    WHERE statut <> 'annulée'
),
ventes AS (
    SELECT lc.produit_id, SUM(lc.quantite) AS qte_vendue
    FROM ligne_commande lc
    JOIN commande co ON co.id = lc.commande_id
    WHERE co.statut <> 'annulée'
    GROUP BY lc.produit_id
),
couverture AS (
    SELECT p.nom AS produit,
           p.categorie,
           p.stock,
           v.qte_vendue,
           ROUND(v.qte_vendue::numeric / m.n, 1)                      AS ventes_par_mois,
           ROUND(p.stock / NULLIF(v.qte_vendue::numeric / m.n, 0), 1) AS mois_de_stock
    FROM produit p
    JOIN ventes v ON v.produit_id = p.id
    CROSS JOIN nb_mois m
)
SELECT *,
       CASE
           WHEN mois_de_stock < 1  THEN 'Risque de rupture'
           WHEN mois_de_stock < 3  THEN 'À surveiller'
           WHEN mois_de_stock > 12 THEN 'Surstock'
           ELSE                         'OK'
       END AS alerte_stock
FROM couverture
ORDER BY mois_de_stock, produit;
-- Résultat (60 produits vendus) : 4 en risque de rupture, 8 à
-- surveiller, 17 OK, 31 en surstock.
--  * Rupture : Lampe 2, Souris 2 et Sweat 1 (stock 0), Haltères 1
--    (1 unité pour environ 4 ventes par mois).
--  * Surstock extrême : Disque dur 2, 43,6 mois de stock.
-- Observation : le stock est mal réparti. Lampe 2 est le 7e produit en
-- CA (18 462,73 €) et se vend environ 5 fois par mois, pourtant il est
-- épuisé : chaque mois de rupture fait perdre environ 1 660 € de ventes
-- au prix catalogue. À l'inverse, plus de la moitié des produits vendus
-- ont plus d'un an de stock devant eux.
-- Intérêt : réapprovisionner en priorité les 4 produits en rupture et
-- les 8 à surveiller, et réduire les commandes fournisseurs sur les
-- produits en surstock (complète l'exercice 14 sur les invendus).


-- =====================================================================
-- Analyse libre 6 - Quelles catégories sont le plus annulées ?
-- ---------------------------------------------------------------------
-- Question : Les annulations touchent-elles certaines catégories plus
--            que d'autres, et quel montant représentent-elles ?
-- Données  : commande.statut, lignes, produit.categorie.
--            Ici on garde volontairement TOUTES les commandes,
--            annulées comprises, puisque ce sont elles qu'on étudie.
-- Remarque : une commande peut contenir plusieurs catégories, donc la
--            somme de nb_annulees dépasse 16.
-- =====================================================================
SELECT p.categorie,
       COUNT(DISTINCT co.id)                                      AS nb_commandes,
       COUNT(DISTINCT co.id) FILTER (WHERE co.statut = 'annulée') AS nb_annulees,
       COALESCE(SUM(lc.quantite * lc.prix_unitaire)
                FILTER (WHERE co.statut = 'annulée'), 0)          AS montant_annule,
       ROUND(100.0 * COALESCE(SUM(lc.quantite * lc.prix_unitaire)
                 FILTER (WHERE co.statut = 'annulée'), 0)
             / SUM(lc.quantite * lc.prix_unitaire), 1)            AS pct_montant_annule
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
JOIN produit p         ON p.id = lc.produit_id
GROUP BY p.categorie
ORDER BY pct_montant_annule DESC;
-- Résultat :
--   Mode           11 commandes annulées   7 337,25 €   5,6 %
--   Informatique    8                      5 907,96 €   4,1 %
--   Maison          8                      3 686,16 €   3,2 %
--   Audio           3                      1 721,46 €   2,1 %
--   Sport           5                      2 627,10 €   1,6 %
--   Total : 16 commandes, 21 279,93 € annulés.
-- Observation : la Mode est la catégorie la plus touchée. 11 des 16
-- commandes annulées contiennent au moins un article de mode, et son
-- taux est 3,5 fois celui du Sport. Une même cliente (id 39) a annulé
-- 3 commandes à elle seule.
-- Intérêt : dans la mode, les annulations viennent souvent de doutes sur
-- la taille ou la coupe. Un guide des tailles plus précis ou de
-- meilleures photos produits pourraient réduire ces annulations et
-- récupérer une partie des 21 279,93 € perdus.
