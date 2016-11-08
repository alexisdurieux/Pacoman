unit pacoman_affichage;

interface

uses pacoman_util, pacoman_file, pacoman_jeu, pacoman_IA, Keyboard, DateUtils, SysUtils, crt, SDL2, SDL2_image, SDL2_ttf, fmod, fmodtypes;
	
	procedure initialise();
	procedure termine(p : pacoman);
	procedure affichage(plat : plateau);
	procedure deplacementPacman(var plat : plateau; var p : pacoman; var N : TDateTime; var NBonus : TDateTime; var tabM:TableauMonstre; var nbTacos : integer);
	procedure deplacementMonstres(plat : plateau;var p : pacoman; var tab : TableauMonstre; var N : TDateTime; Nori : TDateTime;var  k : integer; var NBonus : TDateTime; var nbTacos : integer);
	procedure mouvementMonstre(var tab : TableauMonstre; i : integer; plat : plateau;p:pacoman);	
	procedure mouvementPacman(var p : pacoman; plat : plateau);
	procedure ecrireCaractere(i, j : integer; plat : plateau);
	procedure ecrirePacman(p:pacoman);
	procedure ecrireMonstre(m : monstre);

	const  
		//On définit la taille d'un élément de la carte.
		TILEW=30; {largeur en pixel d'un sprite}
		TILEH=30; {hauteur en pixel d'un sprite}

	
	//Ces variables sont globales au sein de l'unité.
	var 
	SURFACEHEIGHT, SURFACEWIDTH : integer; //Taille de la fenêtre.
	window : PSDL_Window; //Type fenêtre en SDL2.
	
	//Ces variables PSDL_Surface sont là pour stocker nos différentes images nécessaires pour l'affichage.
	surfMur, surfTacos, surfFond, surfPrison, surfBonusInvincible, surfBonusRalentir, surfBonusBoost, surfSwitch1,surfSwitch2,surfSwitch3,surfSwitch4,surfSwitch5, surfVie, surfNoir, surfVieTimer : PSDL_Surface; 
	surfPacmanOuvertHaut, surfPacmanOuvertDroite, surfPacmanOuvertBas, surfPacmanOuvertGauche : PSDL_Surface;
	surfPacmanFermeHaut, surfPacmanFermeDroite, surfPacmanFermeBas, surfPacmanFermeGauche : PSDL_Surface;
	surfMonstreAgressif, surfMonstreFuite, surfMonstreDemarque, surfMonstreDevine, surfMonstreSemiAgressif, surfMonstreAleatoire, SurfMonstreComportementAleatoire : PSDL_Surface;

	//Variable de rendu.
	renderer : PSDL_Renderer;

	//Permet de déterminer si le Pacoman a la bouche ouverte pour gérer l'affichage. 
	ouvert : boolean;

	//font contient la police de l'écriture et fontColor la couleur.
	font : PTTF_Font;
	fontColor : TSDL_Color;

	//Record de musiques cf pacoman_utils.
	m : musiques;
	
	
implementation

	//Cette procédure initialise les outils important de notre programme.
	procedure initialise();
    begin
		InitKeyBoard(); //On initialise l'unité keyboard.
		SDL_Init(SDL_INIT_VIDEO); //On initialise la SDL avec le flag SDL_INIT_VIDEO seulement l'audio étant géré par FMOD.
		TTF_Init(); //On initialise TTF (Pour la gestion des écritures).
		FSOUND_Init(44100, 5, 0); //On initialise FMOD avec 5 chanels. 

		//On charge ensuite tous les fichiers audios que l'on va utiliser. 
		m.musiqueDebut := FSOUND_Sample_Load(0, 'sons/pacman_beginning.wav', FSOUND_NORMAL, 0, 0);
		m.blop := FSOUND_Sample_Load(1, 'sons/blop.wav', FSOUND_NORMAL, 0, 0);
		m.musiqueMangeMonstre := FSOUND_Sample_Load(2, 'sons/pacman_eatghost.wav', FSOUND_NORMAL, 0, 0);
		m.musiqueFin := FSOUND_Sample_Load(3, 'sons/pacman_death.wav', FSOUND_NORMAL, 0, 0);
		m.musiqueMangeBonus := FSOUND_Sample_Load(4, 'sons/pacman_bonus.wav', FSOUND_NORMAL, 0, 0);
		m.slowMonstre := FSOUND_Sample_Load(5, 'sons/slowMonstre.wav', FSOUND_NORMAL, 0, 0);
		m.invincible := FSOUND_Sample_Load(6, 'sons/invincible.wav', FSOUND_NORMAL, 0, 0);
		m.boostPacman := FSOUND_Sample_Load(7, 'sons/boostPacman.wav', FSOUND_NORMAL, 0, 0);
		m.slap := FSOUND_Sample_Load(8, 'sons/slap.wav', FSOUND_NORMAL, 0, 0);
		m.win := FSOUND_Sample_Load(9, 'sons/win.wav', FSOUND_NORMAL, 0, 0);
		m.switch := FSOUND_Sample_Load(10, 'sons/switchSon.wav', FSOUND_NORMAL, 0, 0);

		//On règle les volumes respectifs des différents channels.
		FSOUND_SetVolume(0,50);
		FSOUND_SetVolume(1,50);
		FSOUND_SetVolume(2,50);
		FSOUND_SetVolume(3,70);
		FSOUND_SetVolume(4,70);

		//On charge la police dans font et on initialise la couleur d'écriture.
		font := TTF_OpenFont( 'fonts/Mickey.ttf', 40 );
		fontColor.r := 153;  fontColor.g := 0; fontColor.b := 0;

		//On définit la taille de la fenêtre en fonction de la taille de la map.
		SURFACEHEIGHT := (tailleMapY * TILEH);
		SURFACEWIDTH := (tailleMapX * TILEW) + 300;//On rajoute 300 pixels en largeur pour l'affichage des autres informations du jeu.

		//On crée la fenêtre et on initialise le renderer.
		window := SDL_CreateWindow('PACOMAN', SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SURFACEWIDTH, SURFACEHEIGHT, SDL_WINDOW_SHOWN);
		renderer := SDL_CreateRenderer(window, -1, 0);

		//On charge toutes les images que l'on va utiliser.
		surfMur := IMG_Load('images/mur.png');
		surfPacmanFermeGauche := IMG_Load('images/pacmanFermeGauche.png');
		surfPacmanFermeDroite := IMG_Load('images/pacmanFermeDroite.png');
		surfPacmanFermeHaut := IMG_Load('images/pacmanFermeHaut.png');
		surfPacmanFermeBas := IMG_Load('images/pacmanFermeBas.png');
		surfPacmanOuvertGauche := IMG_Load('images/pacmanOuvertGauche.png');
		surfPacmanOuvertDroite := IMG_Load('images/pacmanOuvertDroite.png');
		surfPacmanOuvertHaut := IMG_Load('images/pacmanOuvertHaut.png');
		surfPacmanOuvertBas := IMG_Load('images/pacmanOuvertBas.png');
		surfMonstreAgressif := IMG_Load('images/monstreAgressif.png');
		surfMonstreDemarque := IMG_Load('images/monstreDemarque.png');
		surfMonstreFuite := IMG_Load('images/monstreFuite.png');
		surfMonstreSemiAgressif := IMG_Load('images/monstreSemiAgressif.png');
		surfMonstreDevine := IMG_Load('images/monstreDevine.png');
		surfMonstreAleatoire := IMG_Load('images/monstreAleatoire.png');
		surfMonstreComportementAleatoire := IMG_Load('images/monstreComportementAleatoire.png');
		surfTacos := IMG_Load('images/tacos.png');
		surfFond := IMG_Load('images/fond.png');
		surfPrison := IMG_Load('images/prison.png');
		surfBonusInvincible := IMG_Load('images/bonusInvincible.png');
		surfBonusBoost := IMG_Load('images/bonusBoost.png');
		surfBonusRalentir := IMG_Load('images/bonusRalentir.png');
		surfSwitch1 := IMG_Load('images/switchRouge.png');
		surfSwitch2 := IMG_Load('images/switchBleu.png');
		surfSwitch3 := IMG_Load('images/switchVert.png');
		surfSwitch4 := IMG_Load('images/switchJaune.png');
		surfSwitch5 := IMG_Load('images/switchNoir.png');
		surfVie := IMG_Load('images/vie.png');
		surfNoir := IMG_Load('images/noir.png');	
		surfVieTimer := IMG_Load('images/vieTimer.png');

		//On initialise ouvert à true. (Le pacoman a la bouche ouverte pour commencer)
		ouvert := true;
		Clrscr;
    end;

    //Procédure appelée à la fin de la partie pour fermer les outils utilisés
    procedure termine(p :pacoman); 
    begin
    	{Si on est à la fin de la partie et que l'on a perdu i.e p.bouclier = 0, 
    	alors on joue la musique de fin
    	Sinon on joue la musique de victoire}
    	if p.bouclier <= 0 then 
	    begin
	    	FSOUND_PlaySound(3, m.musiqueFin);
			SDL_Delay(3000);	
	    end
	    else 
	    begin
	    	FSOUND_PlaySound(3, m.win);
			SDL_Delay(3000);	
	    end;

	    //On ferme les outils, et on libère les samples.
    	DoneKeyboard();
    	SDL_DestroyWindow ( window );
    	SDL_DestroyRenderer(renderer);
		SDL_Quit();
		TTF_Quit();
		FSOUND_Sample_Free(m.blop);
		FSOUND_Sample_Free(m.musiqueMangeMonstre);
		FSOUND_Sample_Free(m.musiqueMangeBonus);
		FSOUND_Sample_Free(m.slowMonstre);
		FSOUND_Sample_Free(m.invincible);
		FSOUND_Sample_Free(m.boostPacman);
		FSOUND_Sample_Free(m.slap);
		FSOUND_Sample_Free(m.musiqueDebut);
		FSOUND_Sample_Free(m.musiqueFin);
		FSOUND_Close();	
    end;

    //Affiche le plateau à partir du tableau de decort plat
	procedure affichage(plat : plateau);
	var 
	i, j,k,l : integer;

	//On va inclure dans texture la texture créée à partir de la surface
	texture	: PSDL_Texture;
	//rect permet de définir la surface sur laquelle on va afficher l'image 
	rect : PSDL_Rect;

	begin
		clrScr(); //On efface l'affichage du terminal

		//Affichage des tiles

		{On parcourt tout le tableau de decort pour le remplir de fond (noir)}
		for j:=1 to tailleMapY do
			for i:=1 to tailleMapX do
				begin
					texture := SDL_CreateTextureFromSurface(renderer, surfFond);
					new(rect);					
					rect^.x:=(i-1)*TILEW;
					rect^.y:=(j-1)*TILEH;
					rect^.w:=TILEW;
					rect^.h:=TILEH;
					SDL_RenderCopy(renderer,texture,nil,rect);
					SDL_RenderPresent (renderer);	
				end;

		{On parcourt tout le tableau de décort(plat) à nouveau et en fonction de notre décort
		on charge dans texture la bonne surface à afficher}
		for j:=1 to tailleMapY do 
		begin
			for i:=1 to tailleMapX do
			begin
				case plat[i,j] of 
					mur : texture := SDL_CreateTextureFromSurface(renderer, surfMur); //On crée la texture à partir de la surface
					tacos : texture := SDL_CreateTextureFromSurface(renderer, surfTacos);

					//Gère les différents switchs pour que 2 switchs liés entre eux ait la même image à partir de tabSwitch
					switch :
						begin
							for k:=1 to MAX_PAIRE_SWITCH do
							for l:=1 to 2 do
							begin
								if ((tabSwitch[k,l,1]=i) and (tabSwitch[k,l,2]=j)) then
								begin
									case k of
										1 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch1);
										2 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch2);
										3 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch3);
										4 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch4);
										5 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch5);
									end;
								end;
							end;
						
						
						end;
					bInvincible : texture := SDL_CreateTextureFromSurface(renderer, surfBonusInvincible);	
					bTurbo : texture := SDL_CreateTextureFromSurface(renderer, surfBonusBoost);
					bRalentisseur : texture := SDL_CreateTextureFromSurface(renderer, surfBonusRalentir);
				else
					texture :=  SDL_CreateTextureFromSurface(renderer, surfFond);
				end;

				{Définit la zone d'affichage de la texture on crée un rect de position de coin supérieur gauche ((i-1)*TILEW, (j-1)*TILEH)
				et de hauteur TILEH et de largeur TILEW}
				new(rect);					
				rect^.x:=(i-1)*TILEW; //i-1 car on part de 1 donc la première image aura une abscisse de 0 puis 30(taille d'un tile)
				rect^.y:=(j-1)*TILEH;
				rect^.w:=TILEW;
				rect^.h:=TILEH;
				//On affiche ensuite
				SDL_RenderCopy(renderer,texture,nil,rect);
				SDL_RenderPresent (renderer);		  		
			end;
		end;
		
		//On joue la musique de début du jeu. 
		
		FSOUND_PlaySound(0, m.musiqueDebut);
		SDL_Delay(5000);
		
	end;

	//Gère le déplacement du Pacoman
	procedure deplacementPacman( var plat : plateau; var p : pacoman; var N : TDateTime; var NBonus : TDateTime; var tabM:TableauMonstre; var nbTacos : integer);
	var
		K : TKeyEvent; //Variable correspondant à une touche du clavier
		coeffVitesse:Real;
		texture : PSDL_Texture;
		rect : PSDL_Rect;
		i : integer;
		textSDL : PSDL_Surface;
		sPChar : PChar;
		sString : string;
	begin
		K := PollKeyEvent(); //Regarde si une touche est rentrée si une touche est rentrée K prend une valeur différente de 0, ça permet de ne rien faire si aucune touche n'est rentrée.
		if p.temps.turbo <= 0 then p.Bturbo:=false; //
		if p.temps.ral <= 0 then p.BRal:=false;
		if plat[p.x,p.y]=switch then K:=0;
		if K <> 0 then //Si une touche est pressée
		begin
			K := GetKeyEvent(); //On récupère quelle touche est rentrée
			K := TranslateKeyEvent(K); 
	    	case KeyEventToString(K) of //Transformation de la valeur de la touche en String et on met cette valeur dans dirKeyboard
	    	'Right' : p.dirKeyboard := droite;
	    	'Left'  : p.dirKeyboard := gauche;
	    	'Up'    : p.dirKeyboard := haut;
	    	'Down'  : p.dirKeyboard := bas;
	    	'a'     : // la touche a du bonus est activée
		    	begin
		    		if p.temps.turbo> 0 then
		    		begin
		    		p.BTurbo:= true; //Quand la touche a est enfoncée on active le bonusTurbo et on joue le son correspondant
		    		FSOUND_PlaySound(1, m.boostPacman);
		    		end;
		    	end;
	    	'z'     :  // la touche z du bonus est activée
		    	begin
		    		if p.temps.ral>0 then 
		    		begin
		    		p.BRal:=true; //Quand la touche z est enfoncée on active le bonusRalentissement et on joue le son correspondant
		    		FSOUND_PlaySound(2, m.slowMonstre);
		    		end;
		    	end;
	    	end;
		end;
	    N := Now(); //On récupère la date 
	    
	    //Si la direction dirKeyboard est possible j'affecte dirKeyboard à dirOri
	    case p.dirKeyboard of 
	    droite : if plat[p.x + 1, p.y] <> mur then p.dirOri := p.dirKeyboard;
	    gauche : if plat[p.x - 1, p.y] <> mur then p.dirOri := p.dirKeyboard;
	    haut   : if plat[p.x, p.y - 1] <> mur then p.dirOri := p.dirKeyboard;
	    bas    : if plat[p.x, p.y + 1] <> mur then p.dirOri := p.dirKeyboard;
	    end;

	    //Je compare la date avec la date du dernier déplacement pour savoir si j'effectue un déplacement
	    
	    if p.BTurbo = true then coeffVitesse:=2.5 // on multiplie par deux la vitesse si le bonus est activé.
	    else coeffVitesse:=1;

	    if MilliSecondOfTheHour(N) - p.temps.date >= VITESSEDEPLACEMENT/coeffVitesse then
	    begin
			if p.Bturbo=true then p.temps.turbo:=p.temps.turbo-1; // le turbo est consommé.

	    	p.temps.date := MilliSecondOfTheHour(N); //Si j'effectue un déplacement j'affecte la date du dernier déplacement à maintenant 
	    	//J'effectue les déplacements en fonctions de la directions et du mur. Il faudrait que je ne prenne plus en paramètre le mur mais que tu me le renvoie sous forme d'un boolean david. Sinon il faut uqe je fasse une fonction pour la réécriture afin de clarifier le code
	    	if plat[p.x,p.y]<>switch then ecrirePacman(p);

	    	//Ici on regarde si la case suivante suivant la direction du pacman est un mur. Si ce n'est pas un mur, on appelle mouvementPacman afin d'effectuer un mouvement.
	    	case p.dirOri of
	    		droite: 
	    			if ((plat[p.x + 1, p.y] <> mur) and (plat[p.x + 1, p.y] <> prison)) then mouvementPacman(p, plat);
	    		gauche: 
	    			if ((plat[p.x - 1, p.y] <> mur) and (plat[p.x - 1, p.y] <> prison)) then mouvementPacman(p, plat);
	    		haut:
	    			if ((plat[p.x, p.y - 1] <> mur) and (plat[p.x, p.y - 1] <> prison)) then mouvementPacman(p, plat);
	    		bas: 
	    			if ((plat[p.x, p.y + 1] <> mur) and (plat[p.x, p.y + 1] <> prison)) then mouvementPacman(p, plat);
	    	end;

	    	//On appelle check, voir pacoman_jeu.pas pour le détail : cette fonction gère les évènements de jeu 
	    	check(tabM, plat, p, NBonus, nbTacos, m);

	    	//On regarde si le pacoman a la bouche ouverte ou fermée 
	    	ouvert := not(ouvert);
	    	
	    	// Affichage des vies: on affiche des surfaces noires ensuite on affiche le nombre de coeurs correspondants aux nombres de vies.
	    	for i:= 1 to 3 do 
	    	begin
	    		texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
	    		new(rect);					
				rect^.x:= (tailleMapX*TILEW) + 10 + ((i*TILEW)-TILEW);
				rect^.y:= 20;
				rect^.w:=TILEW;
				rect^.h:=TILEH;
				SDL_RenderCopy(renderer,texture,nil,rect);
				SDL_RenderPresent (renderer);
	    	end;
	    	for i:= 1 to p.bouclier do
	    	begin
	    		texture := SDL_CreateTextureFromSurface(renderer, surfVie);
	    		new(rect);					
				rect^.x:= (tailleMapX*TILEW) + 10 + ((i*TILEW)-TILEW);
				rect^.y:= 20;
				rect^.w:=TILEW;
				rect^.h:=TILEH;
				SDL_RenderCopy(renderer,texture,nil,rect);
				SDL_RenderPresent (renderer);
			end;
			/////////////////////////////////

			//Affichage du score : on affiche une surface noire puis le score
			texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
    		new(rect);					
			rect^.x:= (tailleMapX*TILEW) + 10;
			rect^.y:= 70;
			rect^.w:=200;
			rect^.h:=70;
			SDL_RenderCopy(renderer,texture,nil,rect);
			SDL_RenderPresent (renderer);

			Str(p.score, sString);
			sString := 'Points : ' + sString;
			sPChar := StrAlloc(length(sString) + 1);
			StrPCopy (sPChar,sString);

			textSDL := TTF_RenderText_Solid(font, sPChar , fontColor);
			texture := SDL_CreateTextureFromSurface(renderer, textSDL);
			new(rect);					
			rect^.x:= (tailleMapX*TILEW) + 10;
			rect^.y:= 70;
			rect^.w:=200;
			rect^.h:= 70;
			SDL_RenderCopy(renderer,texture,nil,rect);
			SDL_RenderPresent (renderer);
			//////////////////////////////////

			//Affichage de la jauge du bonus turbo
			if p.temps.turbo <> 0 then //Si on a un bonus turbo alors
			begin //On affiche l'image correspondant au bonus 
			texture := SDL_CreateTextureFromSurface(renderer, surfBonusBoost);
			new(rect);					
			rect^.x:= (tailleMapX*TILEW) + 10;
			rect^.y:= 150;
			rect^.w:=TILEW;
			rect^.h:=TILEH;
			SDL_RenderCopy(renderer,texture,nil,rect);
			SDL_RenderPresent (renderer);
			for i:=1 to round((p.temps.turbo/bTurboMax)*10) do //Ensuite on affiche le nombre jauge en utilisant la proportion de bonus restant
				begin
					texture := SDL_CreateTextureFromSurface(renderer, surfVieTimer);
					new(rect);					
					rect^.x:= (tailleMapX*TILEW) + 15 + TILEW + (i	-1)*10;
					rect^.y:= 160;
					rect^.w:=10;
					rect^.h:=10;
					SDL_RenderCopy(renderer,texture,nil,rect);
					SDL_RenderPresent (renderer);
				end;
			for i:=round((p.temps.turbo/bTurboMax)*10) to 10 do //Après avoir affiché les jauges on affiche du noir pour cacher les jauges utilisées.
				begin
					texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
					new(rect);					
					rect^.x:= (tailleMapX*TILEW) + 15 + TILEW + (i	-1)*10;
					rect^.y:= 160;
					rect^.w:=10;
					rect^.h:=10;
					SDL_RenderCopy(renderer,texture,nil,rect);
					SDL_RenderPresent (renderer);
				end;
			end
			else
			begin //Si j'ai pas de bonus j'affiche du noir
				texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
				new(rect);					
				rect^.x:= (tailleMapX*TILEW) + 10;
				rect^.y:= 150;
				rect^.w:=TILEW;
				rect^.h:=TILEH;
				SDL_RenderCopy(renderer,texture,nil,rect);
				SDL_RenderPresent (renderer);
				for i:=1 to 10 do 
				begin
					texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
					new(rect);					
					rect^.x:= (tailleMapX*TILEW) + 15 + TILEW + (i	-1)*10;
					rect^.y:= 160;
					rect^.w:=10;
					rect^.h:=10;
					SDL_RenderCopy(renderer,texture,nil,rect);
					SDL_RenderPresent (renderer);
				end;
			end;
			///////////////////////////////////

			//Affichage de la jauge du bonus ralentissement : exactement le même principe que le bonus turbo
			if p.temps.ral <> 0 then
			begin
			texture := SDL_CreateTextureFromSurface(renderer, surfBonusRalentir);
			new(rect);					
			rect^.x:= (tailleMapX*TILEW) + 10;
			rect^.y:= 250;
			rect^.w:=TILEW;
			rect^.h:=TILEH;
			SDL_RenderCopy(renderer,texture,nil,rect);
			SDL_RenderPresent (renderer);
			for i:=1 to round((p.temps.ral/bRalentisseurMax)*10) do 
				begin
					texture := SDL_CreateTextureFromSurface(renderer, surfVieTimer);
					new(rect);					
					rect^.x:= (tailleMapX*TILEW) + 15 + TILEW + (i	-1)*10;
					rect^.y:= 260;
					rect^.w:=10;
					rect^.h:=10;
					SDL_RenderCopy(renderer,texture,nil,rect);
					SDL_RenderPresent (renderer);
				end;
			for i:=round((p.temps.ral/bRalentisseurMax)*10) to 10 do 
				begin
					texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
					new(rect);					
					rect^.x:= (tailleMapX*TILEW) + 15 + TILEW + (i	-1)*10;
					rect^.y:= 260;
					rect^.w:=10;
					rect^.h:=10;
					SDL_RenderCopy(renderer,texture,nil,rect);
					SDL_RenderPresent (renderer);
				end;
			end
			else
			begin
				texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
				new(rect);					
				rect^.x:= (tailleMapX*TILEW) + 10;
				rect^.y:= 250;
				rect^.w:=TILEW;
				rect^.h:=TILEH;
				SDL_RenderCopy(renderer,texture,nil,rect);
				SDL_RenderPresent (renderer);
				for i:=1 to 10 do 
				begin
					texture := SDL_CreateTextureFromSurface(renderer, surfNoir);
					new(rect);					
					rect^.x:= (tailleMapX*TILEW) + 15 + TILEW + (i	-1)*10;
					rect^.y:= 260;
					rect^.w:=10;
					rect^.h:=10;
					SDL_RenderCopy(renderer,texture,nil,rect);
					SDL_RenderPresent (renderer);
				end;
			end;
	    end;
	    /////////////////////////
	    
	end;

	procedure deplacementMonstres(plat : plateau; var p : pacoman; var tab : TableauMonstre; var N : TDateTime; Nori : TDateTime; var k :integer; var NBonus : TDateTime; var nbTacos : integer);
	var 
		i,j,l,numeroPairSwitch,numeroSwitch:integer; //k permet l'apparition des monstres toutes les 5 secondes
		coeffVitesse:Real;
	begin
		N := Now();
		
		if p.BRal = true then coeffVitesse:=2 // on divise par deux la vitesse si le bonus est activé.
	    else coeffVitesse:=1;
	    
		for i:= 1 to k do //Ici on gère l'apparition successive des monstres c'est à dire que le facteur k augmente de 1 toutes les 3,5 secondes.
		begin
			if MilliSecondOfTheHour(N) - tab[i].date >= (tab[i].vitesse *VITESSEDEPLACEMENT*coeffVitesse) then //On effectue un déplacement tous les tab[i].vitesse *VITESSEDEPLACEMENT*coeffVitesse millisecond
			begin
				if ((p.BRal=true) and (i=1)) then p.temps.ral:=p.temps.ral-1; // le bonus est consommé.
				if plat[tab[i].x,tab[i].y]=switch then
				begin
					for l := 1 to MAX_PAIRE_SWITCH do
						for j := 1 to 2 do 
							if ((tabSwitch[l,j,1] = tab[i].x) and (tabSwitch[l,j,2] =tab[i].y)) then
								begin
									numeroPairSwitch := l;
									numeroSwitch:=j;
								end;
				end;			
				if ((plat[tab[i].x,tab[i].y]=switch) and (integerToDirection(tabSwitch[numeroPairSwitch,numeroSwitch,3])<>tab[i].direction)) then
				begin
					if numeroSwitch=1 then numeroSwitch:=2 else numeroSwitch:=1;
					tab[i].x:=tabSwitch[numeroPairSwitch,numeroSwitch,1];
					tab[i].y:=tabSwitch[numeroPairSwitch,numeroSwitch,2];
					tab[i].direction:=integerToDirection(tabSwitch[numeroPairSwitch,numeroSwitch,3]);
			
				
				end
				else
				begin
					tab[i].date := MilliSecondOfTheHour(N);
					if not(((p.statut=invincible) and (tab[i].x=xPrison) and (tab[i].y=yPrison))) then //En fonction du comportement des monstres on appelle les fonctions de comportement correspondantes : 
					begin
						case tab[i].statut of
							agressif : tab[i].direction := comportementAgressif(plat, tab[i].direction,tab[i].x, tab[i].y, p.x, p.y);
							aleatoire : tab[i].direction := comportementAleatoire(plat, tab[i].direction, tab[i].x, tab[i].y);
							fuite: tab[i].direction := comportementFuite(plat,tab[i].direction, tab[i].x, tab[i].y, p.x, p.y);
							retourPrison : tab[i].direction := comportementRentrerALaPrison(plat, tab[i].direction, tab[i].x, tab[i].y);
							semiAgressif : tab[i].direction := comportementSemiAgressif(plat, tab[i].direction,tab[i].x, tab[i].y, p.x, p.y, tab[i].compteur);
							devine : tab[i].direction := comportementDeviner(plat, tab[i].direction, tab[i].x, tab[i].y);
							demarque : tab[i].direction := comportementSeDemarquer(plat, tab, tab[i].direction, tab[i].x, tab[i].y);
							compAleatoire : tab[i].direction:=comportementComportementAleatoire(plat,tab,tab[i].direction,tab[i].x,tab[i].y,p.x,p.y,tab[i].compteur,tab[i].etatAleatoire);
						end;
						if (directionToDecort(plat,tab[i].direction,tab[i].x,tab[i].y)<>mur) then mouvementMonstre(tab, i, plat,p);
					end;
				end;
				//On appelle check, voir pacoman_jeu.pas pour le détail : cette fonction gère les évènements de jeu 
				check(tab, plat, p, NBonus, nbTacos, m);			
			end;
		end;
		if (((MilliSecondOfTheHour(N) - MilliSecondOfTheHour(NOri)) >= (k*3500)) and (k < MAX_MONSTRES)) then k:=k+1; //Toutes les 3,5 secondes on augmente k de 1 jusqu'à MAX_MONSTRES

	end;

	//Cette procédure effectue un mouvement de pacoman
	procedure mouvementPacman(var p : pacoman; plat : plateau);
	begin
		//On écrit le décort correspondant à la case sur laquelle est le pacman puis on écrit le pacman sur la case sur laquelle il se déplace( ecrirePacman)
		ecrireCaractere(p.x, p.y, plat);
		case p.dirOri of
			gauche : 
			begin
				p.x := p.x - 1;
				if plat[p.x,p.y]<>switch then ecrirePacman(p); //
			end;
			droite:
			begin
				p.x := p.x + 1;
				if plat[p.x,p.y]<>switch then ecrirePacman(p);
			end;
			haut :
			begin
				p.y := p.y - 1;
				if plat[p.x,p.y]<>switch then ecrirePacman(p);
			end;
			bas : 
			begin
				p.y := p.y + 1;
				if plat[p.x,p.y]<>switch then ecrirePacman(p);
			end;
		end;
	end;

	//Même principe que mouvementPacman 
	procedure mouvementMonstre(var tab : TableauMonstre; i : integer; plat : plateau;p:pacoman); 
	begin
		//On affiche le décort de la case sur laquelle se trouvait le monstre puis on affiche le monstre sur 
		//la case sur laquelle il se déplace. En effet le monstre ne mange pas les tacos par exemple, 
		//néanmoins lorsque le monstre est sur une case on n'affiche pas le tacos sous celui-ci, il faut donc le réafficher lorsque le monstre quitte la case.
		case tab[i].direction of
			droite : 
			begin
				if not((p.x=tab[i].x) and (p.y=tab[i].y)) then ecrireCaractere(tab[i].x, tab[i].y, plat);
				tab[i].x := tab[i].x  + 1;
				if ((plat[tab[i].x,tab[i].y]<>switch) and (plat[tab[i].x,tab[i].y]<>prison)) then ecrireMonstre(tab[i]);		
			end;
			gauche : 
			begin
				if not((p.x=tab[i].x) and (p.y=tab[i].y)) then ecrireCaractere(tab[i].x, tab[i].y, plat);
				tab[i].x := tab[i].x  - 1;
				if ((plat[tab[i].x,tab[i].y]<>switch) and (plat[tab[i].x,tab[i].y]<>prison)) then ecrireMonstre(tab[i]);		
			end;
			haut : 
			begin
				if not((p.x=tab[i].x) and (p.y=tab[i].y)) then ecrireCaractere(tab[i].x, tab[i].y, plat);
				tab[i].y := tab[i].y - 1;
				if ((plat[tab[i].x,tab[i].y]<>switch) and (plat[tab[i].x,tab[i].y]<>prison)) then ecrireMonstre(tab[i]);	
			end;
			bas : 
			begin
				if not((p.x=tab[i].x) and (p.y=tab[i].y)) then ecrireCaractere(tab[i].x, tab[i].y, plat);
				tab[i].y := tab[i].y  + 1;
				if ((plat[tab[i].x,tab[i].y]<>switch) and (plat[tab[i].x,tab[i].y]<>prison)) then ecrireMonstre(tab[i]);		
			end;
		end;
	end;

	//Cette procédure sert à afficher l'image de décort correspondant au décort dans le plateau plat.
	procedure ecrireCaractere(i, j : integer; plat : plateau);
	var 
	texture	: PSDL_Texture;
	rect : PSDL_Rect;
	k,l:Integer;
	begin
		texture := SDL_CreateTextureFromSurface(renderer, surfFond);
		new(rect);
		rect^.x:=(i - 1)*TILEW;
		rect^.y:=(j - 1)*TILEH;
		rect^.w:=TILEW;
		rect^.h:=TILEH;
		SDL_RenderCopy(renderer,texture,nil,rect);
		SDL_RenderPresent (renderer);
		case plat[i,j] of 
			vide : texture := SDL_CreateTextureFromSurface(renderer, surfFond);
			mur : texture := SDL_CreateTextureFromSurface(renderer, surfMur);
			tacos : texture := SDL_CreateTextureFromSurface(renderer, surfTacos);
			prison: texture := SDL_CreateTextureFromSurface(renderer, surfPrison);
			switch:
					begin
						for k:=1 to MAX_PAIRE_SWITCH do
						for l:=1 to 2 do
						begin
							if ((tabSwitch[k,l,1]=i) and (tabSwitch[k,l,2]=j)) then
							begin
								//En fonction de la paire de switch, nous n'affichons pas la même image
								case k of
									1 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch1);
									2 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch2);
									3 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch3);
									4 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch4);
									5 :texture := SDL_CreateTextureFromSurface(renderer, surfSwitch5);
								end;
							end;
						end;
					
					
					end;
			bInvincible: texture := SDL_CreateTextureFromSurface(renderer, surfBonusInvincible);
			bTurbo : texture := SDL_CreateTextureFromSurface(renderer, surfBonusBoost);
			bRalentisseur : texture := SDL_CreateTextureFromSurface(renderer, surfBonusRalentir);
		end;
		rect^.x:=(i - 1)*TILEW;
		rect^.y:=(j - 1)*TILEH;
		rect^.w:=TILEW;
		rect^.h:=TILEH;
		SDL_RenderCopy(renderer,texture,nil,rect);
		SDL_RenderPresent (renderer);
	end;

//Même principe que pour ecrireCaractère 
procedure ecrirePacman(p:pacoman);
var
texture	: PSDL_Texture;
rect : PSDL_Rect;
begin
	if ouvert = true then //on affiche l'image en fonction de la direction et de l'ouverture ou non de la bouche du pacman.
		case p.dirOri of
			droite: texture:= SDL_CreateTextureFromSurface(renderer, surfPacmanOuvertDroite);
			gauche: texture := SDL_CreateTextureFromSurface(renderer, surfPacmanOuvertGauche);
			haut:texture := SDL_CreateTextureFromSurface(renderer, surfPacmanOuvertHaut);
			bas: texture := SDL_CreateTextureFromSurface(renderer, surfPacmanOuvertBas); //On crée la texture à partir de la surface						
		end		
	else
		case p.dirOri of
			droite: texture:= SDL_CreateTextureFromSurface(renderer, surfPacmanFermeDroite);
			gauche: texture := SDL_CreateTextureFromSurface(renderer, surfPacmanFermeGauche);
			haut:texture := SDL_CreateTextureFromSurface(renderer, surfPacmanFermeHaut);
			bas: texture := SDL_CreateTextureFromSurface(renderer, surfPacmanFermeBas); //On crée la texture à partir de la surface						
		end;	
	new(rect);
	rect^.x:=(p.x - 1)*TILEW;
	rect^.y:=(p.y - 1)*TILEH;
	rect^.w:=TILEW;
	rect^.h:=TILEH;
	SDL_RenderCopy(renderer,texture,nil,rect);
	SDL_RenderPresent (renderer);
end;


//Même principe que ecrireCaractère et ecrireMonstre
procedure ecrireMonstre(m : monstre);
var
texture	: PSDL_Texture;
rect : PSDL_Rect;


begin
		//On affiche l'image correspondant à chaque comportement.
		case m.statut of 
			semiAgressif : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreSemiAgressif);
			agressif : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreAgressif);
			demarque : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreDemarque);
			aleatoire : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreAleatoire);
			fuite : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreFuite);
			devine : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreDevine);
			retourPrison : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreFuite);
			compAleatoire : texture := SDL_CreateTextureFromSurface(renderer, SurfMonstreComportementAleatoire);
		end;
		new(rect);
		rect^.x:=(m.x - 1)*TILEW;
		rect^.y:=(m.y - 1)*TILEH;
		rect^.w:=TILEW;
		rect^.h:=TILEH;
		SDL_RenderCopy(renderer,texture,nil,rect);
		SDL_RenderPresent (renderer);

end;

		    

end.
