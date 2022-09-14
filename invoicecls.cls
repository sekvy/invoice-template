\ProvidesClass{invoicecls}[2022/09/11 invoice doc settings]
\NeedsTeXFormat{LaTeX2e}
\LoadClass[11pt]{article}

% For page number calculations
\RequirePackage{ifthen}

% To handle key=value options in class definition
\RequirePackage{kvoptions}
\SetupKeyvalOptions{%
    prefix=invoicecls@
}

% Default currency option is "dollar"
\DeclareStringOption[dollar]{currency}[dollar]
\ProcessKeyvalOptions*

\RequirePackage{eurosym}

% Customizing lists
\RequirePackage{enumitem}

\ifthenelse{\equal{\invoicecls@currency}{dollar}}{\newcommand{\currencysym}{\$}}{}
\ifthenelse{\equal{\invoicecls@currency}{euro}}{\newcommand{\currencysym}{\euro}}{}
\ifthenelse{\equal{\invoicecls@currency}{pound}}{\newcommand{\currencysym}{\textsterling}}{}

% Set the standard geometry
\RequirePackage[hmargin=.75in,vmargin=1in]{geometry}

% For links and metadata
\RequirePackage[hidelinks]{hyperref}

% For adjusting letter spacing
\RequirePackage{soul}

% For "At*" hooks
\RequirePackage{etoolbox}

% For adjusting footer
\RequirePackage{fancyhdr}

% For tables
\RequirePackage{tabularx}
\RequirePackage{multicol}

% Dates
\RequirePackage{advdate}
\RequirePackage[en-US]{datetime2}

% Localization
\RequirePackage[english]{babel}

% Phone numbers formatting
\RequirePackage{phonenumbers}

% For invoice math
\RequirePackage{fp}
\RequirePackage{tikz}

% Formatting numbers
\RequirePackage{siunitx}
\sisetup{round-integer-to-decimal, group-separator={,}}

\RequirePackage{fontspec}

\defaultfontfeatures{
    Ligatures = TeX,
    Path      = ./Fonts/ }

\IfFileExists{./Fonts/OpenSans-Regular.ttf}{
    \setmainfont[ BoldFont = OpenSans-Bold, ItalicFont = OpenSans-Italic ]{OpenSans-Regular}
    \setsansfont[ BoldFont = OpenSans-Bold, ItalicFont = OpenSans-Italic ]{OpenSans-Regular}
}{}

%%%%% Commands %%%%%

\newcommand*{\setmetadata}[2]{
    \hypersetup{
        bookmarksopen  = false,
        bookmarksdepth = 2,% to show sections and subsections
        pdfauthor      = {#1},
        pdftitle       = {Invoice \##2},
        pdfsubject     = {Invoice \##2},
        pdfkeywords    = {invoice, #2, #1}
    }
}

\newcommand*{\twocolumnlayout}[2]{
    #1 \hfill #2
}

\sodef\invoiceSpacing{}{.15em}{.4em}{.4em}
\newcommand*{\makeheader}[2]{
    \begin{minipage}[t]{.6\linewidth} {\headerStyle #1} \end{minipage}
    \hfill
    \begin{tabular}[t]{@{} c @{}}
        {\headerStyle \invoiceSpacing{INVOICE} \##2} \smallskip \\
        {\today} \\
        {\small due \duedate{\duein}}
    \end{tabular}

    \addvspace{8ex}
}

\newcommand*{\duedate}[1]{%
    \SaveDate
    \AdvMonth{#1}
    \DTMsavedate{mydate}{\the\year-\the\month-\the\day}%
    \DTMusedate{mydate}%
    \SetDate%
}

\newcommand*{\dateNoDay}[1]{%
    \DTMsavedate{mydate}{#1}
    \DTMlangsetup{showdayofmonth=false}
    \DTMusedate{mydate}
    \DTMlangsetup{showdayofmonth=true}
}

\newcommand*{\infoSectionStyle}{\hspace{2em}}
\newcommand*{\infoSubStyle}{\small}

\newenvironment*{infoSection}[1]{\tabular[t]{l}\titleStyle{#1:}\\}{\endtabular}
\newenvironment*{footerSection}[1]{\tabular[t]{l}\footerTitleStyle{#1:}\\}{\endtabular}
\newcommand{\sectionItem}[1]{#1 \\}

\newcommand{\emaillink}[1]{%
    \href{mailto:#1}{#1}%
}

\newcommand*{\itemizationRowStyle}[0]{\small}
\newcommand*{\itemizationHeaderStyle}[0]{\normalsize}
\newcounter{colskipcount}

\newenvironment{hoursItemization}
  {   \setcounter{colskipcount}{4}
      \tabularx{\textwidth}{c X c r r}
      \hline
      \noalign{\smallskip}
      {\itemizationHeaderStyle Date} &
      {\itemizationHeaderStyle Description} &
      {\itemizationHeaderStyle Hours} &
      {\itemizationHeaderStyle Rate}  &
      {\itemizationHeaderStyle Amount} \\
      \hline
      \noalign{\bigskip}
  }
  {\endtabularx}

\newenvironment{contactIconItemization}{\tabular[t]{@{}c@{}@{}l@{}}}{\endtabular}
\newcommand{\contactIconItem}[2]{#1 & \hspace{8pt}\small#2\\}

\gdef\InvoiceTotal{0}

\newcommand*{\calcamount}[2]{%
    \FPmul\t{#1}{#2}%
    \formatcurrency{\t}%
    % TabularX runs the body multiple times https://tex.stackexchange.com/a/227155
    % Since InvoiceTotal is a global variable it'd count those runs as well.
    % Check if it's the final run. This seems hacky, but keeping it until a better soultion if found.
    \ifx\@tempdima\hfuzz%
    \else%
        \FPadd\gt{\InvoiceTotal}{\t}%
        \global\let\InvoiceTotal\gt%
    \fi%
}

\newcommand*\@formatFraction[1]{
    \ifnum\Numerator=25 ¼\fi%
    \ifnum\Numerator=50 ½\fi%
    \ifnum\Numerator=75 ¾\fi%
}

\newcommand*\@formatHoursLeft[1]{
    \pgfmathtruncatemacro{\WholePortion}{int(#1)}%
    \pgfmathtruncatemacro{\Numerator}{100*(#1-\WholePortion)}%
    \ifnum\WholePortion=0%
        \@formatFraction{\Numerator}%
    \else%
        \WholePortion%
    \fi%
}

\newcommand*\@formatHoursRight[1]{
    \pgfmathtruncatemacro{\WholePortion}{int(#1)}%
    \pgfmathtruncatemacro{\Numerator}{100*(#1-\WholePortion)}%
    \ifnum\WholePortion=0%
    \else%
        \@formatFraction{\Numerator}%
    \fi%
}

\newcommand{\lineitem}[5]{  %{Date}{Hours}{Rate}{Description}
    {\itemizationRowStyle \dateNoDay{#1}} &
    \begin{minipage}[t]{.6\textwidth}
        {\itemizationRowStyle #4}%
        \ifblank{#5}%
        {%
           % Empty
        }{%
           \begin{itemize}[leftmargin=5pt, labelsep=2pt, itemsep=0pt] \itemizationRowStyle #5 \end{itemize}%
        }%
    \end{minipage} &
    {\itemizationRowStyle \@formatHoursLeft{#2}}{\itemizationRowStyle \@formatHoursRight{#2}} &
    {\itemizationRowStyle \currencysym#3} &
    {\itemizationRowStyle \currencysym\calcamount{#2}{#3}}
    \\
    \noalign{\bigskip}
}

\newcommand{\beginsummary}{
    \noalign{\bigskip}
    \hline
    \noalign{\medskip}
}

\newcommand*{\summaryline}[2]{
    \multicolumn{\thecolskipcount}{r}{\itemizationHeaderStyle #1} & #2 \\
}

\newcommand*{\formatcurrency}[1]{%
    \num[group-separator={,}, group-minimum-digits=3, round-mode=places, round-precision=2]{#1}%
}

% Implementation by Werner (http://tex.stackexchange.com/a/176815/35707)
\newcommand*{\dectofrac}[1]{\begingroup%
  \pgfkeys{/pgf/number format/frac}% Format as fraction
  \let\frac\sfrac% Let \frac act like \sfrac
  \pgfmathprintnumber{#1}\endgroup}

% Debugging
\newcommand{\showbb}[1]{{\color{red!50}\leavevmode\rlap{\fbox{\phantom{#1}}}}#1}

%%%%% Styles %%%%%
\def\headerStyle{\Huge}
\def\titleStyle{\large\bf}
\def\footerTitleStyle{\small\bf}

% Add page numbers
\fancypagestyle{plain}{
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
  \fancyhf{}}
% page numbers in footer if more than 1 page
% Copied from moderncv
\AtEndPreamble{%
    \AtBeginDocument{%
        \@ifundefined{r@lastpage}{}{%
            \ifthenelse{\pageref{lastpage}>1}{%
                \newlength{\pagenumberwidth}%
                \settowidth{\pagenumberwidth}{\thepage/\pageref{lastpage}}%
                \fancypagestyle{plain}{%
                    \fancyfoot[r]{\parbox[b]{\pagenumberwidth}{\thepage/\pageref{lastpage}}}%
                }%
                \pagestyle{plain}%
            }{}%
        }%
        \AtEndDocument{\label{lastpage}}%
    }%
}
\pagestyle{plain}

% Disable paragraph indent
\setlength{\parindent}{0pt}
