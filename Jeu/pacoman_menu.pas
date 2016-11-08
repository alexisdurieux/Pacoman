unit pacoman_menu;

interface

uses pacoman_file, pacoman_util, pacoman_affichage, pacoman_jeu, pacoman_initialisation,pacoman_analyse,pacoman_IA,DateUtils, SysUtils, crt;	
	const 
		MAX_TOP_SCORES = 5; //On définit le nombre maximal de scores présent dans notre classement des meilleurs scores.
		MAX_NIVEAUX = 5; //On définit le nombre maximal de niveaux.
	
	var 
	fin : boolean; 
	pac : pacoman;
	plat : plateau;
	carte, niveau : string;
	NPacoman, NMonstres, Nori, NBonus : TDateTime;
	tabM : TableauMonstre;
	k, nbTacos : integer;

	procedure menu();
	procedure menu_jeu();
	procedure finPartie();
	procedure topScores();
	procedure actualisationTopScores();
	procedure histoire();
	procedure entrainement();
	procedure jeu(niveau : string; map : string);


implementation

procedure menu(); //Affiche le menu.
	var
		i : Integer;
	begin
		Clrscr;
		Window(25 ,5 ,50 ,20);
		writeln('Bienvenue dans le PACOMAN');
		writeln('Jeu developpe avec amour par :');
		writeln('Adrien DUFRAUX');
		writeln('Alexis DURIEUX');
		writeln('David LAMIDEL');
		writeln();
		
		writeln('1 : Jouer !');
		writeln('2 : Meilleurs scores');
		writeln('3 : Quitter le programme');

		repeat
			readln(i);	
		until ((i=1) or (i=2) or (i=3)); //Condition afin que l'utilisateur rentre un des choix proposés.

		case i of
			1 : menu_jeu();		//Appelle le menu du jeu.
			2 : topScores();	//Appelle la procédure affichant les meilleurs scores.
		end;
		
	end;


procedure menu_jeu(); //Affiche le menu permettant de choisir son mode jeu : Histoire ou Entrainement
	var
		i: Integer;
	begin
		ClrScr; //Efface l'écran. 

		writeln('Mode de menu_jeu: ');
		writeln('1 : Histoire');
		writeln('2 : Entrainement');
		writeln('3 : Retour au menu');

		repeat
			readln(i);
		until ((i=1) or (i=2) or (i=3));

		case i of 
			1 : histoire(); //Lance le mode histoire.
			2 : entrainement(); //Lance le mode entraînement
			3 : menu();	//Revient au menu principal
		end;

		Window(1 ,1 ,80 ,25); //On revient à une fenêtre normale de terminal.
		clrscr;
	end;

procedure topScores();
//Cette procédure gère l'affichage des meilleurs scores et du sous-menu correspondant
	var
		f : text;
		score, ligne : string;
		i, longueur, choix : integer;
	begin
	//initialisation variable locale
		i := 1; //variable qui sert à compter le numéro de la ligne (utilité dans l'affichage du classement)
	//affichage	
		Clrscr;//permet d'effacer l'affichage précédent (menu principal)
		Window(25 ,5 ,55 ,20);//créer une fenêtre dans le terminal
		writeln ('Meilleurs Scores du Pacoman:');
		writeln();
	//chargement du fichier meilleurs scores et affichage dans le terminal
		assign (f, 'meilleurScores.txt');
		reset (f); //car lecture du fichier
		while not (eof(f)) do
		begin
			readln (f, score); //lecture d'une ligne
			longueur := length(score); //recupère la longueur de la chaîne de caractères
			delete(score,longueur,1); //suppression du '#' à la fin de la ligne
			writeln (i,'. ',score,' points'); //écriture dans le terminal
			i := i + 1; //itération qui indique une changement de ligne
		end;
		close(f);
	//création d'un menu
		writeln();
		writeln('1. Effacer les meilleurs scores');
		writeln('0 : Retour au menu');
		readln(choix); //récupération du choix de l'utilisateur
	//séquence à exécuter selon le choix
		case choix of
			1 : //reset des meilleurs scores
				begin
					assign(f, 'meilleurScores.txt');
					rewrite(f); //ici, j'écrase les données présentes pour créer un nouveau texte
					ligne := 'Nom 0#'; //valeur par défaut d'une ligne
					for i := 1 to MAX_TOP_SCORES do //j'itère un certain nombre de fois selon le nombre de meilleurs scores
						writeln (f, ligne); //j'écris une ligne dans le fichier
					close(f);
					topScores(); //j'appelle topScores pour retourner dans le même sous menu
				end; 
			0 : menu(); //appel de menu
		end;
	end;


procedure histoire();
	var
		niveau, map, tmp : string;
		i : integer;

	begin

		fin := false; //On affecte à la variable booléenne fin la valeur false. Le jeu s'arrête quand cette variable globale passe à true. 
		niveau := 'niveau'; //On initialise les variables niveau et map
		map := 'map';
		i := 0; //Au début i = 0
		pac.score := 0;
		repeat 
			{
			Ce code permet d'utiliser successivement les fichiers textes correspondant aux cartes et informations de niveau de chaque niveau 
			en itérant i jusqu'au niveau max (5) et en l'utilisant à chaque fois dans le string permettant de lire les fichiers correspondants
			}
			delete(map, 4, 1); //On supprime à chaque fois le dernier caractère du string map à savoir le chiffre 
			delete(niveau, 7, 1); //Même principe pour niveau
			i:= i+1; //On itère i après avoir suppimé le dernier caractère des strings précédent et avant de concaténer.
			str(i, tmp); //On met dans tmp la valeur de i en tant que string afin de pouvoir concaténer avec les strings map et niveau.
			map := map + tmp; //On concatène afin d'avoir un nom de fichier correspondant à 'map' + i (map1, map2, map3...).
			niveau := niveau + tmp; //Même principe que précedemment.
			jeu(niveau, map); //Appelle la procédure jeu.
		until ((i = MAX_NIVEAUX) or (fin = true)); //On arrête le jeu dès que i = 5 c'est à dire dès que l'on a fini le mode histoire (composé de 5 niveaux) ou quand fin = true (Cette variable globale passe à true dans la procédure jeu() quand p.bouclier = 0 c'est à dire quand l'on a plus de vies).
		finPartie(); //Appelle la procédure fin de partie.
	end;
	
procedure finPartie();
//Cette procédure gère un menu à la fin d'une partie
	var 
		choix : integer;
	
	begin
		ClrScr;
		Window(25 ,5 ,55 ,20);

		TextColor(white);
		actualisationTopScores(); 
		writeln ('1. Nouvelle partie');
		writeln ('2. Retour au menu');
		writeln ('3. Quitter le jeu');
		readln(choix);
		case choix of
			1 : menu_jeu(); //lancement du jeu
			2 : menu(); //retour au menu
		end;
	end;
	
procedure actualisationTopScores();
//Cette procédure est appelée à la fin d'un partie et sert à integrer le score du joueur si il rentre dans le classment des meilleurs scores
	var
		score : array[1..(MAX_TOP_SCORES+1)] of integer;
		nom : array[1..(MAX_TOP_SCORES+1)] of string;
		f : text;
		c : char;
		temp, nomJoueur, ligne : string;
		i : integer;
		 
	begin
	//affichage
		Clrscr;
		Window(25 ,5 ,55 ,20);
		writeln('Votre score est de ',pac.score); //donne le score du joueuer à lafin de la partie
		writeln();
	//initialisation des variables locales
		temp := ''; //contient un morceau de ligne
		i := 1; //contient le numéro de la ligne
	//chargement du fichier meilleurs scores dans des tableaux
		assign (f, 'meilleurScores.txt');
		reset (f); //ici simple lecture du fichier
			while not (eof(f)) do
			begin
				read (f,c); //lecture d'un caractère
				case c of
					' ': //si le caractère lu est un espace alors le nom du joueur i se trouve dans la variable temp
						begin
							nom[i] := temp; //affecte le nom du joueur i dans le tableau nom
							temp := ''; //vide la variable temp
						end;
					'#': //si le caractère lu est un # alors la variable temp contient le score du joueur i
						begin
							val(temp,score[i]); //affecte le score du joueur i dans le tableau score en transformant la chaîne de caractère en integer
							readln(f); //changement de ligne 
							i := i + 1; //itération du numéro de la ligne
							temp := ''; //vide la variable temp
						end;
				else 
					temp := temp + c; //ajout du caractère à ceux déjà ajoutés pour former une chaîne de caractère
				end;
			end;
		close(f);
	//demande du nom du joueur
		if pac.score > score[MAX_TOP_SCORES] then //il faut que le joueur ait au moins fait un score supérieur au dernier meilleur score
			begin
				writeln('Nouveau meilleur score !');
				write('Entrez votre nom: ');
				read(nomJoueur);
			end;
	//insertion d'une valeur (score du joueur) dans un tableau trié 
		for i := MAX_TOP_SCORES downto 1 do //on effectue le tri par le bas du tableau 
			if pac.score > score[i] then //il faut que le score du joueur soit supérieur au 4 ème socre par exemple
			begin
				score[i+1] := score[i]; //décalage de la valeur du tableau d'un rang (de la 4ème place à la 5ème dans l'exemple)
				nom[i+1] := nom[i];
				score[i] := pac.score; //insertion du score du joueur (à la 4éme place dans l'exemple)
				nom[i] := nomJoueur;
			end;
	//écriture des nouveaux tableaux dans le fichier
		temp := '';
		assign (f, 'meilleurScores.txt');
		rewrite (f); //ici on écrase les données et on écrit un nouveau texte dans le fichier
		for i := 1 to MAX_TOP_SCORES do
			begin
				str(score[i], temp); //car score est un integer et que l'on écrit dans un fichier text
				ligne := nom[i] + ' ' + temp + '#'; //affectation d'une ligne 
				writeln (f,ligne);//écriture de la ligne dans le fichier
				temp := ''; //vide la variable
			end;
		close(f);
		//pac.score := 0;
	end;

//Même principe que histoire sauf qu'on ne répète pas jeu. Pas besoin d'une variable fin
//ON choisit seulement un niveau et une carte.
procedure entrainement();

	var
		niveau, map, tmp: string;

	begin
		niveau := 'niveau';
		map := 'map';
		pac.score := 0;

		writeln('Sur quelle map voulez vous jouez ? Entrez un numero de 1 a 5.');
		readln(tmp);
		map := map + tmp;
		writeln(map);
		writeln('Quel difficulte ? Entrez un numero de 1 a 5.');
		Readln(tmp);
		niveau := niveau + tmp;
		writeln(niveau);
		jeu(niveau, map);
		finPartie();
	end;

procedure jeu(niveau : string; map : string);
	begin
		window(1,1,85,25);
		clrscr;
		k := 1;
		nbTacos := 0;
		chargementMap(plat, map, nbTacos); //Chargement du fichier texte dans la variable globale plat
		analyserLaMap(plat); //analyse de la map pour l'IA
		pacInit (pac, NPacoman, plat); //Initialisation des données liées au pacoman
		MonstresInit(plat,tabM, niveau, k);
		initialise(); //Appelle la fonction initialise qui permet d'initialiser le clavier (utilisation de l'unit keyboard)
		affichage(plat);
		NOri := Now();
		repeat
		deplacementPacman(plat, pac, NPacoman, NBonus, tabM, nbTacos); //Appelle le déplacement pacman.
		deplacementMonstres(plat, pac, tabM, NMonstres, Nori, k, NBonus, nbTacos);	
		until (pac.bouclier <=  0) or (nbTacos <= 0);
		if (pac.bouclier <= 0) then fin := true;
		termine(pac);
	end;

end.
