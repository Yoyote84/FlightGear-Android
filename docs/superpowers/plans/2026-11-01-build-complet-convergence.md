# Build complet de convergence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le pipeline Android par une convergence unique qui prépare les sources et l'outillage une seule fois, configure CMake une seule fois et lance la construction complète de l'APK afin de réduire les temps morts et révéler les erreurs de plusieurs sous-systèmes dans le même cycle.

**Architecture:** Un seul job GitHub Actions exécute préparation des sources, configuration CMake et `assembleDebug`. Le cache reste indexé par SHA pour conserver les résultats entre cycles, mais la compilation native partage le même `app/.cxx` au sein d'un run au lieu de passer par trois jobs séquentiels avec des caches intermédiaires.

**Tech Stack:** GitHub Actions, Gradle 8.13, Android SDK 36, NDK 27.2.12479018, CMake 3.22.1, CMake/Ninja, FlightGear/SimGear/OpenSceneGraph.

**Spec:** Stratégie Build complet de convergence décidée dans la conversation du 1er novembre 2026.

## Global Constraints

- Build natif ARM64 Android uniquement; aucune dépendance à Box64 ou à une émulation x86.
- Conserver Android API 36, NDK 27.2.12479018, CMake 3.22.1 et JDK 17.
- Préparer les sources upstream une seule fois par run lorsque le cache est absent.
- Configurer le projet CMake une seule fois avant la convergence complète.
- Produire `app/build/outputs/apk/debug/app-debug.apk` et échouer explicitement si l'APK manque.
- Les gates restent des validations techniques, mais ne doivent plus être des barrières artificielles dans le chemin principal de convergence.

## Review Focus

- Cache `third_party` absent : les sources doivent être récupérées automatiquement.
- Cache `app/.cxx` absent : la configuration CMake doit fonctionner depuis zéro.
- Erreur native OSG/SimGear/FlightGear : le même run doit exposer l'échec sans dépendre d'un job précédent.
- Build déjà partiellement configuré : Gradle/CMake doivent pouvoir réutiliser l'état sans incohérence.
- APK non produit : le workflow doit échouer plutôt que déclarer la convergence réussie.

---

### Task 1: Pipeline de convergence Android

**Files:**
- Modify: `.github/workflows/android.yml`

**Interfaces:**
- Consumes: sources upstream via `scripts/fetch-flightgear.sh`, configuration Gradle/CMake du projet Android.
- Produces: build natif complet et APK debug dans `app/build/outputs/apk/debug/app-debug.apk`.

- [ ] **Step 1: Remplacer les trois jobs OSG/SimGear/FlightGear par un job de convergence unique.**
- [ ] **Step 2: Conserver l'installation de l'outillage et la récupération des sources avec les versions exactes actuelles.**
- [ ] **Step 3: Configurer CMake une seule fois puis lancer `:app:assembleDebug` sans cibler artificiellement un gate intermédiaire.**
- [ ] **Step 4: Restaurer/sauvegarder `app/.cxx` via un cache SHA afin de réutiliser l'état natif entre cycles.**
- [ ] **Step 5: Vérifier la présence de l'APK et publier l'artefact.**
- [ ] **Step 6: Déclencher le workflow et utiliser son résultat comme nouveau cycle de diagnostic/fix.**
