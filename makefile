TEX = pandoc
src = template.tex details.yaml
exampleSrc = template.tex exampleDetails.yaml
FLAGS = --pdf-engine=xelatex

invoice.pdf : $(src)
	$(TEX) -f markdown $(filter-out $<,$^ ) -o $@ --template=$< $(FLAGS)

example : $(exampleSrc)
	$(TEX) -f markdown $(filter-out $<,$^ ) -o $@.pdf --template=$< $(FLAGS)

.PHONY: clean
clean :
	rm *.pdf
