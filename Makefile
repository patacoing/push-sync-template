clean:
	rm -rf children_repositories

lint:
	shellcheck src/*.sh

format:
	shfmt -l -w .

check-format:
	shfmt -d .