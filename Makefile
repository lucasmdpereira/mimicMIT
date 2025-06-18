export PGPASSWORD=1234
PG_HOST=localhost
PG_PORT=5432
PG_USER=postgres
DB_NAME=mimiciv
MIMIC_CODE_DIR=./mimic-code
DATA_DIR=/home/pereira/UFSJ/mimicMIT/files

.PHONY: all setup_local create_tables load_data clean create_constraints create_indexes create_concepts
all: setup_local create_tables load_data create_constraints create_indexes create_concepts
	@echo "------------------------------------------------------"
	@echo "Processo completo para MIMIC-IV concluído!"
	@echo "------------------------------------------------------"

setup_local: create_db clone_repo decompress_data
	@echo "------------------------------------------------------"
	@echo "Setup Local para MIMIC-IV completo!"
	@echo "Execute 'make all' para rodar o processo completo."
	@echo "------------------------------------------------------"

create_db:
	@echo "--> Verificando/Criando o banco de dados '$(DB_NAME)'..."
	-createdb -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) $(DB_NAME)

clone_repo:
	@if [ ! -d "$(MIMIC_CODE_DIR)" ]; then \
		echo "--> Clonando o repositório de código do MIMIC..."; \
		git clone https://github.com/MIT-LCP/mimic-code.git $(MIMIC_CODE_DIR); \
	else \
		echo "--> Repositório '$(MIMIC_CODE_DIR)' já existe. Pulando clonagem."; \
	fi

decompress_data:
	@echo "--> Descompactando arquivos de dados (se necessário)..."
	-gunzip $(DATA_DIR)/hosp/*.csv.gz
	-gunzip $(DATA_DIR)/icu/*.csv.gz

create_tables:
	@echo "--> Criando tabelas do MIMIC-IV no banco de dados '$(DB_NAME)'..."
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(DB_NAME) -f $(MIMIC_CODE_DIR)/mimic-iv/buildmimic/postgres/create.sql
	@echo "--> Tabelas criadas com sucesso."

load_data:
	@echo "--> Carregando dados do MIMIC-IV para o banco '$(DB_NAME)'..."
	@echo "AVISO: Este processo pode demorar MUITO tempo."
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(DB_NAME) -v mimic_data_dir="$(DATA_DIR)" -f $(MIMIC_CODE_DIR)/mimic-iv/buildmimic/postgres/load.sql
	@echo "--> Carga de dados finalizada."

create_constraints:
	@echo "--> Criando chaves primárias e estrangeiras (relacionamentos)..."
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(DB_NAME) -f $(MIMIC_CODE_DIR)/mimic-iv/buildmimic/postgres/constraints.sql
	@echo "--> Constraints criados com sucesso."

create_indexes:
	@echo "--> Criando índices para performance..."
	@echo "AVISO: Este processo também pode demorar."
	psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(DB_NAME) -f $(MIMIC_CODE_DIR)/mimic-iv/buildmimic/postgres/index.sql
	@echo "--> Índices criados com sucesso."

create_concepts:
	@echo "--> Gerando conceitos derivados (tabelas de análise)..."
	@echo "AVISO: Este processo é complexo e pode demorar bastante."
	cd $(MIMIC_CODE_DIR)/mimic-iv/concepts_postgres && psql -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) -d $(DB_NAME) -f postgres-make-concepts.sql
	@echo "--> Conceitos derivados criados com sucesso."

clean:
	@echo "--> Apagando o banco de dados '$(DB_NAME)'..."
	-dropdb -h $(PG_HOST) -p $(PG_PORT) -U $(PG_USER) $(DB_NAME)
	@echo "--> Apagando o diretório de código clonado..."
	-rm -rf $(MIMIC_CODE_DIR)