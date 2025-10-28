# TinyLogs Example

Application d'exemple démontrant l'utilisation du package TinyLogs.

## Fonctionnalités démontrées

- ✅ Initialisation de TinyLogs avec configuration personnalisée
- ✅ Ajout de logs
- ✅ Affichage de tous les logs
- ✅ Récupération de logs autour d'une date (±12h)
- ✅ Récupération de logs de la dernière heure
- ✅ Nettoyage des anciens logs
- ✅ Suppression de tous les logs
- ✅ Compteur de logs en temps réel

## Exécution

```bash
flutter pub get
flutter run
```

## Captures d'écran

L'application affiche :

- Un formulaire pour ajouter des logs
- Le nombre total de logs
- Une liste de tous les logs avec leur horodatage
- Un menu avec différentes options de filtrage et de nettoyage

## Utilisation

1. Entrez du texte dans le champ de saisie
2. Appuyez sur "Ajouter un log" ou la touche Entrée
3. Les logs apparaissent dans la liste ci-dessous
4. Utilisez le menu (⋮) en haut à droite pour :
   - Voir les logs autour de maintenant
   - Voir les logs de la dernière heure
   - Nettoyer les anciens logs
   - Supprimer tous les logs
