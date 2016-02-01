\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{satzungv2}[2016/01/30 Klasse für kommunale Satzungen]
\newcommand\sektion{}
\DeclareOption{paragraf}{\renewcommand\sektion{\S}}
\DeclareOption{artikel}{\renewcommand\sektion{Artikel}}
\ExecuteOptions{paragraf}
\ProcessOptions\relax
\LoadClass[twoside,twocolumn]{article}
\RequirePackage[utf8]{inputenc}
\RequirePackage[T1]{fontenc}
\RequirePackage[ngerman]{babel}
\RequirePackage[a4paper,left=22mm,top=28mm,right=22mm,bottom=22mm]{geometry}
\RequirePackage{microtype}
\RequirePackage[right]{eurosym}
\RequirePackage[scaled=.9]{helvet}
\RequirePackage{enumitem}
\RequirePackage{titlesec}
\RequirePackage{hyperref}

\newcommand{\Bekanntmachung}[5]{Die öffentliche Bekanntmachung erfolgte am #1 im Amtsblatt für das #2, #3. Jahrgang, Ausgabe #4/#5.}

% Allgemeine Einstellungen
\renewcommand{\familydefault}{\sfdefault} % Helvetica bzw. Nimbus Sans als Standardschriftart
\linespread{.9}\selectfont % Zeilenabstand 90% vom Standard
\parskip \smallskipamount % Abstand zwischen Absätzen
\parindent 0pt % Rücksetzen des Einzugs von Absätzen
\setlength{\columnsep}{5mm} % Abstand zwischen den beiden Spalten

% Paket-Optionen

% hyperref
\hypersetup{
	colorlinks			=	false,
	pdfborder			=	{0 0 0},
	bookmarksopen		=	true,
	bookmarksnumbered	=	true,
	pdfstartview		=	FitH,
	pdfauthor			=	{Amt Britz-Chorin-Oderberg},
	pdfsubject			=	{Kommunalrecht, Ortsrecht, Satzungen}
}

% titlesec: Formatierung \section (Paragraf oder Artikel)
\renewcommand*{\thesection}{\texorpdfstring{}{\sektion{ }}\arabic{section}} % für die PDF-Bookmarks
\titleformat{\section}[display]{\centering\normalsize\bfseries}{\normalfont\sektion{ }\thesection}{0pt}{}
\titlespacing{\section}{0pt}{.9\bigskipamount}{0pt}

% enumitem
\setlist{itemsep=\smallskipamount, parsep=0pt, leftmargin=*}
\setlist[1]{topsep=0pt}
\setlist[2]{topsep=\smallskipamount}
\setenumerate[1]{label=\arabic*.}
\setenumerate[2]{label=\alph*), align=left}
\setitemize{label=-, align=left, labelwidth=0.6em, leftmargin=!}

% Definition eigener Befehle

% Kopfzeile
\renewcommand\thepage{\bfseries\arabic{page}} % Seitennummerierung in fetter Schrift
\newcommand{\header}[1]{ % Satzungsname in kleiner Schrift links und Seitennummer rechts bei ungeraden Seiten, vice versa bei geraden Seiten
	\pagestyle{myheadings}
	\markboth{\normalfont\small #1}{\normalfont\small #1}
}

% Befehl \absatz zur Nachbildung eines Absatzes "(x)" im Paragrafen
\newcounter{absatz}[section] % Zähler für den Absatz. Wird mit Beginn einer neuen \section wieder zurück gesetzt.
\newcommand{\absatz}{\par\stepcounter{absatz}\hspace{1em}(\arabic{absatz})\hspace{0.5em}}

% redefine maketitle
\def\changemargin#1#2{\list{}{\rightmargin#2\leftmargin#1}\item[]} % neue Umgebung "changemargin" (TeX Stack-Exchange)
\let\endchangemargin=\endlist

\def\@maketitle{%
	\begin{changemargin}{35mm}{35mm}%
	\newpage
	\null
	\vskip 2em%
	\begin{center}%
		{\large\bfseries \@title \par}%
		\vskip 1.5em%
		{\normalsize\bfseries Vom \@date}%
	\end{center}%
	\par
	\vskip 1em
	\end{changemargin}%
}

% Befehl \satzungstitel der \title wird mit größeren Rändern und einspaltig gesetzt

\newcommand{\titel}{
	\begin{@twocolumnfalse}
		\maketitle
		\thispagestyle{myheadings} % auch auf der Titelseite die Kopfzeile anzeigen
	\end{@twocolumnfalse}
}

% Befehl \unterzeichnung für die Unterzeichungsformel der Satzung (Ort, Datum, Name)
\newcommand{\unterzeichnung}[3]{%
	\begin{center}
		\rule{0.2\textwidth}{0.4pt}
	\end{center}%
	{\bigskip#1\par\bigskip}%
	{\textls[250]{#2}\par\textls[250]{#3}}%
}

% Befehl \rfill eine bessere Version von \hfill (TeX StackExchange)
\newcommand\rfill[1]{{%
	\unskip\nobreak\hfil\penalty50
	\hskip2em\hbox{}\nobreak\hfil #1%
	\parfillskip=0pt \finalhyphendemerits=0 \par}
}
