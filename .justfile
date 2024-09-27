# Build & install a binary package
install package:
	lune run build {{package}} linux-x86_64
	cp build/{{package}}/linux-x86_64/{{package}} ~/bin/{{package}}

# Build a binary package
build package:
	lune run build {{package}}

# Run a binary package
@run package *args:
	lune run src/{{package}}/bin -- {{args}}
