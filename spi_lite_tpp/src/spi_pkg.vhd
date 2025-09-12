library IEEE;
use IEEE.STD_LOGIC_1164.all;

package spi_pkg is

      function log2(n : in integer) return integer;


end spi_pkg;

package body spi_pkg is

   function log2(n : in integer) return integer is
     variable i : integer := 0;
   begin
     while (2**i <= n) loop
       i := i + 1;
     end loop;
     return i-1;
   end log2;

end spi_pkg;
