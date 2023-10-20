# 6. DOMException error when use delete disk of Hive for Web

Date: 2023-09-13

## Status

- Issue:
[#1533](https://github.com/famedly/matrix-dart-sdk/issues/1533)
[#850](https://github.com/isar/hive/issues/850)

## Context

```
Currently, we have two BoxCollection: HiveCollectionToMDatabase and FlutterHiveCollectionsDatabase (Matrix)

In Web platform when we use Hive database, we use the deleteFromDisk() method to delete the database
and recreate it. But when we use this method, we have a DOMException error.
```

## Decision
- Workaround
1. Check platform is Web we don't use deleteFromDisk() method. Only support for Mobile platform.
2. After we have used deleteFromDisk() method. When logging back in, you need to reopen the BoxCollection

## Consequences

1. The funcs are then blocked if deleteDisk both BoxCollection 
2. When logging back in, can't open and put data to HiveCollectionToMDatabase
then can't call API use configuration of HiveCollectionToMDatabase