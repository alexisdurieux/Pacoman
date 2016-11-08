unit pacoman_jeu;

interface

uses pacoman_util, pacoman_file, pacoman_initialisation, SysUtils, dateutils, Crt, fmod, fmodtypes;

procedure check(var tabM : tableauMonstre; var plat : plateau; var p : pacoman; var NBonus : TDateTime; var nbTacos : integer; m : musiques);

implementation

procedure check(var tabM : tableauMonstre; var plat : plateau; var p : pacoman; var NBonus : TDateTime; var nbTacos : integer; m : musiques);
//Cette procédure sert à modifier les différentes variables du jeu (pacoman, monstres, bonus) en fonction des positions et des statuts de chaque entité
//Cette procédure est appelée après chaque déplacement de monstres et de pacoman
var
	i, j:integer;
	
begin

	for j := 1 to MAX_MONSTRES do //actualisation de l'enregistrement monstre pendant la durée du bonus invincibilité
		begin 
			If ((p.statut=invincible) and (tabM[j].x <>xPrison) and (tabM[j].y<>yPrison) and (tabM[j].statut<>retourPrison)) then
			begin
				tabM[j].statut := fuite; //changement du statut 
				tabM[j].vitesse := 2; //diminution de la vitesse des monstres
			end;
		end;
				
	case plat[p.x,p.y] of		
		tacos://pacoman est sur un tacos
			begin
				plat[p.x,p.y] := vide; 
				p.score := p.score+10; //modif score
				nbTacos := nbTacos - 1; //on retire un au nombre de tacos sur la carte
				FSOUND_PlaySound(0, m.blop);//appel du son quand on mange un tacos
			end;

		BInvincible://pacoman est sur un bonus invincibilité
			begin
				NBonus := Now(); //récupération de la date 
				plat[p.x,p.y]:=vide;
				p.statut := invincible; //changement statut pacoman
				FSOUND_PlaySound(3, m.invincible); //appel du son quand pacoman mange un bonus d'invincibilité
				for j := 1 to MAX_MONSTRES do //modification de l'enregistrement monstre
					begin
					If ((tabM[j].x <>xPrison) and (tabM[j].y<>yPrison) and (tabM[j].statut<>retourPrison)) then
						begin
							tabM[j].statut := fuite; //changement statut
							tabM[j].vitesse := 2; //diminution vitesse
						end
					end;
			end;
		
		BTurbo : //pacoman est sur un bonus turbo
			begin
				FSOUND_PlaySound(0, m.musiqueMangeBonus); //appel du son quand pacoman mange un bonus turbo
				plat[p.x,p.y]:=vide;
				p.temps.turbo:=40; //chargement de la barre de bonus turbo
			end;
		BRalentisseur : //pacoman est sur un bonus ralentisseur
			begin
				FSOUND_PlaySound(0, m.musiqueMangeBonus); //appel du son quand pacoman mange un bonus ralentisseur
				plat[p.x,p.y]:=vide;
				p.temps.ral:=30; //chargement de la barre de bonus ralentisseur
			end;
			
		switch: //pacoman est sur un switch
			begin
				for i := 1 to MAX_PAIRE_SWITCH do //on parcourt toutes les paires de switch car on a l'information que le pacoman est sur un switch mais on ne sait pas le quel
					for j := 1 to 2 do //maintenant on a choisit une paire de switch mais il faut regarder si le pacoman est sur le premier ou le deuxième switch
						if ((tabSwitch[i,j,1] = p.x) and (tabSwitch[i,j,2] = p.y)) then
						begin
							if p.dirOri<>integerToDirection(tabSwitch[i,j,3]) then //permet d'éviter que le pacoman retourne au switch précédent après avoir switché
							begin
								if j = 1 then //pacoman est sur le premier switch
									begin
										p.x := tabSwitch[i,2,1]; //changement des coordonnées
										p.y := tabSwitch[i,2,2];
										p.dirOri := integerToDirection(tabSwitch[i,2,3]); //changement direction pacoman
										p.dirKeyboard := integerToDirection(tabSwitch[i,2,3]); //changement direction clavier
									end
								else
									begin //pacoman est sur le deuxième switch
										p.x := tabSwitch[i,1,1]; //chagement des coordonnées
										p.y := tabSwitch[i,1,2];
										p.dirOri := integerToDirection(tabSwitch[i,1,3]); //changement direction pacoman
										p.dirKeyboard := integerToDirection(tabSwitch[i,1,3]); //chamgenet direction clavier
									end;
							end;
						end;
			FSOUND_PlaySound(4, m.switch); //appel du son quand pacoman marche sur un switch
			end;
	end;

	for i := 1 to MAX_MONSTRES do //on traite ici le cas particulier des interactions monstres/pacoman. Les deux entités ne sont pas définies dans le fichier
		if ((p.x = tabM[i].x) and (p.y = tabM[i].y)) then //monstre et pacoman sont sur la même case
			begin
				if tabM[i].statut <> retourPrison then //rien ne se passe si pacoman croise un monstre qui retourne à la prison
				begin
				tabM[i].statut := retourPrison; //peu importe le statut du pacoman, le monstre retourne à la prison
				tabM[i].vitesse := 0.1; //augmentation de la vitesse
					case p.statut of // on regarde d'abord le statut du pacoman
						vivant: //statut du pacoman est vivant (perte de vie)
							begin
								FSOUND_PlaySound(0, m.slap); //appel du son perte de vie
								p.bouclier := p.bouclier - 1; //pacoman perd une vie
							end;
						invincible:
							begin
								FSOUND_PlaySound(0, m.musiqueMangeMonstre); //appel du son quand pacoman mange un monstre
								p.score := p.score + 100; //pacoman gagne 100 points
							end;
					end;
				end;
			end;

	for i:=1 to MAX_MONSTRES do 
	begin
		if (((tabM[i].x = xPrison) and (tabM[i].y = yPrison)) and (p.statut <> invincible))then //ici on gère la sortie de prison des montres quand le pacoman n'est pas invincible 
		begin
			tabM[i].direction := directionInitialePrison; //affection d'une direction de sortie de prison
			tabM[i].statut := statuts[i]; //affection du statut du monstre lors de ce niveau
			tabM[i].vitesse := 1; //affection de la vitesse
		end;
	end;

	if ((MilliSecondOfTheHour(Now()) - MilliSecondOfTheHour(NBonus) >= 12000) and (p.statut = invincible)) then //traitement de la fin du bonus invincibilité
	begin
		p.statut := vivant; //pacoman retourne en statut vivant
		for j := 1 to MAX_MONSTRES do //tous les monstres reprennent leur conditions initiales
			begin
				tabM[j].direction:=directionInitialePrison; //affection d'une direction de sortie de prison
				tabM[j].statut := statuts[j]; //affection du statut du monstre lors de ce niveau
				tabM[j].vitesse := 1; //affection de la vitesse
			end;
	end;
end;

end.
