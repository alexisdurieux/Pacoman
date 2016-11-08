unit pacoman_file;

interface

uses pacoman_util;
	const
		MAX_PAIRE_SWITCH = 5;
	type
		tab5 = Array[1..MAX_PAIRE_SWITCH,1..2,1..3] of Integer;	
	var
		xPrison,yPrison,tailleMapX,tailleMapY:Integer;
		tabSwitch : tab5;
		
	procedure chargementMap(var plat : plateau; nomMap : String; var nbTacos : integer);
	

implementation

	procedure chargementMap(var plat : plateau; nomMap : String; var nbTacos : integer); 
//Cette procédure sert à lire le fichier pour remplir la matrice, compter le nombre de tacos sur la carte, remplir le tableau de switch
	var 
	f : text;
	i, j, Switch1, Switch2, Switch3, Switch4, Switch5, k, l : integer;
	c : char;  
	
	begin
	//initialisation des variables locales
		nbTacos := 0;
		nomMap := nomMap + '.txt';
		j := 1;
		Switch1 := 1; //ses variables servent à compter le numéro du switch dans sa paire (elles peuvent valoir 1 ou 2)
		Switch2 := 1;
		Switch3 := 1;
		Switch4 := 1;
		Switch5 := 1;
	//lecture du fichier
		assign(f, nomMap);
		reset(f);
		while (not eof(f)) do 
		begin
			i := 1; 
			tailleMapY := j;//on repère la taille de la carte selon l'axe x
			repeat 
				read(f, c);//lecture d'un caractère
			//on cherche les coordonnées des switchs dans la matrice
				if c = 's' then  //switch 1
					begin
						tabSwitch[1,Switch1,1] := i; //coordonnée x
						tabSwitch[1,Switch1,2] := j; //coordonnée y
						Switch1 := Switch1 + 1; //on itère la variable de 1 pour la lecture du deuxième switch dans la paire de switch 1
					end;
				if c = 'u' then //switch 2
					begin
						tabSwitch[2,Switch2,1] := i;
						tabSwitch[2,Switch2,2] := j;
						Switch2 := Switch2 + 1;
					end;
				if c = 'w' then //switch 3
					begin
						tabSwitch[3,Switch3,1] := i;
						tabSwitch[3,Switch3,2] := j;
						Switch3 := Switch3 + 1;
					end;
				if c = 'y' then //swtich 4
					begin
						tabSwitch[4,Switch4,1] := i;
						tabSwitch[4,Switch4,2] := j;
						Switch4 := Switch4 + 1;
					end;
				if c = 'z' then //switch 5
					begin
						tabSwitch[5,Switch5,1] := i;
						tabSwitch[5,Switch5,2] := j;
						Switch5 := Switch5 + 1;
					end;
			//on repère la taille de la carte selon l'axe x
				if c= '#' then tailleMapX:=i - 1;
			//affectation du décort dans la matrice en fonction de la lettre lu dans le fichier
				plat[i, j] := charToDecort(c);
			//repérage des coordonnées de la prison
				if plat[i, j] = prison then 
				begin
					xPrison:=i;
					yPrison:=j;
				end;
			//comptage du nombre de taccos sur la carte
				if plat[i, j] = tacos then nbTacos := nbTacos + 1;	
			//on passe au caracètère suivant
				i:=i+1;
			until c='#';
			j := j+1;
			readln(f); //changement de la ligne
		end;
		close(f);
	//on cherche la direction du switch
		for k := 1 to MAX_PAIRE_SWITCH do
			for l := 1 to 2 do 
				begin
					if plat[tabSwitch[k,l,1]+1,tabSwitch[k,l,2]] <> Mur then tabSwitch[k,l,3] := 3; //direction droite
					if plat[tabSwitch[k,l,1]-1,tabSwitch[k,l,2]] <> Mur then tabSwitch[k,l,3] := 1; //direction gauche
					if plat[tabSwitch[k,l,1],tabSwitch[k,l,2]+1] <> Mur then tabSwitch[k,l,3] := 2; //direction bas
					if plat[tabSwitch[k,l,1],tabSwitch[k,l,2]-1] <> Mur then tabSwitch[k,l,3] := 4; //direction haut	
				end;
	//on enlève le tacos sur lequel va apparaître le pacoman			
		nbTacos := nbTacos - 1; 
end;
	
	

end.
