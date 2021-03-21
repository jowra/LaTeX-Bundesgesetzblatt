% $Id: satzung.cls 2.0 2016/02/01 John Exp $
%
% 2016-02-01 2.0.0 - Rewrite der ursprünglichen Satzungsklasse
% 2016-08-13 2.0.1 - Umstellung auf LuaLatex und Helvetica Neue
% 2016-10-31 2.0.2 - erneute Anpassung an BGBL, Änderung Fußnoten
% 2017-09-26 2.0.3 - Paket csquotes hinzugefügt (\enquote{})
% 2017-10-25 2.0.4 - \bekanntmachung{Datum} geändert, so dass der Befehl \footnote{} gleich enthalten ist
% 2018-02-09 2.0.5 - \latinencoding\relax eingefügt, da aktuell Probleme mit \fontspec
%
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{satzung}[2016/08/13 Klasse für kommunale Satzungen]
\newcommand\sektion{}
\DeclareOption{paragraf}{\renewcommand\sektion{\S}} % normale Satzung mit Paragrafen
\DeclareOption{artikel}{% % Artikelgesetz
	\renewcommand\sektion{Artikel}%
	\newcommand\artikel{}% command 'artikel' für ifthen-Abfrage
}
\DeclareOption{noname}{\newcommand\noname{}} % keine Bezeichnung von \thesection, Anpassung spacing
\ExecuteOptions{paragraf}
\ProcessOptions\relax
\LoadClass[twoside,twocolumn]{article}
\RequirePackage[ngerman]{babel}
\let\latinencoding\relax
\RequirePackage{fontspec}
\RequirePackage[a4paper,left=22.8mm,top=29mm,right=22.8mm,bottom=22mm]{geometry}
\RequirePackage{microtype}
\RequirePackage{enumitem}
\RequirePackage[newparttoc,pagestyles]{titlesec}
\RequirePackage{titletoc}
\RequirePackage[hang]{footmisc}
\RequirePackage{ifthen}
\RequirePackage[german=guillemets]{csquotes}
\RequirePackage[pdfencoding=auto]{hyperref}

% Schriftarten
\setmainfont{HelveticaNeueLT Pro}[Scale=0.92]

% Allgemeine Einstellungen
\parskip \smallskipamount % Abstand zwischen Absätzen
\linespread{0.9}\selectfont
\parindent 1em % Länge des Einzugs von Absätzen
\setlength{\columnsep}{5mm} % Abstand zwischen den beiden Spalten

% Fußnotendarstellung
\setlength{\footnotemargin}{0.8em}

% Paket-Optionen

% hyperref
\hypersetup{
	pdftitle			=	\satzungs,
	pdfauthor			=	{Amt Britz-Chorin-Oderberg},
	pdfsubject			=	{Kommunalrecht},
	colorlinks			=	false,
	pdfborder			=	{0 0 0},
	bookmarksopen		=	true,
	bookmarksnumbered	=	true,
	pdfstartview		=	FitH,
}

\AtBeginDocument{\renewcommand*{\contentsname}{\hfill\small \textls[200]{Inhaltsübersicht} \hfill}}
\setcounter{tocdepth}{2} % subsubsections nicht in ToC anzeigen
\contentsmargin{0pt}
\titlecontents{part}[0em]{\centering\small\medskip}{\thecontentslabel \@@par\centering}{}{}[\medskip]% Abschnitt (part)
\titlecontents{section}[3em]{\small}{\contentslabel{3em}}{}{}[]% section

% titlesec: Formatierung \part (Abschnitt) und \section (Paragraf oder Artikel)
\renewcommand*{\thepart}{\texorpdfstring{Abschnitt \arabic{part}}{Abschnitt \arabic{part}}} % für die PDF-Bookmarks
\renewcommand*{\thesection}{\texorpdfstring{\sektion{ }\arabic{section}}{\sektion{ }\arabic{section}}} % für die PDF-Bookmarks
\titleformat{\part}[display]{\centering\normalsize\bfseries}{\textls[200]{\thepart}}{0pt}{\textls[200]}
\titlespacing{\part}{0em}{\bigskipamount}{\bigskipamount}
% wenn command 'artikel' nicht definiert ist (siehe Options), ist es ein Paragraf und \thesection wird in \normalfont gesetzt,
% ist 'artikel' definiert, wird \thesection in \bfseries gesetzt
\titleformat{\section}[display]{\centering\normalsize\bfseries}{\ifthenelse{\isundefined{\artikel}}{\normalfont}{\bfseries} \thesection}{0pt}{}
% wenn command 'noname' nicht definiert ist, wird der Abstand nach \section auf 0pt gesetzt
% ist es ein Artikelgesetz und haben die Artikel keinen Namen, dann wird der Abstand nach \section negativ,
% da sonst ein zu großer Weißraum entsteht
\ifthenelse{\isundefined{\noname}}{\def\sectionafter{0pt}}{\def\sectionafter{-1.5\medskipamount}}
\titlespacing{\section}{0pt}{.9\bigskipamount}{\sectionafter}

% enumitem
\setlist{itemsep=\smallskipamount, parsep=0pt, leftmargin=*}
\setlist[1]{topsep=0pt}
\setlist[2]{topsep=\smallskipamount}
\setenumerate[1]{label=\arabic*.} % bei Zahlen größer 9, [widest=xx] anhängen
\setenumerate[2]{label=\alph*), align=left}
\setenumerate[3]{label=\alph\alph*), align=left}
\setitemize{label=-, align=left, labelwidth=0.6em, leftmargin=!}

% titleps (titlesec)
\newpagestyle{satzung}{%
\sethead[\bfseries\thepage][\satzungs][] % gerade Seiten
	{}{\satzungs}{\bfseries\thepage}% ungerade Seiten
}
\pagestyle{satzung}

% Definition eigener Befehle

% Befehl \absatz zur Nachbildung eines Absatzes "(x)" im Paragrafen
\newcounter{absatz}[section] % Zähler für den Absatz. Wird mit Beginn einer neuen \section zurück gesetzt.
\newcommand{\absatz}{\par\stepcounter{absatz}(\arabic{absatz})\hspace{0.5em}}

% redefine maketitle
% Umgebung 'changemargin' momentan nicht genutzt, da Umbrüche im Titel durch \\ selbst bestimmt werden
%\def\changemargin#1#2{\list{}{\rightmargin#2\leftmargin#1}\item[]} % neue Umgebung "changemargin" (TeX Stack-Exchange)
%\let\endchangemargin=\endlist
\date{\datum} % Datum für \maketitle setzen
\def\@maketitle{%
	\currentpdfbookmark{\satzungs}{Titel} % Titel des PDF für Lesezeichen
	%\begin{changemargin}{35mm}{35mm}%
	\newpage
	\null
	\vskip 5em%
	\begin{center}%
		{\large\bfseries \satzung\par}%
		\bigskip%
		{\normalsize\bfseries \textls[20]{Vom \@date}}%
	\end{center}%
	\par
	\vskip 1em
	%\end{changemargin}%
}

% Befehl \unterzeichnung für die Unterzeichungsformel der Satzung (Ort, Datum, Name)
\newcommand{\unterzeichnung}[2]{%
	\vspace{-0.5\baselineskip}
	\begin{center}
		\rule{0.08\textwidth}{0.6pt}
	\end{center}%
	{\par\smallskip Britz, den \datum\par\vspace{1cm}}%
	\begin{center}
		{\textls[200]{#1}\par\vspace{-2pt}\textls[200]{#2}}%
	\end{center}%
}

% Datum der Bekanntmachung als Fußnote auf der letzten Seite, im Regelfall zum Paragraf »Inkrafttreten«
\newcommand{\bekanntmachung}[1]{%
	\footnote{Die öffentliche Bekanntmachung erfolgte am #1 im Amtsblatt für das Amt Britz-Chorin-Oderberg.}%
}

% Befehl \rfill eine bessere Version von \hfill (TeX StackExchange)
\newcommand\rfill[1]{{%
	\unskip\nobreak\hfil\penalty50
	\hskip2em\hbox{}\nobreak\hfil #1%
	\parfillskip=0pt \finalhyphendemerits=0 \par}
}