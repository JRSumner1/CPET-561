LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY DE1_SoC_Lab10 IS
  PORT (
    -- General input signals
    CLOCK2_50 : IN STD_LOGIC;
    KEY       : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
    SW        : IN STD_LOGIC_VECTOR (7 DOWNTO 0);

    -- Ram signals
    DRAM_CLK, DRAM_CKE                           : OUT STD_LOGIC;
    DRAM_ADDR                                    : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
    DRAM_BA                                      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    DRAM_CS_N, DRAM_CAS_N, DRAM_RAS_N, DRAM_WE_N : OUT STD_LOGIC;
    DRAM_DQ                                      : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    DRAM_UDQM, DRAM_LDQM                         : OUT STD_LOGIC;

    -- Audio signals
    AUD_ADCDAT  : IN STD_LOGIC;
    AUD_ADCLRCK : INOUT STD_LOGIC;
    AUD_BCLK    : INOUT STD_LOGIC;
    AUD_DACDAT  : OUT STD_LOGIC;
    AUD_DACLRCK : INOUT STD_LOGIC;
    AUD_XCK     : OUT STD_LOGIC;

    -- the_audio_and_video_config_0
    FPGA_I2C_SCLK : OUT STD_LOGIC;
    FPGA_I2C_SDAT : INOUT STD_LOGIC;

    -- General output/inout signals
    LEDR   : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    GPIO_0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
  );
END DE1_SoC_Lab10;

ARCHITECTURE rtl OF DE1_SoC_Lab10 IS

  --   Nios II system component
  COMPONENT nios_system IS
    PORT (
      AUD_ADCDAT_to_the_audio_0   : IN STD_LOGIC := 'X';                                    -- ADCDAT
      AUD_ADCLRCK_to_the_audio_0  : IN STD_LOGIC := 'X';                                    -- ADCLRCK
      AUD_BCLK_to_the_audio_0     : IN STD_LOGIC := 'X';                                    -- BCLK
      AUD_DACDAT_from_the_audio_0 : OUT STD_LOGIC;                                          -- DACDAT
      AUD_DACLRCK_to_the_audio_0  : IN STD_LOGIC    := 'X';                                 -- DACLRCK
      clk_clk                     : IN STD_LOGIC    := 'X';                                 -- clk
      i2c_SDAT                    : INOUT STD_LOGIC := 'X';                                 -- SDAT
      i2c_SCLK                    : OUT STD_LOGIC;                                          -- SCLK
      key_export                  : IN STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => 'X');     -- export
      ledr_export                 : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);                       -- export
      pin_export                  : OUT STD_LOGIC;                                          -- export
      reset_reset                 : IN STD_LOGIC := 'X';                                    -- reset
      sdram_addr                  : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);                      -- addr
      sdram_ba                    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                       -- ba
      sdram_cas_n                 : OUT STD_LOGIC;                                          -- cas_n
      sdram_cke                   : OUT STD_LOGIC;                                          -- cke
      sdram_cs_n                  : OUT STD_LOGIC;                                          -- cs_n
      sdram_dq                    : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => 'X'); -- dq
      sdram_dqm                   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);                       -- dqm
      sdram_ras_n                 : OUT STD_LOGIC;                                          -- ras_n
      sdram_we_n                  : OUT STD_LOGIC;                                          -- we_n
      sdram_clk_clk               : OUT STD_LOGIC;                                          -- clk
      sw_export                   : IN STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => 'X')      -- export
    );
  END COMPONENT nios_system;

  ----------------------------------------------------------------------------
  --               Internal Wires and Registers Declarations                --
  ----------------------------------------------------------------------------

  SIGNAL reset_n         : STD_LOGIC;
  SIGNAL DRAM_DQM        : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL int_AUD_BCLK    : STD_LOGIC;
  SIGNAL int_AUD_DACDAT  : STD_LOGIC;
  SIGNAL int_AUD_DACLRCK : STD_LOGIC;
  SIGNAL count           : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL test_sig        : STD_LOGIC;

BEGIN

  --   LEDR    <= "1010101010";
  AUD_XCK <= count(1);

  reset_n   <= NOT KEY(0);
  DRAM_UDQM <= DRAM_DQM(1);
  DRAM_LDQM <= DRAM_DQM(0);

  --int_AUD_BCLK <= AUD_BCLK;
  GPIO_0(0)  <= AUD_BCLK;
  AUD_DACDAT <= int_AUD_DACDAT;
  GPIO_0(1)  <= int_AUD_DACDAT;
  --int_AUD_DACLRCK <= AUD_DACLRCK;
  GPIO_0(2) <= AUD_DACLRCK;
  GPIO_0(3) <= test_sig;
  NiosII : nios_system
  PORT MAP
  (
    AUD_ADCDAT_to_the_audio_0   => AUD_ADCDAT,
    AUD_ADCLRCK_to_the_audio_0  => AUD_ADCLRCK,
    AUD_BCLK_to_the_audio_0     => AUD_BCLK,
    AUD_DACDAT_from_the_audio_0 => int_AUD_DACDAT,
    AUD_DACLRCK_to_the_audio_0  => AUD_DACLRCK,
    clk_clk                     => CLOCK2_50,
    i2c_SDAT                    => FPGA_I2C_SDAT,
    i2c_SCLK                    => FPGA_I2C_SCLK,
    pin_export                  => test_sig,
    reset_reset                 => reset_n,
    sdram_addr                  => DRAM_ADDR,
    sdram_ba                    => DRAM_BA,
    sdram_cas_n                 => DRAM_CAS_N,
    sdram_cke                   => DRAM_CKE,
    sdram_cs_n                  => DRAM_CS_N,
    sdram_dq                    => DRAM_DQ,
    sdram_dqm                   => DRAM_DQM,
    sdram_ras_n                 => DRAM_RAS_N,
    sdram_we_n                  => DRAM_WE_N,
    sdram_clk_clk               => DRAM_CLK,
    sw_export                   => SW(7 DOWNTO 0),
    ledr_export                 => LEDR,
    key_export                  => KEY
  );

  clkgen : PROCESS (CLOCK2_50, reset_n)
  BEGIN
    IF (reset_n = '1') THEN
      count <= "0000";
    ELSIF (rising_edge(CLOCK2_50)) THEN
      count <= count + 1;
    END IF;
  END PROCESS;
END rtl;