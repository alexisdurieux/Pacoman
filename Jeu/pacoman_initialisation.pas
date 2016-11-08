unit pacoman_initialisation;

interface

uses pacoman_util, DateUtils, SysUtils, pacoman_file;

var 
	statuts : array[1..MAX_MONSTRES] of statutMonstre;
	directionInitialePrison:direction;

procedure pacInit ( var pac : pacoman; var N : TDateTime; var plat : plateau);
procedure monstresInit(plat:plateau;var tabM : tableauMonstre; nomNiveau : string; var k : integer);

implementation

procedure pacInit ( var pac : pacoman; var N : TDateTime; var plat : plateau);
//Cette procédure gère l'initialisation de l'enregistrement pacman
var i,j:Integer;

	begin
	//Choisie des coordonnées aléatoires dans la carte qui sont différentes d'un mur, d'un switch ou de la prison
		randomize;
		repeat
		i:= random(tailleMapX)+1;
		j:= random(tailleMapY)+1;
		until ((plat[i,j]<>mur) and (plat[i,j]<>switch) and (plat[i,j]<>prison));

		plat[i, j] := vide; //vide la case où le pacoman va être crée
		pac.x:=i; //affecte les coordonnées au pacoman
		pac.y:=j;
		pac.temps.turbo := 0;//mise à zéro des bonus
		pac.temps.ral := 0;
		pac.statut := vivant; //affection du statut
		pac.bouclier := BOUCLIER_MAX; //affection d'un nombre de vie
		N := Now; 
		pac.temps.date := MilliSecondOfTheHour(N); //affectation à pac.date la valeur de la date actuelle
		pac.dirOri := droite; //affectation d'une direction initiale
	end;
	
procedure monstresInit(plat:plateau ; var tabM : tableauMonstre; nomNiveau : string; var k : integer);
//Cette procédure sert à initialiser le tableau de montres 
	var
	niv : array[1..2] of integer;
	f : text;
	i, j:integer;
	c : char;
	temp : string;
	
	begin
	//initialisation des variables locales
		k := 1;
		i := 1;
		j := 1;
		temp := '';
		directionInitialePrison:=integerToDirection(chercheDirectionLibre(plat,xPrison,yPrison)); //sert à trouver la direction de sortie de la prison selon la carte
		nomNiveau := nomNiveau + '.txt';
	//lecture du fichier niveau
		assign(f, nomNiveau);
		reset(f); //ici on a une simple lecture du fichier
		while (not eof(f)) do 
		begin
			read(f,c); //lecture d'un caractère
			case c of 
				' ' : //si le caractère est un espace alors temp contient un paramètre (niv[1] est le statut et niv[2] est la vitesse)
					begin
						val(temp,niv[i]); 
						i := i + 1; //Changement de paramètre
						temp := ''; //vide temp pour pouvoir lire le deuxième paramètre
					end;
					
				'#' : //on se trouve maintenant à la fin de la ligne (une ligne correspond à un monstre) et on execute l'initialisation d'un monstre
					begin
						tabM[j].statut := integerToStatutMonstre(niv[1]); //affectation du statut
						statuts[j] := tabM[j].statut; //enregistrement du statut pour la durée de la boucle jeu (utilité pour bonus d'invincibilité)
						tabM[j].direction:=directionInitialePrison; //affectation direction
						tabM[j].vitesse := niv[2]/10;  //affectation vitesse
						tabM[j].x := xPrison;//position du monstre en prison
						tabM[j].y := yPrison;
						tabM[j].compteur := 0; 
						j := j + 1; //on itère le numéro de la ligne de 1
						i := 1; //initialisation de i pour la prochaine ligne (lecture du premier paramètre)
						readln(f); //changement de ligne
					end;
				else
					temp := temp + c; //ajout d'un caractère la chaîne de caractère
			end;
		end;
		close(f);	
	end;
	



end.
