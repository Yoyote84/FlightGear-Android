# REA dans le workflow FlightGear Android

REA est un outil de développement optionnel. Il n'est pas embarqué dans l'APK et ne devient pas une dépendance de FlightGear.

## Ce qu'on utilise

- Analyse statique de l'APK : `inspect-android-package`
- Inspection ADB du Z Flip6 : appareil, processus et logcat
- Analyse dynamique plus tard, uniquement quand FlightGear démarre réellement

REA documente ces capacités pour les APK Android et les appareils Android via ADB.

## Préparation

REA demande Node.js 22.x/24.x/26.x selon la version installée. Pour l'analyse APK, REA utilise un JDK complet et son moteur JADX configuré suivant sa documentation officielle.

Installation recommandée :

```bash
npx rea-agents@latest setup
```

Pour une utilisation ponctuelle, le script du projet peut directement utiliser `npx`.

## Analyse de notre APK

Après une compilation :

```bash
bash scripts/rea-flightgear.sh
```

Ou avec un APK précis :

```bash
bash scripts/rea-flightgear.sh app/build/outputs/apk/debug/app-debug.apk
```

## Analyse du Z Flip6

Avec ADB déjà configuré et le téléphone connecté :

```bash
REA_ANDROID_SERIAL=<serial> bash scripts/rea-flightgear.sh
```

Le script reste volontairement en lecture seule : il ne pousse pas de fichiers, n'installe pas l'APK et ne démarre/arrête pas FlightGear.

Quand nous atteindrons le premier démarrage natif, nous utiliserons REA pour corréler :

`APK -> processus -> bibliothèques natives -> logcat -> crash/rendu EGL/GLES`

Cela complète le build CI sans modifier le chemin de compilation FlightGear.
