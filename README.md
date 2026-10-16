# Mini-projet TI503N : Base de données d'une organisation de MMA professionnel

**Partie 1 : Étape 1, analyse des besoins**

- Module : TI503N, Bases de données 1 : Concepts de base (EFREI)
- Binôme : *[Prénom NOM]* et *[Prénom NOM]*
- Domaine : organisation de MMA professionnel (inspirée de l'UFC, du Bellator et du PFL)
- IA générative utilisée pour l'analyse des besoins : **Claude** (Anthropic)
- Outil de modélisation prévu pour le MCD (étape 2) : **Looping**

## Sommaire

1. [Étape 1 : analyse des besoins](#étape-1--analyse-des-besoins)
2. [Contenu du dépôt](#contenu-du-dépôt)

---

## Étape 1 : analyse des besoins

### 1.1 Domaine choisi

Une **organisation** de MMA professionnel, comme l'UFC, le Bellator ou le PFL. Elle organise des galas, gère des combattants sous contrat, programme des combats et tient des classements officiels par catégorie de poids.

Références données à l'IA : <https://www.ufc.com>, <http://ufcstats.com> et <https://fr.wikipedia.org/wiki/Ultimate_Fighting_Championship>.

### 1.2 Prompt utilisé

Le prompt suit le framework RICARDO et la base de prompt fournie. Seules les zones à compléter ont été remplies : domaine, type de structure, activité, exemples, thèmes de données et références. Le fichier complet est dans `prompt_analyse.txt`.

```text
Tu travailles dans le domaine des sports de combat professionnels (arts martiaux mixtes, MMA). Ton organisation a comme activité de organiser des événements de combat professionnels (galas), de gérer les combattants sous contrat, de planifier les combats et de tenir les classements officiels par catégorie de poids. C'est une organisation comme l'UFC (Ultimate Fighting Championship), le Bellator ou le PFL (Professional Fighters League). Les données ont été collectées sur : les combattants, les événements, les combats et leurs résultats, les catégories de poids, les classements, les lieux d'accueil, le personnel d'arbitrage et d'encadrement, et les contrats. Inspire-toi des sites web suivants : https://www.ufc.com, http://ufcstats.com et https://fr.wikipedia.org/wiki/Ultimate_Fighting_Championship.

Ton organisation veut appliquer MERISE pour concevoir un système d'information. Tu es chargé de la partie analyse, c'est-à-dire de collecter les besoins auprès de l'organisation. Elle a fait appel à un étudiant en ingénierie informatique pour réaliser ce projet, tu dois lui fournir les informations nécessaires pour qu'il applique ensuite lui-même les étapes suivantes de conception et développement de la base de données.

D'abord, établis les règles de gestions des données de ton organisation, sous la forme d'une liste à puce. Elle doit correspondre aux informations que fournit quelqu'un qui connaît le fonctionnement de l'organisation, mais pas comment se construit un système d'information.

Ensuite, à partir de ces règles, fournis un dictionnaire de données brutes avec les colonnes suivantes, regroupées dans un tableau : signification de la donnée, type, taille en nombre de caractères ou de chiffres. Il doit y avoir entre 25 et 35 données. Il sert à fournir des informations supplémentaires sur chaque donnée (taille et type) mais sans a priori sur comment les données vont être modélisées ensuite.

Fournis donc les règles de gestion et le dictionnaire de données.
```

### 1.3 Analyse du premier résultat et problèmes relevés

Le premier résultat de l'IA ne respectait pas toutes les exigences :

| Problème relevé | Détail |
|---|---|
| **40 données au lieu de 25 à 35** | Dépassement de la fourchette demandée. |
| **Thèmes non demandés** | L'IA a ajouté les spectateurs, la recette, les suspensions médicales, les primes et l'allonge. |
| **Règles sans donnée associée** | Poids en livres, motif de suspension, date de fin de règne, prénom et nationalité du personnel, prime de la performance de la soirée. |
| **Taille des dates erronée** | « 8 caractères » indiqué pour le format JJ/MM/AAAA, qui en fait 10. |
| **Redondance** | Le nombre de rounds dépend du fait que le combat est pour un titre (titre = 5 rounds, sinon 3). Cela pose un problème de 3FN, traité dans le MCD. |

### 1.4 Prompt de correction et modifications apportées

Le prompt de correction (fichier `prompt_correction.txt`) a été envoyé dans la même conversation :

```text
Ton dictionnaire contient 40 données alors que j'en attends entre 25 et 35. Corrige ta réponse en suivant ces étapes :

1. Supprime du dictionnaire exactement ces 6 données : 8 (allonge du combattant), 14 (prime de victoire), 20 (nombre de spectateurs), 21 (recette de billetterie), 30 (technique de soumission) et 40 (durée de la suspension médicale). Conserve toutes les autres, notamment le prénom du combattant. Le dictionnaire doit alors contenir 34 données.

2. Mets à jour les règles de gestion en conséquence : supprime l'allonge, la prime de victoire (y compris la prime de la performance de la soirée), le relevé des spectateurs et de la recette, la technique de soumission et la section « Suspensions médicales » en entier. Ne modifie pas les autres règles.

3. Vérifie la cohérence entre les règles et le dictionnaire : toute information citée dans une règle doit avoir une donnée correspondante dans le dictionnaire, et inversement. Supprime des règles les informations qui n'ont pas de donnée associée (par exemple la limite de poids en livres, le motif, la date de fin de règne, ou le prénom et la nationalité des arbitres et juges), sauf si tu les ajoutes au dictionnaire sans dépasser 35 données au total.

4. Corrige la taille des dates : une date au format JJ/MM/AAAA fait 10 caractères, pas 8.

5. Renumérote le dictionnaire de 1 à 34, compte les lignes et indique le total à la fin.

Garde exactement le même format qu'avant : règles de gestion en liste à puces, puis tableau avec les colonnes « signification de la donnée », « type » et « taille ».
```

**Données supprimées du dictionnaire (40 vers 34) :**

| N° initial | Donnée supprimée | Règle de gestion supprimée en parallèle |
|---|---|---|
| 8 | Allonge du combattant | Allonge dans les informations du combattant |
| 14 | Prime de victoire | Prime de victoire du contrat et prime de la performance de la soirée |
| 20 | Nombre de spectateurs | Relevé des spectateurs |
| 21 | Recette de billetterie | Relevé de la recette |
| 30 | Technique de soumission | Règle sur la technique de soumission |
| 40 | Durée de la suspension | Section « Suspensions médicales » |

**Modifications faites d'elle-même par l'IA lors de la correction :** retrait de la limite de poids en livres, de la date de fin de règne, du prénom et de la nationalité des arbitres et juges, du prénom des membres de l'encadrement, et des coins rouge et bleu. Les données « personnel » ont été reformulées pour couvrir arbitres, juges et encadrement.

### 1.5 Règles de gestion (résultat final)

**Combattants**
- Chaque combattant est identifié par un numéro unique attribué lors de son premier enregistrement chez nous.
- Nous enregistrons pour chaque combattant son nom, son prénom, son surnom (facultatif), sa date de naissance, sa nationalité et sa taille en centimètres.
- Un combattant combat dans une seule catégorie de poids à la fois, mais il peut changer de catégorie au cours de sa carrière.
- Un combattant peut ne pas avoir de surnom.
- Le bilan d'un combattant (victoires, défaites, nuls) se déduit de ses combats passés ; nous ne le saisissons pas à la main.

**Contrats**
- Un combattant travaille pour nous dans le cadre d'un contrat. Chaque contrat a un numéro, une date de début, une date de fin et un nombre de combats garantis.
- Un contrat concerne un seul combattant. Un combattant peut avoir successivement plusieurs contrats, mais jamais deux contrats actifs en même temps.
- Pour chaque contrat, on convient d'une bourse de base (somme garantie par combat).
- Un combattant sans contrat actif ne peut pas être programmé sur un combat.

**Catégories de poids**
- Nous avons un nombre fixe de catégories (poids paille, mouches, coqs, plumes, légers, mi-moyens, moyens, mi-lourds, lourds…). Chacune a un nom et une limite de poids en kilogrammes.
- Chaque catégorie existe en version masculine et féminine ; on précise le sexe de la catégorie.

**Événements (galas)**
- Un événement a un nom officiel (par exemple « Fight Night Paris »), une date et un lieu d'accueil.
- Un événement se tient dans un seul lieu et à une seule date. Un lieu peut accueillir plusieurs événements au fil du temps.
- Chaque événement comporte plusieurs combats, organisés dans un ordre précis, du premier combat de la soirée jusqu'au combat principal.

**Lieux d'accueil**
- Un lieu a un nom (salle, arène, stade), une ville, un pays et une capacité maximale en spectateurs.

**Combats**
- Un combat est programmé lors d'un événement donné et occupe une position dans la soirée (numéro d'ordre).
- Un combat oppose exactement deux combattants.
- Les deux combattants d'un combat appartiennent à la même catégorie de poids, qui est celle du combat.
- Un combat est soit un combat ordinaire, soit un combat pour un titre. S'il s'agit d'un combat pour un titre, il est de 5 rounds ; sinon il est de 3 rounds. Le nombre de rounds prévu est enregistré.
- Un combat est dirigé par un arbitre et noté par trois juges. Un même arbitre ou juge intervient sur plusieurs combats.
- Un combattant ne peut pas combattre deux fois lors du même événement.

**Résultats**
- À l'issue de chaque combat, nous enregistrons le vainqueur (ou l'absence de vainqueur en cas de nul ou de combat annulé), la méthode de victoire (KO/TKO, soumission, décision unanime, décision partagée, décision majoritaire, disqualification, no contest), le round de fin et le temps écoulé dans ce round (minutes et secondes).
- Dans le cas d'une décision, chaque juge attribue un score à chaque combattant ; on conserve ces scores.
- Chaque soir, nous désignons la « performance de la soirée » et le « combat de la soirée » parmi les combats de l'événement.

**Personnel d'arbitrage et d'encadrement**
- Les arbitres, les juges et les membres de l'encadrement (médecins, commissaire sportif, etc.) sont des personnes identifiées par un numéro de licence, avec un nom et une fonction.
- Chaque événement a une équipe d'encadrement. Chaque membre est affecté à un ou plusieurs événements.

**Classements**
- Nous tenons un classement officiel par catégorie de poids : un champion et les 15 meilleurs combattants en dessous de lui.
- Le classement est mis à jour après chaque événement. Nous gardons l'historique : pour chaque date de mise à jour, on conserve la position de chaque combattant classé (la position 0 correspond au champion).
- Un combattant peut être classé dans plusieurs catégories à la fois (cas exceptionnel), mais il n'a qu'une position par catégorie à une date donnée.
- Le champion est le détenteur actuel du titre de sa catégorie ; nous conservons l'historique des règnes avec leur date de début.
- Un titre est mis en jeu uniquement lors d'un combat pour un titre, et le vainqueur devient champion (ou le reste).

### 1.6 Dictionnaire de données (34 données)

| N° | Signification de la donnée | Type | Taille |
|---|---|---|---|
| 1 | Numéro du combattant | Numérique entier | 6 |
| 2 | Nom du combattant | Alphabétique | 40 |
| 3 | Prénom du combattant | Alphabétique | 40 |
| 4 | Surnom du combattant (facultatif) | Alphabétique | 40 |
| 5 | Date de naissance du combattant | Date | 10 (JJ/MM/AAAA) |
| 6 | Nationalité du combattant | Alphabétique | 40 |
| 7 | Taille du combattant (cm) | Numérique entier | 3 |
| 8 | Numéro du contrat | Numérique entier | 6 |
| 9 | Date de début du contrat | Date | 10 (JJ/MM/AAAA) |
| 10 | Date de fin du contrat | Date | 10 (JJ/MM/AAAA) |
| 11 | Nombre de combats garantis au contrat | Numérique entier | 2 |
| 12 | Bourse de base par combat (€) | Numérique décimal | 9 (dont 2 décimales) |
| 13 | Nom de la catégorie de poids | Alphabétique | 30 |
| 14 | Limite de poids de la catégorie (kg) | Numérique décimal | 5 (dont 1 décimale) |
| 15 | Sexe de la catégorie (M/F) | Alphabétique | 1 |
| 16 | Nom de l'événement | Alphanumérique | 60 |
| 17 | Date de l'événement | Date | 10 (JJ/MM/AAAA) |
| 18 | Nom du lieu d'accueil | Alphanumérique | 60 |
| 19 | Ville du lieu | Alphabétique | 40 |
| 20 | Pays du lieu | Alphabétique | 40 |
| 21 | Capacité maximale du lieu (spectateurs) | Numérique entier | 6 |
| 22 | Numéro d'ordre du combat dans la soirée | Numérique entier | 2 |
| 23 | Nombre de rounds prévus du combat | Numérique entier | 1 |
| 24 | Combat pour un titre (O/N) | Alphabétique | 1 |
| 25 | Méthode de victoire | Alphabétique | 30 |
| 26 | Round de fin du combat | Numérique entier | 1 |
| 27 | Temps écoulé dans le round (mm:ss) | Alphanumérique | 5 |
| 28 | Score attribué par un juge à un combattant | Numérique entier | 2 |
| 29 | Numéro de licence du membre du personnel d'arbitrage ou d'encadrement | Numérique entier | 5 |
| 30 | Nom du membre du personnel d'arbitrage ou d'encadrement | Alphabétique | 40 |
| 31 | Fonction du membre du personnel (arbitre, juge, médecin, commissaire…) | Alphabétique | 30 |
| 32 | Date de mise à jour du classement | Date | 10 (JJ/MM/AAAA) |
| 33 | Position dans le classement (0 = champion) | Numérique entier | 2 |
| 34 | Date de début du règne de champion | Date | 10 (JJ/MM/AAAA) |

---

## Contenu du dépôt

| Fichier | Rôle |
|---|---|
| `README.md` | Documentation (ce fichier) |
| `prompt_analyse.txt` | Prompt initial (framework RICARDO) |
| `prompt_correction.txt` | Prompt de correction envoyé à Claude |
| *Fichier source Looping (.loo)* | Source du MCD (étape 2) |
