
tesi.pdf: tesi.tex
	pdflatex -shell-escape -synctex=1 -interaction=nonstopmode tesi.tex
	# two-pass
	pdflatex -shell-escape -synctex=1 -interaction=nonstopmode tesi.tex

clean:
	rm -f *.pdf *.toc *.out *.log *.aux *.synctex.gz *.auto.dot
