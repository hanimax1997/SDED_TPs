/*Reponse 1*/

/*Creation de la vue matérialisée VM1*/
CREATE MATERIALIZED VIEW VM1 
    BUILD IMMEDIATE REFRESH COMPLETE ON DEMAND
    AS select CodeOp, DateOp
      from Operation
      where TypeOp = '2'
      and DateOp>='01/01/2018'
      and DateOp<='31/01/2018';

/*Création du journal LOG pour utiliser FAST*/
CREATE MATERIALIZED VIEW LOG ON Operation;


/*Reponse 2*/

/*Creation de la vue materialisée VM2*/
CREATE MATERIALIZED VIEW VM2 
    BUILD IMMEDIATE REFRESH FAST ON DEMAND
    AS select CodeOp, DateOp
      from Operation
      where TypeOp = '2'
      and DateOp>='01/01/2018'
      and DateOp<='31/01/2018';


/*Reponse 3*/

/*Ajout d'un retrait en Janvier 2018*/
INSERT INTO Operation
  VALUES (999999,'21/01/2018',
        '19:23','2',90000.21,NULL,28);

/*Consulter l'état du journal log avant rafraichissement*/
select * from MLOG$_Operation;

/*Utiliser set timing on pour examiner les temps de rafraichissement*/
set timing on

/*Rafraichissement de la vue materialisée VM1*/
execute DBMS_MVIEW.REFRESH('VM1');

/*Rafraichissement de la vue materialisée VM2*/
execute DBMS_MVIEW.REFRESH('VM2');

/*Répercussion de l’ajout d’un retrait en janvier 2018 sur la vue VM1 */
select * from VM1 where CodeOp=999999;

/*Répercussion de l’ajout d’un retrait en janvier 2018 sur la vue VM2 */
select * from VM2 where CodeOp=999999;

/*Consulter l'état du journal log après rafraichissement*/
select * from MLOG$_Operation;


/*Reponse 4*/

/*Question 3 avec Modification*/
UPDATE Operation 
  SET DateOp='07/01/2018' 
  Where CodeOp=999999;  

select * from MLOG$_Operation;

execute DBMS_MVIEW.REFRESH('VM1');
execute DBMS_MVIEW.REFRESH('VM2');

select * from MLOG$_Operation;

select * from VM1 where CodeOp=999999;
select * from VM2 where CodeOp=999999;

/*Question 3 avec Suppresion*/
DELETE FROM Operation 
  Where CodeOp=999999;

select * from MLOG$_Operation;

execute DBMS_MVIEW.REFRESH('VM1');
execute DBMS_MVIEW.REFRESH('VM2');

select * from MLOG$_Operation;

select * from VM1 where CodeOp=999999;
select * from VM2 where CodeOp=999999;

/*Reponse 5*/

/*Création et alimentation de la vue materialisée VM3*/
CREATE MATERIALIZED VIEW VM3 
    BUILD IMMEDIATE REFRESH COMPLETE ON COMMIT
    AS select CodeOp, DateOp
      from Operation O, Compte C
     where
     (O.VersementCompte=C.NumCompte or O.RetraitCompte=C.NumCompte)
     and C.est_domicileAg>=1 and C.est_domicileAg<=100;


/*Reponse 6*/

/*Trouver un compte de l'agence 88*/
SELECT NumCompte From Compte Where est_domicileAg=88; 

/*On prend le compte numéro 40195*/

/*Inserer une opération dans l'agence 88*/
INSERT INTO Operation 
  VALUES (999999,'04/11/2019','10:25',
        '1',1000000.21,40195,NULL);

/*Valider avec COMMIT*/
COMMIT;

/*Tester la mise à jour de VM3*/
SELECT CodeOp FROM VM3 WHERE CodeOp=999999;

/*Reponse 7*/

/*Création de la vue materialisée VM4*/
CREATE MATERIALIZED VIEW VM4
    BUILD IMMEDIATE REFRESH COMPLETE ON DEMAND
    AS select est_domicileAg as CodeAgence, 
              count(NumCompte) as NBComptes
      from Compte
     group by est_domicileAg;


/*Reponse 8*/

/*Création du journal LOG pour utiliser FAST sur la table Compte*/
CREATE MATERIALIZED VIEW LOG ON Compte;

/*Création d’une vue matérialisée identiques à VM3 avec l’option FAST */
CREATE MATERIALIZED VIEW VM33 
    BUILD IMMEDIATE REFRESH FAST ON COMMIT
    AS select CodeOp, DateOp
      from Operation O, Compte C
     where
     (O.VersementCompte=C.NumCompte or O.RetraitCompte=C.NumCompte)
     and C.est_domicileAg>=1 and C.est_domicileAg<=100;

/*Création d’une vue matérialisée identiques à VM4 avec l’option FAST */
CREATE MATERIALIZED VIEW VM44
    BUILD IMMEDIATE REFRESH FAST ON DEMAND
    AS select est_domicileAg as CodeAgence, 
              count(NumCompte) as NBComptes
      from Compte
     group by est_domicileAg;


/*Solution*/

/*Suppression des journaux LOG de Compte et Operation*/
Drop MATERIALIZED VIEW LOG ON Operation;
Drop MATERIALIZED VIEW LOG ON Compte;

/*Création et ajout de rowid dans le journal des tables Operation et Compte*/
CREATE MATERIALIZED VIEW LOG ON Operation with rowid;
CREATE MATERIALIZED VIEW LOG ON Compte with rowid;

/*Création d’une vue matérialisée identiques à VM3 avec l’option FAST */
CREATE MATERIALIZED VIEW VM33 
    NOLOGGING CACHE
    BUILD IMMEDIATE REFRESH FAST ON COMMIT
    AS select Operation.CodeOp, Operation.DateOp, 
              Operation.ROWID AS OROW, 
              Compte.ROWID AS CROW
      from Operation, Compte
     where
     (Operation.VersementCompte=Compte.NumCompte 
      or Operation.RetraitCompte=Compte.NumCompte)
     and Compte.est_domicileAg>=1 
     and Compte.est_domicileAg<=100;



/*Suppression des journaux LOG de Compte et Operation*/
Drop MATERIALIZED VIEW LOG ON Operation;
Drop MATERIALIZED VIEW LOG ON Compte;

/*Création et ajout des rowid nécessaires dans le journal des tables Operation et Compte 
ainsi que l’option including new values et with sequence*/

CREATE MATERIALIZED VIEW LOG ON Operation
WITH SEQUENCE, ROWID (CodeOp, DateOp, 
                      VersementCompte, 
                      RetraitCompte) 
INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW LOG ON Compte
WITH SEQUENCE, ROWID (NumCompte, 
                      est_domicileAg) 
INCLUDING NEW VALUES;


/*Création d’une vue matérialisée identiques à VM4 avec l’option FAST */
CREATE MATERIALIZED VIEW VM44
    BUILD IMMEDIATE REFRESH FAST ON DEMAND
    AS select est_domicileAg as CodeAgence, 
              count(NumCompte) as NBComptes
      from Compte
     group by est_domicileAg;
