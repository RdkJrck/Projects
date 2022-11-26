Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
Autor prace : Radek Juracek
Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
Datum odevzdani : DOPLNIT
Ustav : Ustav biomedicinského inženyrstvi
Fakulta : Fakulta elektrotechniky a kominikacnich technologii
Vysoke uceni technicke v Brne

1 . datasets.zip - slozka obsahujici snimky a gt, nutno rozbalit

2 .Hlavní skript:
Main.m -  Výběr metody a datesetu proveď odstranením komentáře

3. ShowResultsAndWriteMetrics.m - Script který provede vykreslení výsledků všech metod ze všech datasetů
			 společně s upravou výstupů práce.

4. Výsledné snímky segmentace najdete v složce results\*nazev datasetu*\segmented_images\

Pomocné funkce :
InitProject.m - Funkce incializující configuraci projektu
PreprocessData.m - Funkce provede předzpracování dat

Funkce segmentace:
BatAlgoMethod.m - funkce provede segmentaci pomoci netopýřiho algoritmu
RegionGrowMethod.m - funkce provede segmentaci pomoci narůstání oblasti
HoughCircle.m - funkce provede segmentaci pomoci Houghovi transformace
MaxLinRotHoughCircle.m - funkce provede segmentaci maskování krevního řečiště rotujícím lineárním operátor provede Houghovu transformaci
TresholdMorphedMethod.m - funkce provede segmentaci pomoci prahování

ShowResults.m - zobrazí výsledky trenovací fáze a segmentace

Matlab class:
UtilsClass.m - Matlab class obsahující funkce konverze parametrického prostoru
LoggerClass.m - Matlab class obsahující funkce čteni a zapisu vysledků

Složka results:
- Struktura do ktere jsou zapisovany GT, predzpracovane snimky a vysledky trenovaci i testovaci faze dle dataset

Implementovaný postup využívá funkci: FitEllipse.m převzatou z:

Ohad Gal (2022). fit_ellipse (https://www.mathworks.com/matlabcentral/fileexchange/3215-fit_ellipse), 
MATLAB Central File Exchange. Retrieved May 22, 2022.

