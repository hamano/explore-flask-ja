LATEX=platex
#LATEX=uplatex
LATEX_OPT=-shell-escape -output-directory=tex
#PANDOC=pandoc
PANDOC=~/.cabal/bin/pandoc
PANDOC_OPT=--toc --listings --chapters
DVIPDFMX=dvipdfmx
DVIPDFMX_OPT=-f ptex-hiragino

NAME=explore-flask-ja
TEMPLATE=template.tex

SRCS=meta.yaml foreword.md preface.md conventions.md environment.md organizing.md configuration.md views.md blueprints.md templates.md static.md storing.md forms.md users.md deployment.md conclusion.md

MD=$(NAME).md
TEX=$(NAME).tex
DVI=$(NAME).dvi
PDF=$(NAME).pdf
EPUB=$(NAME).epub
HTML=$(NAME).html

%.dvi: %.tex
	$(LATEX) $(LATEX_OPT) $<
	$(LATEX) $(LATEX_OPT) $<

%.pdf: %.dvi
	$(DVIPDFMX) $(DVIPDFMX_OPT) $^

all: pdf
pdf: $(PDF)

clean:
	rm -rf tex $(MD) $(TEX) $(DVI) $(PDF) $(EPUB) $(HTML)

$(MD): $(SRCS)
	cat $^ > $@

$(EPUB): $(MD)
	$(PANDOC) -o $@ $<

$(HTML): $(MD)
	$(PANDOC) -o $@ $<

tex/$(TEX): $(MD) $(TEMPLATE)
	mkdir -p tex
	$(PANDOC) -t latex $(PANDOC_OPT) --template=$(TEMPLATE) $< | sed -e 's/\[htbp\]/\[H\]/g' > $@

tex/$(DVI): tex/$(TEX)
$(PDF): tex/$(DVI)
