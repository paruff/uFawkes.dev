RUBY = /usr/local/opt/ruby/bin/ruby
GEM  = /usr/local/opt/ruby/bin/gem
PATH := /usr/local/opt/ruby/bin:$(PATH)

build:
	$(GEM) install bundler --conservative 2>/dev/null; bundle exec jekyll build

serve:
	$(GEM) install bundler --conservative 2>/dev/null; bundle exec jekyll serve --livereload

# GitOps targets
pre-commit-setup: ## Install pre-commit hooks
	@pip install pre-commit
	@pre-commit install
	@echo "✅ Pre-commit hooks installed"

pre-commit-run: ## Run all pre-commit hooks
	@pre-commit run --all-files

validate: pre-commit-run ## Validate all files (alias for pre-commit-run)

clean: ## Remove Jekyll build output, agent tooling caches, and generated reports
	rm -rf _site/ .jekyll-cache/
	rm -rf .opencode/node_modules/
	rm -rf graphify-out/
	rm -rf .agents/logs/
	find . -name '*.pyc' -delete
	rm -f ci-diagnosis.md ci-fix-report.md
	@echo "Cleaned Jekyll build output and agent tooling artifacts"

# Suite status dashboard (docs/ai-sdlc/suite-status/)
status: ## Run the suite acceptance checks and write _data/suite_status.json
	@bash scripts/suite-status.sh

status-check-drift: ## Fail if suite-release/spec.md and acceptance.yml disagree
	@bash scripts/check-status-drift.sh

# Design tokens (DESIGN.md, design/tokens.json)
design-check: ## Fail if a design token pair is below its contrast floor
	@bash scripts/check-design-tokens.sh

# Shift left (docs/ai-sdlc/shift-left/)
shift-left-audit: ## Matrix of shift-left checks x suite repo (add --time via ARGS=--time)
	@bash scripts/shift-left-audit.sh $(ARGS)
