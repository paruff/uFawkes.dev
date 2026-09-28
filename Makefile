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
