# COEsprit_be — mise en place

## 1. Base de données

Exécuter sur `DB_RAD` (Postgres) :

```bash
psql "$DB_RAD" -f sql/001_ddl.sql
```

Schéma créé : `coesprit` (tables `COE_*` + seeds DA3C).

## 2. Connecteurs

- `RadConnector` → `${DB_RAD}?currentSchema=coesprit`
- `CommonConnector` → `${DB_Common}` (annuaire `RET_Agent_Planning`)

## 3. Auth

- `Auth_Login` / `Get_Auth_Hors_SI` / `_auth__session` (pattern Portefeuille)
- Rôles hors SI : `MEMBRE` | `PILOTE` | `ADMIN`
- Membres seed : codes agent `AC750` + 5 chiffres (ex. `AC75000001`, `AC75000002`)

## 4. Séquences V1

| Séquence | Rôle |
|----------|------|
| `Referentiel_Lire` | Domaines, termes, listes |
| `Fiche_Lire` / `Fiche_Enregistrer` | CRUD fiche |
| `Recherche_Profils` | Recherche communauté |
| `Terme_Proposer` | Proposition appétence |
