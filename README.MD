# 🛠️ **Plan de Test**

Bienvenue dans le plan de test le plus chic et robuste pour garantir la qualité irréprochable de l'outil.

---

## 🎨 **Fonctionnalité 1: Configuration Initiale (Initial Config)**

### ✅ **Cas d'utilisation:**
- **🌟 Conditions normales d'utilisation:**
   - Création réussie des paramètres de configuration initiaux.
   - Lecture correcte d’un fichier `config.json` valide.

- **⚠️ Conditions aux limites:**
   - Le fichier `config.json` est **vide**.
   - Le fichier `config.json` contient des entrées **mal formées**.

- **🚨 Erreurs possibles:**
   - Le fichier `config.json` est **introuvable**.
   - Permissions **insuffisantes** pour accéder au fichier de configuration.

---

## 📊 **Fonctionnalité 2: Surveillance des Performances (Performance Monitoring)**

### ✅ **Cas d'utilisation:**
- **🌟 Conditions normales d'utilisation:**
   - Affichage en temps réel des données sur l’utilisation du **CPU**, de la **RAM**, et du **réseau**.
   - Mise à jour des mesures toutes les **2 secondes**.

- **⚠️ Conditions aux limites:**
   - Charge **CPU à 100%**.
   - Mémoire disponible très faible (**< 100 Mo**).

- **🚨 Erreurs possibles:**
   - Une **interface réseau** n'a pas de données.
   - Données **manquantes** pour le CPU ou la RAM.

---

## 💾 **Fonctionnalité 3: Sauvegarde des Données (Saving Backups)**

### ✅ **Cas d'utilisation:**
- **🌟 Conditions normales d'utilisation:**
   - Création réussie d’une **sauvegarde complète** dans un dossier daté.
   - Compression des fichiers dans une **archive ZIP**.

- **⚠️ Conditions aux limites:**
   - Sauvegarde de **fichiers volumineux** ou nombreux (simulateur de charge).
   - Espace disque presque saturé.

- **🚨 Erreurs possibles:**
   - Échec lors de la **copie des fichiers** (permissions insuffisantes).
   - **Compression** échouée.
   - Espace disque **insuffisant**.

---

## 🔄 **Fonctionnalité 4: Mises à Jour Windows (Windows Updates)**

### ✅ **Cas d'utilisation:**
- **🌟 Conditions normales d'utilisation:**
   - Recherche des mises à jour disponibles avec succès.
   - Installation des mises à jour détectées.

- **⚠️ Conditions aux limites:**
   - Aucune mise à jour disponible.
   - Mise à jour nécessitant un **redémarrage**.

- **🚨 Erreurs possibles:**
   - **Échec de connexion** à Windows Update.
   - Installation échouée pour une ou plusieurs mises à jour.
   - Exceptions levées pendant le processus.

---

## 🧑‍💻 **Fonctionnalité 5: Script Principal (Main Script)**

### ✅ **Cas d'utilisation:**
- **🌟 Conditions normales d'utilisation:**
   - Affichage correct des **options du menu principal**.
   - Exécution réussie des scripts sélectionnés via le menu.

- **⚠️ Conditions aux limites:**
   - L’utilisateur sélectionne une option **non valide** (par exemple, "9").
   - Exécution successive de plusieurs scripts.

- **🚨 Erreurs possibles:**
   - Scripts **introuvables** ou corrompus.
   - **Échec d’exécution** dû à des dépendances manquantes.
   - Permissions insuffisantes.

---