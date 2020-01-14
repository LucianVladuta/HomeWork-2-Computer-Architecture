# HomeWork-2-Computer-Architecture


I.Descrierea automatului:
0.RESET
1.HEADER_READ
2.PAYLOAD_READ
3.DECODE
4.EXECUTE
5.STORE_HEADER
6.STORE_PAYLOAD
7.ERROR
8.ERROR + 1
 

II.Descrierea functionarii:
Starea de RESET(0) reprezinta starea initiala a sistemului.Daca rst_n = 0(activ) inseamna ca raman in starea de RESET(0), iar cand rst_n = 1(inactiv) pot trece in starea urmatoare HEADER_READ(1).
In starea HEADER_READ(1) se va  citi un pachet de date de intrare unde se vor decodifica informatii despre codul operatiei si numarul de operanzi.Se vor initializa vectorii opperand_address si mod.Acestia vor fi initializati cu 0 ambii vectori(avand rol de element neutru), doar in cazul in care codul operatiei este AND,  vectorul opperand_address va fi initializat cu 8’b11111111 (avand rol de element neutru)pentru a se putea face AND pe toate elementele vectorului fara a influenta rezultatul final.In caz ca numarul de operanzi nu corespunde cu codul operatiei  sau numarul de operanzi == 0 se va trece direct in starea ERROR(7).Altfel, daca totul este ok pot trece in starea urmatoare PAYLOAD_READ(2);

In starea PAYLOAD_READ(2)  citesc fiecare payload primit, iar pentru fiecare payload primit , decodific opperandul/adresa, precum si modul de adresare(direct sau indirect) le pun pe fiecare in vector(oppperand_address[62:0], respective mod[62:0]).La fiecare citire a unui payload verific daca modul de adresare este direct sau indirect.In caz ca modul este indirect, indexul adresei ce va fi ulterior decodificata il pun intr un vector (index_address[62:0]).Daca numarul de payload uri citite nu corespunde cu numarul de operanzi primit din header continui citirea, altfel pot trece in starea urmatoare astfel:
Daca nu exista adrese de decodificat trec imediat la starea urmatoare `EXECUTE(4).
Daca exista adrese de decodificat trec in starea `DECODE(3).

In starea de `DECODE preiua adresele operanzilor pe care le transmit memoriei pentru a-mi intoarce valoarea operandului.Activez registrul de citire (amm_read_reg), transmit adresa operandului respectiv(amm_address_reg) apoi tin constant aceste valori pana cand se activeaza waitrequest( waitrequest == 0).Cand waitrequest == 0  verific daca valoarea primita este cea corecta astfel:
Daca amm_response != 0 trec direct in starea de `ERROR;
Daca amm_response == 0 suprascriu adresa din vectorul operand_address cu valoarea operandului obtinuta si dezactivez amm_read_reg.
Se repeta aceaste operatii pana cand decodific toate adresele,iar cand am terminat  trec in starea urmatoare `EXECUTE(4);

In starea EXECUTE(4) efectuez operatiile.Pentru ADD voi aduna toti operanzi din vectorul opperand_address.Celelalte valori din vector sunt initializate cu 0 astfel incat nu va influneta rezultatul final.In cazul AND primii 8 biti ai vectorului result sunt initializati cu 1 pentru a nu influenta rezultatul final si pentru a putea face AND pentru toate elementele vectorului.Rezultatul va fi trunchiat la 8 biti.Pentru cazurile OR, XOR se procedeaza asemanator ca la ADD, doar ca rezultatul este trunchiat la 8 biti, neavand nevoie de toti bitii.Pentru celelalte cazuri se executa operatiile pentru primul sau primii 2 operanzi din vector.
Dupa efectuarea operatiei/operatiilor se trece in urmatoarea stare:STORE_HEADER;
In starea de STORE_HEADER activez valid_out_reg si cmd_out_reg pentru a indica headerul de iesire si scriu in registrul de iesire(data_out_reg) codul operatiei si eroarea(fiind 0) dupa care trec in starea urmatoare :STORE_PAYLOAD:
In starea de STORE_PAYLOAD tin active doar valid_out_reg, cmd_out_reg il dezactivez pentru a sugera ca se va transmite payload ul, astfel incat in data_out_reg trec rezultatul obtinut in urma efectuarii operatiei/operatiilor.
In starile de ERROR si ERROR + 1 preocedez asemanator cu STORE_HEADER si STORE_PAYLOAD  doar ca in header-ul de iesire trec codul operatiei si eroarea(fiind 1), iar in payload ul de iesire trec rezultatul care este egal cu 0xBAD.
