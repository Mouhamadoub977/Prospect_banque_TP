# Gestion des Sinistres - Transformation de Données avec PySpark

Ce projet utilise **PySpark** pour transformer une table de sinistres liée aux contrats d'assurance, en réorganisant les informations pour faciliter leur utilisation dans des analyses ou systèmes de gestion. La transformation restructure les données de sinistres d'une structure multi-colonnes vers une table simplifiée.

![PySpark](https://img.shields.io/badge/PySpark-3.3.0-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Table des Matières

- [Introduction](#Introduction)
- [Prérequis](#Prérequis)
- [Installation](#installation)
- [Description du Projet](#description-du-projet)
- [Structure des Données](#structure-des-données)
- [Instructions d'Exécution](#instructions d'Exécution)
- [Instructions d'Exécution](#instructions-dexécution)
- [Requêtes Spécifiques](#Requêtes-Spécifiques)
- [Gestion des Droits d'Accès](#Gestion-des-Droits-d'Accès)
- [Contribuer](#contribuer)
- [Licence](#licence)
- [Contact](#contact)








# Projet de Gestion Bancaire avec SQL

## Introduction

Ce projet consiste à créer et manipuler une base de données pour une banque fictive. Il comprend la création de tables pour gérer les informations personnelles des clients, les comptes, les transactions, ainsi que la gestion des droits d'accès pour différents rôles au sein de la banque.

## Prérequis

- **SGBD** : PostgreSQL (ou tout autre SGBD compatible avec le standard SQL).
- **Scripts SQL** : Les scripts nécessaires sont fournis dans le répertoire `Scripts/`.
- **Données** : Les fichiers de données `set_global`, `set_fr`, et `tr` sont disponibles dans le répertoire `Data/`.

## Installation

1. **Cloner le dépôt** :

   ```bash
   git clone https://github.com/votre-nom-utilisateur/Prospect_banque_TP.git
   cd Prospect_banque_TP
Configurer la base de données :

Assurez-vous que PostgreSQL est installé et en cours d'exécution.

Créez une nouvelle base de données :


CREATE DATABASE banque;
Connectez-vous à la base de données :

bash
Copier le code
psql -d banque

Charger les données :

Importez les fichiers de données situés dans le répertoire Data/ dans votre base de données. Vous pouvez utiliser les commandes COPY ou des outils d'importation spécifiques.
Description du Projet
Le projet modélise une banque avec les fonctionnalités suivantes :

Gestion des clients : Prospects, clients actuels, anciens clients.
Informations personnelles : Stockage des informations personnelles des clients.
Comptes bancaires : Comptes courants, comptes épargne.
Transactions : Enregistrement des transactions bancaires.
Contrôles d'accès : Mise en place de rôles et de permissions pour sécuriser l'accès aux données.
Structure de la Base de Données
Tables Principales
personnal_info : Informations personnelles des individus.
prospects : Informations sur les prospects.
customers : Informations sur les clients actuels.
ex_customers : Informations sur les anciens clients.
contacts : Coordonnées des clients.
accounts : Informations sur les comptes bancaires.
compte_courant : Détails spécifiques des comptes courants.
compte_epargne : Détails spécifiques des comptes épargne.
transactions : Enregistrements des transactions financières.
Schéma Relationnel


Instructions d'Exécution
Exécution du script SQL :

Dans votre client SQL, exécutez le script Scripts/banque.sql pour créer les tables et insérer les données.


\i Scripts/banque.sql
Vérification des données :

Utilisez des requêtes SELECT pour vérifier que les tables ont été correctement créées et peuplées.


SELECT * FROM customers LIMIT 10;
Exécution des requêtes spécifiques :

Des exemples de requêtes pour extraire des informations spécifiques sont fournis dans la section suivante.
Requêtes Spécifiques
Clients premium vivant en Île-de-France :


SELECT * FROM premium_customers WHERE departement = 'Île-de-France';
Clients normaux de nationalité australienne :


SELECT * FROM free_customerd WHERE nationalite = 'Australian';
Comptes courants de clients âgés de plus de 30 ans vivant à Paris et de nationalité européenne :


SELECT * FROM free_customerd
WHERE age > 30 AND ville = 'PARIS' AND nationalite IN ('French', 'German', 'Hispanic', 'United_Kingdom');
Statistiques par nationalité :


SELECT 
    sf.nationalite,
    COUNT(CASE WHEN acc.account_type = 'compte_courant' AND fc.customer_id IS NOT NULL THEN 1 END) AS comptes_normaux,
    COUNT(CASE WHEN acc.account_type = 'compte_courant' AND pc.customer_id IS NOT NULL THEN 1 END) AS comptes_premium,
    COUNT(CASE WHEN acc.account_type = 'compte_epargne' THEN 1 END) AS comptes_epargne
FROM set_fr sf
LEFT JOIN accounts acc ON sf.customer_id = acc.customer_id
LEFT JOIN free_customerd fc ON sf.customer_id = fc.customer_id
LEFT JOIN premium_customers pc ON sf.customer_id = pc.customer_id
GROUP BY sf.nationalite
ORDER BY sf.nationalite;
Gestion des Droits d'Accès
Des rôles spécifiques ont été créés pour gérer les droits d'accès :

Rôles :

ops
auditeurs
management
dev
Attribution des droits :

ops : Droit de lecture sur toutes les tables existantes et futures.
auditeurs : Droit de lecture uniquement sur la table accounts.
dev : Droits de lecture, d'écriture, de mise à jour et de suppression sur toutes les tables.
Création des utilisateurs et assignation des rôles :

sql
Copier le code
CREATE USER user_ops WITH PASSWORD 'password';
GRANT ops TO user_ops;

CREATE USER user_auditeur WITH PASSWORD 'password';
GRANT auditeurs TO user_auditeur;

CREATE USER user_dev WITH PASSWORD 'password';
GRANT dev TO user_dev;
Contributeurs
Mouhamadou BA - Créateur du projet
Licence
Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.