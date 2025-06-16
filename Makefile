setup:
	@echo "Setting password for non-interactive commands..."
	export PGPASSWORD=1234
	@echo "Starting PostgreSQL container..."
	-docker run --name postgres-mimic -e POSTGRES_PASSWORD=1234 -p 5432:5432 -d postgres
	@echo "PostgreSQL server started. Waiting a few seconds for it to initialize..."
	@sleep 5
	@echo "Creating the 'mimic' database..."
	-createdb -h localhost -p 5432 -U postgres mimic
	@echo "Database 'mimic' created."
	@echo "Cloning MIMIC-III code repository..."
	-git clone https://github.com/MIT-LCP/mimic-code.git
	@echo "MIMIC-III code repository cloned."
	@echo "Installing PostgreSQL client..."
	-sudo apt update
	-sudo apt install -y postgresql-client
	@echo "PostgreSQL client installed."
	@echo "Setup complete. You can now run 'make create' to build the tables and load the data."
	@echo "Decompressing data files..."
	-gunzip /home/pereira/ufsj/mimic/files/hosp/*.csv.gz # Path to the MIMIC-III data files
	-gunzip /home/pereira/ufsj/mimic/files/icu/*.csv.gz  # Path to the MIMIC-III data files
	@echo "Data files decompressed."

create:
	@echo "Creating MIMIC-III database..."
	psql -h localhost -p 5432 -U postgres -W -f mimic-code/mimic-iv/buildmimic/postgres/create.sql
	@echo "Loading MIMIC-III data..."
	psql -h localhost -p 5432 -U postgres -d mimic -W \
	-v mimic_data_dir='/home/pereira/ufsj/mimic/files' \ # Path to the MIMIC-III data files
	-f mimic-code/mimic-iv/buildmimic/postgres/load.sql
	@echo "Data loaded into MIMIC-III database."
	@echo "Creating indexes on MIMIC-III database..."
	psql -h localhost -p 5432 -U postgres -d mimic -W -f mimic-code/mimic-iv/buildmimic/postgres/index.sql
	@echo "Indexes created."
	@echo "Creating constraints on MIMIC-III database..."
	psql -h localhost -p 5432 -U postgres -d mimic -W -f mimic-code/mimic-iv/buildmimic/postgres/constraint.sql
	@echo "Constraints created."
	@echo "Creating concepts in MIMIC-III database..."
	cd mimic-code/mimic-iv/concepts_postgres
	psql -h localhost -p 5432 -U postgres -d mimic -W -f postgres-make-concepts.sql
	@echo "Concepts created."
	@echo "Testing MIMIC-III database..."
	psql -h localhost -p 5432 -U postgres -d mimic \
	-c "SELECT subject_id, stay_id, sepsis3 FROM mimic_derived.sepsis3 LIMIT 5;"
	@echo "Testing complete. MIMIC-III database is ready for use."