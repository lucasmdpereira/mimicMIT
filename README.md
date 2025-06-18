1. Crie a pasta /files e coloque os arquivos da MIMIC.
```
|--files
   |--hosp/
   |--icu/
   |--CHANGELOG.txt
   |--LICENSE.txt
   |--SHA256SUMS.txt
|--...
```
2. Altere os valores em Makefile
```
export PGPASSWORD=1234
PG_HOST=localhost
PG_PORT=5432
PG_USER=postgres
DB_NAME=mimiciv
MIMIC_CODE_DIR=./mimic-code
DATA_DIR=/home/pereira/UFSJ/mimicMIT/files
```
3. Com Make instalado:
```
make all
```
Caso deseje rodar as etapas separadamente:
```bash
make setup_local
make create_db
make clone_repo
make decompress_data
make create_tables
make load_data
make create_constraints
make create_indexes
make create_concepts
```
4. Para apagar o banco de dados:
```bash
make clean
```