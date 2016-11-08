unit pacoman_IA;

interface

uses pacoman_analyse,pacoman_util,pacoman_file;


function comportementAgressif(plat:plateau;directionInitial:direction;x1,y1, x2, y2:Integer): direction;
function comportementAleatoire(plat:plateau;directionInitial:direction;x1,y1:Integer): direction;
function comportementFuite(plat:plateau;directionInitial:direction;x1,y1,x2,y2:Integer):direction;
function comportementRentrerALaPrison(plat:plateau;directionInitial:direction;x1,y1:Integer):direction;
function comportementDeviner(plat:plateau;directionInitial:direction;x1,y1:Integer):direction;
function comportementSeDemarquer(plat:plateau;tabM:tableauMonstre;directionInitial:direction;x1,y1:Integer):direction;
function comportementSemiAgressif(plat:plateau;directionInitial:direction;x1,y1,x2,y2:Integer;var compteur:Integer):direction;
function comportementComportementAleatoire(plat:plateau;tabM:tableauMonstre;directionInitial:direction;x1,y1,x2,y2:Integer;var compt,a:Integer):direction;

implementation

function directionPourContinuerChemin(plat:plateau; directionInitial:direction; x, y:Integer): direction; // à utiliser quand un monstre n'est pas sur un croisement. Il ne prend pas une décision, il continue sa route. Renvoie une direction numéroté de 1 à 4
var
	directionAPrendre: direction;
begin
// A chaque fois, on prend la direction qui continue le chemin. Il faut donc ne pas aller vers la case d'où on vient.
if directionInitial = gauche then
begin
	if plat[x,y-1] <> mur then directionAPrendre:= haut
		else if plat[x-1,y] <> mur then directionAPrendre:= gauche
		else if plat[x,y+1] <> mur then directionAPrendre:= bas
		else directionAPrendre:= droite;
end;

if directionInitial = bas then
begin
	if plat[x-1,y] <>mur then directionAPrendre:=gauche
		else if plat[x,y+1] <>mur then directionAPrendre:=bas
		else if plat[x+1,y] <>mur then directionAPrendre:=droite
		else directionAPrendre := haut;
end;

if directionInitial = droite then
begin
	if plat[x,y-1] <>mur then directionAPrendre:=haut
		else if plat[x+1,y] <>mur then directionAPrendre:=droite
		else if plat[x,y+1] <>mur then directionAPrendre:=bas
		else directionAPrendre := gauche;
end;

if directionInitial = haut then
begin
	if plat[x-1,y] <> mur then directionAPrendre:=gauche
		else if plat[x,y-1] <>mur then directionAPrendre:=haut
		else if plat[x+1,y] <>mur then directionAPrendre:=droite
		else directionAPrendre := bas;
end;

directionPourContinuerChemin:=directionAPrendre;
end;

function directionAleatoire(plat:plateau; directionInitial:direction;x, y: Integer):direction; //Choisie une direction aléatoirement mais ne retourne pas sur ses pas.
var
	directionANePasPrendre, directionAPrendre: direction;

begin
	case directionInitial of
	gauche : directionANePasPrendre := droite;
	bas : directionANePasPrendre := haut;
	droite : directionANePasPrendre := gauche;
	haut : directionANePasPrendre := bas;
	end;
	randomize;
	Repeat
	directionAPrendre:= integerToDirection(random(4)+1); // Génère un nombre entre 1 et 4, correspondant au numéro de la direction.
	until ((directionAPrendre <> directionANePasPrendre) and (directionToDecort(plat,directionAPrendre,x,y)<>mur)and (directionToDecort(plat,directionAPrendre,x,y)<>prison));// On vérifie qu'on ne va pas vers un mur ou la prison.
	
	directionAleatoire:=directionAPrendre;
	

end;

function directionPourRejoindreCible(plat:plateau;directionInitial:direction;croisementInitial:Integer; x:Integer; y:Integer): direction; // à utiliser quand un monstre est sur un croisement. Il prend une décision. Renvoie une direction numéroté de 1 à 4
var
	croisementARejoindre :Integer;
begin
	if platCroisement[x,y]<>croisementInitial then
	begin
		if platCroisement[x,y]<> 0 then croisementARejoindre:= platCroisement[x,y]; // si la cible est sur un croisement, on cible ce croisement
		if platCroisement[x,y]=0 then 
		begin
			if croisementLePlusProche[x,y,1]<>croisementInitial then croisementARejoindre:=croisementLePlusProche[x,y,1]; // On cible le croisement le plus proche de la cible
			if croisementLePlusProche[x,y,1]=croisementInitial then croisementARejoindre:=croisementLePlusProche[x,y,2]; // si on est déjà sur le croisement le plus proche, on prend l'autre
		end;
		
		directionPourRejoindreCible:= integerToDirection(tabInterCroisement2[croisementInitial,croisementARejoindre,2]);
	end
	else directionPourRejoindreCible:=directionAleatoire(plat,directionInitial,CoordCroisement[croisementInitial,1],coordCroisement[croisementInitial,2]);
end;

function distanceCroisementCible(croisementInitial:Integer;x2:Integer;y2:Integer):Integer; // la fonction calcul la distance entre un croisement et une case.
var
	d1,d2,distanceCaseCroisement1,distanceCaseCroisement2:Integer;
begin
	if platCroisement[x2,y2]<>0 then
		begin
			distanceCaseCroisement1:=0;
			distanceCaseCroisement2:=0;		
		end
		else
		begin
		distanceCaseCroisement1:=infoCases[x2,y2,3];
		distanceCaseCroisement2:=tabInterCroisement2[infoCases[x2,y2,1],infoCases[x2,y2,2],1]-infoCases[x2,y2,3];
		end;
		
	d1:=tabInterCroisement2[croisementInitial,infoCases[x2,y2,1],1]+distanceCaseCroisement1;
	d2:=tabInterCroisement2[croisementInitial,infoCases[x2,y2,2],1]+distanceCaseCroisement2;
		
	if d1<d2 then distanceCroisementCible:=d1
			else distanceCroisementCible:=d2;
	if d1<0 then  distanceCroisementCible:=d2; // dans certaine configuration de map les distances étaient négatives. On corrige le problème. La valeur est fausse mais celà n'arrive pas souvent.
	if d2<0 then  distanceCroisementCible:=d1;
	if ((d1<0) and (d2<0)) then distanceCroisementCible:=1; // Normalement ce cas là n'arrive jamais.Mais c'est pour être sûr de ne pas avoir d'erreur.
end;

function directionPourFuirCible(plat:plateau;directionInitial:direction;croisementInitial:Integer;x:Integer;y:Integer):direction; // on cherche la direction qu'il faut prendre pour s'éloigner de la cible.
var
	distanceCroisementAdjacentAvecCible : Array [1..4,1..2] of Integer;
	i,j,k,d,croisementCible,x2,y2:Integer;
begin
	k:=0;
	for i:=1 to 4 do 
	for j:=1 to 2 do distanceCroisementAdjacentAvecCible[i,j]:=0;
	
	for i:=1 to nbCroisement do
	begin
		if tabInterCroisement1[croisementInitial,i,1]<>0 then
		begin
		k:=k+1;
		distanceCroisementAdjacentAvecCible[k,1]:=i;
		distanceCroisementAdjacentAvecCible[k,2]:=distanceCroisementCible(i,x,y); 
		end;
	end;
	d:=0;
	for i:=1 to 4 do // on cherche quel est le croisement adjacent qui a la plus grande distance avec la cible, on exclue les croisement où on rencontre la cible et aussi la prison;
	begin
		x2:=coordCroisement[i,1];
		y2:=coordCroisement[i,2];
		if ((distanceCroisementAdjacentAvecCible[i,2]>d) and (infoCases[x,y,1]<>i) and (infoCases[x,y,2]<>i) and (plat[x2,y2]<>prison)) then 
		begin
			d:= distanceCroisementAdjacentAvecCible[i,2];
			croisementCible:=distanceCroisementAdjacentAvecCible[i,1];
		end;
	end;
	
	directionPourFuirCible:= integerToDirection(tabInterCroisement2[croisementInitial,croisementCible,2]);
end;

function nombreTacosDansUnCarre(plat:plateau;x,y:Integer):integer; // On compte simplement combien on a de tacos dans un carré de longeur 5.
var
	k,l,d:Integer;

begin
	d:=0;

		for k:=x-2 to x+2 do
		for l:=y-2 to y+2 do
		if plat[k,l]=tacos then d:=d + 1;

	nombreTacosDansUnCarre:=d;
end;

function densiteMonstre(plat:plateau;tabM:tableauMonstre;x,y:Integer):Real; // Cette fonction la densité de monstre sur une case.
var
	i,xMonstre,yMonstre,croisementProche:Integer;
	d:Real;
begin
	d:=0;
	for i:=1 to MAX_MONSTRES do
	begin
		xMonstre:=tabM[i].x;
		yMonstre:=tabM[i].y;
		if ((tabM[i].statut <> retourPrison) and (plat[xMonstre,yMonstre]<>prison)) then // on compte les monstres qui s'ils ne sont pas dans la prison.
		begin
		if platCroisement[xMonstre,yMonstre]=0 then croisementProche:=infoCases[xMonstre,yMonstre,1]// On calcul avec le croisement le plus proche du monstre.
		else croisementProche := platCroisement[xMonstre,yMonstre];		
		d:= d + 1/(distanceCroisementCible(croisementProche,x,y)+1); //le +1 évite de diviser par 0.
		end;
	densiteMonstre:=d; // PLus la valeur est grande plus il y a de monstre qui sont proche de cette case.
	end;
end;

function directionPourDeviner(plat:plateau;directionInitial:direction;x1,y1:Integer):direction; // On regarde où le pacoman a envie d'aller en fonction des tacos qu'il reste sur la map.
var
	i,j,xCible,yCible,croisementInitial,croisementCible,d,dMax:Integer;

begin
	dMax:=0;
	for i:=3 to tailleMapX-3 do // Les "3" évitent d'appeller des valeurs de tableau non définies.
	for j:=3 to tailleMapY-3 do // on regarde pour chaque carré combien on a de tacos.
	if ((plat[i,j]<>mur) and (plat[i,j]<>switch) and (plat[i,j]<>prison)) then
	begin
		d:=nombreTacosDansUnCarre(plat,i,j);
		if d>dMax then
		begin	
			dMax:=d;
			xCible:=i;
			yCible:=j;// on garde les coordonnée du centre du carré où il y a le plus de tacos.
		end;	
	end;
	if platCroisement[xCible,yCible]=0 then // on cible alors le croisement le plus proche de la cible.
	begin
		croisementCible:=infoCases[xCible,yCible,1];
		if infoCases[x1,y1,1]=croisementCible then croisementCible:=infoCases[x1,y1,2]; // si on est déjà sur la case alors on prend l'autre croisement.
	end
	else
	begin
		croisementCible:=platCroisement[xCible,yCible];
		if infoCases[x1,y1,1]=croisementCible then croisementCible:=infoCases[x1,y1,2];
	end;
	
	croisementInitial:=platCroisement[x1,y1];
	directionPourDeviner:=directionPourRejoindreCible(plat,directionInitial,croisementInitial,coordCroisement[croisementCible,1],coordCroisement[croisementCible,2]) ; // on Cible alors le croisement.
end;

function directionPourSeDemarquer(plat:plateau;directionInitial:direction;tabM:tableauMonstre;x1,y1:Integer):direction; // On regarde où les monstres ne sont pas.
var
	i,j,xCible,yCible,croisementInitial,croisementCible:Integer;
	d,dmin:Real;
begin
	dmin:=-1;
	croisementInitial:=platCroisement[x1,y1];
	for i:=1 to tailleMapX do
	for j:=1 to tailleMapY do
	if ((plat[i,j]<>mur) and (plat[i,j]<>switch) and (plat[i,j]<>prison)) then
	begin
		d:=densiteMonstre(plat,tabM,i,j);
		if (d<dmin) or (dmin=-1) then
		begin
			dmin:=d;
			xCible:=i;
			yCible:=j;// On choisie la cible où la densité de monstre y est la plus faible.
		end;
	end;
	if platCroisement[xCible,yCible]=0 then 
	begin
	croisementCible:=infoCases[xCible,yCible,1];
	if infoCases[x1,y1,1]=croisementCible then croisementCible:=infoCases[x1,y1,2];
	end
	else
	begin
	croisementCible:=platCroisement[xCible,yCible];
	end;
	if croisementCible<>croisementInitial then directionPourSeDemarquer:=integerToDirection(tabInterCroisement2[croisementInitial,croisementCible,2])
	else directionPourSeDemarquer:=directionAleatoire(plat,directionInitial,x1,y1);

end;

function comportementAgressif(plat:plateau;directionInitial:direction; x1, y1, x2, y2:Integer): direction; // On poursuit tout le temps une cible.
var
	croisementInitial : integer;
	directionARejoindre: direction;

begin
	if platCroisement[x1,y1]<>0 then // si on est sur un croisement, on prend une décision
	begin
		croisementInitial:=platCroisement[x1,y1];
		directionARejoindre:=directionPourRejoindreCible(plat,directionInitial,croisementInitial,x2,y2);
	end;
	//sinon on continue juste la route.
	if platCroisement[x1,y1]=0 then directionARejoindre := directionPourContinuerChemin(plat,directionInitial,x1,y1);
	
	comportementAgressif:=directionARejoindre;

end;

function comportementAleatoire(plat:plateau; directionInitial: direction;x1, y1: Integer): direction; // le fonctionnement est ensuite toujours le même.
var
	directionARejoindre : direction;

begin
	if platCroisement[x1,y1]<>0 then directionARejoindre:= directionAleatoire(plat, directionInitial,x1,y1);
	if platCroisement[x1,y1]=0 then directionARejoindre := directionPourContinuerChemin(plat,directionInitial,x1,y1);
	
	comportementAleatoire:=directionARejoindre;

end;

function comportementFuite(plat:plateau;directionInitial:direction;x1,y1,x2,y2:Integer):direction;
var
	directionARejoindre:direction;
	croisementInitial:Integer;

begin
	if platCroisement[x1,y1]<>0 then 
	begin
		croisementInitial:=platCroisement[x1,y1];
		directionARejoindre:=directionPourFuirCible(plat,directionInitial,croisementInitial,x2,y2);
	end
	else directionARejoindre:= directionPourContinuerChemin(plat,directionInitial,x1,y1);
	
	comportementFuite:=directionARejoindre;
end;

function comportementRentrerALaPrison(plat:plateau;directionInitial:direction;x1,y1:Integer):direction; // cette fois ci on cible la prison.
var
	directionARejoindre:direction;
	croisementInitial:Integer;

begin
	if platCroisement[x1,y1]<>0 then 
	begin
		croisementInitial:=platCroisement[x1,y1];
		directionARejoindre:=directionPourRejoindreCible(plat,directionInitial,croisementInitial,xPrison,yPrison);
	end
	else directionARejoindre:= directionPourContinuerChemin(plat,directionInitial,x1,y1);
	
	comportementRentrerALaPrison:=directionARejoindre;


end;

function comportementDeviner(plat:plateau;directionInitial:direction;x1,y1:Integer):direction;
var
	directionARejoindre:direction;

begin
	if platCroisement[x1,y1]<>0 then 
	begin
		directionARejoindre:=directionPourDeviner(plat,directionInitial,x1,y1);
	end
	else directionARejoindre:= directionPourContinuerChemin(plat,directionInitial,x1,y1);
	
	comportementDeviner:=directionARejoindre;


end;

function nbMonstresVivant(plat:plateau;tabM:tableauMonstre):Integer;
var
	i,nbMonstres,xMonstre,yMonstre:Integer;
begin
	nbMonstres:=0;
	for i:= 1 to MAX_MONSTRES do
	begin
		xMonstre:=tabM[i].x;
		yMonstre:=tabM[i].y;
		if ((tabM[i].statut <> retourPrison) and (plat[xMonstre,yMonstre]<>prison)) then nbMonstres:=nbMonstres+1;
	end;
	nbMonstresVivant:=nbMonstres;
end;

function comportementSeDemarquer(plat:plateau;tabM:tableauMonstre;directionInitial:direction;x1,y1:Integer):direction;
var
	directionARejoindre:direction;

begin
	if platCroisement[x1,y1]<>0 then 
	begin
		if nbMonstresVivant(plat,tabM)>=3 then // on se démarque seulement quand il y a au moins 3 monstres sur la map. Sinon on prend une direction aléatoire.
		begin
		directionARejoindre:=directionPourSeDemarquer(plat,directionInitial,tabM,x1,y1);
		end
		else
		begin
		directionARejoindre:= directionAleatoire(plat,directionInitial,x1,y1);
		end
	end
	else directionARejoindre:= directionPourContinuerChemin(plat,directionInitial,x1,y1);
	
	comportementSeDemarquer:=directionARejoindre;


end;

function comportementSemiAgressif(plat:plateau;directionInitial:direction;x1,y1,x2,y2:Integer;var compteur:Integer):direction;
// On alterne entre le comportement agressif et le comportement aléatoire avec un compteur qui est dans le record des monstres.
var 
	directionARejoindre:direction;

begin
//on change de comportement tout les 5 croisements traversés.
	if compteur=10 then compteur:=0;
	if compteur<5 then directionARejoindre:=comportementAleatoire(plat,directionInitial,x1,y1)
	else directionARejoindre:=comportementAgressif(plat,directionInitial,x1,y1,x2,y2);
	
	if platCroisement[x1,y1]<>0 then compteur:=compteur+1; // si on traverse un croisement on incrémente le compteur.

	comportementSemiAgressif:=directionARejoindre;
end;

function comportementComportementAleatoire(plat:plateau;tabM:tableauMonstre;directionInitial:direction;x1,y1,x2,y2:Integer;var compt,a:Integer):direction;
// On prend aléatoirement un comportement qui existe déjà.
var
	directionARejoindre:direction;
begin
	a := 2;
	if compt=5 then 
	begin
		compt:=0;
		randomize;
		a:=random(5)+1;
	end;
	case a of
		1:directionARejoindre:=comportementAgressif(plat,directionInitial,x1,y1,x1,y2);
		2:directionARejoindre:=comportementAleatoire(plat,directionInitial,x1,y1);
		3:directionARejoindre:=comportementDeviner(plat,directionInitial,x1,y1);
		4:directionARejoindre:=comportementSeDemarquer(plat,tabM,directionInitial,x1,y1);
		5:directionARejoindre:=comportementFuite(plat,directionInitial,x1,y1,x2,y2);
		end;

	if platCroisement[x1,y1]<>0 then compt:=compt+1;
	
	comportementComportementAleatoire:=directionARejoindre;


end;
end.
