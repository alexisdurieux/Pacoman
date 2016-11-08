unit pacoman_util;

interface

uses crt, fmodtypes;
	//Définition des constantes, il faudra utiliser un pointeur à terme car ça c'est valable que pour une seule carte
	const
		MAX_X = 50; //Taille maximum en abscisse
		MAX_Y = 50;	//Taille maximum en ordonnée
		MAX_MONSTRES = 5; //Nombre maximum de monstres
		BOUCLIER_MAX = 3; //Nombre initial de vies
		SCORE_INIT = 0; //Score initial
		bTurboMax = 40; //Nombre de déplacement durant lequel le turbo a lieu
		bRalentisseurMax = 30; //Nombre de déplacements durant lequel le ralentissement a lieu
		VITESSEDEPLACEMENT = 200; //Facteur de vitesse

	type 
	//Statuts

	//Ici on définit les types de données primordiaux au bon fonctionnement de notre programme
	statutPacman = (vivant, mort, invincible); //Les différents statuts possibles du pacman
	statutMonstre = (agressif, aleatoire, fuite, retourPrison, semiAgressif, devine, demarque, compAleatoire); //Les différents comportements
	direction = (haut, bas, gauche, droite); //Les différentes directions
	
	//Enregistrement des différentes variables relatives aux "timers", c'est à dire les bonus
	timer = Record
		date : TDateTime;
		turbo : integer;
		ral : integer;
	end;
	
	//Enregistrement du Pacoman, contient toutes les informations essentielles relatives à celui-ci
	pacoman = Record
		bouclier : Integer;
		statut : statutPacman;
		score : integer;
		x : Integer;
		y : Integer;
		dirOri : direction;
		dirKeyboard : direction;
		temps : timer;
		BTurbo : Boolean; // sert à savoir si la touche A est activé
		BRal :Boolean; // sert à savoir si la touche Z est activé
	end;

	//Enregistrement de monstre, contient toutes les informations relatives à celui-ci.
	monstre = Record
		statut : statutMonstre;
		etatAleatoire:Integer;
		x : Integer;
		y : Integer;
		direction: direction;
		date : TDateTime;
		vitesse : real;
		compteur : integer;	
	end;
	
	//Enregistrement contenant tous les fichiers musicaux
	musiques = record
		slowMonstre : PFSoundSample;
		invincible : PFSoundSample;
		boostPacman : PFSoundSample;
		musiqueMangeBonus : PFSoundSample;
		musiqueMangeMonstre : PFSoundSample;
		musiqueFin : PFSoundSample;
		musiqueDebut : PFSoundSample;
		blop : PFSoundSample;
		slap : PFSoundSample;
		win : PFSoundSample;
		switch : PFSoundSample;
	end;
	

	

	decort = (mur, vide, tacos, prison, switch, bInvincible,bTurbo,bRalentisseur,fin); //Tous les différents types de décors possibles
	plateau = array[1..MAX_X, 1..MAX_Y] of decort; //Définit le plateau comme un tableau de décors
	tableauMonstre = array[1..MAX_MONSTRES] of monstre; //ON définit un tableau de monstre de 1 à MAX_MONSTRE. Dans chaque case du tableau, il y a un enregistrement de monstre.

	function charToDecort(c : char) : decort;
	function directionToDecort(plat:plateau; direction: direction; x1, y1:Integer) : decort;
	function integerToDirection(i : integer) : direction;
	function integerToStatutMonstre(i : integer) : statutMonstre;
	function chercheDirectionLibre(plat:plateau;x,y:integer):integer;
	
implementation

	function charToDecort(c : char) : decort; //Renvoie le type de décort correspondant à la lettre. Il faudra rajouter une lettre pour monstre éventuellement si l'on veut enregistrer
	var
		temp : decort;
	begin
		case c of 
			'v' : temp := vide;
			'm' : temp := mur;
			't' : temp := tacos;
			'j' : temp := prison;
			's' : temp := switch;
			'u' : temp := switch;
			'w' : temp := switch;
			'z' : temp := switch;
			'y' : temp := switch;
			'i' : temp := bInvincible;
			'a' : temp := bTurbo;
			'b' : temp := bRalentisseur;
			'#' : temp := fin;
			end;
		charToDecort := temp;
	end;

	//Renvoie le décor de la case pointée par la direction
	function directionToDecort(plat:plateau;direction:direction;x1:Integer;y1:Integer):decort;
	var 
		x2, y2 :Integer;
	begin
		if (direction = gauche) then
		begin
			x2:=x1-1;
			y2:=y1;
		end;
	
		if (direction = bas) then
		begin
			x2:=x1;
			y2:=y1+1;
		end;
		
		if (direction = droite) then
		begin
			x2:=x1+1;
			y2:=y1;
		end;
		
		if (direction = haut) then
		begin
			x2:=x1;
			y2:=y1-1;
		end;
		
		directionToDecort:=plat[x2,y2];
	
	end;

	//Renvoie la direction correspondant à l'entier. Cette fonction permet de passer des résultats utilisés pour l'IA à l'affichage.
	//En effet nous avons créé cette fonction pour répondre au fait que il était plus pratique dans certains cas de parler de direction en tant que type parfois et en tant qu'entier d'autres fois
	function integerToDirection(i : integer) : direction;
	begin
		case i of 
		1 : integerToDirection := gauche;
		2 : integerToDirection := bas;
		3 : integerToDirection := droite;
		4 : integerToDirection := haut;
		end;
	end;

	//Renvoie le comportement correspondant à l'entier lu dans le fichier texte.
	function integerToStatutMonstre(i : integer) : statutMonstre;
	begin
		case i of 
		1 : integerToStatutMonstre := semiAgressif;
		2 : integerToStatutMonstre := aleatoire;
		3 : integerToStatutMonstre := demarque;
		4 : integerToStatutMonstre := devine;
		5 : integerToStatutMonstre := agressif;
		6 : integerToStatutMonstre := compAleatoire
		end;
	end;
//cette fonction cherche une direction libre lorsque le monstre est sur un croisement.
function chercheDirectionLibre(plat:plateau;x,y:integer):integer;
var
	directionLibre:integer;
begin
			if plat[x-1,y]<>mur then  directionLibre:=1;  //1 = gauche
			if plat[x,y+1]<>mur then  directionLibre:=2;  //2 = bas
			if plat[x+1,y]<>mur then	directionLibre:=3;  //3 = droite
			if plat[x,y-1]<>mur then 	directionLibre:=4;  //4 = haut

	chercheDirectionLibre:=directionLibre;
end;

end.
