// DESIGN SPECIFIC
`define ALU_BUS_WITH 		16
`define ALU_AMM_ADDR_WITH 	8
`define ALU_AMM_DATA_WITH	8  

//definirea starilor
`define RESET 						0 
`define HEADER_READ				1
`define PAYLOAD_READ				2
`define DECODE						3
`define EXECUTE					4
`define STORE_HEADER				5
`define STORE_PAYLOAD			6
`define ERROR						7 

//definirea operatiilor
`define ADD			4'b0000
`define AND			4'b0001
`define OR			4'b0010
`define XOR			4'b0011
`define NOT			4'b0100
`define INC			4'b0101
`define DEC			4'b0110
`define NEG			4'b0111
`define SHR			4'b1000
`define SHL			4'b1001

 module alu(
	 // Output interface
    output[`ALU_BUS_WITH - 1:0] data_out,
	 output 							  valid_out,
	 output 							  cmd_out,

	 //Input interface
	 input [`ALU_BUS_WITH - 1:0] data_in,
	 input 							  valid_in,
	 input 							  cmd_in,
	 
	 // AMM interface
	 output 									 amm_read,
	 output[`ALU_AMM_ADDR_WITH - 1:0] amm_address,
	 input [`ALU_AMM_DATA_WITH - 1:0] amm_readdata,
	 input 									 amm_waitrequest,
	 input[1:0] 							 amm_response,
	 
	 
	 //clock and reset interface
	 input clk,
	 input rst_n
    );
	
	// TODO: Implement Not-so-simple ALU
	
//Stari	
integer state;
integer next_state;

//Counter payload
integer COUNTER;
integer COUNTER_NEXT;

//Counter index
integer COUNTER_INDEX;
integer COUNTER_INDEX_NEXT;


//header_in
reg [3:0]opcode; //codul operatiei
reg [5:0] nof_operands; //nr de operanzi


//payload_in
reg [1:0] mod[62:0]; //mod pentru fiecare payload
reg [7:0] opperand_address[62:0]; //operandul sau adresa pentru fiecare payload

//header_out
reg error; 

//payload_out
reg [11:0]result;

//reg pentru memorie
reg amm_read_reg;
reg [7:0]amm_address_reg;


//reg pentru iesiri
reg [`ALU_BUS_WITH - 1:0] data_out_reg;
reg valid_out_reg;
reg cmd_out_reg;

//Aux
reg[5:0] index_address[62:0]; //vector pentru stocarea index-urilor adreselor 
integer i;


initial begin
next_state 	= `RESET;
state 		= `RESET;

COUNTER =0;
COUNTER_NEXT =0;

COUNTER_INDEX = 0;
COUNTER_INDEX_NEXT = 0;
end	
	
always @ (posedge clk)
begin
	if(rst_n == 1) //daca nu e activ 
		begin
		state <= next_state;
		COUNTER <= COUNTER_NEXT;
		COUNTER_INDEX <=COUNTER_INDEX_NEXT;
		end
		else begin
		state <= `RESET;
		end
end	
	
	
always @ (*)
begin	
//initializare registrii de iesire
error = 0;
valid_out_reg = 0;
cmd_out_reg = 0;	
data_out_reg = 0;
amm_read_reg = 0;

	
		case (state)
		`RESET:
		begin
	
			next_state = `HEADER_READ;
		end
		
		`HEADER_READ:
		begin
			COUNTER_NEXT = 0;
			COUNTER_INDEX_NEXT=0;
			result = 0;
			amm_read_reg = 0;
			amm_address_reg = 0;
			
			if(valid_in == 1 && cmd_in ==1)
			 begin
				nof_operands = data_in[5:0]; //stochez numarul de operanzi
				opcode = data_in[11:8]; //stochez codul operatiei
				
				//in cazul AND se va initializa vectorul de adrese/operanzi cu 11111111 pentru a nu influenta rezultatul final
				if(opcode == `AND)
				begin
					for(i=0;i<63;i=i+1)
					begin
						mod[i] = 0;
						index_address[i] = 0;
						opperand_address[i] = 8'b11111111;
					end
				end
				else //altfel initializez vectorul de adrese/operanzi cu 0
				begin
					for(i=0;i<63;i=i+1)
					begin
						mod[i] = 0;
						index_address[i] = 0;
						opperand_address[i] = 0;
					end
				end
				
				//tratarea cazurilor de eroare pentru header
				if(nof_operands == 0 || nof_operands > 63)
				begin
					error = 1;
					next_state = `ERROR;
				end
				else if(opcode == `NOT && nof_operands >1)
				begin
					error = 1;
					next_state = `ERROR;
				end
				else if(opcode == `INC && nof_operands >1)
				begin
					error = 1;
					next_state = `ERROR;
				end
				else if(opcode == `DEC && nof_operands >1)
				begin
					error = 1;
					next_state = `ERROR;
				end
				else if(opcode == `NEG && nof_operands >1)
				begin
					error = 1;
					next_state = `ERROR;			
				end
				else if(opcode == `SHR && nof_operands !=2)
				begin
					error = 1;
					next_state = `ERROR;						
				end
				else if(opcode == `SHL && nof_operands !=2)
				begin
					error = 1;
					next_state = `ERROR;				
				end
				else begin //in caz ca nu exista erori trec in starea urmatoare de citire a operanzilor/adreselor
					next_state = `PAYLOAD_READ;
				end
					
			 end
			 
		  end
			
	
	
		`PAYLOAD_READ:begin
			i=0;
			if(valid_in == 1 && cmd_in == 0)begin
				opperand_address[COUNTER_NEXT] = data_in[7:0]; //stochez operandul sau adresa in vector
				mod[COUNTER_NEXT] = data_in[9:8]; //stochez modul(adresare directa sau indirecta) in vector
				
				if(mod[COUNTER_NEXT] == 2'b01) //daca modul de adresare este indirect
				begin
					index_address[COUNTER_INDEX_NEXT] = COUNTER_NEXT; //stochez indexul adresei ce va trebui cautata in memorie intr un vector
					COUNTER_INDEX_NEXT= COUNTER_INDEX + 1; //contorizez numarul de adresari indirecte
				end
				else
					index_address[COUNTER_INDEX_NEXT] = 0;
				
				if(COUNTER_NEXT + 1 == nof_operands) //verific daca numarul de citiri este egal  cu numarul de operanzi
				begin
					
					if(COUNTER_INDEX_NEXT != 0) //verific daca exista adresari indirecte; daca nu exista trec direct la executarea operatiei/operatiilor
						next_state = `DECODE;
					else
						next_state = `EXECUTE;
				end
				else //daca nu am citit toti operanzii reiau citirea
				begin
					COUNTER_NEXT = COUNTER + 1;
					next_state = `PAYLOAD_READ;
				end

			end
		end
		
		
		`DECODE:begin
			//activez amm_read_reg si stochez adresa operandului
			amm_read_reg = 1; //activez amm_read pentru citire
			amm_address_reg = opperand_address[index_address[i]]; //pun adresa ce trebuie cautata in memorie
					
			if( amm_waitrequest == 0 ) //daca waitrequest s-a activat pot prelua valoarea operandului
			begin
			
				if(amm_response !=0)
				begin
					amm_read_reg = 0;
					amm_address_reg = 0;
					next_state=`ERROR; //in caz ca amm_response != 0 generez eroare
				end
			
				if(amm_response == 0 ) //daca nu am nicio eroare
				begin
					opperand_address[index_address[i]]=amm_readdata; //se suprascrie adresa cu valoarea operandului din memorie
					amm_read_reg = 0;
					amm_address_reg = 0;
					
					if(i == COUNTER_INDEX_NEXT-1 ) //verific daca s-au suprascris toate adresele cu valori; in caz afirmativ trec la executarea operatiilor
						next_state=`EXECUTE;
					else
					begin //daca mai am adrese de citit din memorie trec la indexul urmator si reiau operatiile
						i=i+1;
						next_state=`DECODE;
					end
				 end
				
			end
			else
				next_state=`DECODE; //in caz ca amm_waitrequest nu se activeaza(nu devine 0) buclez la starea curenta si continui cautarea
		end
		
		`EXECUTE:begin
			
			case(opcode)
			
			`ADD:begin //ADD
				result = 0;
				for(i=0;i<63;i=i+1)
				begin
					if(opperand_address[i] !=0)
						result = result + opperand_address[i]; //adun toti operanzii din vector
				end
				next_state = `STORE_HEADER;
			end
			
			`AND:begin //AND
					result[7:0]=8'b11111111; //initializez result cu 8'b11111111 pentru a nu influenta rezultatul(joaca rolul de element neutru)
					for (i = 0 ; i<63 ; i=i+1 )
					begin
						result[7:0]=result[7:0] & opperand_address[i][7:0];
					end
				next_state = `STORE_HEADER;

			end
			
			`OR:begin //OR
				result =0;
				for (i = 0 ; i<63 ; i=i+1 )
					begin
						if(opperand_address[i] !=0)
						result[7:0]=result[7:0] | opperand_address[i][7:0];
					end
				next_state = `STORE_HEADER;
			end
			
			`XOR:begin //XOR
					result =0;
					for (i = 0 ; i<63 ; i=i+1 )
					begin
						result[7:0]=result[7:0] ^ opperand_address[i][7:0];
					end
				next_state = `STORE_HEADER;
			end
			
			`NOT:begin //NOT
				result = 0;
				result[7:0] = ~opperand_address[0][7:0];
				next_state = `STORE_HEADER;
			end
			
			`INC:begin //INC
				result = 0;
				result = opperand_address[0] + 1;
				next_state = `STORE_HEADER;
			end
			
			`DEC:begin //DEC
				result = 0;
				result = opperand_address[0] - 1;
				next_state = `STORE_HEADER;
			end
			
  			`NEG:begin //NEG
				result = 0;
				result[7:0] = -opperand_address[0][7:0];
				next_state = `STORE_HEADER;
			end
			
			`SHR:begin //SHR
				result = 0;
				result[7:0] = opperand_address[0][7:0] >> opperand_address[1][7:0];
				next_state = `STORE_HEADER;
			end
			
			`SHL:begin //SHL
				result = 0;
				result[7:0] = opperand_address[0][7:0] << opperand_address[1][7:0];
				next_state = `STORE_HEADER;
			end
			
			endcase
		 end
		 
			`STORE_HEADER:begin
				//header_out
				valid_out_reg = 1;
				cmd_out_reg = 1;
				data_out_reg[3:0] = opcode;
				data_out_reg[4] = error;
				
			
				next_state = `STORE_PAYLOAD;
			end
			
			
			
			`STORE_PAYLOAD:begin
				//payload_out
				cmd_out_reg = 0;
				valid_out_reg = 1;
				data_out_reg[11:0] = result;
			
				next_state = `RESET;
			end
			
			
			`ERROR:begin
				//header_out
				valid_out_reg = 1;
				cmd_out_reg = 1;
				error = 1;
				data_out_reg[3:0] = opcode;
				data_out_reg[4] = error;
				
				next_state = `ERROR +1;
			end
			
			`ERROR + 1:begin
				//payload_out
				cmd_out_reg = 0;
				valid_out_reg = 1;
				data_out_reg[11:0] = 12'hBAD; //0x0BAD
				
				next_state = `RESET;
			end
			
		endcase
		
end


assign amm_address = amm_address_reg;
assign amm_read = amm_read_reg;	
	
assign data_out = data_out_reg;
assign valid_out = valid_out_reg;
assign cmd_out = cmd_out_reg;

endmodule
