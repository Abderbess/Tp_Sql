SET client_encoding TO 'UTF8';

BEGIN;

CREATE TABLE client (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    ville VARCHAR(100) NOT NULL,
    date_inscription DATE NOT NULL
);

CREATE TABLE produit (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    categorie VARCHAR(100) NOT NULL,
    prix NUMERIC(10, 2) NOT NULL CHECK (prix >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0)
);

CREATE TABLE commande (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id INTEGER NOT NULL,
    date_commande DATE NOT NULL,
    statut VARCHAR(20) NOT NULL
        CHECK (statut IN ('payée', 'expédiée', 'livrée', 'annulée')),
    CONSTRAINT fk_commande_client
        FOREIGN KEY (client_id) REFERENCES client(id)
);

CREATE TABLE ligne_commande (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    commande_id INTEGER NOT NULL,
    produit_id INTEGER NOT NULL,
    quantite INTEGER NOT NULL CHECK (quantite > 0),
    prix_unitaire NUMERIC(10, 2) NOT NULL CHECK (prix_unitaire >= 0),
    CONSTRAINT fk_ligne_commande_commande
        FOREIGN KEY (commande_id) REFERENCES commande(id),
    CONSTRAINT fk_ligne_commande_produit
        FOREIGN KEY (produit_id) REFERENCES produit(id)
);

COMMIT;
