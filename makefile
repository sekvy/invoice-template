TEX = pandoc
src = template.tex exampleDetails.yaml
FLAGS = --pdf-engine=xelatex

output.pdf : $(src)
	$(TEX) -f markdown $(filter-out $<,$^ ) -o $@ --template=$< $(FLAGS)

.PHONY: clean
clean :
	rm output.pdf
