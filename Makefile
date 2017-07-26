
tesi.pdf: tesi.tex
	latexmk -pdf -shell-escape tesi.tex

clean:
	rm -f *.pdf *.toc *.out *.log *.aux *.synctex.gz *.auto.dot *.fls *.fdb_latexmk
