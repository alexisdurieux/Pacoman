unit pacoman_analyse;

interface

uses pacoman_util,pacoman_file;

type

tab1 = Array[1..MAX_X,1..MAX_Y] of Integer;
liste = Array[1..MAX_X*MAX_Y,1..2] of Integer;
tab2 = Array[1..MAX_X*MAX_Y,1..MAX_X*MAX_Y,1..2] of Integer; 
tab3 = Array[1..MAX_X,1..MAX_Y,1..2] of Integer;
tab4 = Array[1..MAX_X,1..MAX_Y,1..3] of Integer;
	
var
	nbCroisement:Integer;
	platCroisement:tab1;
	tabInterCroisement1:tab2;
	tabInterCroisement2:tab2;
	coordCroisement:liste;
	croisementLePlusProche:tab3;
	infoCases:tab4;
	listeCases: liste;	

procedure analyserLaMap(plat:plateau); // c'est la procédure générale, le but de cette unité étant d'analyser la map pour pouvoir coder des comportements de monstre.

implementation

//On cherche à cartographier la map, à la transformer en un graphe pour pouvoir appliqué l'algoryhtme de Djikstra.
procedure chercheCroisement(plat:plateau); // Trouve les croisements de la map, c'est à dire les noeuds du graphe.
	var i,j,nbRoute:Integer;	
	begin
		nbCroisement:=0; // initialise le nombre de croisement
		for i:=1 to tailleMapX do
			for j:= 1 to tailleMapY do platCroisement[i,j]:=0; // met toutes les valeurs de platCroisement à 0
	
		for i:=2 to tailleMapX do
			for j:=2  to tailleMapY do
				
				begin
					nbRoute :=0;
					if plat[i,j]<>mur then
					begin
						if plat[i-1,j]<>mur then nbRoute:=nbRoute +1;
						if plat[i,j+1]<>mur then nbRoute:=nbRoute +1;
						if plat[i+1,j]<>mur then nbRoute:=nbRoute +1;
						if plat[i,j-1]<>mur then nbRoute:=nbRoute +1;
						if ((nbRoute > 2) or (plat[i,j]=switch) or (plat[i,j]=prison)) then // si au moins 3 routes sont reliées à une case, c'est que cette case est un croisement. Ou alors c'est un switch ou la prison.
						begin
							nbCroisement:=nbCroisement+1;
							platCroisement[i,j]:=nbCroisement; // le tableau platCroisement ne possède que des 0 sauf aux cases où il y a des croisements. Dans ce cas, la case porte le numéro du croisement.
							coordCroisement[nbCroisement,1]:=i; // enregistre les coordonnées (x,y) de tout les croisements. 
							coordCroisement[nbCroisement,2]:=j;// Celà permet de passer facilement du numéro du croisement à ses coordonnées (x,y) et inversement.
						end;
					end;
				end;
	end;

procedure trouveProchainCroisement(plat:plateau;numCroisement1:Integer;x1:Integer;y1:Integer;x2:Integer;y2:Integer;distance :Integer; directionPourAllerAuCroisement :Integer); // la procedure fonctionne de manière récursive.
var numCroisement2,d :Integer;
// On analyse case après case jusqu'à ce qu'on tombe sur un nouveau croisement
// On en profite pour calculer la distance entre deux croisements en encrémentant une variable d à chaque nouvel appel de la procedure
// On en profite aussi pour savoir qu'elles sont les cases entre les deux croisements qu'on étudie afin de déterminer à chaque case quelles sont les croisements associés.
	begin
		numCroisement2:=platCroisement[x2,y2];
		listeCases[distance,1]:=x2; // on liste toutes les cases entre les deux croisements
		listeCases[distance,2]:=y2;
		if (numCroisement2>0) then // A traduire par :  si cette case est un croisement
		begin
			tabInterCroisement1[numCroisement1,numCroisement2,1]:=distance; // on remplie le tableau avec la distance pour aller du croisement 1 vers le croisement 2
			tabInterCroisement1[numCroisement1,numCroisement2,2]:=directionPourAllerAuCroisement; // Et la direction à prendre pour aller du croisement 1 vers le croisement 2
			for d:=1 to (distance-1) do
			begin
			
			// On remplie le tableau infoCases avec :
			infoCases[listeCases[d,1],listeCases[d,2],1]:= numCroisement1; // au premier niveau le numéro du 1er croisement
			infoCases[listeCases[d,1],listeCases[d,2],2]:= numCroisement2; // au 2eme niveau, le numéro de l'autre croisement
			infoCases[listeCases[d,1],listeCases[d,2],3]:= d; // au troisième niveau, la distance par rapport au 1er croisement
			
			end;
		end
		else
		begin
			// seulement une de ces 4 conditions est vérifié. On regarde autour de la case où est la prochaine.
			if ((plat[x2-1,y2]<>mur) and ((x2-1<>x1) or (y2<>y1))) then trouveProchainCroisement(plat,numCroisement1,x2,y2,x2-1,y2,distance +1,directionPourAllerAuCroisement);
			if ((plat[x2,y2+1]<>mur) and ((x2<>x1) or (y2+1<>y1))) then trouveProchainCroisement(plat,numCroisement1,x2,y2,x2,y2+1,distance +1,directionPourAllerAuCroisement);
			if ((plat[x2+1,y2]<>mur) and ((x2+1<>x1) or (y2<>y1))) then trouveProchainCroisement(plat,numCroisement1,x2,y2,x2+1,y2,distance +1,directionPourAllerAuCroisement);
			if ((plat[x2,y2-1]<>mur) and ((x2<>x1) or (y2-1<>y1))) then trouveProchainCroisement(plat,numCroisement1,x2,y2,x2,y2-1,distance +1,directionPourAllerAuCroisement);
		end;
	end;


procedure distanceEntreCroisement(plat:plateau);
var
	x1,y1,i,j,k,numCroisement1 :Integer;   

	begin
		for i:=1 to nbCroisement do
		for j:=1 to nbCroisement do 
		for k:=1 to 2 do tabInterCroisement1[i,j,k]:= 0; // On initialise le tableau à 0.
		
		for numCroisement1:=1 to nbCroisement do // on part de tout les croisements 
		begin
			x1:= coordCroisement[numCroisement1,1];
			y1:= coordCroisement[numCroisement1,2];
			
			// on cherche les croisement associés à un croisement. Pour cel) on regarde par où on peut aller à partir du croisement.
			if plat[x1-1,y1]<>mur then trouveProchainCroisement(plat,numCroisement1,x1,y1,x1-1,y1,1,1);   //1 = gauche
			if plat[x1,y1+1]<>mur then trouveProchainCroisement(plat,numCroisement1,x1,y1,x1,y1+1,1,2);   //2 = bas
			if plat[x1+1,y1]<>mur then trouveProchainCroisement(plat,numCroisement1,x1,y1,x1+1,y1,1,3);	//3 = droite
			if plat[x1,y1-1]<>mur then trouveProchainCroisement(plat,numCroisement1,x1,y1,x1,y1-1,1,4);	//4 = haut
				
		end;

	end;

procedure teleporteur(plat:plateau);
// Ici on crée artificielement l'arrête du graphe entre deux switchs. On indique que la distance est de 1 entre deux switchs qui sont reliés.
var
	s1,s2,i:integer;
	begin
		for i:= 1 to MAX_PAIRE_SWITCH do
		begin
		s1:=platCroisement[tabSwitch[i,1,1],tabSwitch[i,1,2]];
		s2:=platCroisement[tabSwitch[i,2,1],tabSwitch[i,2,2]];
		
		tabInterCroisement1[s1,s2,1]:=1;
		tabInterCroisement1[s2,s1,1]:=1;		
		end;
	end;
	
procedure associerlesDeuxCroisementsAUneCase(); // la procedure associe les deux croisements par ordre de distance par rapport à la case
var i,j,k:Integer;

	begin
		for i:=1 to tailleMapX do
		for j:=1 to tailleMapY do
		for k:=1 to 2 do croisementLePlusProche[i,j,k] := 0; // On initialise le tableau à 0.
		
		for i:=1 to tailleMapX do
		for j:=1 to tailleMapY do
		if infoCases[i,j,3] <> 0 then // A traduire par : Si tu n'es pas un croisement
		begin
			if infoCases[i,j,3] < (tabInterCroisement1[infoCases[i,j,1],infoCases[i,j,2],1])/2 then // si cette condition est vérifiée, c'est que le croisement le plus proche est celui qu'on avait noté en premier.
			begin
				croisementLePlusProche[i,j,1]:=infoCases[i,j,1];
				croisementLePlusProche[i,j,2]:=infoCases[i,j,2];
			end;
			if infoCases[i,j,3] > (tabInterCroisement1[infoCases[i,j,1],infoCases[i,j,2],1])/2 then // sinon c'est l'autre.
			begin
				croisementLePlusProche[i,j,1]:=infoCases[i,j,2];
				croisementLePlusProche[i,j,2]:=infoCases[i,j,1];
			end;
			if infoCases[i,j,3] = (tabInterCroisement1[infoCases[i,j,1],infoCases[i,j,2],1])/2 then // si une case est exactement au milieu, on prend le croisement le plus proche au hasard
			begin
				randomize;
				k:=random(2)+1;	// Ce nombre vaut soit 1 soit 2.		
				croisementLePlusProche[i,j,1]:=infoCases[i,j,k];
				if k=1 then croisementLePlusProche[i,j,2]:=infoCases[i,j,2];
				if k=2 then croisementLePlusProche[i,j,2]:=infoCases[i,j,1];
			end;
		end;
		
		
		
	
	
	
	end; 

procedure cheminLePlusCourt(); // adaptation de l'algorithme de Dijkstra pour trouver comment aller d'un croisement à un autre le plus rapidemment possible
var depart,arrive,i,j,croisementPere,croisement,premierCroisement:Integer;
	tabDesPoids:liste;
	tabDesPredecesseurs:Array[1..MAX_X*MAX_Y] of Integer;

begin
	for depart:=1 to nbCroisement do
	for arrive:=1 to nbCroisement do
	
	begin
		if depart=arrive then 
		begin
			tabInterCroisement2[depart,arrive,1]:=0;
			tabInterCroisement2[depart,arrive,2]:=0;
		end;
		
		if depart<>arrive then
		begin
			for i:=1 to nbCroisement do // On initialise les tableaux
			begin
				tabDesPoids[i,1]:= -1; // On affecte tout les croisements avec un poids de -1
				tabDesPoids[i,2]:= 0;  // On met 0 partout --> on est pas encore passé par ces croisements
				tabDesPredecesseurs[i]:= 0; // Pour l'instant il n'y a aucun predecesseur pour chacun des croisements
			end;
			tabDesPoids[depart,1]:= 0; // On affecte 0 comme poids pour la ville de départ, le 1er noeuds Père
			
			croisementPere:=0;  // on initialise le croisementPere pour être sur de rentrer dans la boucle
			
			while croisementPere<>arrive do
			begin
				croisementPere:=0;
				for j:= 1 to nbCroisement do
				begin
					if ((tabDesPoids[j,2]=0) and (tabDesPoids[j,1]<>-1))then 
					begin
						if croisementPere=0 then croisementPere:=j;
						if tabDesPoids[j,1]<tabDesPoids[croisementPere,1] then croisementPere:=j;
						//On recherche le croisement non parcouru avec le poids le plus faible
					end;
				end;
				tabDesPoids[croisementPere,2]:=1;  // On le choisie, on marque qu'on y est passé
				begin	
					for j:=1 to nbCroisement do // On recherche tout les croisements-fils venant du croisements-Père
					begin
						if tabInterCroisement1[croisementPere,j,1] <> 0 then // si la distance entre CroisementPère/Croisementfils est différente de 0, c'est bien qu'ils sont reliés.
						begin
							if ((tabDesPoids[j,2]=0) and ((tabDesPoids[croisementPere,1]+tabInterCroisement1[croisementPere,j,1]<tabDesPoids[j,1]) or (tabDesPoids[j,1]=-1))) then 
							// si on n'est pas encore passé par le croisement-fils et si la distance pour aller du depart au Croisement-fils
							// en passant par le Croisement-Pere est plus petite que la distance pour aller du départ au Croisement-fils
							// que l'on avait déjà trouvé en passant par un autre chemin alors.. 
							begin
								tabDesPoids[j,1]:= tabDesPoids[croisementPere,1]+tabInterCroisement1[croisementPere,j,1];
								tabDesPredecesseurs[j]:=croisementPere;
								// on change le poids du croisement fils en mettant celui passant par le croisement-Père
								// et on indique que le prédecesseur du Croisement Fils est le croisement Pere
							end;
						end;
					end;
				end;
				
			end;
			croisement:=arrive;
			repeat // ce qui nous interesse au final c'est seulement vers qu'elles croisements il faut aller au départ pour rejoindre le croisement final
			premierCroisement:=croisement;
			croisement:=tabDesPredecesseurs[croisement];
			until  croisement=depart;
			
			tabInterCroisement2[depart,arrive,1]:=tabDesPoids[arrive,1]; // Distance entre départ et arrivé
			tabInterCroisement2[depart,arrive,2]:=tabInterCroisement1[depart,premierCroisement,2]; // la direction à prendre pour aller du départ à l'arrivé est la même que pour aller du départ au croisement adjacent qu'il faut emprunter. Ce qu'on avait déterminer avant.		
			
		end;
	end;

end;


procedure analyserLaMap(plat:plateau);
begin
	chercheCroisement(plat);
	distanceEntreCroisement(plat);
	teleporteur(plat);
	associerlesDeuxCroisementsAUneCase();
	cheminLePlusCourt();
end;

end.
