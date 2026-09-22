# Contacts : correctifs et validation locale

État de départ : `contacts/09-tab-migration`, commit `a6ec8bb4a5b574130f0b9c642e9a272aec27dfdf`. Ce commit de nettoyage, ajouté après le pré-audit du 21 septembre, est conservé. Correctifs appliqués au cumul de la pile sur la branche courante ; aucune branche intermédiaire réécrite, aucun commit ni push effectué.

## Correctifs livrés localement

- **Fusion des sources** : un échec conserve les contributions persistées ; un snapshot réussi remplace les contributions de cette source, même vide. Les autres contributions restent présentes. Les contacts sans contribution sont retirés.
- **Enrichissement TOM** : le plafond compte les tentatives, y compris les échecs. La passe suivante poursuit la rotation pour éviter qu'un début de liste constamment en erreur bloque les contacts suivants. Avant écriture, le contact est relu dans la file de mutations : une réponse tardive ne recrée plus un contact supprimé.
- **Flux Hive** : chaque listener possède sa propre annulation. Une lecture initiale retardée ne remplace plus un état récent. Le disposal ferme les listeners et empêche les émissions tardives.
- **Sessions** : les anciennes collectes sont invalidées ; les écritures et les transitions partagent une file. Les refresh concurrents du même service sont regroupés. Première connexion, restauration, changement de compte, déconnexion, picker et notification passent par le même lifecycle. La comparaison utilise l'identité du client, pas seulement un index réutilisable.
- **Cache hors ligne** : propriétaire persistant défini par homeserver et utilisateur. Un cache du même compte est conservé. Un propriétaire inconnu ou différent, ou une déconnexion, entraîne une purge. Les anciens caches sans marqueur sont donc purgés une fois. Le clear logique des contacts conserve ce marqueur pour permettre un refresh suivi d'un redémarrage du même compte.

Points d'entrée : `lib/domain/contact/services/contact_sync_service.dart`, `lib/domain/contact/services/contact_sync_session.dart`, `lib/providers/contact_session_controller.dart`, `lib/domain/contact/usecases/sync_contacts.dart`, `lib/data/contact/datasources_impl/contact_local_datasource_impl.dart`, `lib/data/contact/sources/tom_user_info_source.dart`.

## Preuves de validation

SDK : Flutter 3.38.9 local. Tests sans résolution de dépendances (`--no-pub`), sans production et sans GitHub Actions.

| Vérification | Résultat |
| --- | --- |
| Fusion et enrichissement, nouveaux tests sur code précédent | 7 échecs comportementaux |
| Datasource Hive réelle, nouveaux tests sur code précédent | 3 échecs comportementaux |
| Refresh terminé après clear, test compatible anciennes API | 1 échec comportemental sur code précédent |
| Suites contacts finales | 83 tests passent |
| Suite locale complète avant stabilisation WorkerQueue, reporter JSON | 1 487 tests passent, zéro erreur, code retour 0 |
| Deux tests WorkerQueue après stabilisation, huit répétitions chacun | 16 exécutions réussies |
| Suite locale complète après stabilisation WorkerQueue | 1 487 tests passent, zéro erreur, code retour 0 |
| Analyse statique du test WorkerQueue modifié | Aucun diagnostic |
| Analyse statique des sources et tests concernés | Aucun diagnostic |
| `git diff --check` | Réussi |

Les ensembles se recouvrent : ne pas additionner ces nombres. Les 11 échecs ont été reproduits dans un checkout isolé au commit de départ avec les nouveaux tests, puis les tests ont passé sur les corrections. Les tests de session supplémentaires utilisent de vrais providers, Hive jetable et des `Completer` pour contrôler l'ordre des événements.

Un passage complet précédent sur le code contacts corrigé a échoué avec `Expected: 2 / Actual: 3`. La sortie filtrée de ce passage n'a pas conservé le nom du test. Trois relances complètes sans changement de code ont ensuite réussi, ainsi que huit répétitions des deux tests WorkerQueue candidats. La trace `/tmp/contacts-suite-repro-20260922.json` conserve une des suites complètes vertes. **Cause non établie : ces résultats ne prouvent pas l'absence d'instabilité et n'identifient pas le test initialement en échec.**

Deux tests de `test/worker_queue_test.dart` (quatre tâches ordinaires et quatre identifiants identiques) lisaient la longueur de la file après deux attentes successives de 1 seconde, alors que le runnable durait 2 secondes. Le passage de trois à deux tâches en attente dépend de la résolution de `Task.execute`, puis de `_handleTaskExecuteCompleted`, qui lance et retire la tâche suivante. Les attentes du test n'observaient pas cette transition. Elles sont remplacées par des `Completer` : chaque runnable signale son démarrage, attend sa libération explicite et signale sa fin via le callback existant. Les assertions sur les longueurs, l'identifiant et l'ordre sont conservées ; le test d'erreur et le code de production sont inchangés. Cette modification supprime la dépendance à l'horloge de ces deux tests, sans constituer une reproduction ni une attribution de l'échec initial.

Après cette édition, les deux tests ont passé huit fois chacun, puis la suite complète a passé ses 1 487 tests. L'analyse ciblée et `git diff --check` passent également. La trace complète est conservée localement dans `/tmp/contacts-suite-stabilized-20260922.json` ; elle contient les noms des tests et les événements du reporter JSON.

Commandes principales :

```sh
fvm flutter test --no-pub --reporter expanded test/domain/contact test/data/contact test/pages/contacts_tab
fvm flutter test --no-pub --reporter json
fvm flutter analyze --no-pub lib/domain/contact lib/data/contact lib/pages/contacts_tab lib/providers lib/widgets/matrix.dart lib/pages/multiple_accounts/multiple_accounts_picker.dart lib/utils/background_push.dart test/domain/contact test/data/contact test/pages/contacts_tab
git diff --check
```

## Architecture et limites

Le domaine contacts n'importe ni Flutter, ni Riverpod, ni Matrix, ni Hive, ni les couches data/presentation/DI. Le lifecycle applicatif reste dans les providers ; le domaine contient les règles, les cas d'usage et la coordination des mutations. Les adaptateurs GetIt existants sont conservés pendant la migration.

Le nettoyage des providers suit le cycle de vie Riverpod ; les abonnements sont possédés individuellement selon le contrat de `Stream.multi`. Références : [Riverpod, disposal](https://riverpod.dev/docs/concepts2/auto_dispose), [Dart, Stream.multi](https://api.dart.dev/dart-async/Stream/Stream.multi.html).

- **Transport** : une requête déjà soumise à Dio n'est pas annulée. Les interceptors URL/token restent partagés et mutables. L'invalidation empêche les requêtes suivantes et les écritures obsolètes ; elle ne constitue pas une garantie d'isolation URL/token d'une requête déjà en attente dans Dio. Ce transport n'a pas été refondu.
- **Profils déjà enrichis** : `_alreadyEnriched` continue à les exclure des requêtes. Une politique d'expiration ou de rechargement des contributions TOM déjà présentes n'a pas été ajoutée ; leur actualisation ultérieure n'est pas garantie par ces tests.
- **Appareil** : aucun smoke test iPhone/Android ni parcours authentifié réel exécuté. Les tests de transition vérifient le controller utilisé par Matrix, pas une connexion complète aux fournisseurs.
- **Préservation** : empreintes SHA-256 des deux fichiers préexistants (`ios/Runner.xcodeproj/project.pbxproj`, `chat_details_members_page.dart`) identiques avant et après le travail.
