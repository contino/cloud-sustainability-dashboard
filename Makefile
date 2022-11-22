SHELL := /bin/bash
$(VERBOSE).SILENT:
SRC_DIR = collect-resource-data
export PIPENV_PIPFILE := $(SRC_DIR)/Pipfile
TF_DR = terraform
TF_PLAN_FILE = tfplan

install: # local dev
	pip3 install pipenv
	pre-commit install
	pipenv install --dev --skip-lock

shell: # local dev
	pipenv shell
	cd ..

clean_dependencies: # local dev
	pipenv lock --pre --clear

install_ci:
	pip3 install pipenv
	pipenv install --system --deploy --dev --skip-lock
	pipenv check

clean_tests:
	rm -rf $(SRC_DIR)/.test_reports

check:
	pipenv check

lint: clean_tests
	mkdir -p $(SRC_DIR)/.test_reports
	rm -f $(SRC_DIR)/.test_reports/lint_report.txt
	flake8 $(SRC_DIR)/ --color never --ignore E501

test: clean_tests
	pytest $(SRC_DIR)/tests --junitxml=$(SRC_DIR)/.test_reports/tests.xml

test_unit: clean_tests
	pytest $(SRC_DIR)/tests --junitxml=$(SRC_DIR)/.test_reports/unit_tests.xml -m "not integration and not smoke"

test_integration: clean_tests
	pytest $(SRC_DIR)/tests --junitxml=$(SRC_DIR)/.test_reports/integration_tests.xml -m integration

test_smoke: clean_tests
	pytest $(SRC_DIR)/tests --junitxml=$(SRC_DIR)/.test_reports/smoke_tests.xml -m smoke

build_lambda: clean_lambda
	mkdir $(SRC_DIR)/.build
	cp $(SRC_DIR)/*.py $(SRC_DIR)/.build

clean_lambda:
	rm -rf $(SRC_DIR)/.build

fmt_terraform:
	terraform fmt -recursive -check .

init_terraform:
ifndef BACKEND_BUCKET
	$(error "Terraform init requires environment variable BACKEND_BUCKET")
endif
ifndef BACKEND_KEY
	$(error "terraform init requires environment variable BACKEND_KEY")
endif
ifndef BACKEND_REGION
	$(error "terraform init requires environment variable BACKEND_REGION")
endif
	terraform -chdir=$(TF_DR)/ init -backend-config="bucket=$(BACKEND_BUCKET)" -backend-config="key=$(BACKEND_KEY)" -backend-config="region=$(BACKEND_REGION)"

init_terraform_ci:
	terraform -chdir=$(TF_DIR)/ init -reconfigure -upgrade -backend=false

validate_terraform:
	terraform -chdir=$(TF_DIR)/ validate

test_terraform: fmt_terraform	init_terraform	validate_terraform

plan_terraform: build_lambda	test_terraform
	terraform -chdir=$(TF_DR)/ plan

apply_terraform: build_lambda	test_terraform
	terraform -chdir=$(TF_DR)/ apply

scan_terraform:
	checkov -d $(TF_DR)


scan_plan_terraform: create_plan_terraform
	checkov --repo-root-for-plan-enrichment . -f $(TF_PLAN_FILE).json

create_plan_terraform:
	terraform -chdir=$(TF_DR)/ plan -out=$(TF_PLAN_FILE)
	terraform -chdir=$(TF_DR)/ show -json $(TF_PLAN_FILE) > $(TF_PLAN_FILE).json

ci_terraform: build_lambda	test_terraform	scan_terraform	create_plan_terraform	scan_plan_terraform

cd_terraform: build_lambda	test_terraform
	terraform -chdir=$(TF_DR)/ apply $(TF_PLAN_FILE)
