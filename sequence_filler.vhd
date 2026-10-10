library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port(
    i_clk   : in std_logic; -- segnale di clock
    i_rst   : in std_logic; -- segnale di reset
    i_start : in std_logic; -- segnale di partenza di elaborazione
    i_add   : in std_logic_vector (15 downto 0); -- input primo indirizzo da cui leggere
    i_k     : in std_logic_vector (9 downto 0); -- input intero numero di parole
    
    o_done  : out std_logic; -- segnale per indicaare la fine della esecuzione
    
    o_mem_addr  : out std_logic_vector (15 downto 0); -- indirizzo di accesso in memoria sia scrittura che lettura
    i_mem_data  : in std_logic_vector (7 downto 0);  -- input di dati dalla memoria
    o_mem_data  : out std_logic_vector (7 downto 0); -- output di dati dalla memoria
    o_mem_we    : out std_logic; -- segnale per indicare modalità lettura/scrittura dalla memoria
    o_mem_en    : out std_logic -- segnale di attivazione della memoria
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state_type is (IDLE, WAIT_R_D, READ, EVALUATE, WAIT_W_D, WRITE_D, WAIT_W_C, WRITE_C, DONE);

    signal state : state_type := IDLE; -- assegnazione dello stato di reset
    signal address: std_logic_vector(15 downto 0); -- indirizzo da richiedere alla memoria sia in lettura che in scrittura
    signal credibility : std_logic_vector(7 downto 0) := "00011111"; -- valore 31 in binario 
    signal value : std_logic_vector(7 downto 0) := "00000000"; -- valore valido nella sequenza
    signal last_valid_value : std_logic_vector(7 downto 0) := "00000000"; -- ultimo valore valido nella sequenza
    signal counter : unsigned(9 downto 0);  -- contatore per tener traccia della sequenza
begin
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then 
            state <= IDLE; -- stato iniziale 
            o_done <= '0';
            o_mem_en <= '0'; 
            o_mem_we <= '0'; 
            o_mem_data <= (others => '0');
            o_mem_addr <= (others => '0');
            address <= (others => '0');
            counter <= (others => '0');
            credibility <= (others => '0');
            value <= (others => '0');
            last_valid_value <= (others => '0');

        elsif rising_edge(i_clk) then 
            case state is
            
                when IDLE =>
                    if i_start = '1' then           
                        state <= WAIT_R_D;
                        address <= i_add; -- assegno ad address il valore di input i_add al primo indirizzo 
                        o_mem_data <= (others => '0');
                        counter <= (others => '0');
                        credibility <= (others => '0');
                        value <= (others => '0');
                        last_valid_value <= (others => '0');                     
                        o_mem_en <= '1'; -- attivo la memoria 
                        o_mem_we <= '0';
                        o_mem_addr <= i_add;  
                    end if;
                    
                when WAIT_R_D =>
                        state <= READ;
                        
                when READ => 
                    value <= i_mem_data;
                    if to_integer(counter) < to_integer(unsigned(i_k)) then  -- verifico che non sia terminata la sequenza da elaborare             
                        state <= EVALUATE;
                    else -- altrimenti stato finale
                        state <= DONE; 
                        o_done <= '1';
                    end if;
                    
                when EVALUATE =>
                    if value = "00000000" then -- caso in cui il valore è nullo
                        if to_integer(unsigned(credibility)) > 1 then
                            credibility <= std_logic_vector(unsigned(credibility) - 1);
                        else 
                            credibility <= (others => '0');
                        end if;        
                        o_mem_we <= '1';
                        o_mem_addr <= address;
                        o_mem_en <= '1';
                        o_mem_data <= last_valid_value;
                        state <= WAIT_W_D; 
                    else -- caso in cui il valore è valido
                        last_valid_value <= value;
                        credibility <= "00011111"; -- resetto credibility a 31
                        address <= std_logic_vector(unsigned(address) + 1); 
                        o_mem_we <= '1';
                        o_mem_addr <= std_logic_vector(unsigned(address) + 1);
                        o_mem_en <= '1';
                        o_mem_data <= "00011111";
                        state <= WAIT_W_C; 
                    end if;
                                        
                when WAIT_W_D =>    
                        state <= WRITE_D;
                     
                when WRITE_D =>
                        address <= std_logic_vector(unsigned(address) + 1); 
                        o_mem_we <= '1'; 
                        o_mem_data <= std_logic_vector(unsigned(credibility));
                        o_mem_addr <= std_logic_vector(unsigned(address) + 1);
                        state <= WAIT_W_C;
                    
                when WAIT_W_C =>
                        state <= WRITE_C;
                    
                when WRITE_C => 
                        address <= std_logic_vector(unsigned(address) + 1); 
                        o_mem_addr <= std_logic_vector(unsigned(address) + 1);
                        o_mem_en <= '1';
                        o_mem_we <= '0';
                        counter <= counter + 1; -- aggiorno il contatore
                        state <= WAIT_R_D; -- torno indietro a leggere il prossimo numero nella sequenza
                             
                when DONE => 
                    if i_start = '0' then
                    o_done <= '0';
                    o_mem_en <= '0';
                    state <= IDLE;
                    end if;
                    
                when others =>
                    state <= IDLE;   
                                        
            end case;                        
        end if;
    end process;
end Behavioral;