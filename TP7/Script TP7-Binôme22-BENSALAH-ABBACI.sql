/*
  Script TP 7
  Réalisé en binome par: BENSALAH Kawthar / ABBACI Khaled
  Numéro du Binome : 22
  Master 2 IL - Groupe 1
  USTHB 2019/2020
*/

/*Activation l’option timing de oracle*/ 
set timing on;

/*Reponse 1*/
/*Montants versés annuels par Wilaya, pour chaque type de compte*/
Select t.Année, d.CodeWilaya, f.CodeTypeCompte, 
        sum(f.MontantV) as MontV 
from FOperation f, DAgence d, DTemps t
where f.NumAgence = d.NumAgence
      and f.CodeTemps = t.CodeTemps
group by t.Année, d.CodeWilaya, f.CodeTypeCompte
order by t.Année, d.CodeWilaya, f.CodeTypeCompte;

/*Reponse 2*/
/*Introduction des sous totaux sur R1 avec la clause rollup by*/
Select t.Année, d.CodeWilaya, f.CodeTypeCompte, 
        sum(f.MontantV) as MontV 
from FOperation f, DAgence d, DTemps t
where f.NumAgence = d.NumAgence
      and f.CodeTemps = t.CodeTemps
group by rollup (t.Année, d.CodeWilaya, f.CodeTypeCompte)
order by t.Année, d.CodeWilaya, f.CodeTypeCompte;

/*Reponse 3*/
/*Introduction des sous totaux sur R1 avec la clause cube by*/
Select t.Année, d.CodeWilaya, f.CodeTypeCompte, 
        sum(f.MontantV) as MontV 
from FOperation f, DAgence d, DTemps t
where f.NumAgence = d.NumAgence
      and f.CodeTemps = t.CodeTemps
group by cube (t.Année, d.CodeWilaya, f.CodeTypeCompte)
order by t.Année, d.CodeWilaya, f.CodeTypeCompte;

/*Reponse 4*/
/*Introduction de la fonction grouping pour chaque dimension dans R2*/
Select t.Année, d.CodeWilaya, f.CodeTypeCompte, 
        sum(f.MontantV) as MontV, 
grouping (t.Année) as An, grouping (d.CodeWilaya) as Cw, 
        grouping (f.CodeTypeCompte) as Tc 
from FOperation f, DAgence d, DTemps t
where f.NumAgence = d.NumAgence
        and f.CodeTemps = t.CodeTemps
group by rollup (t.Année, d.CodeWilaya, f.CodeTypeCompte)
order by t.Année, d.CodeWilaya, f.CodeTypeCompte;

/*Reponse 5*/
/*Remplacement de la fonction grouping par la fonction grouping_id*/
Select t.Année, d.CodeWilaya, f.CodeTypeCompte, 
        sum(f.MontantV) as MontV, 
grouping_id (t.Année, d.CodeWilaya, f.CodeTypeCompte) as GID 
from FOperation f, DAgence d, DTemps t
where f.NumAgence = d.NumAgence
        and f.CodeTemps = t.CodeTemps
group by rollup (t.Année, d.CodeWilaya, f.CodeTypeCompte)
order by t.Année, d.CodeWilaya, f.CodeTypeCompte;

/*Reponse 6*/
/*Amélioration de la lisibilité de la requête en utilisant la fonction decode*/
Select decode(grouping (t.Année),1,'Total_A',t.Année)as an, 
decode(grouping (d.CodeWilaya),1,'Total_W',d.CodeWilaya)as cdw,
decode(grouping (f.CodeTypeCompte),1,'Total_T',f.CodeTypeCompte) as cdt
from FOperation f, DAgence d, DTemps t
where f.NumAgence = d.NumAgence
        and f.CodeTemps = t.CodeTemps
group by rollup(t.Année, d.CodeWilaya, f.CodeTypeCompte)
order by t.Année, d.CodeWilaya, f.CodeTypeCompte;

/*Reponse 7*/
/*Classement des spécialités dans chaque ville selon leurs montants versés*/
/*Classement non dense*/
Select a.codeWilaya, a.codeBanque, sum(f.montantV) as MontantV, 
        rank() over (order by sum(MontantV) Desc) as Classement 
from DAgence a, FOperation f
where a.NumAgence = f.NumAgence
group by (a.codeWilaya,a.codeBanque);
/*Classement dense*/
Select a.codeWilaya, a.codeBanque, sum(f.montantV) as MontantV, 
      dense_rank() over (order by sum(MontantV) Desc) as Classement 
from DAgence a, FOperation f
where a.NumAgence = f.NumAgence
group by (a.codeWilaya,a.codeBanque);


/*Reponse 8*/
/*Répartition cumulative du nombre d’opérations, par banque dans chaque année*/
Select t.Année , d.NomBanque, sum(f.NbOperationR+f.NbOperationR) as SommeNb,
  cume_dist() over (partition by t.Année order by sum(f.NbOperationR+f.NbOperationR)) 
    as cum_dist_nb
from FOperation f, DAgence d, DTemps t
where f.NumAgence = d.NumAgence
and f.CodeTemps = t.CodeTemps
group by t.Année , d.NomBanque
order by t.Année , d.NomBanque;

/*Reponse 9*/
/*Le nombre d’opérations global pour chaque mois, et segmentation des mois en 4 segments à l’aide de la fonction ntile*/
select t.Mois, sum(f.NbOperationR+f.NbOperationV) as SommeNb, 
  ntile(4) over(order by sum(f.NbOperationR+f.NbOperationV)) 
    as ntile_4
from FOperation f, DTemps t
where f.CodeTemps = t.CodeTemps
group by t.Mois
order by t.Mois;

/*Reponse 10*/
/*Ratio du montant versé pour chaque banque, dans chaque année*/
Select t.Année, d.NomBanque, sum(f.MontantV) as MontV, 
        sum(sum(f.MontantV)) over() as Total,
        ratio_to_report (sum(f.MontantV)) 
          over(partition by t.Année) as Ratio
from FOperation f, DAgence d, Dtemps t
where f.NumAgence = d.NumAgence and f.CodeTemps = t.CodeTemps
group by t.Année, d.NomBanque;

/*Reponse 11*/
/*L’agence qui réalise un nombre d’opérations maximal pour chaque banque*/
Select codeBanque, NumAgence, nbOp
from (select da.codeBanque, da.NumAgence, 
        sum(fo.NbOperationR+fo.NbOperationV) as nbOp, 
        max (sum(fo.NbOperationR+fo.NbOperationV)) 
          over (partition by da.codeBanque) as Max_nb_op
      from DAgence da, FOperation fo
where da.NumAgence = fo.NumAgence
group by da.codeBanque, da.NumAgence)
where nbOp = Max_nb_op;
