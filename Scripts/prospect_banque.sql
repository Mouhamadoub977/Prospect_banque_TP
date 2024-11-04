SELECT * FROM set_global LIMIT 10;

select * from set_fr

-- Création des tables PROSPECTS, CUSTOMERS, EX_CUSTOMERS, CONTACTS
-- Table infos perso
CREATE TABLE personnal_info (
    id_personnal_info SERIAL PRIMARY KEY,
    nationalite VARCHAR(50),
    noms VARCHAR(100),
    prenoms VARCHAR(100),
    genre VARCHAR(10),
    titre VARCHAR(20),
    date_de_naissance DATE,
    age INT
);

-- Fonction pour calculer et mettre à jour l'âge
CREATE OR REPLACE FUNCTION update_age()
RETURNS TRIGGER AS $$
BEGIN
    NEW.age := DATE_PART('year', AGE(NEW.date_de_naissance));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour exécuter la fonction lors d'une insertion ou mise à jour
CREATE TRIGGER age_update
BEFORE INSERT OR UPDATE OF date_de_naissance
ON personnal_info
FOR EACH ROW
EXECUTE FUNCTION update_age();

-- table prospect
CREATE TABLE prospects (
    id_customer SERIAL PRIMARY KEY,
    id_personnal_info INT,
    employeur VARCHAR(100),
    poste VARCHAR(100),
    FOREIGN KEY (id_personnal_info) REFERENCES personnal_info(id_personnal_info)
);

-- inserer les données
INSERT INTO prospects (id_personnal_info, employeur, poste)
SELECT pi.id_personnal_info, sf.Employeur, sf.Poste
FROM set_fr sf
JOIN personnal_info pi ON sf.Noms = pi.noms AND sf.Prenoms = pi.prenoms;

select * from prospects

-- table customer
CREATE TABLE customers (
    id_customer SERIAL PRIMARY KEY,
    id_personnal_info INT,
    employeur VARCHAR(100),
    poste VARCHAR(100),
    FOREIGN KEY (id_personnal_info) REFERENCES personnal_info(id_personnal_info)
);

-- insertion de données dans customers
INSERT INTO customers (id_personnal_info, employeur, poste)
SELECT pi.id_personnal_info, sf.Employeur, sf.Poste
FROM set_fr sf
JOIN personnal_info pi ON sf.Noms = pi.noms AND sf.Prenoms = pi.prenoms;

-- Table ex customer
CREATE TABLE ex_customers (
    id_customer SERIAL PRIMARY KEY,
    id_personnal_info INT,
    employeur VARCHAR(100),
    poste VARCHAR(100),
    date_sortie DATE,
    raisons_sortie TEXT,
    FOREIGN KEY (id_personnal_info) REFERENCES personnal_info(id_personnal_info)
);

-- table contact
CREATE TABLE contacts (
    id_contact SERIAL PRIMARY KEY,
    email VARCHAR(100),
    telephone VARCHAR(20),
    id_customer INT,
    indicatif_pays VARCHAR(10),
    FOREIGN KEY (id_customer) REFERENCES customers(id_customer)
);
-- insertion des données

INSERT INTO contacts (id_customer, email, telephone, indicatif_pays)
SELECT c.id_customer, sf.Email, sf.Telephone, sf.IndicatifPays
FROM set_fr sf
JOIN personnal_info pi ON sf.noms = pi.noms AND sf.prenoms = pi.prenoms
JOIN customers c ON c.id_personnal_info = pi.id_personnal_info;

select * from contacts
select * from personnal_info
select * from set_fr
select * from customers




-- Table des comptes
CREATE TABLE accounts (
    id_account SERIAL PRIMARY KEY,
    id_customer INT NOT NULL REFERENCES customers(id_customer),
    type_account VARCHAR(20) NOT NULL,
    date_ouverture DATE NOT NULL,
    solde DECIMAL(15, 2) NOT NULL DEFAULT 0.0,
    CONSTRAINT chk_type_account CHECK (type_account IN ('courant', 'epargne'))
);

-- Insertion compte et partition selo type de compte
INSERT INTO accounts (id_customer, type_account, date_ouverture, solde)
SELECT c.id_customer, 
       CASE WHEN sf.CarteType = 'Visa' THEN 'courant' ELSE 'epargne' END,
       NOW() AS date_ouverture,
       0.0 AS solde
FROM set_fr sf
JOIN personnal_info pi ON sf.noms = pi.noms AND sf.prenoms = pi.prenoms
JOIN customers c ON pi.id_personnal_info = c.id_personnal_info;




select * from accounts


-- compte courant
CREATE TABLE compte_courant (
    id_account INT PRIMARY KEY REFERENCES accounts(id_account),
    numero_carte VARCHAR(16) UNIQUE,
    carte_type VARCHAR(20),
    expiration_carte DATE,
    frais DECIMAL(10, 2) DEFAULT 0.0
);

-- insertion données dans compte courant (sup des doublons avant l'insertion)
INSERT INTO compte_courant (id_account, numero_carte, carte_type, expiration_carte)
SELECT DISTINCT ON (sf.NumeroCarte) a.id_account, sf.NumeroCarte, sf.CarteType, sf.ExpirationCarte
FROM set_fr sf
JOIN accounts a ON a.id_customer = sf.CustomerID
WHERE a.type_account = 'courant';


-- verif s'il y a des doublons
SELECT NumeroCarte, COUNT(*)
FROM set_fr
GROUP BY NumeroCarte
HAVING COUNT(*) > 1;

-- compte épargne
CREATE TABLE compte_epargne (
    id_account INT PRIMARY KEY REFERENCES accounts(id_account),
    taux_interet DECIMAL(5, 2) NOT NULL CHECK (taux_interet >= 0),
    plafond DECIMAL(15, 2)
);

-- epargne insertion 
INSERT INTO compte_epargne (id_account, taux_interet, plafond)
SELECT a.id_account, 0.02 AS taux_interet, 100000.0 AS plafond
FROM accounts a
WHERE a.type_account = 'epargne';

select * from compte_epargne

-- contact remplissage table
INSERT INTO contacts (id_customer, email, phone, country_code)
SELECT CustomerID, Email, Telephone, IndicatifPays
FROM set_fr;

-- remplissage table info personnel
INSERT INTO personnal_info (nationalite, noms, prenoms, genre, titre, date_de_naissance)
SELECT Nationalite, Noms, Prenoms, Genre, Titre, Date_de_naissance
FROM set_fr;

select * from personnal_info;
select * from set_fr



DROP TABLE IF EXISTS transactions;


CREATE TABLE transactions (
    account_number VARCHAR(20),
    timestamp VARCHAR(8),
    transaction_amount VARCHAR(30),
    reciprocal_account_number VARCHAR(50)
);
select * from set_fr


-- 1- Modifier le nom du champ "customer_id" original du dataset en "id_int"
alter table set_fr rename column customerid to id_int;
select * from set_fr

-- 2- Générer un Customer_id (différent de id_int) à partir du champ nationalID privé de ses 3 derniers caractères.
alter table set_fr add column Customer_id VARCHAR(50);
update set_fr
set Customer_id = left(nationalid, length(nationalid) -3);

select Customer_id, nationalid, cartetype from set_fr

-- 3- Séparer les données en 2 parties Carte visa = free_customerd 
-- MasterCard= premium_customers Les champs de ces 2 tables sont identiques 
--et sont le customer_id avec les autres champs du dataset contenant les infos sur les cartes

select Customer_id, cartetype from set_fr

create table set_fr_copy as table set_fr;

-- table pour client carte visa et primium
create table free_customerd as select * from set_fr where cartetype = 'Visa';
create table premium_customers as select * from set_fr where cartetype = 'MasterCard';

select count(*) from premium_customers
select * from premium_customers

-- 4- On suppose que parmi les 5000 clients, 1578 ont un compte épargne 
-- et les 3422 restants, n'ont qu'un compte courant. 
-- Assignez les 1578 premiers id_int dans la table compte_epargne

drop table if exists compte_epargne;

create table compte_epargne as
select * from set_fr
order by id_int limit 1578;

select * from compte_epargne

Drop table if exists compte_courant;

create table compte_courant as
select * from set_fr
order by id_int offset 1578;

select count(*) from compte_courant
select count(*) from compte_epargne



-- 5- La table ACCOUNTS contient 3 champs : - Le customer_id précédemment  
-- généré Le account_number que vous devrez récupérer à partir des 16 premiers
-- caractères des différentes occurrences du champ reciprocal_account_number 
-- du dataset transactions - Le account_type qui sera "compte_epargne" 
-- pour les 1578 account_number non nuls et "compte_courant" pour les lignes 
-- restantes avec des account_number nuls

drop table if exists accounts
Create table accounts (
	customer_id VARCHAR(50),
	account_number VARCHAR(16),
	account_type VARCHAR(20)	
);
insert into accounts (customer_id, account_number, account_type)
select sf.customer_id,
left (tr.reciprocal_account_number, 16) as account_number,
case when ce.customer_id is not null then 'compte_epargne' else 'compte_courant' end as account_type
from set_fr sf
LEFT JOIN transactions tr ON sf.numerocarte = tr.reciprocal_account_number
LEFT JOIN compte_epargne ce ON sf.customer_id = ce.customer_id;




select * from accounts

select * from transactions where reciprocal_account_number = '4716734894589650';


-- définissions des droits d'accès
-- on créé les rôles spécifiques
create ROLE ops;
create ROLE auditeurs;
create ROLE management;
create ROLE dev;

-- Création des utilisateurs et assignation des rôles
create user user_ops with password 'password';
CREATE USER user_auditeur WITH PASSWORD 'password';
CREATE USER user_management WITH PASSWORD 'password';
CREATE USER user_dev WITH PASSWORD 'password';

-- Assignons les rôles 
GRANT ops to user_ops;
Grant auditeurs to user_auditeur;
Grant management to user_management;
Grant dev to user_dev;

-- Attribution des accès
-- Accordons le droit de lecture sur toutes les tables existantes et futures
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ops;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ops;

-- accorder le droit de lecture sur la table accounts seulement (pour les auditeurs)
grant select on table accounts to auditeurs;

-- droit de lecture et d'écriture sur toutes les tables pour les dev
grant select, insert, update, delete on all tables in schema public to dev;
alter default privileges in schema public grant select, update, insert, delete on tables to dev;




select * from accounts where account_number is not null

select * from set_fr where customer_id like '%'
select * from transactions

select * from transactions where reciprocal_account_number is null or reciprocal_account_number = ''

UPDATE accounts
SET account_number = LEFT(tr.reciprocal_account_number, 16)
FROM transactions tr
WHERE accounts.customer_id = tr.customer_id
AND accounts.account_number IS NULL
AND tr.reciprocal_account_number IS NOT NULL;





select * from accounts
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

-- créer table adresses (custumer_id, rue, ville, departement, pays)
drop table if exists transactions_1;
select * from contacts

select * from set_fr




-- num de rue, nom de rue
-- calcul de l'age a partir de la date de n
-- contact, adresse, info perso tables pour les données perso ; puis separation entre 
-- prospect, custumers et anciens custumers
-- dispatcher ceux qui ont une carte visa et ancien carte à la place de custumers, ex-custumers
-- attribuer les droits à différents utilisateurs
-- limit table space (trouver un moyen de décharger les table qu'on a crée : 
-- proces d'archivage) et limit req space ()
-- gerer la volumétrie, type de champs, ce qui est sensé etre faite sur la données
-- pouvoir anticiper ça (fluidité et rapidité des requête):
-- partitionnement (partition by ex: date, tech, house)
-- index
-- Table transaction ; jointure (créer les clés)
-- de fr creer tables info perso, adress, contacts. A partir de ça creer tables custumers et custumers primium


-- l'ensemble des clients primium vivant en IDF
select * from premium_customers where departement = 'Île-de-France'
select count(*) from free_customerd where departement = 'Île-de-France'

-- l'ensemble des clients normaux qui sont australiens
select distinct nationalite from set_global
select * from free_customerd where nationalite = 'Australian'

-- l'ensemble des comptes courants des clients ayant + 30 ans vivant à Paris et de nationalité européen
select * from free_customerd where age > 30 and ville = 'PARIS'
and (nationalite = 'French' or nationalite = 'German'
or nationalite = 'Hispanic' or nationalite = 'United_Kingdom')


-- ["French", "German", "Hispanic", "United_Kingdom"]
-- select distinct nationalite from free_customerd where age > 30 and ville = 'PARIS'

-- Pour chaque nationalité, sortir nbre de compte normaux, nbre de compte primium, nbre de compte épargne
select distinct nationalite from set_fr
select * from accounts
SELECT 
    sf.Nationalite AS nationalite,
    COUNT(CASE WHEN acc.account_type = 'compte_courant' AND fc.customer_id IS NOT NULL THEN 1 END) AS comptes_normaux,
    COUNT(CASE WHEN acc.account_type = 'compte_courant' AND pc.customer_id IS NOT NULL THEN 1 END) AS comptes_premium,
    COUNT(CASE WHEN acc.account_type = 'compte_epargne' THEN 1 END) AS comptes_epargne
FROM 
    set_fr sf
LEFT JOIN 
    accounts acc ON sf.customer_id = acc.customer_id
LEFT JOIN 
    free_customerd fc ON sf.customer_id = fc.customer_id
LEFT JOIN 
    premium_customers pc ON sf.customer_id = pc.customer_id
GROUP BY 
    sf.Nationalite
ORDER BY 
    nationalite;

	
-- et nbre de clients vivant en Aquitaine
select count(*) from set_fr where departement = 'Aquitaine'
	
-- Pour chaque ville, sortir la nationalité la plus représentée; le genre le plus représenté
select ville,
	Nationalite as nationalite_plus_representee,
	genre as genre_plus_representee,
	age as moyenne_d_age,
	addresse
from (
	select ville,
			nationalite,
			genre,
			age,
			addresse,
			row_number () over(partition by Ville ORDER BY COUNT(Nationalite) DESC) AS nationalite_rank,
			row_number() over (partition by ville order by count(Genre) desc) as genre_rank
	from set_fr
	group by ville, nationalite, genre, age, addresse) AS ranked_data
WHERE nationalite_rank = 1 AND genre_rank = 1;
 
-- puis la moyenne d'age, la rue ayant le plus grand nombre de client


select distinct ville from set_fr





-- sortir tous les services mails distincts des clients
select distinct substring (email, position('@' in email) + 1,
position('.' in email) - position('@' in email) - 1 ) as service_mail_
from set_fr

select distinct substring (email from position('@' in email) + 1) as service_mail
from set_fr