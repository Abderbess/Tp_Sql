# Projet — Analyse des données d'une plateforme e-commerce
Groupe 4

Analyse en SQL (PostgreSQL) de l'activité d'une plateforme e-commerce sur l'année 2025 : produits, clients, commandes, chiffre d'affaires, qualité des données et indicateurs clés.

## Structure du dépôt

```
projet-ecommerce/
├── create_schema.sql    # création des tables et des contraintes
├── seed_ecommerce.sql   # données fournies
├── analysis.sql         # toutes les requêtes (exercices 1 à 15 + analyse libre), avec résultats commentés
├── README.md
└── .gitignore
```

## Modèle de données

| Table            | Rôle                               | Clés                                             |
|------------------|------------------------------------|--------------------------------------------------|
| `client`         | clients inscrits                   | PK `id`, `email` unique                          |
| `produit`        | catalogue (prix actuel, stock)     | PK `id`                                          |
| `commande`       | commandes passées                  | PK `id`, FK `client_id` → `client(id)`           |
| `ligne_commande` | produits d'une commande            | PK `id`, FK `commande_id` → `commande(id)`, FK `produit_id` → `produit(id)` |

Choix de modélisation :
- **Prix payé séparé du prix actuel** : `prix_unitaire` est stocké dans `ligne_commande`, car le prix payé peut différer du prix catalogue (promotions). Modifier `produit.prix` ne change donc pas l'historique des ventes.
- **Table `ligne_commande`** : une commande contient plusieurs produits et un produit apparaît dans plusieurs commandes (relation plusieurs-à-plusieurs).
- **Types** : `NUMERIC(10,2)` pour les montants (calcul exact, contrairement à `FLOAT`), `DATE` pour les dates, `INTEGER GENERATED ALWAYS AS IDENTITY` pour les identifiants.
- **Contraintes** : `NOT NULL` sur les champs obligatoires, `UNIQUE` sur l'email, `CHECK` sur le statut (`payée`, `expédiée`, `livrée`, `annulée`), sur les prix (≥ 0), le stock (≥ 0) et la quantité (> 0).
- **Cas prévus par les règles métier** : un client sans commande et un produit jamais vendu sont possibles, car les clés étrangères sont portées par `commande` et `ligne_commande`.
- **Pas de suppression en cascade** : on ne peut pas supprimer un client ou un produit qui a des ventes, ce qui protège l'historique.

## Installation et exécution

Prérequis : PostgreSQL installé et la commande `psql` disponible.

**1. Créer la base**

```bash
createdb ecommerce
```

(ou dans `psql` : `CREATE DATABASE ecommerce;`)

**2. Créer les tables**

```bash
psql -d ecommerce -f create_schema.sql
```

**3. Charger les données**

```bash
psql -d ecommerce -f seed_ecommerce.sql
```

Vérification de l'import (résultat attendu : 100 clients, 65 produits, 500 commandes, 1 547 lignes) :

```sql
SELECT 'client', COUNT(*) FROM client
UNION ALL SELECT 'produit', COUNT(*) FROM produit
UNION ALL SELECT 'commande', COUNT(*) FROM commande
UNION ALL SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;
```

**4. Exécuter les analyses**

```bash
psql -d ecommerce -f analysis.sql
```

Les requêtes peuvent aussi être exécutées une par une dans pgAdmin ou DBeaver. Sous Windows, ajouter `-U postgres` aux commandes si nécessaire.

> **Règle de calcul :** montant d'une ligne = `quantite × prix_unitaire`. Les commandes `annulée` sont exclues du chiffre d'affaires, des quantités vendues et du panier moyen. Elles restent comptées dans le nombre de commandes passées par client, la classification des paniers et le taux d'annulation.

## Principales conclusions

### Activité globale
- Chiffre d'affaires 2025 : **617 494,76 €** pour **484 commandes** non annulées, soit un **panier moyen de 1 275,82 €**.
- **90 clients actifs sur 100 inscrits** ; 10 clients n'ont jamais commandé.
- **16 commandes annulées sur 500 (3,2 %)**, pour 21 279,93 € : les annulations pèsent peu.

### Produits et catégories
- Le **Sport** génère le plus de CA (162 149,83 €, 26,3 %), mais l'**Informatique** vend le plus d'unités (1 051). L'écart s'explique par le prix moyen payé : 207,88 € par unité en Sport contre 131,33 € en Informatique.
- Produit le plus vendu : **Montre sport 1** (101 unités). Produit qui rapporte le plus : **Sac à dos 1** (24 925,47 €).
- Les **gros paniers** (≥ 1 500 €) représentent 38 % des commandes mais **64 % du CA**.
- **5 produits n'ont jamais été vendus** (un par catégorie) : 325 unités en stock, soit 22 296,30 € immobilisés.

### Évolution dans le temps
- Meilleurs mois : **mai** (68 841,64 €), août (65 441,63 €) et décembre (60 655,34 €).
- Mois les plus faibles : **janvier** (34 765,36 €), avril (35 932,15 €) et septembre (40 578,54 €).
- Tendance : début d'année lent (T1 = 126 281,09 €), puis activité stable autour de 160 000 € par trimestre, T4 le plus fort. Le second semestre dépasse le premier de **13 %**.
- Le panier moyen explique une partie des écarts : février a beaucoup de commandes mais de petits paniers, octobre l'inverse.

### Qualité des données
- **30 commandes** (6 %) ont une date antérieure à l'inscription du client. Elles concernent 12 clients, tous inscrits en 2025. C'est impossible dans la réalité : erreur de saisie ou date d'inscription modifiée après coup. Il faudrait corriger à la source et ajouter un contrôle à l'insertion (trigger).
- Aucune valeur manquante : toutes les colonnes sont `NOT NULL`.

### Analyse libre
1. **Promotions** : 51,7 % des lignes vendues l'ont été sous le prix catalogue, toujours avec une réduction de 5 %, 10 % ou 20 %. L'écart total atteint 40 350,04 € (6,13 %). Le Sport est la catégorie la plus remisée. Sans coût d'achat, on ne peut pas conclure sur la marge.
2. **Concentration du CA** : les 20 % des clients actifs les plus dépensiers (18 clients sur 90) réalisent seulement **35,4 % du CA**. La loi des 80/20 ne s'applique pas : l'entreprise ne dépend pas de quelques gros clients.
3. **Fidélité** : **88,9 %** des clients actifs ont commandé au moins 3 fois en 2025 (5,4 commandes en moyenne). Un client repasse commande en médiane **36 jours** après la précédente.
4. **Jour de la semaine** : le **vendredi** est le jour le plus fort (17,6 % du CA, panier moyen de 1 410,48 €). Le week-end est le moment le plus calme.
5. **Stocks** : **4 produits en rupture** (dont Lampe 2, 7e produit en CA, environ 1 660 € de ventes perdues par mois) et **31 produits en surstock** (plus d'un an de stock).
6. **Annulations** : la **Mode** est la plus touchée (5,6 % de son montant, 11 commandes annulées sur 16 en contiennent), le Sport la moins touchée (1,6 %).

### Recommandations
- **Stocks** : réapprovisionner en priorité les 4 produits en rupture (Lampe 2, Souris 2, Sweat 1, Haltères 1), réduire les achats sur les produits en surstock et écouler les 5 produits jamais vendus.
- **Clients** : la fidélité est déjà forte ; l'effort doit porter sur l'**activation des 10 inscrits sans commande** (offre de bienvenue), et sur la relance des clients sans achat depuis plus de 75 jours.
- **Commercial** : concentrer les promotions et les newsletters avant le vendredi, et vérifier avec les coûts d'achat la rentabilité des remises à 20 %.
- **Mode** : améliorer le guide des tailles et les fiches produits pour réduire les annulations.
- **Données** : corriger les 30 dates incohérentes et empêcher leur réapparition par un contrôle à l'insertion.
