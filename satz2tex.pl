#!perl
#
# Satzung 2 LaTeX
#
# 3.0.2 - 2019-02-25
# - Perl::Critic: Anpassungen an die Stufe 3 (harsh)
# - Änderungen an der Verarbeitung der Zeilenumbrüche (speziell für Texte aus PDF/Amtsblatt)
# - Definition der Variable $satztitel (Name der Satzung)
# - Definition der Variable $satzdatum (Datum der Ausfertigung)
#
# 3.0.1 - 2018-03-18
# - Bundesgesetzblatt: Schreibweise mit Komma funktionierte fehlerhaft
# - Variable $satzung: erste Zeile der Textdatei wird als Satzungstitel interpretiert und in der Tex-Datei bei \def\satzung{} eingetragen
# - Bug bei itemize-Umgebung, - durch \p{Pd} ersetzt
#
# 3.0.0 - 2017-10-19 
# - Nummerierungen 1., 1.1, a), aa) vorerst fertig inklusive [widest=XX] für Einzelnummerierung bei Zahlen
# - itemize-Umgebung auf Regex-Basis für die Aufzählungszeichen [-·•o]
# - Umstellung auf UTF-8: Lesen und Schreiben der Datei mit Kodierung und Verwendung des Modules 'utf8'
# - Optimierung der Ersetzung von Daten, Abkürzungen und Uhrzeiten
#
use 5.014;
use autodie;
use open qw(:std :utf8);
use utf8;
use warnings;

# Text-Datei lesen
my $file = shift;
open my $fh, '<', $file;
chomp(my @lines = <$fh>);
close $fh;

my $content = join "\n", @lines;

# -----------------------------------------------
# TEXT-BEREINIGUNG
# -----------------------------------------------

$content  =~ s/\p{Cf}|\x{0007}//gmsx;
$content  =~ s/\h+/ /gmsx;
$content  =~ s/^\h?\n?|\h$//gmsx;
$content  =~ s/\h([.,;:!?)])\h/$1 /gmsx;
$content  =~ s/^Britz,\hden.*//gmsx;
# Zeilenumbrüche entfernen bei:
my $par   =  qr/§\h?\d+/x; # Paragrafen § 1
my $abs   =  qr/[(]\h?\d+\h?[)]/x; # Absätze (1)
my $enum1 =  qr/\d{1,2}[.](?:\d{1,2})?/x; # Zahlen 1. oder 1.1
my $enum2 =  qr/\p{Ll}{1,2}[)]/x; # Buchstaben a) oder aa)
my $item1 =  qr/[·•o\p{Pd}]/x; #Aufzählungszeichen
$content  =~ s/^($par|$abs|$enum1|$enum2|item1)\n/$1 /gmx;
$content  =~ s/(?<=\p{L})-\n//gmsx; # Worttrennungen am Zeilenende (PDF)

# Speichern der ersten Zeile = Satzungstitel und der zweiten Zeile = Datum der Ausfertigung. Wird beim Output eingetragen.
@lines = split /\n/x, $content;
my $satztitel = shift @lines;
my $satzdatum = shift @lines;
$satzdatum =~ s/Vom\h(\d{1,2}[.])\h(\p{L}+)\h(\d{4})/$1~$2~$3/x;
$content = join "\n", @lines;

# -----------------------------------------------
# Paragrafen, Absätze
# -----------------------------------------------

$content =~ s/^($par.+?)\n([^(].+?\n)(?=$abs)/$1 $2/gmx;
$content =~ s/^§\h?(\d+)\h(.+)/\n% § $1 · $2\n\\section{$2}/gmx;
$content =~ s/^$abs\h/\\absatz /gmx;

# -----------------------------------------------
# TEX-UMGEBUNGEN
# Enumerate: \begin{enumerate}, \item, \end{enumerate}
# Itemize: \begin{itemize}, \item, \end{itemize}
# -----------------------------------------------

# Arrays für Nummerierungen
# 0 = Einzelnummerierung: Counter
# 1 = Einzelnummerierung: aktuelle Zeile
# 2 = Einzelnummerierung: Zeile in der die Nummerierung beginnt
# 3 = Einzelnummerierung: Flag, ob Nummerierung
# 4 = Doppelnummerierung: Counter
# 5 = Doppelnummerierung: aktuelle Zeile
# 6 = Doppelnummerierung: Zeile in der die Nummerierung beginnt
# 7 = Doppelnummerierung: Flag, ob Nummerierung
my @numbers = (  0, 0, 0, 0,   0, 0, 0, 0);
my @chars   = ('a', 0, 0, 0, 'a', 0, 0, 0);

# \begin der Nummerierungen durch global Regex
# Setzen der Flags, ob eine bestimmte Nummerierung aktiv ist
# (benötigt für das Schließen der jeweils letzten Nummerierung)
if ( $content =~ s/^(1[.]\h.*)/\\begin{enumerate}\n$1/gmx ) { $numbers[3] = 1; }
if ( $content =~ s/^((\d{1,2})[.]1\h.*)/\\begin{enumerate}[label=$2.\\arabic*]\n$1/gmx ) { $numbers[7] = 1; }
if ( $content =~ s/^(a[)]\h.*)/\\begin{enumerate}[label=\\alph*)]\n$1/gmx ) { $chars[3] = 1; }
if ( $content =~ s/^((\p{Ll})a[)]\h.*)/\\begin{enumerate}[label=$2\\alph*)]\n$1/gmx ) { $chars[7] = 1; }

# itemize-Umgebung nur mit Regex
$content =~ s/^([^·•o\p{Pd}].*\n)[·•o\p{Pd}]\h/$1\\begin{itemize}\n\\item /gmx;
$content =~ s/^[·•o\p{Pd}]\h(.+\n)(?![·•o\p{Pd}])/\\item $1\\end{itemize}\n/gmx;

# Aufteilen des Textes in Zeilen an Hand von Zeilenumbrüchen
@lines = split /\n/x, $content;

# mitlaufende Variable für die Zeilennummer
my $i = 0;

# Iteration durch die Zeilen und Schließen der Nummerierungen
foreach my $line (@lines) {
	given ( $line ) {
		# Beginn (Zeile) der ersten Einzelnnummerierung für [widest=XX] ermitteln
		when ( /^\\begin[{]enumerate[}]$/x and not $numbers[2] ) {
			$numbers[2] = $i;
		}
		# Zahlen: Einzelnummerierung (1.)
		when ( /^(\d{1,2})[.]\h/x ) { # Einzelnummerierung
			if ( $1 < $numbers[0] ) { # Neustart der Nummerierung?
				if ( $numbers[0] > 9 ) { # wenn Nummerierung zweistellig, dann am Beginn anhängen: \begin{enumerate}[widest=XX]
					$lines[$numbers[2]] = $lines[$numbers[2]] . '[widest=' . $numbers[0] . ']';
				}
				$numbers[0] = 1; # Neustart der Nummerierung bei 1
				$lines[$numbers[1]] = "$lines[$numbers[1]]\n\\end{enumerate}";
				$numbers[2] = $i-1; # Zeile in der die neue Nummerierung beginnt
			} else { # sonst weiter in der laufenden Einzelnummerierung
				$numbers[0]++;  # Counter der Einzelnummerierung erhöhen
				$numbers[1] = $i; # Zeilennummer der Einzelnummerierung = aktuelle Zeilennummer
			}
		}
		# Zahlen: Doppelnummerierung (1.1)
		when ( /^\d+[.](\d+)\h/x ) { # Doppelnummerierung
			if ( $1 < $numbers[4] ) { # Neustart der Nummerierung?
				$numbers[4] = 1; # Neustart der Nummerierung bei 1
				$lines[$numbers[5]] = "$lines[$numbers[5]]\n\\end{enumerate}";
			} else { # sonst weiter in der laufenden Nummerierung
				$numbers[1] = $numbers[5] = $i; # Zeilennummer für Einzel- und Doppelnummerierung = aktuelle Zeilennummer
				$numbers[4]++; # Counter der Doppelnummerierung erhöhen
			}
		}
		# Buchstaben: Einzelnummerierung (a))
		when ( /^(\p{Ll})[)]\h/x ) { # Einzelnummerierung
			if ( $1 lt $chars[0] ) { # Neustart der Nummerierung?
				$chars[0] = 'a'; # Neustart der Nummerierung bei 'a'
				$lines[$chars[1]] = "$lines[$chars[1]]\n\\end{enumerate}";
			} else { # sonst weiter in der laufenden Einzelnummerierung
				$chars[0]++; # Counter für den ersten Buchstaben erhöhen
				$chars[1] = $i; # Zeilennummer für Einzelbuchstaben = aktuelle Zeilennummer
			}
		}
		# Buchstaben: Doppelnummerierung (aa))
		when ( /^\p{Ll}(\p{Ll})[)]\h/x ) { # Doppelnummerierung
			if ( $1 lt $chars[4] ) { # Neustart der Nummerierung?
				$chars[4] = 'a'; # Neustart der Nummerierung bei 'a'
				$lines[$chars[5]] = "$lines[$chars[5]]\n\\end{enumerate}";
			} else { # sonst weiter in der laufenden Nummerierung
				$chars[1] = $chars[5] = $i; # Zeilennummer bei Einzel- und Doppelbuchstaben = aktuelle Zeilennummer
				$chars[4]++; # Counter für den zweiten Buchstaben erhöhen
			}
		}
	}
	# alle nummerierten Zeilen und solche mit Aufzählungszeichen durch \item... ersetzen
	$line =~ s/^(?:\d{1,2}[.](?:\d{1,2})?|\p{Ll}\p{Ll}?[)]|[·•o\p{Pd}])\h(.*)/\\item $1/x;
	# Variable $i für aktuelle Zeile erhöhen
	$i++;
}

# wenn Flag gesetzt, Schließen der jeweils letzten offenen Nummerierung
if ( $numbers[3] ) {
	$lines[$numbers[1]] = "$lines[$numbers[1]]\n\\end{enumerate}";
	if ( $numbers[0] > 9 ) {
		# wenn die Nummerierung zweistellig ist, Ergänzung des Anfangs der Nummerierung mit [widest=XX]
		# zum Beispiel \begin{enumerate}[widest=10]; momentan nur bei Einzelnummerierung mit Zahlen
		$lines[$numbers[2]] = $lines[$numbers[2]] . '[widest=' . $numbers[0] . ']';
	}
}
if ( $numbers[7] ) { $lines[$numbers[5]] = "$lines[$numbers[5]]\n\\end{enumerate}"; }
if ( $chars[3]   ) { $lines[$chars[1]]   = "$lines[$chars[1]]\n\\end{enumerate}"; }
if ( $chars[7]   ) { $lines[$chars[5]]   = "$lines[$chars[5]]\n\\end{enumerate}"; }

# Zusammenfügen und erneutes Aufteilen des Textes in Zeilen,
# um auch die neu eingefügten Zeilenumbrüche korrekt zu trennen,
# sonst ggf. Probleme mit dem Einrücken der Nummerierungen (siehe unten)
$content = join "\n", @lines;
@lines = split /\n/x, $content;

# Einrückung der Nummerierungen durch Tabulatoren
my $indent = 0;

foreach my $line (@lines) {
	if ( $line =~ /^\\begin[{](enum|item)/x ) { $indent++; }
	if ( $line =~ /^\\end[{](enum|item)/x ) { $indent--; }
	if ( $indent and $line =~ /^\\begin[{](enum|item)/x ) {
		$line = "\t" x ( $indent - 1 ) . $line;
	} elsif ( $indent ) {
		$line = "\t" x $indent . $line;
	}
}

# Endgültiges Zusammenfügen der Zeilen des Textes
$content = join "\n", @lines;

# -----------------------------------------------
# MIKRO-TYPOGRAFIE
# -----------------------------------------------

# Formatierung der Uhrzeit nach DIN 5008
$content =~ s/\h(\d{1,2})[.:]?(\d{2})?\h?Uhr/$2 ? sprintf(" %02d:%02d~Uhr",$1,$2) : sprintf(" %d~Uhr",$1)/gex;
# Formatierung Datum (siehe Subroutine)
$content =~ s/\h(\d{1,2})[.]\h?(\d{1,2}|\pL{3,9})[.]?\h?(\d{4})/&date/gex;
# Achtelgeviert \,
$content =~ s/(?<!%\h)§\h?(\d+)\h?(\pL)?(?=\h|\pP)/$2?"§\\,$1\\,$2":"§\\,$1"/gex; # §§ x, außer in Tex-Kommentaren (%...)
$content =~ s/(?<!\w)(\pL[.])\h?(?=\pL[.])/$1\\,/gx; # Abkürzungen alá i. S. d. F.; z. B.
# Viertelgeviertstrich
$content =~ s/(?<=\pL)\p{Pd}(?=\h|\pP|\n)/-/gx; # Divis, Bindestrich (hinter einem Wortbestandteil)
$content =~ s/(?<=\h|\pP|\n)\p{Pd}(?=\pL)/-/gx; # Divis, Bindestrich (vor einem Wortbestandteil)
# Halbgeviertstrich --
$content =~ s/\h([-\x{2013}])\h/ -- /gx; # als Gedankenstrich
$content =~ s/(?<=\d)\h?[-\x{2013}]\h?(?=\d)/--/gx; # als bis-Strich (2011-2013)
# Hochgestellte Zeichen, superscript, \textsuperscript{}
$content =~ s/²(?= |\pP)/\\textsuperscript{2}/gx; # cm²
$content =~ s/³(?= |\pP)/\\textsuperscript{3}/gx; # mm³
# Auslassungspunkte
$content =~ s/[.]{3}/…/gx;
# Umbruchgeschützte Leerzeichen
$content =~ s/(?<=\d)\h?([ckmq]{1,2})(?!\pL)/~$1/gx; # Maße (mm, m, cm², km, etc.)
$content =~ s/(?<=\d)\h(?=v[.]\\,H[.])/~/gx; # xx vom Hundert (v. H.)
$content =~ s/([(]([BGV]+)[1lI].+?[)])/&gesetzblatt/gex; # Gesetzesblätter
my %abbr = qw/Abs Absatz Art Artikel Nr Nummer S Satz Str Straße Ziff Ziffer/; # Abkürzungen für Verweise wie Abs. Ziff. usw. in Langform umwandeln
$content =~ s/\h(\pL+)[.]\h(\d)/ $abbr{$1}~$2/gx; # Verweise mit ~ ersetzen
$content =~ s/\h((?:Ab|Halb)?[Ss][aä]tze?[ns]?)\h(?=\d)/ $1~/gx;  # Absatz, Nummer, Satz etc.
$content =~ s/\h((?:Artikel|Ziffer|Nummer)n?)\h(?=\d)/ $1~/gx; # Absatz, Nummer, Satz etc.
$content =~ s/(?<=\h)(Buchstaben?)\h(\p{Ll})/$1~$2/gx; # Absatz, Nummer, Satz etc.
$content =~ s/(?<=\d)\h?(Euro|EUR|\p{Sc})(?=\h|\pP)/~Euro/gx; # x,xx €/EUR/Euro with x,xx~Euro
$content =~ s/(?<=\d\h)(bis|und)\h(?=\d)/$1~/gx; # z. B. §§ 2, 3 und ~4
$content =~ s/(?<=\d)\hff[.]?\h/~ff. /gx; # ~ff.
# französische Anführungszeichen nach innen (Chevrons) mit \enquote{...}
$content =~ s/(?<=\h)["\x{201d}\x{201e}\xbb](.+?)["\x{201c}\x{201f}\xab](?=\h|[.])/\\enquote{$1}/gsx; #doppelt
$content =~ s/(?<=\h)['\x{201a}](.+?)['\x{2018}\x{201b}](?=\h)/\x{203a}$1\x{2039}/gx; # einfach

# Specials
if ( $content =~ s/(?<=nach\hihrer\h)(?:öffentlichen\h)?(Bekanntmachung)(?=\hin\hKraft)/$1\\bekanntmachung{dd.~mmmm~yyyy}/gix ) {
	print 'Datum der Bekanntmachung ergänzen!';
}

# am Anfang der LaTeX-Datei einfügen
$content = "\\def\\satzung{$satztitel}\n\\def\\satzungs{$satztitel}\n\\def\\datum{$satzdatum}\n\\documentclass{satzung}\n% Optionen der Klasse:\n% [paragraf]\t\\section steht für den Paragrafen einer Satzung (Standard)\n% [artikel]\t\t\\section steht für Artikel in einer Satzung, klassisch zum Beispiel bei einer Änderungssatzung\n% [noname]\t\tin Verbindung mit [artikel], wenn der Artikel keine Bezeichnung hat, muss der Weißraum darunter angepasst werden\n\\begin{document}\n\\maketitle\n\\thispagestyle{satzung}\n\n$content";
# am Ende der LaTeX-Datei anfügen
$content .= "\n\n\\unterzeichnung{Jörg\\enskip Matthes}{Amtsdirektor}\n\\end{document}";

# LaTeX-Datei schreiben
$file =~ s/(.+[.])\w+/$1tex/x;
open $fh, '>', $file;
print {$fh} $content;
close $fh;

# -----------------------------------------------
# SUBROUTINEN
# -----------------------------------------------

# Gesetzblätter
# Bundesgesetzblatt und Gesetz- und Verordnungsblatt Brandenburg
# die Abkürzungen Nr. und S. werden nicht in die Langform umgewandelt
sub gesetzblatt {
	if ( $1 ) {
	my $match = $1;
		if ( $2 eq 'BGB' ) { # Bundesgesetzblatt
			my $vol = $match =~ s{.+[.]\h?([1lI]+)\,?\h.+}{$1}rx;
			$vol =~ tr/1l/I/;
			$match =~ /S[.]\h?(\d+)/x;
			return "\\mbox\{(BGBl.~$vol\} S.~$1)";
		} else { # Gesetz- und Verordnungsblatt Brandenburg
			my $gvbl = '\mbox{(GVBl.} ';
			my $vol = $match =~ s{.+?[.]\h?([1lI]+)\/.+}{$1}rx;
			$vol =~ tr/1l/I/;
			$match =~ /\/(\d+)[ ,]+\[?Nr[.]\h?(\d+)\]?(?:[ ,]+S[.]\h?(\d+))?/x;
			if ($3) { $gvbl .= "$vol/$1, Nr.~$2, S.~$3)"; }
			else { $gvbl .= "$vol/$1, Nr.~$2)"; }
			return $gvbl;
		}
	}
}

# Datum
# Entfernen führender Nullen (01. > 1.), Ausgabe des Monatsnamens in voller Länge (01./Jan. > Januar),
# Einfügen eines umbruchgeschützen Leerzeichens = 3.~Januar~2000
sub date {
	my @months = qw/Januar Februar März April Mai Juni Juli August September Oktober November Dezember/;
	if (length($2) > 2) {
		my @match = grep { /^$2/x } @months;
		return sprintf ' %d.~%s~%d', $1, $match[0], $3;
	} else {
		return sprintf ' %d.~%s~%d', $1, $months[$2-1], $3;
	}
}
