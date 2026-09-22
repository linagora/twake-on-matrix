# Pré-audit de la migration contacts

État inspecté : `contacts/09-tab-migration`, `9327b11c3`, 21 septembre 2026.
Les dix références fournies correspondent aux branches locales et forment une pile linéaire. Le diff cumulé depuis le parent de `e988305aa` touche 95 fichiers.

Ce document consigne les premiers défauts et la validation initiale. Il ne constitue ni une revue exhaustive des consommateurs, ni une certification des dix étapes intermédiaires. Aucun correctif applicatif n'a été effectué.

## Résultats locaux

- `fvm flutter test --no-pub --reporter expanded test/domain/contact test/data/contact test/pages/contacts_tab` : 55 tests passent.
- `fvm flutter test --no-pub --reporter expanded` appliqué aux 15 fichiers de tests existants modifiés par la pile : 137 tests passent. Ces deux ensembles se recouvrent ; ne pas additionner leurs résultats.
- `fvm flutter analyze --no-pub lib/domain/contact lib/data/contact lib/pages/contacts_tab lib/providers/active_matrix_client_provider.dart` : aucun diagnostic.
- Aucun workflow GitHub Actions utilisé. Aucun push ni appel aux services de production.
- Modifications préexistantes préservées dans `ios/Runner.xcodeproj/project.pbxproj` et `lib/pages/chat_details/chat_details_page_view/chat_details_members_page.dart`.

## Constats prioritaires

### P1 — Une synchronisation partielle écrase les contributions conservées

`lib/domain/contact/usecases/sync_contacts.dart:26-53` transforme une erreur de source en liste vide, résout exclusivement les contributions de la nouvelle collecte, puis remplace le contact entier. Il ne relit pas les contributions persistées.

Exemple déduit du code : un contact possède un alias téléphone et un nom TOM. Si le téléphone échoue mais TOM renvoie ce contact, le nouvel enregistrement perd l'alias. Les contributions manuelles et l'enrichissement TOM sont également perdus lorsque le contact est réécrit par la collecte de base. Le commentaire promet pourtant la conservation des valeurs de la source défaillante.

Test nécessaire : précharger plusieurs contributions, faire échouer une seule source, vérifier les champs persistés et affichables après collecte. Distinguer explicitement échec et résultat vide réussi. Tester une seconde synchronisation pour empêcher accumulation de doublons et maintien accidentel des anciennes valeurs d'une source actualisée.

### P1 — Rafraîchissement et changement de session ne sont pas coordonnés

`lib/widgets/matrix.dart:199-203` publie le nouveau client et démarre le rafraîchissement avant de reconfigurer les services TOM. `contacts_providers.dart:42-55` conserve datasource et repository indépendamment du client actif. `ContactSyncService.refresh` ne protège pas les écritures d'une collecte devenue obsolète.

Le changement de compte peut donc lancer une collecte avec des dépendances de sessions différentes ; la contamination effective n'a pas été reproduite sur appareil. La déconnexion appelle aussi `reSyncContacts` sans l'attendre (`matrix.dart:1387`), tandis qu'un ancien rafraîchissement peut toujours terminer.

Autre rupture à vérifier : `reSyncContacts` ne fait désormais qu'un `clear` (`matrix.dart:1400-1402`), alors que les chemins de connexion l'appellent encore (`729`, `769`). Un test doit établir quel événement repeuple ensuite le stockage, et dans quel ordre.

Tests nécessaires : orchestrer avec des `Completer` une collecte A lente, basculer vers B, terminer A ; aucune donnée A ne doit être publiée dans B. Rejouer collecte lente puis déconnexion/clear. Vérifier première connexion et ajout d'un compte sans rafraîchissement manuel.

### P2 — Deux écoutes d'un même flux partagent leur annulation

`lib/data/contact/datasources_impl/contact_local_datasource_impl.dart:75-89` déclare `subscription` à l'extérieur du callback de `Stream.multi`. Deux écoutes du même objet stream écrasent cette référence. Annuler la première peut annuler la seconde et laisser la première subscription attachée.

Le fake de `test/data/contact/repositories/unified_contact_repository_impl_test.dart` recopie cette implémentation. Aucun test sous `test/` ne référence la vraie `ContactLocalDataSourceImpl` au moment de l'audit.

Tests nécessaires sur la datasource réelle : deux listeners, annulation de l'un, écriture puis réception par l'autre ; fermeture et annulation sans fuite. Vérifier aussi lecture initiale lente concurrencée par une écriture, et disposal pendant `_emit` : le contrôle `isClosed` précède un `await` (`94-95`).

### P2 — La limite de requêtes d'enrichissement ne limite que les succès

`lib/data/contact/sources/tom_user_info_source.dart:32-58` incrémente `processed` après requête et persistance réussies. Avec des erreurs réseau, `maxPerRun = 50` ne limite pas le nombre de tentatives. Le commentaire annonce pourtant un plafond d'appels réseau.

Test nécessaire : plus de 50 contacts, réponses toutes en échec, vérifier au plus 50 appels. Vérifier aussi un mélange succès/échecs et les contacts déjà enrichis.

## Architecture observée

- `lib/domain/contact` n'importe ni Flutter, ni Matrix, ni Hive, ni Riverpod, ni les couches data/presentation/DI : frontière de dépendances correcte dans ce périmètre.
- Politique de résolution centralisée et repository abstrait : base cohérente.
- Le controller expose un stream et sépare la recherche : Riverpod possède normalement la subscription et le mot-clé ne doit pas redémarrer la collecte.
- Les responsabilités de session restent réparties entre `MatrixState`, Riverpod et des repositories legacy récupérés via GetIt. C'est la frontière prioritaire à sécuriser, avant d'ajouter des abstractions.
- La variable globale `debugUnifiedContactRepository` est une couture de test partagée entre containers. Son remplacement éventuel doit être évalué avec le scénario d'intégration qui l'utilise ; ce n'est pas un correctif fonctionnel livré.

## Suite proposée

1. Planification Astra ciblée sur ces défauts, le contrat des sources et la frontière de session.
2. Correction cohérente de la fusion et de l'enrichissement, avec tests de résultats métier.
3. Correction des flux persistés et tests de la datasource réelle sur stockage jetable.
4. Correction du cycle de session et tests déterministes des courses, sans service de production.
5. Revue indépendante, puis validation locale par l'orchestrateur.

Chaque correction devra démontrer un test rouge sur l'ancien comportement puis vert sur le correctif. Les tests doivent vérifier état persisté, émissions et bornes d'appels ; ne pas se limiter à vérifier qu'une méthode délègue à un mock.

Budget soumis : au plus cinq passages GPT-6 Astra, sur quota Codex ; estimation monétaire indisponible. Accord utilisateur encore attendu au moment de rédaction. Aucune branche intermédiaire réécrite.
